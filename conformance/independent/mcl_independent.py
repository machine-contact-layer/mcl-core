"""
An independent MCL implementation.

RELEASE GATE ITEM 15.

WHAT THIS IS

A second implementation of MCL Wire Tier-0, the MCL Link frame, and the Link
capability/version negotiation, written from the NORMATIVE SPECIFICATIONS and
the PUBLISHED VECTORS. It exists so that "two independent implementations
interoperate" can be tested rather than asserted.

WHAT IT DELIBERATELY IS NOT

It is not a translation of the reference C. It shares no source, no header, no
build system and no language with it. Python was chosen for exactly that
reason: it is not possible to accidentally reuse a C structure layout, a
bit-packing macro, or an enum from a header when the language cannot include
one. Where the reference C uses a bit-writer that accumulates across field
boundaries, this uses whole-byte assembly from the offset table in the
specification; where the reference C returns status enums, this raises. Those
divergences are intentional -- an implementation that made the same structural
choices would fail to expose the assumptions that only show up when two
different designs meet.

This is the one place in MCL where Python is permitted alongside the research
tooling. It is a conformance instrument, never protocol-facing code, and nothing
in the eight repositories links against it.

SOURCES USED, AND NOTHING ELSE

    mcl-wire/spec/common-header-v0.2.md          the 16-bit header
    mcl-wire/spec/tier0-layout-v0.2.md           the object bodies
    mcl-wire/spec/duration-v0.1.md               ttl and validity
    mcl-link/spec/link-v0.md                     the frame
    mcl-link/spec/link-negotiation-v1.md         CAPABILITY and NEGOTIATION
    mcl-wire/conformance/vectors/tier0-v0.3.json published bytes

WHERE THE SPECIFICATION WAS INSUFFICIENT

Recorded honestly in SPEC_GAPS.md next to this file. A clean-room
implementation's most valuable output is not that it works; it is the list of
things it had to guess.
"""

import json
import struct

# --------------------------------------------------------------------------
# Common header - mcl-wire/spec/common-header-v0.2.md section 2
#
#   15            12 11             8 7              3 2       1 0
#   +---------------+----------------+----------------+-----------+-+
#   | major_version | category       | opcode         | priority  |E|
#   +---------------+----------------+----------------+-----------+-+
#         4 bits          4 bits           5 bits         2 bits  1
# --------------------------------------------------------------------------

EXPERIMENTAL_MAJOR = 0
STABLE_MAJOR = 1

# Object kinds, named by their (category, opcode) from tier0-layout-v0.2.md
# section 4. The spec assigns the codes; this table transcribes them and does
# not invent an ordinal of its own.
CODES = {
    "PRESENCE":         (0, 0),
    "AUTHORITY_CLAIM":  (1, 1),
    "HAZARD":           (3, 1),
    "REQUEST":          (5, 1),
    "DEGRADED_STATE":   (6, 1),
    "TRANSPORT_OFFER":  (8, 0),
    "TRANSPORT_ACCEPT": (8, 1),
}
BY_CODE = {v: k for k, v in CODES.items()}

# Stable set for major 1 - common-header-v0.2.md section 3.1.
STABLE_AT_MAJOR_1 = {"PRESENCE", "TRANSPORT_OFFER", "TRANSPORT_ACCEPT"}


class MclError(Exception):
    """Any refusal. The reference C returns status codes; raising here is a
    deliberate structural divergence, not an oversight."""


def encode_header(major, category, opcode, priority, extension_present):
    if not (0 <= major <= 15):
        raise MclError("major out of range")
    if not (0 <= category <= 15):
        raise MclError("category out of range")
    if not (0 <= opcode <= 31):
        raise MclError("opcode out of range")
    if not (0 <= priority <= 3):
        raise MclError("priority out of range")
    word = (major << 12) | (category << 8) | (opcode << 3) | (priority << 1)
    word |= 1 if extension_present else 0
    return struct.pack(">H", word)


def decode_header(data):
    if len(data) < 2:
        raise MclError("truncated header")
    (word,) = struct.unpack(">H", data[:2])
    return {
        "major": (word >> 12) & 0xF,
        "category": (word >> 8) & 0xF,
        "opcode": (word >> 3) & 0x1F,
        "priority": (word >> 1) & 0x3,
        "extension_present": word & 0x1,
    }


def kind_allowed_at_major(major, kind):
    """common-header-v0.2.md section 3.1: a Stable major carries only Stable
    semantics; any unassigned major carries nothing."""
    if major == EXPERIMENTAL_MAJOR:
        return kind in CODES
    if major == STABLE_MAJOR:
        return kind in STABLE_AT_MAJOR_1
    return False


# --------------------------------------------------------------------------
# Duration codec - mcl-wire/spec/duration-v0.1.md
#
#   e = high nibble, m = low nibble
#   e == 0 : seconds = m
#   e >= 1 : seconds = (16 + m) << (e - 1)
# --------------------------------------------------------------------------

DURATION_MAX_SECONDS = (16 + 15) << (15 - 1)


def duration_seconds(code):
    if not (0 <= code <= 255):
        raise MclError("duration code out of range")
    e = code >> 4
    m = code & 0xF
    if e == 0:
        return m
    return (16 + m) << (e - 1)


def duration_encode(seconds):
    """Greatest representable duration not exceeding `seconds`.

    The bands do not touch: band e spans 16<<(e-1) .. 31<<(e-1), so there is a
    gap above every band top. A request landing in a gap takes the top of the
    band BELOW it, never the bottom of the band above -- rounding up would
    report a longer validity than was asked for.
    """
    if seconds < 0:
        raise MclError("negative duration")
    if seconds > DURATION_MAX_SECONDS:
        raise MclError("duration exceeds the representable range")
    if seconds < 16:
        return seconds
    for e in range(1, 16):
        shift = e - 1
        bottom = 16 << shift
        top = 31 << shift
        if seconds < bottom:
            return ((e - 1) << 4) | 0xF
        if seconds <= top:
            return (e << 4) | (((seconds >> shift) - 16) & 0xF)
    raise MclError("unreachable: range check above should have caught this")


# --------------------------------------------------------------------------
# Tier-0 bodies - mcl-wire/spec/tier0-layout-v0.2.md section 4
#
# Field tables transcribed from the specification's offset/width columns. All
# offsets are byte-aligned for the three Stable objects, so these are assembled
# whole-byte rather than through a bit writer. HAZARD and REQUEST are not
# byte-aligned and are handled by an explicit bit reader below; they are
# Candidate and are decoded here only so that the vector file can be checked in
# full.
# --------------------------------------------------------------------------

# PRESENCE has TWO layouts and the major says which -- tier0-layout-v0.2.md
# section 4.1. Major 1 drops machine_class, so an implementation carrying one
# table keyed on kind alone would be wrong at exactly one major. Keyed on
# (major, kind) here for that reason.
PRESENCE_MAJOR_0 = [
    ("source_ref", 4),
    ("machine_class", 1),
    ("capability_tag", 3),
    ("ttl", 1),
]
PRESENCE_MAJOR_1 = [
    ("source_ref", 4),
    ("capability_tag", 3),
    ("ttl", 1),
]

STABLE_LAYOUT = {
    # name: [(field, byte_width), ...] after the 2-byte header
    "PRESENCE": PRESENCE_MAJOR_0,
    "TRANSPORT_OFFER": [
        ("source_ref", 4),
        ("migration_ref", 4),
        ("transport_id", 1),
        ("profile_id", 1),
        ("endpoint_token", 4),
        ("validity", 1),
    ],
    "TRANSPORT_ACCEPT": [
        ("source_ref", 4),
        ("migration_ref", 4),
        ("transport_id", 1),
        ("profile_id", 1),
        ("session_ref", 4),
    ],
}

# Fields the specification marks MUST NOT be 0.
NONZERO = {
    "TRANSPORT_OFFER": ("migration_ref", "transport_id"),
    "TRANSPORT_ACCEPT": ("migration_ref", "transport_id", "session_ref"),
}


def _int_to_bytes(value, width, field):
    limit = 1 << (8 * width)
    if not (0 <= value < limit):
        raise MclError("%s does not fit %d bytes" % (field, width))
    return value.to_bytes(width, "big")


def layout_for(major, kind):
    """The body layout of `kind` at `major`.

    PRESENCE is the only kind whose layout depends on the major, and it is why
    this function exists rather than a direct dict lookup.
    """
    if kind == "PRESENCE":
        return PRESENCE_MAJOR_1 if major == STABLE_MAJOR else PRESENCE_MAJOR_0
    return STABLE_LAYOUT[kind]


def encode_tier0(kind, priority, fields, major=EXPERIMENTAL_MAJOR):
    if kind not in STABLE_LAYOUT:
        raise MclError("this implementation encodes only the Stable objects")
    if not kind_allowed_at_major(major, kind):
        raise MclError("%s is not carried at major %d" % (kind, major))
    category, opcode = CODES[kind]
    out = bytearray(encode_header(major, category, opcode, priority, False))
    for field, width in layout_for(major, kind):
        if field not in fields:
            raise MclError("missing field %s" % field)
        value = fields[field]
        if field in NONZERO.get(kind, ()) and value == 0:
            raise MclError("%s MUST NOT be zero" % field)
        out += _int_to_bytes(value, width, field)
    return bytes(out)


def decode_tier0(data):
    header = decode_header(data)
    code = (header["category"], header["opcode"])
    if code not in BY_CODE:
        raise MclError("unassigned category/opcode %r" % (code,))
    kind = BY_CODE[code]
    if not kind_allowed_at_major(header["major"], kind):
        raise MclError("%s is not carried at major %d" % (kind, header["major"]))
    if kind not in STABLE_LAYOUT:
        return decode_candidate_tier0(kind, header, data)

    fields = {}
    pos = 2
    for field, width in layout_for(header["major"], kind):
        if pos + width > len(data):
            raise MclError("truncated %s at %s" % (kind, field))
        fields[field] = int.from_bytes(data[pos:pos + width], "big")
        pos += width
    for field in NONZERO.get(kind, ()):
        if fields[field] == 0:
            raise MclError("%s MUST NOT be zero" % field)
    return {
        "kind": kind,
        "major": header["major"],
        "priority": header["priority"],
        "fields": fields,
        "consumed": pos,
    }


# Candidate objects. Bit-level, because their fields are not byte-aligned.
CANDIDATE_BITS = {
    "HAZARD": [
        ("source_ref", 32, False), ("hazard_class", 8, False),
        ("severity", 3, False), ("confidence", 7, False),
        ("x", 12, True), ("y", 12, True), ("z", 10, True),
        ("radius", 10, False), ("ttl", 8, False),
    ],
    "REQUEST": [
        ("source_ref", 32, False), ("request_class", 8, False),
        ("target_ref", 32, False),
        ("x", 12, True), ("y", 12, True),
        ("radius", 10, False), ("ttl", 8, False),
    ],
    # authority_class is 6 bits and jurisdiction is 12, NOT 8 and 16. A first
    # draft of this file guessed 8 and 16, whose total is identical, so the
    # object still consumed exactly 14 bytes and a length-only check passed
    # while every field after source_ref was misread. Caught by comparing field
    # VALUES against the reference decoder, not by counting bytes.
    "AUTHORITY_CLAIM": [
        ("source_ref", 32, False), ("authority_class", 6, False),
        ("jurisdiction", 12, False), ("credential_ref", 32, False),
        ("validity", 8, False),
    ],
    # health is 7 bits followed by a 3-bit severity, then ttl -- not an 8-bit
    # health followed by validity. tier0-layout-v0.2.md section 4.5 warns about
    # exactly this transposition, because HAZARD orders the 3-bit and 7-bit
    # fields the other way round. The first draft of this file made the mistake
    # the specification predicted.
    "DEGRADED_STATE": [
        ("source_ref", 32, False), ("affected_capability", 8, False),
        ("health", 7, False), ("severity", 3, False), ("ttl", 8, False),
    ],
}


class BitReader(object):
    def __init__(self, data, bit_offset=0):
        self.data = data
        self.pos = bit_offset

    def read(self, width, signed):
        if self.pos + width > len(self.data) * 8:
            raise MclError("truncated body")
        value = 0
        for _ in range(width):
            byte = self.data[self.pos >> 3]
            bit = (byte >> (7 - (self.pos & 7))) & 1
            value = (value << 1) | bit
            self.pos += 1
        if signed and (value >> (width - 1)) & 1:
            value -= 1 << width
        return value


def decode_candidate_tier0(kind, header, data):
    reader = BitReader(data, 16)
    fields = {}
    for field, width, signed in CANDIDATE_BITS[kind]:
        fields[field] = reader.read(width, signed)
    consumed = (reader.pos + 7) // 8
    padding_bits = consumed * 8 - reader.pos
    if padding_bits:
        tail = data[consumed - 1] & ((1 << padding_bits) - 1)
        if tail != 0:
            raise MclError("padding MUST be zero")
    return {
        "kind": kind,
        "major": header["major"],
        "priority": header["priority"],
        "fields": fields,
        "consumed": consumed,
    }


# --------------------------------------------------------------------------
# Link frame - mcl-link/spec/link-v0.md
#
#   u8   link_major (high nibble) | frame_class (low nibble)
#   u8   flags
#   u32  source_ref                     always
#   u32  destination_ref                if DESTINATION
#   u32  session_ref                    if SESSION
#   u16  sequence                       if SEQUENCE
#   u16  freshness_ms                   if FRESHNESS
#   u16  payload_len                    always
#   u8   payload[payload_len]
#   u32  frame_check (CRC-32/IEEE)      if FRAME_CHECK
# --------------------------------------------------------------------------

FLAG_DESTINATION = 0x01
FLAG_SESSION = 0x02
FLAG_SEQUENCE = 0x04
FLAG_FRESHNESS = 0x08
FLAG_FRAME_CHECK = 0x10
FLAG_RESERVED = 0xE0

LINK_MAJOR = 0
LINK_CLASS_COUNT = 10
LINK_CLASS_ADAPT = 7
FRAME_MAX_PAYLOAD = 1024


def _crc32(data):
    """CRC-32/IEEE, computed from the polynomial rather than imported.

    zlib.crc32 would be the obvious call and is deliberately not used: it would
    make this implementation agree with the reference C because both delegate to
    the same well-known routine, rather than because both read the same
    specification.
    """
    crc = 0xFFFFFFFF
    for byte in data:
        crc ^= byte
        for _ in range(8):
            if crc & 1:
                crc = (crc >> 1) ^ 0xEDB88320
            else:
                crc >>= 1
    return crc ^ 0xFFFFFFFF


def encode_frame(frame_class, flags, source_ref, payload,
                 destination_ref=0, session_ref=0, sequence=0, freshness_ms=0,
                 link_major=LINK_MAJOR):
    if frame_class >= LINK_CLASS_COUNT:
        raise MclError("unknown frame class")
    if frame_class == LINK_CLASS_ADAPT:
        raise MclError("ADAPT is reserved and MUST NOT be emitted")
    if flags & FLAG_RESERVED:
        raise MclError("reserved flag bit set")
    if len(payload) > FRAME_MAX_PAYLOAD:
        raise MclError("payload too large")

    out = bytearray()
    out.append(((link_major & 0xF) << 4) | (frame_class & 0xF))
    out.append(flags)
    out += struct.pack(">I", source_ref)
    if flags & FLAG_DESTINATION:
        out += struct.pack(">I", destination_ref)
    if flags & FLAG_SESSION:
        out += struct.pack(">I", session_ref)
    if flags & FLAG_SEQUENCE:
        out += struct.pack(">H", sequence)
    if flags & FLAG_FRESHNESS:
        out += struct.pack(">H", freshness_ms)
    out += struct.pack(">H", len(payload))
    out += payload
    if flags & FLAG_FRAME_CHECK:
        out += struct.pack(">I", _crc32(bytes(out)))
    return bytes(out)


def decode_frame(data):
    if len(data) < 8:
        raise MclError("truncated frame")
    link_major = data[0] >> 4
    frame_class = data[0] & 0xF
    if link_major != LINK_MAJOR:
        raise MclError("unsupported link major")
    if frame_class >= LINK_CLASS_COUNT:
        raise MclError("unknown frame class")
    if frame_class == LINK_CLASS_ADAPT:
        raise MclError("ADAPT is reserved and MUST be refused")
    flags = data[1]
    if flags & FLAG_RESERVED:
        raise MclError("reserved flag bit set")

    pos = 2
    out = {"link_major": link_major, "frame_class": frame_class, "flags": flags}

    def take(width, name):
        nonlocal pos
        if pos + width > len(data):
            raise MclError("truncated frame at %s" % name)
        value = int.from_bytes(data[pos:pos + width], "big")
        pos += width
        return value

    out["source_ref"] = take(4, "source_ref")
    out["destination_ref"] = take(4, "destination_ref") if flags & FLAG_DESTINATION else 0
    out["session_ref"] = take(4, "session_ref") if flags & FLAG_SESSION else 0
    out["sequence"] = take(2, "sequence") if flags & FLAG_SEQUENCE else 0
    out["freshness_ms"] = take(2, "freshness_ms") if flags & FLAG_FRESHNESS else 0
    payload_len = take(2, "payload_len")
    if payload_len > FRAME_MAX_PAYLOAD:
        raise MclError("declared payload exceeds the maximum")
    if pos + payload_len > len(data):
        raise MclError("truncated payload")
    out["payload"] = data[pos:pos + payload_len]
    pos += payload_len

    if flags & FLAG_FRAME_CHECK:
        if pos + 4 > len(data):
            raise MclError("truncated frame check")
        (carried,) = struct.unpack(">I", data[pos:pos + 4])
        if carried != _crc32(data[:pos]):
            raise MclError("frame check failed")
        pos += 4

    out["consumed"] = pos
    return out


# --------------------------------------------------------------------------
# Capability / version negotiation - mcl-link/spec/link-negotiation-v1.md
# --------------------------------------------------------------------------

CONTROL_VERSION = 0
CAPABILITY_SIZE = 9
NEGOTIATION_SIZE = 7
# section 5.3: FRAME_MIN_SIZE 8 + FRAME_MAX_OPTIONAL 16 + HANDOFF_MAX 18
FRAME_FLOOR = 8 + 16 + 18


def encode_capability(wire_majors, link_majors, max_frame, features):
    if wire_majors == 0 or link_majors == 0:
        raise MclError("a node supporting no major cannot be negotiated with")
    if max_frame < FRAME_FLOOR:
        raise MclError("max_frame below the floor")
    return struct.pack(">BHHHH", CONTROL_VERSION, wire_majors, link_majors,
                       max_frame, features)


def decode_capability(data):
    if len(data) < CAPABILITY_SIZE:
        raise MclError("truncated capability")
    if len(data) > CAPABILITY_SIZE:
        raise MclError("capability is an exact length")
    version, wire_majors, link_majors, max_frame, features = struct.unpack(
        ">BHHHH", data)
    if version != CONTROL_VERSION:
        raise MclError("unsupported control version")
    if wire_majors == 0 or link_majors == 0:
        raise MclError("empty major set")
    if max_frame < FRAME_FLOOR:
        raise MclError("max_frame below the floor")
    return {"wire_majors": wire_majors, "link_majors": link_majors,
            "max_frame": max_frame, "features": features}


def encode_negotiation(wire_major, link_major, max_frame, features):
    if wire_major > 15 or link_major > 15:
        raise MclError("major does not fit the header nibble")
    if max_frame < FRAME_FLOOR:
        raise MclError("max_frame below the floor")
    return struct.pack(">BBBHH", CONTROL_VERSION, wire_major, link_major,
                       max_frame, features)


def decode_negotiation(data):
    if len(data) < NEGOTIATION_SIZE:
        raise MclError("truncated negotiation")
    if len(data) > NEGOTIATION_SIZE:
        raise MclError("negotiation is an exact length")
    version, wire_major, link_major, max_frame, features = struct.unpack(
        ">BBBHH", data)
    if version != CONTROL_VERSION:
        raise MclError("unsupported control version")
    if wire_major > 15 or link_major > 15:
        raise MclError("major out of range")
    if max_frame < FRAME_FLOOR:
        raise MclError("max_frame below the floor")
    return {"wire_major": wire_major, "link_major": link_major,
            "max_frame": max_frame, "features": features}


def select(local, peer):
    """section 3. Every operation is symmetric, which is what makes glare
    self-resolving without a tiebreaker."""
    common_wire = local["wire_majors"] & peer["wire_majors"]
    common_link = local["link_majors"] & peer["link_majors"]
    if common_wire == 0 or common_link == 0:
        raise MclError("no common major")
    max_frame = min(local["max_frame"], peer["max_frame"])
    if max_frame < FRAME_FLOOR:
        raise MclError("common frame size below the floor")
    return {
        "wire_major": common_wire.bit_length() - 1,
        "link_major": common_link.bit_length() - 1,
        "max_frame": max_frame,
        "features": local["features"] & peer["features"],
    }


__all__ = [
    "MclError", "EXPERIMENTAL_MAJOR", "STABLE_MAJOR",
    "encode_header", "decode_header", "kind_allowed_at_major",
    "duration_seconds", "duration_encode", "DURATION_MAX_SECONDS",
    "encode_tier0", "decode_tier0", "layout_for",
    "encode_frame", "decode_frame",
    "encode_capability", "decode_capability",
    "encode_negotiation", "decode_negotiation", "select",
    "FLAG_DESTINATION", "FLAG_SESSION", "FLAG_SEQUENCE", "FLAG_FRESHNESS",
    "FLAG_FRAME_CHECK", "FRAME_FLOOR",
]

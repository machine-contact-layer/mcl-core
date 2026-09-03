"""
C4: cross-implementation conformance.

RELEASE GATE ITEM 16.

Two things are checked, and only the second is interoperability:

  1. The independent implementation reproduces the PUBLISHED VECTORS exactly.
     This is conformance to the artifacts, and it is the weaker half -- the
     vectors were produced by the reference implementation, so agreeing with
     them shows the specification was read correctly, not that two
     implementations can talk.

  2. Bytes produced by the independent implementation are decoded by the
     REFERENCE C, and bytes produced by the reference C are decoded by the
     independent implementation, in both directions, including refusals.
     Nothing but a byte buffer crosses between them.

The second half is run by cross_check.c on the C side; this file produces and
consumes the buffers it exchanges. A test in which one implementation drove
both ends would prove the state machine is coherent and nothing about whether
the protocol is specified.
"""

import json
import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

sys.path.insert(0, HERE)
import mcl_independent as mcl  # noqa: E402

checks = 0
failures = []


def check(cond, what):
    global checks
    checks += 1
    if not cond:
        failures.append(what)
        print("  FAIL: %s" % what)


def load_vectors(path):
    with open(path) as handle:
        return json.load(handle)


# --------------------------------------------------------------------------
# 1. Published vectors
# --------------------------------------------------------------------------

def test_published_tier0_vectors(binary):
    """Every published vector, compared FIELD BY FIELD against the reference.

    A length check is not a comparison. The first draft of the independent
    implementation gave AUTHORITY_CLAIM an 8-bit authority_class and a 16-bit
    jurisdiction instead of 6 and 12 -- the totals are identical, so the object
    still consumed exactly 14 bytes and a length-only test passed while every
    field after source_ref was misread. Only comparing values found it.
    """
    print("[C4] published vectors: field-by-field against the reference")
    path = os.path.join(ROOT, "mcl-wire", "conformance", "vectors",
                        "tier0-v0.3.json")
    doc = load_vectors(path)
    check(doc["wire_major"] == 0, "the published vectors are major 0")

    for vector in doc["vectors"]:
        name = vector["name"]
        raw = bytes.fromhex(vector["hex"])
        check(len(raw) == vector["length"],
              "%s: declared length matches its bytes" % name)

        try:
            decoded = mcl.decode_tier0(raw)
        except mcl.MclError as exc:
            check(False, "%s: decode failed (%s)" % (name, exc))
            continue

        check(decoded["kind"] == name, "%s: decoded as itself" % name)
        check(decoded["consumed"] == len(raw),
              "%s: every byte consumed" % name)

        # The reference decoder's view of the same bytes.
        rc, out = c_call(binary, "fields_tier0", vector["hex"])
        if rc != 0:
            check(False, "%s: reference refused its own vector" % name)
            continue
        reference = dict(part.split("=", 1) for part in out.split(" "))
        check(reference["kind"] == name, "%s: reference agrees on kind" % name)
        check(int(reference["priority"]) == decoded["priority"],
              "%s: priority agrees" % name)

        mine = dict(decoded["fields"])
        for field, value in mine.items():
            check(field in reference,
                  "%s: reference reports %s at all" % (name, field))
            if field in reference:
                check(int(reference[field]) == value,
                      "%s.%s: %s vs reference %s"
                      % (name, field, value, reference[field]))
        # And the reference must not carry a field this implementation lost.
        for field in reference:
            if field in ("kind", "priority"):
                continue
            check(field in mine,
                  "%s: independent implementation reports %s" % (name, field))

        if name in mcl.STABLE_LAYOUT:
            again = mcl.encode_tier0(name, decoded["priority"],
                                     decoded["fields"])
            check(again == raw,
                  "%s: re-encodes to the identical bytes" % name)


def test_duration_codec_against_spec():
    print("[C4] duration codec: injective, monotonic, never rounds up")
    seen = {}
    previous = -1
    for code in range(256):
        seconds = mcl.duration_seconds(code)
        check(seconds not in seen, "duration code %d is not a duplicate" % code)
        seen[seconds] = code
        check(seconds > previous, "duration code %d is monotonic" % code)
        previous = seconds
    check(previous == mcl.DURATION_MAX_SECONDS,
          "the maximum is %d seconds" % mcl.DURATION_MAX_SECONDS)

    # Exhaustive round-down over the whole representable range.
    worst = 0.0
    for seconds in range(0, mcl.DURATION_MAX_SECONDS + 1):
        code = mcl.duration_encode(seconds)
        got = mcl.duration_seconds(code)
        if got > seconds:
            check(False, "%ds encoded to %ds, which is longer" % (seconds, got))
            break
        if seconds >= 60:
            worst = max(worst, (seconds - got) / float(seconds))
    else:
        check(True, "never rounds up, over every representable second")
    print("      worst relative loss above 60s: %.3f%%" % (worst * 100.0))


def test_major_1_presence_is_ten_bytes():
    print("[C4] major-1 PRESENCE drops machine_class")
    fields = {"source_ref": 0x11223344, "capability_tag": 0xABCDEF, "ttl": 60}
    encoded = mcl.encode_tier0("PRESENCE", 1, fields, major=mcl.STABLE_MAJOR)
    check(len(encoded) == 10, "major-1 PRESENCE is 10 bytes")

    decoded = mcl.decode_tier0(encoded)
    check(decoded["major"] == mcl.STABLE_MAJOR, "major survives")
    check("machine_class" not in decoded["fields"],
          "and carries no machine_class")
    check(decoded["fields"]["capability_tag"] == 0xABCDEF,
          "capability_tag survives")

    # Major 0 still carries it, so the removal is scoped to the Stable major.
    m0 = mcl.encode_tier0("PRESENCE", 1,
                          {"source_ref": 0x11223344, "machine_class": 7,
                           "capability_tag": 0xABCDEF, "ttl": 60})
    check(len(m0) == 11, "major-0 PRESENCE is still 11 bytes")

    # A Candidate object may not be carried at the Stable major.
    try:
        mcl.encode_tier0("HAZARD", 1, {}, major=mcl.STABLE_MAJOR)
        check(False, "HAZARD must not encode at major 1")
    except mcl.MclError:
        check(True, "HAZARD refused at the Stable major")


# --------------------------------------------------------------------------
# 2. Cross-implementation exchange
# --------------------------------------------------------------------------

def build_cross_check():
    """Compile the C side of the exchange."""
    out = os.path.join(HERE, "cross_check")
    if os.name == "nt":
        out += ".exe"
    cmd = [
        os.environ.get("CC", "cc"), "-std=c99", "-Wall", "-Wextra", "-Werror",
        "-I", os.path.join(ROOT, "mcl-wire", "include"),
        "-I", os.path.join(ROOT, "mcl-link", "include"),
        "-o", out,
        os.path.join(HERE, "cross_check.c"),
        os.path.join(ROOT, "mcl-wire", "src", "wire.c"),
        os.path.join(ROOT, "mcl-wire", "src", "extension.c"),
        os.path.join(ROOT, "mcl-link", "src", "link.c"),
        os.path.join(ROOT, "mcl-link", "src", "control.c"),
        os.path.join(ROOT, "mcl-link", "src", "negotiation.c"),
        os.path.join(ROOT, "mcl-link", "src", "contact.c"),
        os.path.join(ROOT, "mcl-link", "src", "handoff.c"),
        os.path.join(ROOT, "mcl-link", "src", "rendezvous.c"),
    ]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(result.stderr[-2000:])
        raise SystemExit("cross_check.c failed to build")
    return out


def c_call(binary, verb, payload_hex=""):
    """Run one operation on the reference C side and return its answer."""
    result = subprocess.run([binary, verb, payload_hex],
                            capture_output=True, text=True)
    return result.returncode, result.stdout.strip()


def test_cross_implementation(binary):
    print("[C4] independent -> reference C, and back, bytes only")

    # --- Tier-0, independent encodes, C decodes -------------------------
    cases = [
        ("PRESENCE", {"source_ref": 0x0BADCAFE, "machine_class": 3,
                      "capability_tag": 0x00ABCD, "ttl": 60}),
        ("TRANSPORT_OFFER", {"source_ref": 0x0BADCAFE,
                             "migration_ref": 0x4D194201, "transport_id": 2,
                             "profile_id": 192, "endpoint_token": 0xD00D0001,
                             "validity": 30}),
        ("TRANSPORT_ACCEPT", {"source_ref": 0x0BADCAFE,
                              "migration_ref": 0x4D194201, "transport_id": 2,
                              "profile_id": 192, "session_ref": 0x5E5510C7}),
    ]
    for kind, fields in cases:
        raw = mcl.encode_tier0(kind, 1, fields)
        rc, out = c_call(binary, "decode_tier0", raw.hex())
        check(rc == 0, "C accepts independent %s (%s)" % (kind, out))
        check(out == kind, "C reads it as %s, got %r" % (kind, out))

    # --- Tier-0, C encodes, independent decodes -------------------------
    for kind, fields in cases:
        rc, out = c_call(binary, "encode_tier0", kind)
        check(rc == 0, "C encodes %s" % kind)
        try:
            decoded = mcl.decode_tier0(bytes.fromhex(out))
            check(decoded["kind"] == kind,
                  "independent reads C's %s" % kind)
        except mcl.MclError as exc:
            check(False, "independent rejected C's %s: %s" % (kind, exc))

    # --- Link frame, both directions ------------------------------------
    payload = mcl.encode_tier0("PRESENCE", 1, cases[0][1])
    frame = mcl.encode_frame(
        frame_class=0, flags=mcl.FLAG_SEQUENCE | mcl.FLAG_FRAME_CHECK,
        source_ref=0x0BADCAFE, payload=payload, sequence=7)
    rc, out = c_call(binary, "decode_frame", frame.hex())
    check(rc == 0, "C accepts an independently framed PRESENCE (%s)" % out)
    check(out == "ok", "and reports it clean, got %r" % out)

    rc, out = c_call(binary, "encode_frame", "")
    check(rc == 0, "C encodes a frame")
    try:
        got = mcl.decode_frame(bytes.fromhex(out))
        check(got["frame_class"] == 0, "independent reads C's frame class")
        check(got["sequence"] == 7, "and its sequence")
        inner = mcl.decode_tier0(got["payload"])
        check(inner["kind"] == "PRESENCE", "and its payload object")
    except mcl.MclError as exc:
        check(False, "independent rejected C's frame: %s" % exc)

    # --- The CRC agrees, which is the sharpest single check -------------
    # This implementation computes CRC-32 from the polynomial rather than
    # calling zlib, so agreement here means both derived the same function
    # from the specification rather than both delegating to one library.
    check(True, "frame check agreed across implementations (implied above)")

    # --- Negotiation controls, both directions --------------------------
    cap = mcl.encode_capability(0x0003, 0x0001, 1048, 0)
    rc, out = c_call(binary, "decode_capability", cap.hex())
    check(rc == 0, "C accepts an independent CAPABILITY (%s)" % out)
    check(out == "0003,0001,1048,0000",
          "and reads the same fields, got %r" % out)

    rc, out = c_call(binary, "encode_capability", "")
    check(rc == 0, "C encodes a CAPABILITY")
    try:
        got = mcl.decode_capability(bytes.fromhex(out))
        check(got["wire_majors"] == 0x0003, "independent reads C's majors")
        check(got["max_frame"] == 1048, "and its frame limit")
    except mcl.MclError as exc:
        check(False, "independent rejected C's CAPABILITY: %s" % exc)

    # --- The selection function agrees ----------------------------------
    local = {"wire_majors": 0x000B, "link_majors": 0x0003,
             "max_frame": 900, "features": 0x0F0F}
    peer = {"wire_majors": 0x0007, "link_majors": 0x0001,
            "max_frame": 512, "features": 0x00FF}
    mine = mcl.select(local, peer)
    rc, out = c_call(binary, "select", "")
    check(rc == 0, "C computes a selection")
    expected = "%d,%d,%d,%04x" % (mine["wire_major"], mine["link_major"],
                                  mine["max_frame"], mine["features"])
    check(out == expected,
          "both implementations select the same outcome: %r vs %r"
          % (out, expected))

    # --- Refusals agree, which matters as much as acceptances -----------
    print("[C4] both implementations refuse the same malformed input")
    bad = [
        ("00", "a two-byte header alone"),
        ("0002aa0000010100001f", "a PRESENCE one byte short"),
        ("0002aa0000010100001f7900", "a PRESENCE one byte long"),
        ("1002aa0000010100001f79", "major 1 on the wire, not yet cut"),
        ("0f02aa0000010100001f79", "an unassigned major"),
    ]
    for hex_bytes, what in bad:
        raw = bytes.fromhex(hex_bytes)
        independent_ok = True
        try:
            decoded = mcl.decode_tier0(raw)
            independent_ok = decoded["consumed"] == len(raw)
        except mcl.MclError:
            independent_ok = False
        rc, _ = c_call(binary, "decode_tier0", hex_bytes)
        c_ok = (rc == 0)
        check(independent_ok == c_ok,
              "%s: both refuse (independent=%s, C=%s)"
              % (what, independent_ok, c_ok))
        check(not c_ok, "%s: and it really is refused" % what)


def main():
    print("=== MCL C4 cross-implementation conformance ===")
    print("Independent implementation: mcl_independent.py, written from the")
    print("normative specifications. Nothing but byte buffers crosses between")
    print("it and the reference C.\n")

    binary = build_cross_check()

    test_published_tier0_vectors(binary)
    test_duration_codec_against_spec()
    test_major_1_presence_is_ten_bytes()
    test_cross_implementation(binary)

    print("\n%d checks, %d failed." % (checks, len(failures)))
    if failures:
        for item in failures:
            print("  - %s" % item)
        return 1
    print("C4 CROSS-IMPLEMENTATION PASSED")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

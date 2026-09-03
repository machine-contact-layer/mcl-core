"""
C5: independent implementation against the Candidate transport profiles.

RELEASE GATE ITEM 17.

C4 established that two implementations agree about Wire objects and Link
frames. C5 asks the narrower question the profiles actually pose: does an
implementation written from `ip-datagram-profile-v1.md` and
`ble-gatt-profile-v1.md` carry and refuse the same things as the reference
bindings?

WHAT IS BEING TESTED, AND UNDER WHICH PROFILE VALUE

Profile 192 in both registries -- the Experimental Use value. That is
deliberate and is the promotion sequence recorded in `V1_SCOPE.md` §5.6:
interoperate on the experimental value, and only then perform the Standards
Action assignment.

**This run is therefore evidence about profile 192, not about the Stable value
that does not exist yet.** When the Stable value is assigned, C4 and C5 are
re-run on the final bytes, because `profile_id` travels inside
`TRANSPORT_OFFER` and `TRANSPORT_ACCEPT` and changing it changes what was
tested.

The profile carriage rules are implemented here from the specifications only;
`ip_binding.c` and `ble_binding.c` were not read while writing them.
"""

import os
import subprocess
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.abspath(os.path.join(HERE, "..", "..", ".."))

sys.path.insert(0, HERE)
import mcl_independent as mcl  # noqa: E402

checks = 0
failures = []

EXPERIMENTAL_PROFILE = 192


def check(cond, what):
    global checks
    checks += 1
    if not cond:
        failures.append(what)
        print("  FAIL: %s" % what)


# --------------------------------------------------------------------------
# IP-DATAGRAM v1, implemented from mcl-ip/spec/ip-datagram-profile-v1.md
# --------------------------------------------------------------------------

IPV4_OVERHEAD = 20 + 8
IPV6_OVERHEAD = 40 + 8
LINK_FRAME_MAX_SIZE = 8 + 16 + 1024
LINK_FRAME_MIN_SIZE = 8


def ip_datagram_validate(datagram):
    """§2 framing, §6 frame check. Refusals are silent and local (§7)."""
    frame = mcl.decode_frame(datagram)          # raises on anything invalid
    if frame["consumed"] != len(datagram):
        raise mcl.MclError("trailing bytes: refused, never ignored")
    if not (frame["flags"] & mcl.FLAG_FRAME_CHECK):
        raise mcl.MclError("this profile requires a frame check")
    return frame


def ip_max_frame_for_mtu(family, path_mtu):
    """§4. Two limits apply and the smaller wins."""
    overhead = IPV4_OVERHEAD if family == "ipv4" else IPV6_OVERHEAD
    if path_mtu <= overhead:
        return 0
    usable = path_mtu - overhead
    if usable < LINK_FRAME_MIN_SIZE:
        return 0
    return min(usable, LINK_FRAME_MAX_SIZE)


def test_ip_profile(binary):
    print("[C5] IP-DATAGRAM v1")

    payload = mcl.encode_tier0("PRESENCE", 1, {
        "source_ref": 0x0BADCAFE, "machine_class": 3,
        "capability_tag": 0x00ABCD, "ttl": 60})
    good = mcl.encode_frame(0, mcl.FLAG_SEQUENCE | mcl.FLAG_FRAME_CHECK,
                            0x0BADCAFE, payload, sequence=1)

    # Positive: the reference binding accepts what this implementation built.
    rc, out = c_call(binary, "ip_validate", good.hex())
    check(rc == 0, "reference IP binding accepts an independent datagram (%s)" % out)
    check(ip_datagram_validate(good) is not None,
          "and this implementation accepts it too")

    # §7, row by row. Both sides must refuse each one.
    cases = [
        (good + b"\x00", "trailing byte"),
        (good[:-1], "truncated"),
        (b"", "empty payload"),
        (mcl.encode_frame(0, mcl.FLAG_SEQUENCE, 0x0BADCAFE, payload,
                          sequence=1), "no frame check"),
    ]
    # A corrupted frame check, built by flipping the last byte.
    corrupt = bytearray(good)
    corrupt[-1] ^= 0x01
    cases.append((bytes(corrupt), "corrupted frame check"))

    for datagram, what in cases:
        independent_ok = True
        try:
            ip_datagram_validate(datagram)
        except (mcl.MclError, Exception):
            independent_ok = False
        rc, _ = c_call(binary, "ip_validate", datagram.hex())
        reference_ok = (rc == 0)
        check(not independent_ok, "IP: %s refused by this implementation" % what)
        check(not reference_ok, "IP: %s refused by the reference" % what)
        check(independent_ok == reference_ok,
              "IP: %s -- both agree" % what)

    # §4 size contract, compared against the reference helper.
    for family, mtu in [("ipv4", 1500), ("ipv6", 1500), ("ipv4", 9000),
                        ("ipv6", 9000), ("ipv4", 100), ("ipv6", 56),
                        ("ipv6", 40), ("ipv4", 28)]:
        mine = ip_max_frame_for_mtu(family, mtu)
        rc, out = c_call(binary, "ip_mtu", "%s:%d" % (family, mtu))
        check(rc == 0, "reference reports an MTU answer for %s/%d" % (family, mtu))
        if rc == 0:
            check(int(out) == mine,
                  "IP MTU %s/%d: %d vs reference %s" % (family, mtu, mine, out))

    # A jumbo MTU must not raise the answer above the protocol limit.
    check(ip_max_frame_for_mtu("ipv4", 9000) == LINK_FRAME_MAX_SIZE,
          "a jumbo MTU is capped by the protocol, not the path")

    # The profile identifier travels inside the objects, so it is part of what
    # is being tested. Recorded explicitly.
    offer = mcl.encode_tier0("TRANSPORT_OFFER", 1, {
        "source_ref": 0x0BADCAFE, "migration_ref": 0x4D194201,
        "transport_id": 2, "profile_id": EXPERIMENTAL_PROFILE,
        "endpoint_token": 0xD00D0001, "validity": 30})
    rc, out = c_call(binary, "fields_tier0", offer.hex())
    check(rc == 0, "reference decodes an offer naming profile 192")
    check("profile_id=%d" % EXPERIMENTAL_PROFILE in out,
          "and reads the experimental profile value back, got %r" % out)


# --------------------------------------------------------------------------
# BLE-GATT v1, implemented from mcl-ble/spec/ble-gatt-profile-v1.md
# --------------------------------------------------------------------------

ATT_DEFAULT_MTU = 23
ATT_HEADER_SIZE = 3
FRAG_HEADER_SIZE = 1
FRAG_START = 0x80
FRAG_END = 0x40
FRAG_SEQ_MASK = 0x3F
FRAG_SEQ_MODULUS = 64


def ble_payload_per_pdu(att_mtu):
    return att_mtu - ATT_HEADER_SIZE - FRAG_HEADER_SIZE


def ble_fragment(frame, att_mtu):
    """§3. One header byte per PDU; START and END together on a single-PDU
    frame; sequence wraps modulo 64 and must not wrap within a frame."""
    per = ble_payload_per_pdu(att_mtu)
    if per <= 0:
        raise mcl.MclError("MTU too small to carry anything")
    chunks = [frame[i:i + per] for i in range(0, len(frame), per)]
    if len(chunks) > FRAG_SEQ_MODULUS:
        raise mcl.MclError("sequence would wrap within one frame")
    out = []
    for index, chunk in enumerate(chunks):
        header = index & FRAG_SEQ_MASK
        if index == 0:
            header |= FRAG_START
        if index == len(chunks) - 1:
            header |= FRAG_END
        out.append(bytes([header]) + chunk)
    return out


class BleReassembler(object):
    """§5, including the rule that a new START abandons a partial frame."""

    def __init__(self):
        self.buffer = bytearray()
        self.active = False
        self.next_seq = 0

    def feed(self, fragment):
        if len(fragment) <= FRAG_HEADER_SIZE:
            self.reset()
            raise mcl.MclError("empty fragment payload")
        header = fragment[0]
        seq = header & FRAG_SEQ_MASK
        start = bool(header & FRAG_START)
        end = bool(header & FRAG_END)

        if start:
            self.buffer = bytearray()
            self.active = True
            self.next_seq = seq
        elif not self.active:
            raise mcl.MclError("fragment without a preceding START")

        if seq != self.next_seq:
            self.reset()
            raise mcl.MclError("sequence gap")

        self.buffer += fragment[FRAG_HEADER_SIZE:]
        if len(self.buffer) > LINK_FRAME_MAX_SIZE:
            self.reset()
            raise mcl.MclError("reassembly would exceed the maximum")
        self.next_seq = (self.next_seq + 1) % FRAG_SEQ_MODULUS

        if end:
            complete = bytes(self.buffer)
            self.reset()
            return complete
        return None

    def reset(self):
        self.buffer = bytearray()
        self.active = False
        self.next_seq = 0


def ble_frame_validate(frame_bytes):
    """§6: the frame check is required, and verified after reassembly."""
    frame = mcl.decode_frame(frame_bytes)
    if frame["consumed"] != len(frame_bytes):
        raise mcl.MclError("spliced input")
    if not (frame["flags"] & mcl.FLAG_FRAME_CHECK):
        raise mcl.MclError("this profile requires a frame check")
    return frame


def test_ble_profile(binary):
    print("[C5] BLE-GATT v1")

    payload = mcl.encode_tier0("PRESENCE", 1, {
        "source_ref": 0x0BADCAFE, "machine_class": 3,
        "capability_tag": 0x00ABCD, "ttl": 60})
    frame = mcl.encode_frame(0, mcl.FLAG_SEQUENCE | mcl.FLAG_FRAME_CHECK,
                             0x0BADCAFE, payload, sequence=1)

    # §4: 19 usable bytes at the 23-byte minimum, which is the only MTU every
    # peer must support and therefore the one fragmentation is exercised at.
    check(ble_payload_per_pdu(ATT_DEFAULT_MTU) == 19,
          "19 usable payload bytes at the minimum MTU")
    rc, out = c_call(binary, "ble_per_pdu", str(ATT_DEFAULT_MTU))
    check(rc == 0 and int(out) == 19,
          "reference agrees on the per-PDU payload, got %r" % out)

    # Fragment with this implementation, reassemble with the reference.
    fragments = ble_fragment(frame, ATT_DEFAULT_MTU)
    rc, out = c_call(binary, "ble_reassemble",
                     ",".join(f.hex() for f in fragments))
    check(rc == 0, "reference reassembles independent fragments (%s)" % out)
    check(out == frame.hex(),
          "and recovers the identical frame")

    # Fragment with the reference, reassemble with this implementation.
    rc, out = c_call(binary, "ble_fragment", frame.hex())
    check(rc == 0, "reference fragments a frame")
    if rc == 0:
        reassembler = BleReassembler()
        recovered = None
        for piece in out.split(","):
            recovered = reassembler.feed(bytes.fromhex(piece))
        check(recovered == frame,
              "independent implementation recovers the identical frame")
        check(len(out.split(",")) == len(fragments),
              "and both produce the same fragment count")

    # A maximal frame at the minimum MTU: 56 fragments, under the modulus of 64.
    # Maximal means EVERY optional field set plus a maximal payload:
    # 8 mandatory + 16 optional + 1024 = 1048. A frame carrying only the frame
    # check is 1036 bytes and needs 55 fragments, which is not the worst case
    # the sequence field has to survive.
    big_payload = (bytes(range(256)) * 4)[:1024]
    big = mcl.encode_frame(
        3,
        mcl.FLAG_DESTINATION | mcl.FLAG_SESSION | mcl.FLAG_SEQUENCE |
        mcl.FLAG_FRESHNESS | mcl.FLAG_FRAME_CHECK,
        0x0BADCAFE, big_payload,
        destination_ref=0xFEEDFACE, session_ref=0x01020304,
        sequence=0xABCD, freshness_ms=60000)
    check(len(big) == LINK_FRAME_MAX_SIZE,
          "the test frame really is maximal: %d bytes" % len(big))
    big_fragments = ble_fragment(big, ATT_DEFAULT_MTU)
    check(len(big_fragments) == 56,
          "a maximal frame is 56 fragments at the minimum MTU, got %d"
          % len(big_fragments))
    check(len(big_fragments) <= FRAG_SEQ_MODULUS,
          "which is inside the 64-value sequence, so it cannot wrap")
    rc, out = c_call(binary, "ble_reassemble",
                     ",".join(f.hex() for f in big_fragments))
    check(rc == 0 and out == big.hex(),
          "the reference reassembles a maximal frame from independent pieces")

    # §5 discard table. Each case must be refused by both.
    print("[C5] BLE reassembly discards, both implementations")
    bad_sets = [
        ([fragments[0]] + fragments[2:], "sequence gap"),
        (fragments[1:], "fragment without a preceding START"),
        ([bytes([FRAG_START | 0])], "empty fragment payload"),
    ]
    for pieces, what in bad_sets:
        reassembler = BleReassembler()
        independent_ok = True
        try:
            result = None
            for piece in pieces:
                result = reassembler.feed(piece)
            independent_ok = result is not None
        except mcl.MclError:
            independent_ok = False
        rc, _ = c_call(binary, "ble_reassemble",
                       ",".join(p.hex() for p in pieces))
        reference_ok = (rc == 0)
        check(not independent_ok, "BLE: %s discarded here" % what)
        check(not reference_ok, "BLE: %s discarded by the reference" % what)
        check(independent_ok == reference_ok, "BLE: %s -- both agree" % what)

    # §6 frame check required, both sides.
    unchecked = mcl.encode_frame(0, mcl.FLAG_SEQUENCE, 0x0BADCAFE, payload,
                                 sequence=1)
    ok_here = True
    try:
        ble_frame_validate(unchecked)
    except mcl.MclError:
        ok_here = False
    rc, _ = c_call(binary, "ble_validate", unchecked.hex())
    check(not ok_here, "BLE: a frame with no check is refused here")
    check(rc != 0, "BLE: and by the reference")

    rc, _ = c_call(binary, "ble_validate", frame.hex())
    check(rc == 0, "BLE: a frame with a check is accepted by the reference")
    check(ble_frame_validate(frame) is not None, "and here")


def c_call(binary, verb, payload=""):
    result = subprocess.run([binary, verb, payload],
                            capture_output=True, text=True)
    return result.returncode, result.stdout.strip()


def main():
    print("=== MCL C5: independent implementation vs the Candidate profiles ===")
    print("Profile %d in both registries -- the Experimental Use value."
          % EXPERIMENTAL_PROFILE)
    print("This is evidence about profile %d, NOT about a Stable value that"
          % EXPERIMENTAL_PROFILE)
    print("does not exist yet. C4 and C5 are re-run on the final assigned")
    print("bytes once the Standards Action assignment is made.\n")

    sys.path.insert(0, HERE)
    from test_independent import build_cross_check
    binary = build_cross_check()

    test_ip_profile(binary)
    test_ble_profile(binary)

    print("\n%d checks, %d failed." % (checks, len(failures)))
    if failures:
        for item in failures:
            print("  - %s" % item)
        return 1
    print("C5 PROFILE INTEROPERABILITY PASSED (on experimental profile %d)"
          % EXPERIMENTAL_PROFILE)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

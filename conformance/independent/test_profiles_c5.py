"""
C5: independent implementation against the Stable transport profiles.

RELEASE GATE ITEM 17.

C4 established that two implementations agree about Wire objects and Link
frames. C5 asks the narrower question the profiles actually pose: does an
implementation written from `ip-datagram-profile-v1.md` and
`ble-gatt-profile-v1.md` carry and refuse the same things as the reference
bindings?

WHAT IS BEING TESTED, AND UNDER WHICH PROFILE VALUE

`profile_id = 1` in both registries -- the MCL Standards Action assignments
`IP-DATAGRAM` and `BLE-GATT`, made 2026-09-04. This is step 5 of the promotion
sequence in `GOVERNANCE.md` section 4.3, and it is not ceremony: `profile_id`
travels inside `TRANSPORT_OFFER` and `TRANSPORT_ACCEPT`, so the earlier run
against the Experimental Use value 192 is evidence about 192 and does not
transfer to these bytes.

192 has NOT been dropped from this file. It stays as an experimental value that
both implementations must carry without treating it as interoperable, and this
file asserts against the registries themselves that it is still Experimental Use
-- a test that fails the day somebody relabels it.

The profile carriage rules are implemented here from the specifications only;
`ip_binding.c` and `ble_binding.c` were not read while writing them.
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

STABLE_PROFILE = 1          # IP-DATAGRAM under IP, BLE-GATT under BLE
EXPERIMENTAL_PROFILE = 192  # Experimental Use, permanently


def check(cond, what):
    global checks
    checks += 1
    if not cond:
        failures.append(what)
        print("  FAIL: %s" % what)


def load_registry(relative):
    with open(os.path.join(ROOT, relative), encoding="utf-8") as handle:
        return json.load(handle)


def test_registry_agrees_with_what_is_being_tested():
    """The registry is the authoritative source of assigned numbers.

    A test that hardcodes a profile value proves the two implementations agree
    with each other and nothing about whether they agree with the registry.
    These checks close that gap, and they are the ones that fail if an
    Experimental Use value is ever quietly relabelled Stable.
    """
    print("[C5] the registries say what this file assumes")
    for relative, transport, name in [
            ("mcl-ip/registries/ip-profiles-v0.1.json", "IP", "IP-DATAGRAM"),
            ("mcl-ble/registries/ble-profiles-v0.1.json", "BLE", "BLE-GATT")]:
        reg = load_registry(relative)
        rows = dict((row["id"], row) for row in reg["profiles"])

        check(STABLE_PROFILE in rows,
              "%s registry assigns profile %d" % (transport, STABLE_PROFILE))
        if STABLE_PROFILE in rows:
            row = rows[STABLE_PROFILE]
            check(row["status"] == "stable",
                  "%s profile %d is stable, got %r"
                  % (transport, STABLE_PROFILE, row["status"]))
            check(row["name"] == name,
                  "%s profile %d is named %s, got %r"
                  % (transport, STABLE_PROFILE, name, row["name"]))
            check(row["range"] == "MCL Standards Action",
                  "%s profile %d came from the Standards Action range"
                  % (transport, STABLE_PROFILE))
            check(row["specification_status"] == "Stable",
                  "%s profile %d cites a Stable specification" % (transport,
                                                                  STABLE_PROFILE))

        check(rows[EXPERIMENTAL_PROFILE]["status"] == "experimental",
              "%s profile %d is STILL Experimental Use -- never relabelled"
              % (transport, EXPERIMENTAL_PROFILE))
        check(rows[0]["status"] == "reserved",
              "%s profile 0 stays reserved, so a zeroed field names no profile"
              % transport)


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


def check_profile_carriage(binary, transport_id, profile_id, what):
    """Both objects that carry profile_id, both directions, by value.

    An 8-bit field is easy to get right by accident and easy to lose in a
    struct layout. These checks compare the decoded VALUE on the far side,
    which is the only comparison that catches a field being read from the
    wrong offset.
    """
    for kind, extra in [("TRANSPORT_OFFER",
                         {"endpoint_token": 0xD00D0001, "validity": 30}),
                        ("TRANSPORT_ACCEPT",
                         {"session_ref": 0x5E5510C7})]:
        fields = {"source_ref": 0x0BADCAFE, "migration_ref": 0x4D194201,
                  "transport_id": transport_id, "profile_id": profile_id}
        fields.update(extra)
        raw = mcl.encode_tier0(kind, 1, fields)
        rc, out = c_call(binary, "fields_tier0", raw.hex())
        check(rc == 0, "%s: reference decodes %s (%s)" % (what, kind, out))
        check("profile_id=%d" % profile_id in out,
              "%s: reference reads profile_id=%d back from %s, got %r"
              % (what, profile_id, kind, out))
        check("transport_id=%d" % transport_id in out,
              "%s: and transport_id=%d, which scopes it"
              % (what, transport_id))
        # And back: the reference's own bytes, read by this implementation.
        again = mcl.decode_tier0(raw)
        check(again["fields"]["profile_id"] == profile_id,
              "%s: %s round-trips the value here too" % (what, kind))


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
    # is being tested rather than a label on the test.
    check_profile_carriage(binary, 2, STABLE_PROFILE,
                           "IP: the assigned IP-DATAGRAM value")
    check_profile_carriage(binary, 2, EXPERIMENTAL_PROFILE,
                           "IP: the experimental value, carried not blessed")

    # An offer this implementation builds at the assigned value must survive
    # the whole carriage path, not merely decode in isolation.
    offer = mcl.encode_tier0("TRANSPORT_OFFER", 1, {
        "source_ref": 0x0BADCAFE, "migration_ref": 0x4D194201,
        "transport_id": 2, "profile_id": STABLE_PROFILE,
        "endpoint_token": 0xD00D0001, "validity": 30})
    carried = mcl.encode_frame(0, mcl.FLAG_SEQUENCE | mcl.FLAG_FRAME_CHECK,
                               0x0BADCAFE, offer, sequence=2)
    rc, out = c_call(binary, "ip_validate", carried.hex())
    check(rc == 0,
          "an IP datagram carrying an IP-DATAGRAM offer is accepted (%s)" % out)
    check(ip_datagram_validate(carried) is not None,
          "and this implementation accepts the same datagram")


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

    # The BLE profile identifier, under transport 3. Profile 1 here and
    # profile 1 under IP are unrelated assignments; the transport_id is what
    # keeps them apart, so both fields are compared together.
    check_profile_carriage(binary, 3, STABLE_PROFILE,
                           "BLE: the assigned BLE-GATT value")
    check_profile_carriage(binary, 3, EXPERIMENTAL_PROFILE,
                           "BLE: the experimental value, carried not blessed")

    # An offer naming BLE-GATT, fragmented at the minimum MTU and reassembled
    # by the reference: the identifier has to survive fragmentation too.
    offer = mcl.encode_tier0("TRANSPORT_OFFER", 1, {
        "source_ref": 0x0BADCAFE, "migration_ref": 0x4D194201,
        "transport_id": 3, "profile_id": STABLE_PROFILE,
        "endpoint_token": 0xD00D0001, "validity": 30})
    carried = mcl.encode_frame(0, mcl.FLAG_SEQUENCE | mcl.FLAG_FRAME_CHECK,
                               0x0BADCAFE, offer, sequence=3)
    pieces = ble_fragment(carried, ATT_DEFAULT_MTU)
    check(len(pieces) > 1, "the offer really does fragment at the minimum MTU")
    rc, out = c_call(binary, "ble_reassemble",
                     ",".join(f.hex() for f in pieces))
    check(rc == 0 and out == carried.hex(),
          "a BLE-GATT offer survives fragmentation and reassembly intact")


def c_call(binary, verb, payload=""):
    result = subprocess.run([binary, verb, payload],
                            capture_output=True, text=True)
    return result.returncode, result.stdout.strip()


def main():
    print("=== MCL C5: independent implementation vs the Stable profiles ===")
    print("profile_id %d in both registries -- IP-DATAGRAM under transport 2,"
          % STABLE_PROFILE)
    print("BLE-GATT under transport 3. MCL Standards Action, 2026-09-04.")
    print("These are the FINAL assigned bytes: profile_id travels inside")
    print("TRANSPORT_OFFER and TRANSPORT_ACCEPT, so the earlier run against")
    print("the Experimental Use value %d is evidence about %d and does not"
          % (EXPERIMENTAL_PROFILE, EXPERIMENTAL_PROFILE))
    print("transfer here. %d is still exercised, still experimental.\n"
          % EXPERIMENTAL_PROFILE)

    sys.path.insert(0, HERE)
    from test_independent import build_cross_check
    binary = build_cross_check()

    test_registry_agrees_with_what_is_being_tested()
    test_ip_profile(binary)
    test_ble_profile(binary)

    print("\n%d checks, %d failed." % (checks, len(failures)))
    if failures:
        for item in failures:
            print("  - %s" % item)
        return 1
    print("C5 PROFILE INTEROPERABILITY PASSED on the assigned profile value %d"
          % STABLE_PROFILE)
    print()
    print("What this does NOT establish: that two ORGANISATIONS interoperate.")
    print("The implementation on this side is independent of the reference")
    print("code and was written by the same author. See ICS.md.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

#!/bin/sh
#
# Release gate item 21: every Stable feature traces end to end.
#
# THE CLAIM BEING TESTED
#
#   requirement -> normative spec -> registry -> public API -> positive test
#                                             -> negative test -> evidence
#
# A missing link means an unfinished feature. A feature with a specification and
# no negative test is a feature nobody has tried to break; a feature with code
# and no specification cannot be implemented by anyone else.
#
# WHY THIS IS EXECUTABLE
#
# A traceability table written by hand asserts the links exist. This one
# CHECKS them: every path is opened, every symbol is looked for in the API
# baseline, every test file must exist. A row that names a file that is not
# there fails.
#
# Exit 0 when every Stable feature traces; 1 otherwise.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
BASELINE="$ROOT/mcl-core/conformance/api-baseline-v1.txt"
FAILURES=0
ROWS=0

# feature | spec | registry-or-'-' | api symbol-or-'-' | positive test | negative test | evidence-or-'-'
FEATURES="
Wire common header|mcl-wire/spec/common-header-v0.2.md|-|mcl_wire_header_encode|mcl-wire/tests/test_wire.c|mcl-wire/tests/test_fuzz_decode.c|-
Stable major rule|mcl-wire/spec/common-header-v0.2.md|mcl-core/registries/semantic-codes-v0.2.json|mcl_wire_kind_allowed_at_major|mcl-wire/tests/test_major_rule.c|mcl-wire/tests/test_major_rule.c|-
PRESENCE|mcl-wire/spec/tier0-layout-v0.2.md|mcl-core/registries/tier0-fields-v0.1.json|mcl_wire_tier0_encode|mcl-wire/tests/test_vectors.c|mcl-wire/tests/test_fuzz_decode.c|mcl-ap/experiments/001-known-waveform/evidence
TRANSPORT_OFFER|mcl-wire/spec/tier0-layout-v0.2.md|mcl-core/registries/tier0-fields-v0.1.json|mcl_wire_tier0_encode|mcl-wire/tests/test_vectors.c|mcl-wire/tests/test_fuzz_decode.c|mcl-sdk/evidence
TRANSPORT_ACCEPT|mcl-wire/spec/tier0-layout-v0.2.md|mcl-core/registries/tier0-fields-v0.1.json|mcl_wire_tier0_encode|mcl-wire/tests/test_vectors.c|mcl-wire/tests/test_fuzz_decode.c|mcl-sdk/evidence
Duration codec|mcl-wire/spec/duration-v0.1.md|mcl-core/registries/tier0-fields-v0.1.json|mcl_wire_duration_encode|mcl-wire/tests/test_duration.c|mcl-wire/tests/test_duration.c|-
Extension envelope|mcl-wire/spec/tier0-extensions-v0.1.md|mcl-wire/registries/extension-ids-v0.1.json|mcl_wire_tier0_encode_ext|mcl-wire/tests/test_extension.c|mcl-wire/tests/test_extension.c|-
Link frame|mcl-link/spec/link-v0.md|-|mcl_link_frame_encode|mcl-link/tests/test_link_frame.c|mcl-link/tests/test_link_frame.c|mcl-ip/evidence
Link frame classes|mcl-link/spec/link-class-disposition-v1.md|-|mcl_link_frame_decode|mcl-link/tests/test_control.c|mcl-link/tests/test_control.c|-
ACK and NACK|mcl-link/spec/link-frame-classes-v0.1.md|-|mcl_link_ack_encode|mcl-link/tests/test_control.c|mcl-link/tests/test_control.c|-
CLOSE|mcl-link/spec/link-frame-classes-v0.1.md|-|mcl_link_close_encode|mcl-link/tests/test_control.c|mcl-link/tests/test_control.c|-
Capability negotiation|mcl-link/spec/link-negotiation-v1.md|-|mcl_link_capability_encode|mcl-link/tests/test_negotiation.c|mcl-link/tests/test_negotiation.c|-
Version selection|mcl-link/spec/link-negotiation-v1.md|-|mcl_link_negotiation_select|mcl-link/tests/test_negotiation.c|mcl-link/tests/test_negotiation.c|-
Contact lifecycle|mcl-link/spec/link-contact-ownership-v0.1.md|-|mcl_contact_begin|mcl-link/tests/test_contact.c|mcl-link/tests/test_contact.c|mcl-sdk/evidence
Migration handoff|mcl-link/spec/link-handoff-control-v0.1.md|mcl-link/registries/handoff-ops-v0.1.json|mcl_handoff_control_encode|mcl-link/tests/test_handoff.c|mcl-link/tests/test_handoff.c|mcl-sdk/evidence
Rendezvous beacon|mcl-link/spec/link-handoff-control-v0.1.md|-|mcl_rendezvous_beacon_encode|mcl-link/tests/test_endpoint_rendezvous.c|mcl-link/tests/test_endpoint_rendezvous.c|-
Transport IDs|mcl-link/spec/link-v0.md|mcl-link/registries/transport-ids-v0.1.json|-|mcl-sdk/tests/test_transport_registry_binding.c|mcl-sdk/tests/test_transport_registry_binding.c|-
Transport-aware SDK|mcl-link/spec/link-contact-ownership-v0.1.md|-|mcl_node_send_framed_tier0|mcl-sdk/tests/test_sdk_framed.c|mcl-sdk/tests/test_sdk_framed.c|mcl-sdk/evidence
Multi-contact isolation|mcl-link/spec/link-contact-ownership-v0.1.md|-|mcl_node_init|mcl-sdk/tests/test_multi_contact.c|mcl-sdk/tests/test_multi_contact.c|-
IP datagram carriage|mcl-ip/spec/ip-datagram-profile-v1.md|mcl-ip/registries/ip-profiles-v0.1.json|mcl_ip_datagram_validate|mcl-ip/tests/test_ip_binding.c|mcl-ip/tests/test_ip_binding.c|mcl-ip/evidence
BLE GATT carriage|mcl-ble/spec/ble-gatt-profile-v1.md|mcl-ble/registries/ble-profiles-v0.1.json|mcl_ble_frame_validate|mcl-ble/tests/test_ble_binding.c|mcl-ble/tests/test_ble_binding.c|mcl-ble/evidence
"

echo "=== MCL feature traceability ==="
echo
printf '%-26s %s\n' "FEATURE" "SPEC REG API POS NEG EVID"
echo "---------------------------------------------------------------"

fail_row() {
    echo "  FAIL $1: $2"
    FAILURES=$((FAILURES + 1))
}

echo "$FEATURES" | while IFS='|' read -r feature spec registry symbol positive negative evidence; do
    [ -z "$feature" ] && continue
    echo "$feature|$spec|$registry|$symbol|$positive|$negative|$evidence"
done > "${TMPDIR:-/tmp}/mcl-trace.txt"

while IFS='|' read -r feature spec registry symbol positive negative evidence; do
    [ -z "$feature" ] && continue
    ROWS=$((ROWS + 1))
    marks=""

    if [ -f "$ROOT/$spec" ]; then marks="$marks  Y"; else
        marks="$marks  N"; fail_row "$feature" "no specification at $spec"; fi

    if [ "$registry" = "-" ]; then marks="$marks   -"
    elif [ -f "$ROOT/$registry" ]; then marks="$marks   Y"
    else marks="$marks   N"; fail_row "$feature" "no registry at $registry"; fi

    if [ "$symbol" = "-" ]; then marks="$marks   -"
    elif grep -qx "$symbol" "$BASELINE"; then marks="$marks   Y"
    else marks="$marks   N"; fail_row "$feature" "$symbol is not in the API baseline"; fi

    if [ -f "$ROOT/$positive" ]; then marks="$marks   Y"; else
        marks="$marks   N"; fail_row "$feature" "no positive test at $positive"; fi

    if [ -f "$ROOT/$negative" ]; then marks="$marks   Y"; else
        marks="$marks   N"; fail_row "$feature" "no negative test at $negative"; fi

    if [ "$evidence" = "-" ]; then marks="$marks   -"
    elif [ -d "$ROOT/$evidence" ]; then marks="$marks   Y"
    else marks="$marks   N"; fail_row "$feature" "no evidence at $evidence"; fi

    printf '%-26s %s\n' "$feature" "$marks"
done < "${TMPDIR:-/tmp}/mcl-trace.txt"

# The subshell above cannot export FAILURES, so recount by re-running the file
# checks in this shell. Duplicated work, and correct -- a count that was wrong
# because of a subshell would be the worst possible defect in this script.
FAILURES=0
ROWS=0
while IFS='|' read -r feature spec registry symbol positive negative evidence; do
    [ -z "$feature" ] && continue
    ROWS=$((ROWS + 1))
    [ -f "$ROOT/$spec" ] || FAILURES=$((FAILURES + 1))
    [ "$registry" = "-" ] || [ -f "$ROOT/$registry" ] || FAILURES=$((FAILURES + 1))
    [ "$symbol" = "-" ] || grep -qx "$symbol" "$BASELINE" || FAILURES=$((FAILURES + 1))
    [ -f "$ROOT/$positive" ] || FAILURES=$((FAILURES + 1))
    [ -f "$ROOT/$negative" ] || FAILURES=$((FAILURES + 1))
    [ "$evidence" = "-" ] || [ -d "$ROOT/$evidence" ] || FAILURES=$((FAILURES + 1))
done < "${TMPDIR:-/tmp}/mcl-trace.txt"

echo
echo "$ROWS features traced."
echo
echo "Y = present   - = not applicable to this feature   N = MISSING"

if [ "$FAILURES" -ne 0 ]; then
    echo
    echo "$FAILURES broken link(s). A missing link is an unfinished feature."
    echo "TRACEABILITY CHECK FAILED"
    exit 1
fi

echo
echo "TRACEABILITY CHECK PASSED"
echo
echo "What this does NOT establish: that the tests are GOOD, or that the"
echo "evidence supports what the feature claims. It establishes that no"
echo "Stable feature is missing a specification, an API, a positive test or a"
echo "negative test."

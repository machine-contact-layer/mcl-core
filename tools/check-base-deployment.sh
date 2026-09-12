#!/bin/sh
#
# The published Base deployment profile and the SDK constant must agree.
#
# WHY THIS GATE EXISTS
#
# The same reason as check-reference-deployment.sh: the deployment is one
# decision written twice, once as a document a builder reads and once as a
# constant a builder calls, and nothing else connects them.
#
# It exists SEPARATELY because MCL-BASE-DEPLOYMENT-1 asserts things the
# reference deployment does not, and those are the things most likely to be
# broken by a well-meaning edit:
#
#   - it names NO bootstrap profile. Base 1 discovers nothing, so a bootstrap
#     entry here would impose a rendezvous requirement no Base implementation
#     must meet. `deployment-profiles/invalid/03-base-names-bootstrap.json`
#     exists to record that exact mistake.
#   - it declares Wire major 1 and Link major 1. Base 1 conformance is defined
#     in terms of the Stable pair (conformance-profiles-v1.md section 4.1), and
#     a Base deployment silently running at the experimental major would be
#     claiming a conformance it does not have.
#   - it requires no candidate_open. That is checked by tests/test_base1.c
#     rather than here, because it is a property of init, not of the profile.
#
# The C side is not grepped out of the source. It is COMPILED and asked, so
# what this checks is the value a builder actually receives.
#
# Exit 0 when they agree, 1 otherwise.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
PROFILE="$ROOT/mcl-core/deployments/MCL-BASE-DEPLOYMENT-1.json"
WORK=$(mktemp -d)
trap 'status=$?; rm -rf "$WORK"; exit $status' EXIT

CC=${CC:-cc}
FAILURES=0

echo "=== base deployment: document vs SDK ==="
echo

if [ ! -f "$PROFILE" ]; then
    echo "  FAIL no profile at $PROFILE"
    exit 1
fi

fail() {
    echo "  FAIL $1"
    FAILURES=$((FAILURES + 1))
}

# ---------------------------------------------------------------- the document
#
# sed and awk rather than a JSON library, for the same reason as the reference
# gate: a release gate that needs a dependency installed is a release gate that
# stops being run.

conformance=$(sed -n 's/.*"conformance_layer"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PROFILE")
wire_major=$(sed -n 's/.*"wire_major"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$PROFILE")
link_major=$(sed -n 's/.*"link_major"[[:space:]]*:[[:space:]]*\([0-9][0-9]*\).*/\1/p' "$PROFILE")
security=$(sed -n 's/.*"security"[[:space:]]*:[[:space:]]*{[[:space:]]*"profile"[[:space:]]*:[[:space:]]*\([^ }]*\).*/\1/p' "$PROFILE")
bootstrap=$(sed -n 's/.*"bootstrap_profile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PROFILE")

doc_bearers=$(awk '
    /"mandatory"/ { block = "m"; next }
    /"optional"/  { block = "o"; next }
    /"transport_id"/ {
        t = $0; sub(/.*"transport_id"[[:space:]]*:[[:space:]]*/, "", t); sub(/[^0-9].*/, "", t)
        p = $0; sub(/.*"profile_id"[[:space:]]*:[[:space:]]*/, "", p); sub(/[^0-9].*/, "", p)
        if (block == "m") { m = m t ":" p " " } else if (block == "o") { o = o t ":" p " " }
    }
    END { printf "%s%s", m, o }
' "$PROFILE")

[ "$conformance" = "MCL Base 1" ] || \
    fail "conformance_layer is '$conformance'; this profile is the Base 1 deployment"

[ "$wire_major" = "1" ] || \
    fail "wire_major is '$wire_major'; Base 1 is defined on the Stable Wire major"

[ "$link_major" = "1" ] || \
    fail "link_major is '$link_major'; Base 1 is defined on the Stable Link major"

if [ -n "$bootstrap" ]; then
    fail "the profile names bootstrap_profile '$bootstrap'; a Base deployment has an arranged bearer and no rendezvous requirement, and naming one imposes a requirement no Base implementation must meet"
fi

if [ "$security" != "null" ]; then
    fail "security.profile is '$security'; v1 has no security profile to select"
fi

echo "  document   conformance         $conformance"
echo "  document   majors              wire $wire_major, link $link_major"
echo "  document   bearers             $doc_bearers"
echo "  document   bootstrap           none"

# --------------------------------------------------------------------- the SDK

cat > "$WORK/print_base.c" <<'CEOF'
#include "mcl/machine.h"
#include <stdio.h>

int main(void)
{
    mcl_machine_config_t cfg;
    unsigned i;

    if (mcl_machine_config_deployment(&cfg, MCL_DEPLOYMENT_BASE_ARRANGED_1,
                                      0xA1B2C3D4u,
                                      MCL_CONTACT_ROLE_INITIATOR)
        != MCL_MACHINE_OK) {
        printf("REFUSED\n");
        return 1;
    }
    for (i = 0u; i < cfg.bearer_count; ++i) {
        printf("%u:%u ", (unsigned)cfg.bearer_transport_id[i],
               (unsigned)cfg.bearer_profile_id[i]);
    }
    printf("\n%u\n", (unsigned)cfg.wire_major);
    printf("%u\n", (unsigned)cfg.arranged_bearer);
    printf("%u\n", (unsigned)cfg.shared_medium);
    printf("%s\n", (cfg.deployment_profile_id != NULL)
                   ? cfg.deployment_profile_id : "(none)");
    return 0;
}
CEOF

INC="-I$ROOT/mcl-sdk/include -I$ROOT/mcl-wire/include -I$ROOT/mcl-link/include"
SRC="$ROOT/mcl-sdk/src/machine.c $ROOT/mcl-sdk/src/rendezvous.c \
     $ROOT/mcl-sdk/src/sdk.c \
     $ROOT/mcl-wire/src/wire.c $ROOT/mcl-wire/src/extension.c \
     $ROOT/mcl-link/src/link.c $ROOT/mcl-link/src/contact.c \
     $ROOT/mcl-link/src/handoff.c $ROOT/mcl-link/src/control.c \
     $ROOT/mcl-link/src/negotiation.c $ROOT/mcl-link/src/endpoint_rendezvous.c"

if ! $CC -std=c99 -Wall -Wextra -Werror $INC "$WORK/print_base.c" $SRC \
        -o "$WORK/print_base" 2> "$WORK/cc.log"; then
    echo "  FAIL the SDK side would not compile"
    sed 's/^/    /' "$WORK/cc.log" | head -20
    exit 1
fi

"$WORK/print_base" > "$WORK/out.txt"
sdk_bearers=$(sed -n '1p' "$WORK/out.txt")
sdk_wire=$(sed -n '2p' "$WORK/out.txt")
sdk_arranged=$(sed -n '3p' "$WORK/out.txt")
sdk_shared=$(sed -n '4p' "$WORK/out.txt")
sdk_name=$(sed -n '5p' "$WORK/out.txt")

echo
echo "  SDK        bearers             $sdk_bearers"
echo "  SDK        wire major          $sdk_wire"
echo "  SDK        arranged bearer     $sdk_arranged"
echo "  SDK        shared medium       $sdk_shared"
echo "  SDK        names               $sdk_name"
echo

# ----------------------------------------------------------------- comparison

doc_norm=$(printf '%s' "$doc_bearers" | sed 's/[[:space:]]*$//')
sdk_norm=$(printf '%s' "$sdk_bearers" | sed 's/[[:space:]]*$//')
[ "$doc_norm" = "$sdk_norm" ] || \
    fail "bearer list (transport:profile, in order): document [$doc_norm], SDK [$sdk_norm]"

[ "$sdk_wire" = "$wire_major" ] || \
    fail "wire major: document $wire_major, SDK $sdk_wire"

[ "$sdk_arranged" = "1" ] || \
    fail "the SDK configuration is not marked as an arranged bearer, so mcl_machine_init() would still demand a candidate_open this deployment never uses"

[ "$sdk_shared" = "0" ] || \
    fail "the SDK configuration claims a shared medium; a Base deployment has an arranged bearer and no contention discipline to apply"

[ "$sdk_name" = "MCL-BASE-DEPLOYMENT-1" ] || \
    fail "the SDK configuration names '$sdk_name' rather than the profile it came from"

if [ "$FAILURES" -ne 0 ]; then
    echo
    echo "BASE DEPLOYMENT CHECK FAILED"
    echo
    echo "The published profile and the constant a builder calls disagree."
    echo "Whichever is right, a builder following the document and a builder"
    echo "calling the function are not on the same deployment."
    exit 1
fi

echo "BASE DEPLOYMENT CHECK PASSED"
echo
echo "What this does NOT establish: that any machine implements it, or that"
echo "the arranged bearer exists. Only that the document and the code describe"
echo "the same Base 1 deployment on the same Stable majors."

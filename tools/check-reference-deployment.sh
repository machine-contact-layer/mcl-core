#!/bin/sh
#
# The published deployment profile and the SDK constant must agree.
#
# WHY THIS GATE EXISTS
#
# `deployments/MCL-REFERENCE-DEPLOYMENT-1.json` tells a builder which optional
# pieces of MCL are mandatory on the reference path. `mcl_machine_config_
# deployment(MCL_DEPLOYMENT_REFERENCE_1, ...)` hands them to that builder's
# code. They are the same decision written twice, in two languages, and nothing
# connected them: an editor could change the profile and leave every
# implementation quietly running the old one, or change the C and leave the
# document describing a deployment that no longer exists.
#
# A builder who reads the document and a builder who calls the function must end
# up on the same bearers, in the same order, or "they both implement
# MCL-REFERENCE-DEPLOYMENT-1" means nothing.
#
# WHAT IS COMPARED
#
#   bootstrap transport      from requires.bootstrap_profile
#   bearer transport ids     continuation.mandatory then continuation.optional,
#   bearer profile ids       IN THAT ORDER -- the order IS the mechanism by
#                            which two builders who never coordinate converge,
#                            so it is compared, not just the set.
#   security profile         must be null; v1 has no security to select
#
# The C side is not grepped out of the source. It is COMPILED and asked, so
# what this checks is the value a builder actually receives.
#
# Exit 0 when they agree, 1 otherwise.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
PROFILE="$ROOT/mcl-core/deployments/MCL-REFERENCE-DEPLOYMENT-1.json"
WORK=$(mktemp -d)
# The trap restores the status explicitly. dash and bash both preserve it
# without this -- verified rather than assumed -- but a cleanup trap that can
# change the exit status of a release gate is not worth leaving to the shell.
trap 'status=$?; rm -rf "$WORK"; exit $status' EXIT

CC=${CC:-cc}
FAILURES=0

echo "=== reference deployment: document vs SDK ==="
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
# Read with sed rather than a JSON library, because this script has to run in
# the same places the rest of the gates do and adding a parser dependency to a
# release gate is how a gate stops being run.

bootstrap_profile=$(sed -n 's/.*"bootstrap_profile"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' "$PROFILE")
security=$(sed -n 's/.*"security"[[:space:]]*:[[:space:]]*{[[:space:]]*"profile"[[:space:]]*:[[:space:]]*\([^ }]*\).*/\1/p' "$PROFILE")

# Every continuation entry, mandatory block first, then optional, in file order.
# awk keeps the blocks apart so the ORDER survives; a plain grep would not.
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

case "$bootstrap_profile" in
    AP-BOOTSTRAP-1) doc_bootstrap_transport=1 ;;
    "")  fail "the profile names no bootstrap_profile"; doc_bootstrap_transport=0 ;;
    *)   fail "unknown bootstrap profile '$bootstrap_profile'; this gate maps names to transport ids and does not know that one"
         doc_bootstrap_transport=0 ;;
esac

if [ "$security" != "null" ]; then
    fail "security.profile is '$security'; v1 has no security profile to select, and a deployment that names one is describing something that does not exist"
fi

echo "  document   bootstrap transport $doc_bootstrap_transport ($bootstrap_profile)"
echo "  document   bearers             $doc_bearers"

# --------------------------------------------------------------------- the SDK

cat > "$WORK/print_deployment.c" <<'CEOF'
#include "mcl/machine.h"
#include <stdio.h>

int main(void)
{
    mcl_machine_config_t cfg;
    unsigned i;

    if (mcl_machine_config_deployment(&cfg, MCL_DEPLOYMENT_REFERENCE_1,
                                      0xA1B2C3D4u,
                                      MCL_CONTACT_ROLE_INITIATOR)
        != MCL_MACHINE_OK) {
        printf("REFUSED\n");
        return 1;
    }
    printf("%u\n", (unsigned)cfg.bootstrap_transport_id);
    for (i = 0u; i < cfg.bearer_count; ++i) {
        printf("%u:%u ", (unsigned)cfg.bearer_transport_id[i],
               (unsigned)cfg.bearer_profile_id[i]);
    }
    printf("\n%s\n", (cfg.deployment_profile_id != NULL)
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

if ! $CC -std=c99 -Wall -Wextra -Werror $INC "$WORK/print_deployment.c" $SRC \
        -o "$WORK/print_deployment" 2> "$WORK/cc.log"; then
    echo "  FAIL the SDK side would not compile"
    sed 's/^/    /' "$WORK/cc.log" | head -20
    exit 1
fi

"$WORK/print_deployment" > "$WORK/out.txt"
sdk_bootstrap=$(sed -n '1p' "$WORK/out.txt")
sdk_bearers=$(sed -n '2p' "$WORK/out.txt")
sdk_name=$(sed -n '3p' "$WORK/out.txt")

echo "  SDK        bootstrap transport $sdk_bootstrap"
echo "  SDK        bearers             $sdk_bearers"
echo "  SDK        names               $sdk_name"
echo

# ----------------------------------------------------------------- comparison

[ "$sdk_bootstrap" = "$doc_bootstrap_transport" ] || \
    fail "bootstrap transport: document $doc_bootstrap_transport, SDK $sdk_bootstrap"

# Normalise trailing space only; the ORDER is significant and is not sorted.
doc_norm=$(printf '%s' "$doc_bearers" | sed 's/[[:space:]]*$//')
sdk_norm=$(printf '%s' "$sdk_bearers" | sed 's/[[:space:]]*$//')
[ "$doc_norm" = "$sdk_norm" ] || \
    fail "bearer list (transport:profile, in offer order): document [$doc_norm], SDK [$sdk_norm]"

[ "$sdk_name" = "MCL-REFERENCE-DEPLOYMENT-1" ] || \
    fail "the SDK configuration names '$sdk_name' rather than the profile it came from"

if [ "$FAILURES" -ne 0 ]; then
    echo
    echo "REFERENCE DEPLOYMENT CHECK FAILED"
    echo
    echo "The published profile and the constant a builder calls disagree."
    echo "Whichever is right, two builders following them are not on the same"
    echo "deployment, which is the one thing a deployment profile exists to"
    echo "guarantee."
    exit 1
fi

echo "REFERENCE DEPLOYMENT CHECK PASSED"
echo
echo "What this does NOT establish: that the deployment is a good one, or that"
echo "any machine implements it. Only that the document and the code describe"
echo "the same bearers in the same order."

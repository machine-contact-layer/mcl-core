#!/bin/sh
#
# Gate: deployment profiles validate, and the negative fixtures are refused.
#
# The second half is the half that matters. A validator that accepts everything
# passes a suite made only of valid inputs, so each fixture in
# conformance/deployment-profiles/invalid/ must FAIL, and this script fails if
# any of them is accepted.
#
# spec/deployment-profile-v1.md is the prose; tools/validate_deployment_profile.c
# is the executable form; these fixtures keep the two honest.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORK=${TMPDIR:-/tmp}/mcl-deployment-profiles
CC=${CC:-cc}

rm -rf "$WORK"
mkdir -p "$WORK"

echo "=== deployment profile gate ==="

$CC -std=c99 -O2 -Wall -Wextra -Werror \
    -o "$WORK/validate_deployment_profile" \
    "$ROOT/mcl-core/tools/validate_deployment_profile.c"

VALIDATOR="$WORK/validate_deployment_profile"
failures=0
checked=0

# ---- profiles that must validate --------------------------------------------

for f in "$ROOT/mcl-core/deployments/"*.json \
         "$ROOT/mcl-core/conformance/deployment-profiles/"*.json; do
    [ -f "$f" ] || continue
    checked=$((checked + 1))
    if ! "$VALIDATOR" --root "$ROOT" "$f" > "$WORK/out.txt" 2>&1; then
        echo "FAIL: a valid profile was rejected: $f"
        cat "$WORK/out.txt"
        failures=$((failures + 1))
    fi
done

# ---- fixtures that must be refused ------------------------------------------

for f in "$ROOT/mcl-core/conformance/deployment-profiles/invalid/"*.json; do
    [ -f "$f" ] || continue
    checked=$((checked + 1))
    if "$VALIDATOR" --root "$ROOT" "$f" > "$WORK/out.txt" 2>&1; then
        echo "FAIL: an invalid fixture was ACCEPTED: $f"
        echo "      A validator that accepts everything passes a suite of valid"
        echo "      inputs. This is the check that notices."
        failures=$((failures + 1))
    fi
done

echo "checked $checked profile(s)"

if [ "$failures" -ne 0 ]; then
    echo "DEPLOYMENT PROFILE GATE FAILED ($failures)"
    exit 1
fi

# The reference deployment names AP-BOOTSTRAP-1, which does not exist yet. That
# is reported as PENDING rather than as an error, and it is deliberately NOT a
# gate failure: the profile is correctly written and is waiting on MCL. When
# AP-BOOTSTRAP-1 is specified, the PENDING line disappears on its own.
"$VALIDATOR" --root "$ROOT" "$ROOT/mcl-core/deployments/MCL-REFERENCE-DEPLOYMENT-1.json" \
    | grep -E "PENDING|guarantees" || true

echo "deployment profiles OK"

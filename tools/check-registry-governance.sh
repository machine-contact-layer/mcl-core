#!/bin/sh
#
# Release gate item 3: every MCL registry names its change controller and its
# four procedures.
#
# WHY THIS IS A SCRIPT AND NOT A CHECKLIST
#
# "Every registry has governance" is the kind of claim that is true on the day
# it is written and quietly false the first time a registry is added. A new
# registry file that nobody remembers to bind is exactly the failure this
# catches: the check enumerates registries from the FILESYSTEM, not from a list,
# so a registry that exists is a registry that must be governed.
#
# Exit 0 when every registry is bound; 1 otherwise.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
FAILURES=0

REQUIRED="change_controller procedures application review promotion deprecation"

echo "=== MCL registry governance ==="
echo

found=0
for registry in "$ROOT"/mcl-*/registries/*.json; do
    [ -e "$registry" ] || continue
    found=$((found + 1))
    name=$(echo "$registry" | sed "s|$ROOT/||")
    missing=""

    for key in $REQUIRED; do
        # The key must appear inside a "governance" object. Checking for the
        # key alone would pass on a registry that happened to use the word
        # elsewhere, so the governance block is extracted first.
        if ! sed -n '/"governance"/,/^ *}/p' "$registry" | grep -q "\"$key\""; then
            missing="$missing $key"
        fi
    done

    if [ -n "$missing" ]; then
        echo "  FAIL $name"
        echo "       missing:$missing"
        FAILURES=$((FAILURES + 1))
    else
        echo "  ok   $name"
    fi
done

echo
if [ "$found" -eq 0 ]; then
    echo "no registries found -- the search pattern is wrong, which is a defect"
    echo "in this script rather than a clean result"
    exit 1
fi

echo "$found registries checked."

if [ "$FAILURES" -ne 0 ]; then
    echo
    echo "$FAILURES registry/registries lack governance."
    echo "Every registry needs a change controller and the four procedures."
    echo "See mcl-core/governance/GOVERNANCE.md section 4."
    echo "REGISTRY GOVERNANCE CHECK FAILED"
    exit 1
fi

echo "REGISTRY GOVERNANCE CHECK PASSED"
echo
echo "What this does NOT establish: that the procedures are FOLLOWED, or that"
echo "any particular assignment was reviewed. It establishes that every"
echo "registry names who controls it and by what process."

#!/bin/sh
#
# A FAILED BUILD MUST NOT LEAVE AN OLDER BINARY RUNNABLE.
#
# This exists because of a specific incident, on 2026-09-06, in this project.
#
# A build-and-run helper for the rendezvous checks sent compiler output to
# /dev/null and then ran whichever binary it found. When the test file stopped
# compiling, the helper silently re-ran a STALE executable -- and three
# consecutive runs printed byte-identical results while the source was being
# changed underneath them. Two conclusions were drawn from those runs before
# anyone noticed. Both were worthless.
#
# That failure mode is worse than a crash in both directions. A stale binary
# manufactures false PASSES, by running code that no longer exists; and false
# FAILURES, by running code that a fix has already replaced. Neither announces
# itself, because the numbers look exactly like numbers.
#
# The invariant is mechanical, so it is checked mechanically:
#
#     a script that builds and then runs must abort on a build failure
#
# In practice that means `set -e` (or `set -eu`, `-euo pipefail`), or an
# explicit status check on the build itself. Discarding the compiler's output
# is not the defect on its own -- a quiet passing build is fine -- but
# discarding it while ignoring the status is exactly the incident.
#
# This is a heuristic over shell text and it is deliberately conservative: it
# reports what it cannot verify rather than staying silent, because a checker
# that misses the case it was written for is the same class of mistake all over
# again.
set -u

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
STATUS=0
CHECKED=0

echo "== build-then-run harnesses =="

for script in $(find "$ROOT" -name '*.sh' -type f -not -path '*/.git/*' | sort); do
    # Does it build anything?
    #
    # `\$CC` is in this pattern because it was missing from the first version,
    # which then reported four scripts where the tree has five: experiment
    # 012's self-test builds through "$CC" and was silently skipped. A checker
    # written against a stale-binary incident that quietly overlooks a script
    # is repeating the incident, so the count is printed and a zero is a
    # failure rather than a pass.
    if ! grep -qE '(^|[^A-Za-z_-])(cc|gcc|clang|cl)[[:space:]]+-|cmake[[:space:]]+--build|[$]\{?CC\}?[[:space:]]+-|"[$]\{?CC\}?"[[:space:]]+-' \
            "$script"; then
        continue
    fi
    CHECKED=$((CHECKED + 1))
    rel="${script#$ROOT/}"

    # Aborts on any failing command?
    if grep -qE '^[[:space:]]*set[[:space:]]+-[a-z]*e' "$script"; then
        printf '   ok   %s  (set -e)\n' "$rel"
        continue
    fi
    # Or checks the build's own status explicitly?
    if grep -qE '(cmake[[:space:]]+--build|(^|[^A-Za-z_-])(cc|gcc|clang)[[:space:]]+-)[^\n]*(\|\||&&)' \
            "$script" ||
       grep -qE 'if[[:space:]]+!?[[:space:]]*(cmake[[:space:]]+--build|(cc|gcc|clang)[[:space:]]+-)' \
            "$script"; then
        printf '   ok   %s  (build status checked)\n' "$rel"
        continue
    fi
    printf '   FAIL %s\n' "$rel"
    echo "        builds and runs, but has neither 'set -e' nor a check"
    echo "        on the build's exit status. A failed compile here can leave"
    echo "        an older executable runnable, which produces confident"
    echo "        numbers about code that was never built."
    STATUS=1
done

echo
if [ "$CHECKED" -eq 0 ]; then
    echo "FAIL: no build-then-run scripts were found at all."
    echo "That is not a clean result, it is a broken search: this tree has"
    echo "several, so a zero here means the pattern stopped matching and the"
    echo "check has been passing on nothing."
    exit 1
fi

if [ "$STATUS" -eq 0 ]; then
    echo "PASS: $CHECKED build-then-run scripts, all abort on a failed build."
else
    echo "FAIL: a build-then-run script can run a stale binary."
fi
exit "$STATUS"

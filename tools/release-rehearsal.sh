#!/bin/sh
#
# Release gate item 32: the full rehearsal.
#
# Runs everything that can be run, in one pass, on the tree as it stands. This
# is what happens immediately before a tag, and it is a single command so that
# nobody has to remember the list.
#
# It does NOT run the MSVC half -- that needs a Windows shell and is
# tools/local-gates-msvc.ps1. A rehearsal that silently skipped a compiler
# would be worse than one that says it did.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
FAILED=""
PASSED=0

run() {
    label=$1
    shift
    printf '%-42s ' "$label"
    if "$@" > "${TMPDIR:-/tmp}/rehearsal-$$.log" 2>&1; then
        echo "PASS"
        PASSED=$((PASSED + 1))
    else
        echo "FAIL"
        FAILED="$FAILED $label"
        tail -15 "${TMPDIR:-/tmp}/rehearsal-$$.log" | sed 's/^/      /'
    fi
}

#
# TOOLCHAIN PREFLIGHT
#
# This is not the silent skip the header above rules out -- it is the other
# half of the same rule. A gate that fails because THIS MACHINE lacks a
# compiler must not look identical to a gate that fails because the TREE is
# wrong.
#
# Run under a Windows git shell, this script reported
#
#     FAILED: local gates (GCC/Clang/sanitizers/cross) ...
#
# with the tree in perfect order, because that shell has no cc. Anyone reading
# that summary would go looking for a defect that was never there -- and a
# later run that fixed nothing would look like a repair. So the rehearsal
# refuses to start rather than return a verdict about a tree it did not test.
MISSING=""
for tool in cc gcc clang cmake ctest python3 git; do
    command -v "$tool" > /dev/null 2>&1 || MISSING="$MISSING $tool"
done
if [ -n "$MISSING" ]; then
    echo "=== MCL release rehearsal ==="
    echo
    echo "REFUSING TO RUN. This shell is missing:$MISSING"
    echo
    echo "The rehearsal exercises POSIX compilers, and without them it would"
    echo "report FAIL for every gate that needs one -- which says nothing"
    echo "about the tree. Run it under the POSIX toolchain:"
    echo
    echo "  wsl.exe -d Ubuntu-24.04 -- bash -lc 'cd \$MCL && sh mcl-core/tools/release-rehearsal.sh'"
    echo
    echo "where \$MCL is this tree under /mnt/c. The MSVC half is separate and"
    echo "is tools/local-gates-msvc.ps1, run from PowerShell."
    exit 2
fi

echo "=== MCL release rehearsal ==="
echo "root: $ROOT"
echo

echo "-- the eight repositories are at their release commits"
for repo in mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb; do
    printf '   %-9s %s\n' "$repo" \
        "$(git -C "$ROOT/$repo" rev-parse --short HEAD)"
done
echo

run "local gates (GCC/Clang/sanitizers/cross)" \
    sh "$ROOT/mcl-core/tools/local-gates.sh"
# Runs BEFORE everything that builds. A stale binary fabricates both false
# passes and false failures, so a rehearsal whose harnesses can run one is
# reporting about code that may never have been compiled. It cost three
# byte-identical runs and two wrong conclusions to learn that once.
run "test harnesses cannot run a stale binary" \
    sh "$ROOT/mcl-core/tools/check-test-harnesses.sh"
run "C4 cross-implementation" \
    python3 "$ROOT/mcl-core/conformance/independent/test_independent.py"
run "C5 profile interoperability" \
    python3 "$ROOT/mcl-core/conformance/independent/test_profiles_c5.py"
run "installable package + external consumer" \
    sh "$ROOT/mcl-sdk/packaging/install-and-verify.sh"
run "public API surface" \
    sh "$ROOT/mcl-core/tools/api-baseline.sh"
run "registry governance" \
    sh "$ROOT/mcl-core/tools/check-registry-governance.sh"
run "specification index" \
    sh "$ROOT/mcl-core/tools/build-spec-index.sh" --check
run "specification maturity" \
    sh "$ROOT/mcl-core/tools/check-maturity.sh"
run "AP-BOOTSTRAP-1 vectors, both receivers" \
    sh "$ROOT/mcl-ap/conformance/check-vectors.sh"
run "feature traceability" \
    sh "$ROOT/mcl-core/tools/check-traceability.sh"
run "deployment profiles" \
    sh "$ROOT/mcl-core/tools/check-deployment-profiles.sh"
run "reference deployment: document vs SDK" \
    sh "$ROOT/mcl-core/tools/check-reference-deployment.sh"
run "clean-checkout adoption path" \
    sh "$ROOT/mcl-core/tools/check-adoption-path.sh"
run "provenance and licensing" \
    sh "$ROOT/mcl-core/tools/check-provenance.sh"
run "go/no-go audit" \
    sh "$ROOT/mcl-core/tools/go-no-go-audit.sh"
run "publication readiness" \
    sh "$ROOT/mcl-core/tools/check-publication-readiness.sh"
run "release bundle reconstruction" \
    sh "$ROOT/mcl-core/tools/build-release-bundle.sh" --verify v1.0.0

rm -f "${TMPDIR:-/tmp}/rehearsal-$$.log"

echo
echo "=== SUMMARY ==="
echo "$PASSED passed"
if [ -n "$FAILED" ]; then
    echo "FAILED:$FAILED"
    echo
    echo "REHEARSAL FAILED"
    exit 1
fi
echo
echo "REHEARSAL PASSED"
echo
echo "WHAT THIS DOES NOT COVER:"
echo "  - MSVC. Run mcl-core/tools/local-gates-msvc.ps1 on the Windows side."
echo "    A claim of 'all compilers' needs both halves."
echo "  - Hardware. No experiment runs here. The E3/E4 evidence stands on the"
echo "    rigs its READMEs name and is not re-measured by a software pass."
echo "  - Independent review. EVERY CHECK HERE WAS WRITTEN BY THIS PROJECT,"
echo "    including the one that checks the others. Passing them all says"
echo "    the tree is self-consistent, not that it is right."
echo "    v1.0.0 does not claim that two organisations have interoperated,"
echo "    that anyone outside this project has implemented these"
echo "    specifications, or that anyone outside has reviewed them."
echo "    V1_SCOPE.md section 5.9. The first outside report goes to"
echo "    mcl-core/REPORTING.md and is a v1.1 event."

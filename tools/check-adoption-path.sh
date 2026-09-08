#!/bin/sh
#
# THE CLEAN-CHECKOUT ADOPTION TEST.
#
# Every other gate in this project asks whether the code is correct. This one
# asks a different question, and it is the one that decides whether MCL is
# adoptable rather than merely finished:
#
#   Can a technically competent stranger, with only what we PUBLISH, follow the
#   Quickstart from a clone to two machines in contact -- without a build tree
#   we forgot to delete, an untracked file, an environment variable we set
#   months ago, or a piece of project knowledge that lives in somebody's head?
#
# HOW IT AVOIDS BELIEVING ITSELF
#
# The eight repositories are exported with `git archive HEAD`, into an empty
# directory, in a temporary location. That means:
#
#   - only COMMITTED content is present. An uncommitted file that the working
#     tree has been quietly depending on is absent here, which is the whole
#     point;
#   - no build tree, no CMake cache, no installed prefix comes along;
#   - the paths are new, so anything with an absolute path baked in fails.
#
# Then it runs the commands the Quickstart actually prints, in order, and
# checks the example reaches CONTACT ESTABLISHED. A Quickstart whose commands
# are not the commands that work is a Quickstart that has already failed.
#
# WHAT IT DOES NOT ESTABLISH
#
# That the documentation is good, that the API is pleasant, or that a stranger
# would understand any of it. Only that the published artifacts are sufficient
# and self-contained. The rest is a judgement no script makes.
#
# Exit 0 when the path works end to end, 1 otherwise.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
WORK=$(mktemp -d)
trap 'status=$?; rm -rf "$WORK"; exit $status' EXIT

REPOS="mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb"
FAILURES=0

echo "=== clean-checkout adoption path ==="
echo
echo "  export dir: $WORK/tree"
echo

fail() {
    echo "  FAIL $1"
    FAILURES=$((FAILURES + 1))
}

# ------------------------------------------------------- 1. export, committed only
mkdir -p "$WORK/tree"
for repo in $REPOS; do
    if [ ! -d "$ROOT/$repo/.git" ]; then
        fail "$repo is not a git repository, so 'what is published' cannot be determined"
        continue
    fi
    mkdir -p "$WORK/tree/$repo"
    if ! (cd "$ROOT/$repo" && git archive HEAD) | tar -x -C "$WORK/tree/$repo" 2>/dev/null; then
        fail "$repo would not export from HEAD"
        continue
    fi
    printf '  exported %-10s %s\n' "$repo" "$(cd "$ROOT/$repo" && git rev-parse --short HEAD)"
done
[ "$FAILURES" -eq 0 ] || { echo; echo "ADOPTION PATH FAILED at export"; exit 1; }

# A newcomer has no uncommitted anything. Prove the export is clean rather than
# assuming it: a stray build directory here would invalidate every later step.
if find "$WORK/tree" -name 'CMakeCache.txt' -o -name '*.o' -o -name 'build' -type d 2>/dev/null | grep -q .; then
    fail "the export contains build output, so the published tree is not clean"
fi

echo

# ------------------------------------------------------ 2. QUICKSTART section 03
echo "  QUICKSTART 03: build"
if cmake -S "$WORK/tree/mcl-sdk" -B "$WORK/build" \
        -DCMAKE_BUILD_TYPE=Release > "$WORK/cmake.log" 2>&1 &&
   cmake --build "$WORK/build" --config Release -j 4 \
        >> "$WORK/cmake.log" 2>&1; then
    echo "    build ok"
else
    fail "the documented build command does not work on a clean export"
    tail -25 "$WORK/cmake.log" | sed 's/^/      /'
    echo
    echo "ADOPTION PATH FAILED"
    exit 1
fi

if ctest --test-dir "$WORK/build" -C Release --output-on-failure \
        > "$WORK/ctest.log" 2>&1; then
    echo "    $(grep -c 'Passed' "$WORK/ctest.log") test(s) passed"
else
    fail "the documented test command fails on a clean export"
    grep -E 'Failed|\*\*\*' "$WORK/ctest.log" | head -10 | sed 's/^/      /'
fi

echo "  QUICKSTART 03: one self-contained developer package"
if sh "$WORK/tree/mcl-sdk/packaging/verify-developer-sdk.sh" \
        > "$WORK/developer-sdk.log" 2>&1; then
    echo "    package built; scratch high-level consumer passed"
else
    fail "the single-package developer SDK does not work from committed files"
    tail -25 "$WORK/developer-sdk.log" | sed 's/^/      /'
fi

# ------------------------------------------------------ 3. QUICKSTART section 04
echo "  QUICKSTART 04: run two machines"
EXAMPLE=
for candidate in \
    "$WORK/build/mcl_sdk_first_contact" \
    "$WORK/build/mcl_sdk_first_contact.exe" \
    "$WORK/build/Release/mcl_sdk_first_contact.exe"
do
    if [ -f "$candidate" ]; then EXAMPLE=$candidate; break; fi
done
if [ -z "$EXAMPLE" ]; then
    fail "the example the Quickstart tells a newcomer to run was not built"
else
    if "$EXAMPLE" > "$WORK/example.log" 2>&1; then
        if grep -q 'CONTACT ESTABLISHED' "$WORK/example.log"; then
            echo "    reached CONTACT ESTABLISHED"
        else
            fail "the example exited 0 without establishing a contact"
        fi
        # The claim boundary must survive into the thing a newcomer actually
        # runs. A demonstration that prints a success and not its limits is
        # how "MCL established a contact" becomes "MCL authenticated a peer"
        # in somebody's slide deck.
        if grep -q 'NOT established: identity, authenticity, authority or trust' \
                "$WORK/example.log"; then
            echo "    and states what it did not establish"
        else
            fail "the example does not state its claim boundary"
        fi
    else
        fail "the example the Quickstart names does not run"
        tail -15 "$WORK/example.log" | sed 's/^/      /'
    fi
fi

# ------------------------------------------------------ 4. QUICKSTART section 07
echo "  QUICKSTART 07: conformance an adopter can run"
PYTHON=
if command -v python3 > /dev/null 2>&1; then
    PYTHON=python3
elif command -v python > /dev/null 2>&1; then
    PYTHON=python
fi
if [ -n "$PYTHON" ] &&
   "$PYTHON" "$WORK/tree/mcl-core/conformance/independent/test_independent.py" \
        > "$WORK/c4.log" 2>&1; then
    echo "    C4 independent implementation ok"
else
    fail "C4 does not run from a clean export"
    if [ -f "$WORK/c4.log" ]; then
        tail -10 "$WORK/c4.log" | sed 's/^/      /'
    else
        echo "      neither python3 nor python is available"
    fi
fi

if sh "$WORK/tree/mcl-core/tools/check-reference-deployment.sh" \
        > "$WORK/dep.log" 2>&1; then
    echo "    reference deployment agrees with the SDK"
else
    fail "the reference deployment check does not run from a clean export"
    grep FAIL "$WORK/dep.log" | head -5 | sed 's/^/      /'
fi

# ---------------------------------------------- 5. no local paths in what ships
#
# An absolute path in a published artifact is a build that works here and
# nowhere else. check-publication-readiness.sh covers the repositories; this
# covers the same rule from the newcomer's side, on the export.
echo "  no developer-local paths in the exported tree"
if grep -rIl -E '/home/[a-z]|/Users/[A-Za-z]|C:\\\\Users\\\\' "$WORK/tree" \
        --include='*.md' --include='*.c' --include='*.h' --include='*.sh' \
        --include='*.json' --include='*.txt' 2>/dev/null | head -5 | grep -q .; then
    fail "the exported tree names a developer's own directories"
    grep -rIl -E '/home/[a-z]|/Users/[A-Za-z]|C:\\\\Users\\\\' "$WORK/tree" \
        --include='*.md' --include='*.c' --include='*.h' --include='*.sh' \
        --include='*.json' --include='*.txt' 2>/dev/null | head -5 |
        sed "s|$WORK/tree/|      |"
else
    echo "    none"
fi

echo
if [ "$FAILURES" -ne 0 ]; then
    echo "ADOPTION PATH FAILED"
    echo
    echo "Treat this as a v1 defect. The remedy is the SDK facade, the adapters,"
    echo "the documentation or the packaging -- not new protocol surface, unless"
    echo "the failure proves the existing protocol contract insufficient."
    exit 1
fi

echo "ADOPTION PATH PASSED"
echo
echo "What this does NOT establish: that a stranger would understand the"
echo "documentation, that the API is pleasant, or that anyone outside this"
echo "project has ever tried. Only that what is published is sufficient and"
echo "self-contained."

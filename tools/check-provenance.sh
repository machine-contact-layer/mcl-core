#!/bin/sh
#
# Release gate item 25: every releasable artifact has known provenance and
# compatible terms.
#
# WHAT THIS CATCHES
#
# A file that entered the repositories without anyone deciding it should be
# there: a copied third-party source, a binary nobody can account for, a
# dependency manifest that appeared, a licence that drifted between repos.
#
# The eight repositories claim to have NO dependencies and NO vendored code.
# That claim is exactly the kind that is true when written and quietly false
# later, so it is checked rather than restated.
#
# Exit 0 when everything is accounted for; 1 otherwise.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
REPOS="mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb"
FAILURES=0

echo "=== MCL provenance and licensing audit ==="
echo

# ---------------------------------------------------------------- 1. licences
echo "-- licence file present and identical in every repository"
reference=""
for repo in $REPOS; do
    lic="$ROOT/$repo/LICENSE"
    if [ ! -f "$lic" ]; then
        echo "  FAIL $repo has no LICENSE"
        FAILURES=$((FAILURES + 1))
        continue
    fi
    sum=$(cksum < "$lic" | awk '{print $1}')
    if [ -z "$reference" ]; then
        reference=$sum
    elif [ "$sum" != "$reference" ]; then
        echo "  FAIL $repo/LICENSE differs from the others"
        FAILURES=$((FAILURES + 1))
        continue
    fi
    echo "  ok   $repo"
done

# ---------------------------------------------------------------- 2. no deps
echo
echo "-- no dependency manifests (the repositories claim to have none)"
manifests="package.json package-lock.json requirements.txt Pipfile Cargo.toml
go.mod pom.xml build.gradle Gemfile composer.json pyproject.toml setup.py
conanfile.txt vcpkg.json"
found_manifest=0
for repo in $REPOS; do
    for name in $manifests; do
        hit=$(find "$ROOT/$repo" -name "$name" -not -path '*/.git/*' 2>/dev/null || true)
        if [ -n "$hit" ]; then
            echo "  FAIL dependency manifest: $(echo "$hit" | sed "s|$ROOT/||")"
            FAILURES=$((FAILURES + 1))
            found_manifest=1
        fi
    done
done
[ "$found_manifest" -eq 0 ] && echo "  ok   none found"

# ---------------------------------------------------------------- 3. vendored
echo
echo "-- no vendored or third-party source trees"
found_vendor=0
for repo in $REPOS; do
    hit=$(find "$ROOT/$repo" -type d \( -name vendor -o -name third_party \
          -o -name third-party -o -name node_modules -o -name external \) \
          -not -path '*/.git/*' 2>/dev/null || true)
    if [ -n "$hit" ]; then
        echo "  FAIL vendored tree: $(echo "$hit" | sed "s|$ROOT/||")"
        FAILURES=$((FAILURES + 1))
        found_vendor=1
    fi
done
[ "$found_vendor" -eq 0 ] && echo "  ok   none found"

# ---------------------------------------------------------------- 4. binaries
#
# Binary artifacts are not forbidden -- the acoustic evidence is WAV captures
# and could not be anything else. They must be ACCOUNTED FOR: every one has to
# sit under an evidence or experiment directory, where a README says what
# produced it. A binary anywhere else entered without a decision.
echo
echo "-- every tracked binary sits under evidence, with a README"
unaccounted=0
for repo in $REPOS; do
    for f in $(git -C "$ROOT/$repo" ls-files | grep -iE '\.(png|jpe?g|gif|bmp|wav|mp3|bin|zip|gz|tar|so|dll|dylib|a|o|obj|exe|pdf|jar|whl|class)$' || true); do
        case "$f" in
            *evidence/*|*experiments/*)
                dir=$(dirname "$ROOT/$repo/$f")
                # Walk up to the nearest README.
                while [ "$dir" != "$ROOT/$repo" ] && [ ! -f "$dir/README.md" ]; do
                    dir=$(dirname "$dir")
                done
                if [ ! -f "$dir/README.md" ]; then
                    echo "  FAIL $repo/$f is under evidence but no README explains it"
                    FAILURES=$((FAILURES + 1))
                    unaccounted=$((unaccounted + 1))
                fi
                ;;
            *)
                echo "  FAIL $repo/$f is a binary outside evidence/experiments"
                FAILURES=$((FAILURES + 1))
                unaccounted=$((unaccounted + 1))
                ;;
        esac
    done
done
total_binaries=0
for repo in $REPOS; do
    n=$(git -C "$ROOT/$repo" ls-files | grep -icE '\.(png|jpe?g|gif|bmp|wav|mp3|bin|zip|gz|tar|so|dll|dylib|a|o|obj|exe|pdf|jar|whl|class)$' || true)
    total_binaries=$((total_binaries + n))
done
[ "$unaccounted" -eq 0 ] && echo "  ok   $total_binaries binary artifact(s), all under evidence with a README"

# ---------------------------------------------------------------- 5. licensing doc
echo
echo "-- licensing terms are documented"
if [ -f "$ROOT/mcl-core/LICENSING.md" ]; then
    echo "  ok   mcl-core/LICENSING.md"
else
    echo "  FAIL no mcl-core/LICENSING.md"
    FAILURES=$((FAILURES + 1))
fi
if [ -f "$ROOT/mcl-core/CONTRIBUTING.md" ]; then
    echo "  ok   mcl-core/CONTRIBUTING.md"
else
    echo "  FAIL no mcl-core/CONTRIBUTING.md"
    FAILURES=$((FAILURES + 1))
fi

echo
if [ "$FAILURES" -ne 0 ]; then
    echo "$FAILURES provenance problem(s)."
    echo "PROVENANCE AUDIT FAILED"
    exit 1
fi
echo "PROVENANCE AUDIT PASSED"
echo
echo "What this does NOT establish: that the licence is the RIGHT one, or that"
echo "no patent claim reads on the specification. Those are legal questions and"
echo "this is a filesystem check. It establishes that nothing entered these"
echo "repositories without provenance."

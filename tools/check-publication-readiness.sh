#!/bin/sh
#
# Release gate item 27: everything that can be true before the repositories are
# made public.
#
# The act itself is not in this tree -- nothing here can change a repository's
# visibility. What this checks is that when someone does, they are publishing
# what they think they are.
#
# THE DISTINCTION THIS SCRIPT KEEPS
#
# A tracked SCRIPT containing an absolute user path is a defect: it will not
# run on anyone else's machine, and publishing it publishes a username for no
# benefit. That is FATAL.
#
# An EVIDENCE file containing one is not a defect. Evidence records what a
# machine printed on a date and is never edited -- rewriting it to look tidier
# is the one thing this project's rules forbid outright. Those are listed as a
# DECISION for the owner, who may publish them, redact the whole record, or
# withhold that directory. What must not happen is editing them quietly.
#
#   ./check-publication-readiness.sh

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
REPOS="mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb"
FATAL=0
DECISIONS=0

echo "=== MCL publication readiness ==="
echo

# ------------------------------------------------------- 1. front-door files
echo "-- every repository has the files a reader lands on"
for repo in $REPOS; do
    missing=""
    for f in README.md LICENSE NOTICE; do
        [ -f "$ROOT/$repo/$f" ] || missing="$missing $f"
    done
    if [ -n "$missing" ]; then
        echo "  FAIL $repo is missing:$missing"
        FATAL=$((FATAL + 1))
    else
        echo "  ok   $repo"
    fi
done

echo
echo "-- mcl-core carries the shared process documents"
for f in SECURITY.md LICENSING.md CONTRIBUTING.md CODE_OF_CONDUCT.md \
         REPORTING.md SPECIFICATION_INDEX.md errata/README.md; do
    if [ -f "$ROOT/mcl-core/$f" ]; then
        echo "  ok   mcl-core/$f"
    else
        echo "  FAIL mcl-core/$f is missing"
        FATAL=$((FATAL + 1))
    fi
done

# ------------------------------------------------- 2. absolute paths, scripts
echo
echo "-- no absolute user paths in tracked scripts (FATAL)"
hits=""
for repo in $REPOS; do
    hit=$(git -C "$ROOT/$repo" grep -lIE '[A-Za-z]:\\Users\\[A-Za-z0-9_.-]+|/home/[A-Za-z0-9_.-]+|/mnt/[a-z]/Users/[A-Za-z0-9_.-]+/' -- \
        '*.sh' '*.ps1' '*.py' '*.c' '*.h' '*.cmd' '*.bat' 'CMakeLists.txt' \
        ':!*/evidence/*' ':!*evidence/*' 2>/dev/null | sed "s|^|$repo/|" || true)
    [ -n "$hit" ] && hits="$hits$hit
"
done
hits=$(printf '%s' "$hits" | sed '/^$/d')
if [ -n "$hits" ]; then
    echo "$hits" | sed 's/^/  FATAL /'
    n=$(echo "$hits" | wc -l | tr -d ' ')
    FATAL=$((FATAL + n))
else
    echo "  ok   none"
fi

# ---------------------------------------------- 3. absolute paths, evidence
echo
echo "-- absolute user paths inside EVIDENCE (a decision, never an edit)"
ev=""
for repo in $REPOS; do
    hit=$(git -C "$ROOT/$repo" grep -lIE '[A-Za-z]:\\Users\\[A-Za-z0-9_.-]+|/home/[A-Za-z0-9_.-]+|/mnt/[a-z]/Users/[A-Za-z0-9_.-]+/' -- \
        '*evidence/*' 'conformance/independent/*' 2>/dev/null | sed "s|^|$repo/|" || true)
    [ -n "$hit" ] && ev="$ev$hit
"
done
ev=$(printf '%s' "$ev" | sed '/^$/d')
if [ -n "$ev" ]; then
    n=$(echo "$ev" | wc -l | tr -d ' ')
    DECISIONS=$((DECISIONS + n))
    echo "  $n evidence file(s) name a local path. Publishing them discloses a"
    echo "  username. Editing them is NOT an option -- decide per directory:"
    echo "$ev" | head -20 | sed 's/^/       /'
    [ "$n" -gt 20 ] && echo "       ... and $((n - 20)) more"
else
    echo "  ok   none"
fi

# ------------------------------------------------------------- 4. secrets
echo
echo "-- device and local-topology identifiers inside retained records (a decision)"
ids=""
for repo in $REPOS; do
    hit=$(git -C "$ROOT/$repo" grep -lIE \
        '(Android device:|device serial|serial number|(^|[^A-Za-z])MAC([ :=]| address)|BSSID|192\.168\.[0-9]+\.[0-9]+)' \
        -- '*evidence/*' '*/runs/*' 'conformance/independent/*' 2>/dev/null | sed "s|^|$repo/|" || true)
    [ -n "$hit" ] && ids="$ids$hit
"
done
ids=$(printf '%s' "$ids" | sed '/^$/d' | LC_ALL=C sort -u)
if [ -n "$ids" ]; then
    n=$(echo "$ids" | wc -l | tr -d ' ')
    DECISIONS=$((DECISIONS + n))
    echo "  $n retained record(s) name a physical device or private test topology."
    echo "  Preserve the record; decide whether each directory is publishable as-is:"
    echo "$ids" | head -20 | sed 's/^/       /'
    [ "$n" -gt 20 ] && echo "       ... and $((n - 20)) more"
else
    echo "  ok   none"
fi

# ------------------------------------------------------------- 5. secrets
echo
echo "-- no credential-shaped strings (FATAL)"
sec=""
for repo in $REPOS; do
    hit=$(git -C "$ROOT/$repo" grep -nIE \
        '(BEGIN [A-Z ]*PRIVATE KEY|ghp_[A-Za-z0-9]{20,}|AKIA[0-9A-Z]{16}|xox[baprs]-)' \
        -- . ':!*check-publication-readiness.sh' 2>/dev/null | sed "s|^|$repo/|" || true)
    [ -n "$hit" ] && sec="$sec$hit
"
done
sec=$(printf '%s' "$sec" | sed '/^$/d')
if [ -n "$sec" ]; then
    echo "$sec" | sed 's/^/  FATAL /'
    FATAL=$((FATAL + 1))
else
    echo "  ok   none"
fi

# ----------------------------------------------- 6. the claim boundary is said
#
# The claim boundary lives in the normative and release authorities. README.md
# is the adoption surface and is deliberately not required to carry it.
echo
echo "-- the normative release authorities preserve the claim boundary"
for f in "mcl-core/conformance/ICS.md" \
         "mcl-core/governance/V1_SCOPE.md" \
         "mcl-core/releases/v1.0.0/manifest.txt"; do
    if grep -q "NOT claim" "$ROOT/$f" 2>/dev/null; then
        echo "  ok   $f"
    else
        echo "  FAIL $f does not state the claim boundary"
        FATAL=$((FATAL + 1))
    fi
done

# ------------------------------------------------------------- 7. CI policy
#
# This section used to fail the release if ANY workflow existed. That rule was
# correct while the project was private and every gate was run by hand, and it
# became wrong the moment the repositories were prepared for public
# contribution: from a contributor nobody knows, "the gates passed locally" is
# an assertion the project cannot check.
#
# What is enforced now is the policy in CONTRIBUTING.md, mechanically:
#
#   - only GitHub Actions. A second CI system means two definitions of "green".
#   - every workflow declares an explicit `permissions:` block. Without one the
#     job inherits whatever the repository default happens to be, which is a
#     token that can write to the repository.
#   - no `pull_request_target`. It runs fork-authored code with repository
#     credentials, which is the one trigger that turns a public PR into a
#     supply-chain hole.
#   - no `secrets` in anything triggered by `pull_request`. A public PR must
#     not be able to read them even indirectly.
echo
echo "-- CI policy (hosted CI is required; only reviewed project workflows)"
ci=0
for repo in $REPOS; do
    for d in .gitlab-ci.yml .circleci azure-pipelines.yml; do
        if [ -e "$ROOT/$repo/$d" ]; then
            echo "  FAIL $repo/$d exists; GitHub Actions is the only CI system"
            FATAL=$((FATAL + 1))
            ci=1
        fi
    done

    wf_dir="$ROOT/$repo/.github/workflows"
    [ -d "$wf_dir" ] || continue

    for wf in "$wf_dir"/*.yml "$wf_dir"/*.yaml; do
        [ -e "$wf" ] || continue
        rel="$repo/.github/workflows/$(basename "$wf")"

        if ! grep -q '^[[:space:]]*permissions:' "$wf"; then
            echo "  FAIL $rel declares no permissions: block"
            FATAL=$((FATAL + 1)); ci=1
        fi
        if grep -q '^[[:space:]]*pull_request_target:' "$wf"; then
            echo "  FAIL $rel uses pull_request_target, which runs fork code with repository credentials"
            FATAL=$((FATAL + 1)); ci=1
        fi
        if grep -q '^[[:space:]]*pull_request:' "$wf" && grep -q 'secrets\.' "$wf"; then
            echo "  FAIL $rel exposes secrets to a pull_request trigger"
            FATAL=$((FATAL + 1)); ci=1
        fi
    done
done
[ "$ci" -eq 0 ] && echo "  ok   policy satisfied"

# ---------------------------------------------------------------- summary
echo
echo "=== SUMMARY ==="
echo "fatal:      $FATAL"
echo "decisions:  $DECISIONS"
echo
if [ "$FATAL" -ne 0 ]; then
    echo "NOT READY TO PUBLISH. $FATAL fatal finding(s)."
    exit 1
fi
echo "READY, as far as a script can tell."
echo
echo "What remains is not in this tree and cannot be:"
echo "  - making the repositories readable by other people"
echo "  - deciding the $DECISIONS evidence file(s) above, if any"
echo
echo "See mcl-core/governance/PUBLISHING.md for the order those happen in."

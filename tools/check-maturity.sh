#!/bin/sh
# Release gate: a Stable claim may not rest on a document that is not Stable.
#
# THE DEFECT THIS CATCHES
#
# V1_SCOPE.md declares a surface Stable. The specification index reports what
# each document says about itself. Until this gate existed nothing compared the
# two, and they disagreed IN BOTH DIRECTIONS:
#
#   - Wire major 1 and Link major 1 were called Stable in the scope table while
#     the documents specifying them said "Research Draft. Not normative. Not a
#     basis for an implementation."
#   - Two transport profiles were labelled Stable in their own documents having
#     been promoted without the public review ARCHITECTURE_CHARTER.md section 6
#     requires.
#
# A reader who believes the scope table and a reader who believes the document
# reach opposite conclusions about whether they may implement against it, and
# both are reading the same release.
#
# WHAT IT DOES NOT DO
#
# It does not decide which document is normative for a claim -- that is an
# editorial judgement and lives in governance/STABLE_BACKING.tsv, written by
# hand. A gate that inferred the mapping from filenames would guess, and then
# certify its own guess.
#
# It also does not check that a Stable document DESERVES to be Stable. The
# promotion rule is V1_SCOPE.md section 6, it requires independent
# interoperability evidence for the exact bytes being frozen, and no script can
# read evidence. This gate checks consistency, which is the part a script can
# actually own.

set -eu

ROOT=$(CDPATH='' cd -- "$(dirname -- "$0")/../.." && pwd)
MAP="$ROOT/mcl-core/governance/STABLE_BACKING.tsv"

failures=0
checked=0

fail() {
    failures=$((failures + 1))
    echo "FAIL: $1"
}

if [ ! -f "$MAP" ]; then
    echo "FAIL: $MAP is missing. The mapping is the gate."
    exit 1
fi

# Same extraction the index generator uses, so the two cannot disagree about
# what a document's status line says.
extract_status() {
    grep -m1 -iE '^\**status:?\**' "$1" 2>/dev/null \
        | sed -e 's/^\**[Ss]tatus:\?\**//' -e 's/^[[:space:]]*//' \
              -e 's/[[:space:]]*$//' \
        || true
}

echo "=== Stable claims and the documents behind them ==="

# A tab-separated read. IFS is set for this loop only.
while IFS='	' read -r claim path; do
    case "$claim" in ''|\#*) continue ;; esac
    [ -z "${path:-}" ] && continue

    checked=$((checked + 1))
    full="$ROOT/$path"

    if [ ! -f "$full" ]; then
        fail "$claim -> $path does not exist"
        continue
    fi

    status=$(extract_status "$full")
    if [ -z "$status" ]; then
        fail "$claim -> $path has no status line at all"
        continue
    fi

    # Stable must be asserted, not merely mentioned. "Research Draft" contains
    # neither word; "Stable for the three objects in section 3.2" does assert
    # it and is accepted, because a scoped Stable claim is still a Stable claim
    # and the scope is the document's to state.
    case "$status" in
        *Stable*|*STABLE*|*stable*)
            printf '  ok    %-52s %s\n' "$claim" "$status"
            ;;
        *)
            fail "$claim is Stable in V1_SCOPE but $path says: $status"
            ;;
    esac
done < "$MAP"

# The reverse direction. A document that calls itself Stable must appear in the
# mapping, or the release contains a Stable surface that no scope entry claims
# and no gate covers.
echo
echo "=== Stable documents, and whether a claim accounts for them ==="
for spec in "$ROOT"/mcl-*/spec/*.md; do
    [ -f "$spec" ] || continue
    status=$(extract_status "$spec")
    case "$status" in
        *Stable*|*STABLE*|*stable*) ;;
        *) continue ;;
    esac
    rel=${spec#"$ROOT"/}
    if grep -q "	$rel\$" "$MAP"; then
        printf '  ok    %s\n' "$rel"
    else
        fail "$rel calls itself Stable but no claim in STABLE_BACKING.tsv names it"
    fi
done

echo
echo "claims checked: $checked"
if [ "$failures" -ne 0 ]; then
    echo "MATURITY CHECK FAILED: $failures inconsistency(ies)."
    echo
    echo "Each one is a place where the scope table and a specification tell a"
    echo "reader different things. Repair the document or repair the claim --"
    echo "not this gate."
    exit 1
fi
echo "MATURITY CHECK PASSED"

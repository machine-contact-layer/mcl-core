#!/bin/sh
#
# Release gate item 33: the final sweep.
#
# Searches every repository for the marks of unfinished work and for claims
# that have gone stale. Every hit is either fixed or deliberately acceptable
# and documented -- and this script's job is to make sure nobody is deciding
# that by not looking.
#
# It is INFORMATIONAL for categories where a hit can be legitimate, and FATAL
# where it cannot. The distinction matters: a script that failed on every
# occurrence of the word "draft" would be run once, found annoying, and
# disabled.
#
#   ./go-no-go-audit.sh          report
#   ./go-no-go-audit.sh --strict fail on informational findings too
#
# Run before a release candidate and again immediately before the tag.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
REPOS="mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb"
FATAL=0
INFO=0
STRICT=0
[ "$1" = "--strict" ] && STRICT=1

# Search tracked files only. An untracked scratch file is not part of a release.
#
# This script excludes ITSELF. Its first full run reported two fatal findings
# that were its own search patterns -- the marker strings appear in this file
# because this is the file that looks for them. A scanner that fails on its own
# patterns is noise, and noise is what gets a check disabled.
#
# Evidence directories are excluded for a different reason: they record what was
# measured on a date and are never edited, so a marker inside one is history
# rather than unfinished work.
tracked_grep() {
    pattern=$1
    for repo in $REPOS; do
        git -C "$ROOT/$repo" grep -nIE "$pattern" -- \
            ':!*/evidence/*' ':!*evidence/*' \
            ':!conformance/independent/20260910-private-rc/*-rehearsal.log' \
            ':!conformance/independent/20260910-private-rc/msvc-gates.log' \
            ':!conformance/independent/20260910-private-rc/go-no-go.log' \
            ':!conformance/independent/20260910-private-rc/reconstruction.log' \
            ':!*go-no-go-audit.sh' 2>/dev/null \
            | sed "s|^|$repo/|" || true
    done
}

section() {
    echo
    echo "-- $1"
}

report_fatal() {
    hits=$1
    what=$2
    if [ -n "$hits" ]; then
        echo "$hits" | sed 's/^/  FATAL /'
        n=$(echo "$hits" | wc -l | tr -d ' ')
        FATAL=$((FATAL + n))
    else
        echo "  ok   $what"
    fi
}

report_info() {
    hits=$1
    what=$2
    if [ -n "$hits" ]; then
        n=$(echo "$hits" | wc -l | tr -d ' ')
        echo "  $n occurrence(s) of $what -- review each:"
        echo "$hits" | head -20 | sed 's/^/       /'
        [ "$n" -gt 20 ] && echo "       ... and $((n - 20)) more"
        INFO=$((INFO + n))
    else
        echo "  ok   no $what"
    fi
}

echo "=== MCL go/no-go audit ==="
echo "Tracked files only. Evidence directories are excluded: they record what"
echo "was true on a date and are never edited."

# ------------------------------------------------------------------ FATAL
section "unfinished-work markers (FATAL: none may ship)"
report_fatal "$(tracked_grep '\b(TODO|FIXME|XXX|HACK|TBD)\b' || true)" "no TODO/FIXME/XXX/HACK/TBD"

section "placeholder text (FATAL)"
report_fatal "$(tracked_grep '(FILL ME|PLACEHOLDER|<placeholder>|lorem ipsum|CHANGEME|your-name-here)' || true)" "no placeholders"

section "GitHub Actions (FATAL: this project uses none, deliberately)"
gh=""
for repo in $REPOS; do
    [ -d "$ROOT/$repo/.github/workflows" ] && gh="$gh$repo/.github/workflows exists\n"
done
report_fatal "$(printf '%b' "$gh" | sed '/^$/d')" "no workflow directories"

section "hardcoded Tier-0 field counts (FATAL: stale four times already)"
report_fatal "$(tracked_grep '(Sixteen|Thirteen|[0-9]+) of the (21|twenty-one)' || true)" "no hardcoded field counts"

# ANY NUMBER THAT CAN BE DERIVED MUST NOT BE HAND-MAINTAINED IN RELEASE PROSE.
#
# Learned four times on Tier-0 field counts, then again on the specification
# index row count, and then twice more in one ledger on the same day: row 14
# said "143 symbols" while api-baseline-v1.txt held 155, and row 30 said "35
# artifacts" while artifacts.txt held 48. Every one of those numbers is one
# command away from the file that owns it.
#
# The rule this enforces is narrow on purpose: prose may CITE the file, and may
# not restate its count. Numbers inside generated files, and inside evidence
# recording what a run actually produced, are untouched -- those are results,
# not summaries.
section "hand-copied derived counts in release prose (FATAL)"
# GOVERNANCE PROSE ONLY, and never generated bundles or evidence.
#
# The scope is narrow because the words are not reserved. "16 symbols" in
# AP-BOOTSTRAP-1 is the FSK training sequence -- a physical quantity that
# document owns and must state. What this forbids is a RELEASE LEDGER restating
# a number another file already computes, which is where it went stale twice in
# one day. A generated manifest describing its own contents is the source, not
# a copy of one.
prose_grep() {
    for repo in $REPOS; do
        git -C "$ROOT/$repo" grep -nIE "$1" -- 'governance/*.md' \
            ':!*/evidence/*' ':!*evidence/*' ':!*/releases/*' \
            ':!conformance/independent/20260910-private-rc/posix-rehearsal.log' \
            ':!conformance/independent/20260910-private-rc/msvc-gates.log' \
            ':!conformance/independent/20260910-private-rc/go-no-go.log' \
            ':!conformance/independent/20260910-private-rc/reconstruction.log' 2>/dev/null \
            | sed "s|^|$repo/|" || true
    done
}
report_fatal "$(prose_grep '[0-9]+ symbols' || true)" "no hand-copied API symbol counts"
report_fatal "$(prose_grep '[0-9]+ (artifacts|checksums)' || true)" "no hand-copied artifact counts"

# ------------------------------------------------------------------ INFO
section "status: draft, in tracked specifications"
report_info "$(tracked_grep '^\**[Ss]tatus:?\**.*(Research Draft|draft)' || true)" "draft status lines"

section "provisional registry entries"
report_info "$(tracked_grep '"status": *"provisional"' || true)" "provisional entries"

section "experimental profile values appearing in examples"
report_info "$(tracked_grep 'profile_id *= *19[0-9]' || true)" "experimental profile uses"

section "old API signatures that were replaced"
report_info "$(tracked_grep 'tx_fn\(user, data, size\)|tx\(user, bytes, size\)' || true)" "obsolete signatures"

# ------------------------------------------------------------------ checks
section "the other gate checks still pass"
for tool in check-registry-governance.sh check-traceability.sh \
            check-provenance.sh api-baseline.sh \
            check-publication-readiness.sh; do
    if sh "$ROOT/mcl-core/tools/$tool" > /dev/null 2>&1; then
        echo "  ok   $tool"
    else
        echo "  FATAL $tool fails"
        FATAL=$((FATAL + 1))
    fi
done
if sh "$ROOT/mcl-core/tools/build-spec-index.sh" --check > /dev/null 2>&1; then
    echo "  ok   build-spec-index.sh --check"
else
    echo "  FATAL specification index is out of date"
    FATAL=$((FATAL + 1))
fi

# ------------------------------------------------------------------ summary
echo
echo "=== SUMMARY ==="
echo "fatal findings:         $FATAL"
echo "informational findings: $INFO"
echo
echo "An informational finding is not automatically a problem. 'Research Draft'"
echo "on a document v1.0 does not make Stable is correct. A provisional registry"
echo "entry for a Candidate object is correct. Experimental profile 192 in a"
echo "test is correct -- that is the value C4/C5 run against. Each still has to"
echo "be LOOKED AT, which is why they are listed rather than counted."

if [ "$FATAL" -ne 0 ]; then
    echo
    echo "GO/NO-GO: NO. $FATAL fatal finding(s)."
    exit 1
fi
if [ "$STRICT" -eq 1 ] && [ "$INFO" -ne 0 ]; then
    echo
    echo "GO/NO-GO: NO under --strict. $INFO informational finding(s)."
    exit 1
fi

echo
echo "GO/NO-GO: no fatal findings."
echo
echo "This is NOT a release authorization. It says nothing about whether the"
echo "RELEASE_GATE_V1.md rows are DONE. A tree with no TODOs and a complete"
echo "specification index can still be missing independent review."

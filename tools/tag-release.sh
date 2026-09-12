#!/bin/sh
#
# Tag one synchronized MCL release across all eight repositories.
#
# DO NOT RUN THIS YET.
#
# `governance/PUBLISHING.md` and row 36 order it: public repositories ->
# logged-out verification -> public external review -> and only THEN the Stable
# v1.0.0 tag. Row 34 is `WAIT_DEP` on exactly that. This script exists so the
# mechanics are written, reviewed and argued about now rather than improvised
# on the day, which is how a tag ends up pointing at the wrong commit.
#
# WHY ALL EIGHT ARE TAGGED
#
# The manifest names one exact revision per component. A tag turns each of
# those into a permanent human-readable anchor instead of a SHA a reader has to
# copy out of a file. The revisions come FROM releases/<version>/commits.txt,
# never from whatever HEAD happens to be when this runs -- the release is a
# recorded set of eight commits, not "the tip of main today".
#
# WHY ONLY ONE GITHUB RELEASE
#
# This script creates TAGS only. The GitHub Release page belongs to mcl-core
# alone, because mcl-core owns the manifest, the artifact inventory, the
# developer SDK archive and the evidence index. Eight release pages would give
# a reader eight things called v1.0.0 and no way to tell which is authoritative,
# plus eight places for release notes to drift apart. Creating that page is a
# separate, deliberate act -- see --print-release-notes below.
#
# Usage:
#   sh tag-release.sh --dry-run v1.0.0        show what would be tagged
#   sh tag-release.sh --print-release-notes v1.0.0
#   sh tag-release.sh --confirm v1.0.0        actually create the tags
#   sh tag-release.sh --push v1.0.0           push tags already created
#
# --confirm is required. There is no default that writes.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
MODE=""
VERSION=""

for arg in "$@"; do
    case "$arg" in
        --dry-run|--confirm|--push|--print-release-notes) MODE="$arg" ;;
        v*) VERSION="$arg" ;;
        *) echo "unknown argument: $arg" >&2; exit 2 ;;
    esac
done

[ -n "$VERSION" ] || { echo "no version given, e.g. v1.0.0" >&2; exit 2; }
[ -n "$MODE" ] || { echo "one of --dry-run --confirm --push --print-release-notes is required" >&2; exit 2; }

COMMITS="$ROOT/mcl-core/releases/$VERSION/commits.txt"
[ -f "$COMMITS" ] || { echo "no commits.txt for $VERSION at $COMMITS" >&2; exit 1; }

# ---------------------------------------------------------------- gate check
#
# Refuse to tag while the ledger still says the prerequisites are open. The
# rows are EXTERNAL acts; this script cannot verify them, but it can refuse to
# proceed silently past a ledger that has not been updated to record them.
GATE="$ROOT/mcl-core/governance/RELEASE_GATE_V1.md"
if [ "$MODE" = "--confirm" ] || [ "$MODE" = "--push" ]; then
    for row in 27 36 37; do
        if grep -qE "^\| $row \|.*\`EXTERNAL\`" "$GATE"; then
            echo "REFUSING: release gate row $row is still EXTERNAL." >&2
            echo "" >&2
            echo "  27  public candidate operations (visibility, rulesets, receipt)" >&2
            echo "  36  charter-required public external review" >&2
            echo "  37  github governance receipt" >&2
            echo "" >&2
            echo "A Stable tag before external review is exactly what" >&2
            echo "governance/PUBLISHING.md forbids. Update the ledger when the" >&2
            echo "acts are genuinely done, not to get past this check." >&2
            exit 1
        fi
    done
fi

if [ "$MODE" = "--print-release-notes" ]; then
    core_commit=$(awk '$1 == "mcl-core" {print $2}' "$COMMITS")
    cat <<NOTES
# MCL $VERSION

One synchronized release across eight repositories. Every component is tagged
$VERSION; this page is the only release page, because mcl-core owns the
manifest, the artifact inventory and the evidence index.

## What this is

The **Stable** release, tagged after public Candidate review.

Charter section 6 requires public external review before any Stable
promotion. That review is what release gate row 36 records, and this tag
cannot be created while row 36 is open -- the script refuses. The review
reports and what was done about them are in \`errata/\`; an empty \`errata/\`
means reviewers reported nothing that required correction, not that nobody
read it.

The Candidate period itself has no tag and no release page. It was the
public repositories at their frozen candidate heads, which are the revisions
listed below.

## Component revisions

\`\`\`
$(cat "$COMMITS")
\`\`\`

mcl-core records the commit the bundle was BUILT FROM. It cannot record the
commit that contains it: writing the hash changes the hash.

## Attached artifacts

  mcl-developer-sdk.tar.gz   one CMake build, no sibling checkout required
  SHA256SUMS.txt             digests for every artifact in the inventory
  manifest.txt               what constitutes this release
  commits.txt                the eight revisions above
  artifacts.txt              the normative inventory
  EVIDENCE_INDEX.json        every empirical claim bound to a path and digest
  REPRODUCIBILITY.md         how to reconstruct and verify

## Start here

\`mcl-sdk/QUICKSTART.md\`, section 04. \`MCL Base 1\` on a bearer both machines
already share: Wire major 1 inside Link major 1, no rendezvous, no bearer to
open.

## What is NOT claimed

  - no independent organisation has IMPLEMENTED this; public review under
    charter section 6 has happened, interoperability with a second
    independent implementation has not
  - no cryptographic profile exists in any repository
  - AP bootstrap and BLE activation are Candidate, not Stable
  - no physical UWB qualification
  - Wire 1 + Link 1 *under migration* has not been run as one physical cell;
    the constituent layers are evidenced separately in EVIDENCE_INDEX.json

Read \`conformance/ICS.md\` for what is claimed and at what level.
NOTES
    exit 0
fi

# ------------------------------------------------------------------- tagging
echo "=== $MODE $VERSION ==="
echo

FAILURES=0

while read -r repo commit; do
    [ -n "$repo" ] || continue
    dir="$ROOT/$repo"
    [ -d "$dir/.git" ] || { echo "  FAIL $repo is not a git repository"; FAILURES=$((FAILURES+1)); continue; }

    if ! git -C "$dir" cat-file -e "$commit^{commit}" 2>/dev/null; then
        echo "  FAIL $repo does not contain $commit"
        FAILURES=$((FAILURES+1))
        continue
    fi

    existing=$(git -C "$dir" rev-parse -q --verify "refs/tags/$VERSION" || true)
    if [ -n "$existing" ]; then
        if [ "$existing" = "$commit" ]; then
            echo "  ok   $repo already tagged $VERSION at $commit"
        else
            echo "  FAIL $repo has $VERSION at $existing, manifest says $commit"
            echo "       A release tag is never moved. Investigate; do not force."
            FAILURES=$((FAILURES+1))
        fi
        continue
    fi

    case "$MODE" in
        --dry-run)
            echo "  would tag $repo $VERSION -> $commit"
            ;;
        --confirm)
            git -C "$dir" tag -a "$VERSION" "$commit" \
                -m "MCL $VERSION -- Stable release after public Candidate review. See mcl-core releases/$VERSION."
            echo "  tagged $repo $VERSION -> $commit"
            ;;
        --push)
            git -C "$dir" push origin "refs/tags/$VERSION"
            echo "  pushed $repo $VERSION"
            ;;
    esac
done < "$COMMITS"

echo
if [ "$FAILURES" -ne 0 ]; then
    echo "TAGGING FAILED: $FAILURES repository/repositories"
    exit 1
fi

case "$MODE" in
    --dry-run) echo "Dry run only. Nothing was written." ;;
    --confirm) echo "Tags created locally. They are NOT pushed. Review, then --push." ;;
    --push)    echo "Tags pushed. The GitHub Release page on mcl-core is a separate act." ;;
esac

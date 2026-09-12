#!/bin/sh
#
# Every SHA256SUMS.txt under evidence/ and experiments/ must verify.
#
# WHY THIS GATE EXISTS
#
# It did not, and that is the whole point. On 2026-09-12, nine days before the
# first public candidate, a pre-publication sweep found that 25 recorded
# digests across six evidence directories did not match the files they
# certified -- including the directory holding the 104-migration continuity
# campaign, this project's headline continuing-contact result.
#
# The cause was benign and the measurements were intact. The sums had been
# computed on the capture machine while the logs still carried the CRLF framing
# a board terminal emits; Git stored them LF, per .gitattributes, so the
# recorded digest described bytes that were never committed. Not one .wav
# failed -- every mismatch was a text log or CSV, which is the signature of a
# line-ending normalisation and not of a corrupted recording.
#
# The defect was not the mismatch. The defect was that NOTHING CHECKED. A
# digest nobody verifies is not provenance, it is decoration, and the first
# person to run `sha256sum -c` would have been an external reviewer reading a
# public repository. `check-provenance.sh` verifies that a binary under
# evidence/ has a README explaining it; it never verified the digests
# themselves. This gate closes that.
#
# WHAT IT DOES NOT DO
#
# It cannot tell you that a capture is the right capture, that a log came from
# the run its directory names, or that an experiment was performed at all. It
# tells you only that the bytes present are the bytes recorded. That is a floor,
# not a proof.
#
# Exit 0 when every digest file verifies, 1 otherwise.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
REPOS="mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb"

FAILURES=0
CHECKED=0
FILES=0

echo "=== evidence digests ==="
echo

for repo in $REPOS; do
    [ -d "$ROOT/$repo" ] || continue

    # Release bundles are excluded: their SHA256SUMS.txt records paths relative
    # to the eight-repository root rather than to its own directory, and
    # check-provenance.sh and the reconstruction gate already cover them.
    sums=$(cd "$ROOT/$repo" && find . -name SHA256SUMS.txt \
             -not -path "./.git/*" -not -path "./releases/*" 2>/dev/null | sort)

    for s in $sums; do
        dir=$(dirname "$ROOT/$repo/$s")
        CHECKED=$((CHECKED + 1))

        n=$(grep -cv '^[[:space:]]*#' "$ROOT/$repo/$s" 2>/dev/null || echo 0)
        FILES=$((FILES + n))

        # A byte-order mark makes sha256sum SKIP the first line and, when
        # other lines parse, STILL EXIT 0 -- so the directory reports success
        # while one artifact was never checked. Two directories were in exactly
        # that state when this gate was written. A silent partial check is
        # worse than a loud failure, so the BOM itself is the error.
        if head -c 3 "$ROOT/$repo/$s" | od -An -tx1 | tr -d '[:space:]' \
             | grep -q '^efbbbf'; then
            echo "  FAIL $repo/${s#./} begins with a UTF-8 BOM"
            echo "         sha256sum skips the first line and may still exit 0,"
            echo "         so this file does not verify what it appears to."
            echo "         Written by a PowerShell redirect; use -Encoding ascii."
            FAILURES=$((FAILURES + 1))
            continue
        fi

        if out=$(cd "$dir" && sha256sum -c SHA256SUMS.txt 2>&1); then
            :
        else
            echo "  FAIL $repo/${s#./}"
            echo "$out" | grep -E 'FAILED|No such file' | sed 's/^/         /'
            FAILURES=$((FAILURES + 1))
        fi
    done
done

echo "  checked $CHECKED digest file(s) covering $FILES artifact(s)"

if [ "$FAILURES" -ne 0 ]; then
    echo
    echo "EVIDENCE DIGEST CHECK FAILED in $FAILURES directory/directories"
    echo
    echo "A recorded digest and the file it certifies disagree. Before"
    echo "regenerating anything, find out WHICH is wrong: if the file changed,"
    echo "the evidence has been altered and that is far more serious than a"
    echo "stale digest. Raw measurements are immutable. If the digest was"
    echo "computed over bytes that were never committed -- CRLF framing is the"
    echo "usual reason -- correct the digest and keep the original in the file."
    exit 1
fi

echo
echo "EVIDENCE DIGEST CHECK PASSED"
echo
echo "What this does NOT establish: that any capture is the capture its"
echo "directory claims, or that the experiment was performed. Only that the"
echo "bytes present are the bytes recorded."

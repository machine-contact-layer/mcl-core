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
# It also requires each covered file's WORKING TREE bytes to equal its
# COMMITTED bytes before verifying, because on Windows those can differ while
# `git status` still reports the tree clean -- see the long note at the check
# itself. Without that, this gate can report a false pass on one platform.
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

        # THE WORKING TREE IS NOT AUTHORITATIVE. THE COMMITTED BYTES ARE.
        #
        # This check used to verify only what sat in the working tree, and on
        # Windows that is not necessarily what Git stores. `.gitattributes`
        # says `* text=auto eol=lf`, and `text=auto` makes Git compare
        # NORMALISED content -- so a file left over from before that rule, or
        # written by a Windows tool, can sit in the tree with CRLF, hash to the
        # CRLF value, and still be reported by `git status` as perfectly clean.
        # A digest recorded from that tree then agrees with itself forever on
        # that one machine and fails everywhere else.
        #
        # That is not hypothetical. Two run.log digests under mcl-ap passed a
        # full Windows sweep on 2026-09-12 and failed on a Linux runner minutes
        # after the repositories became public. The sweep was not wrong about
        # the bytes it saw; it was looking at the wrong bytes.
        #
        # So before trusting the tree, require the tree to equal HEAD. An
        # external reviewer clones fresh and gets the committed bytes on every
        # platform, and that is the only thing a published digest can mean.
        divergent=""
        while read -r _hash name; do
            case "$_hash" in ''|'#'*) continue ;; esac
            name=${name#\*}
            # A digest file may reference a path outside its own directory --
            # ../../exp002_probe.wav is a real entry here -- so the `..` has to
            # be resolved before Git is asked about it. `git rev-parse HEAD:`
            # does not normalise a path containing `..` the way `ls-files`
            # does, and comparing the two answers without resolving it first
            # reports a divergence that does not exist. That false positive is
            # why this is done with cd rather than string concatenation.
            ndir=$(cd "$dir" 2>/dev/null && cd "$(dirname "$name")" 2>/dev/null && pwd) || continue
            [ -n "$ndir" ] || continue
            rel="${ndir#"$ROOT/$repo/"}/$(basename "$name")"
            git -C "$ROOT/$repo" ls-files --error-unmatch -- "$rel" >/dev/null 2>&1 || continue
            # `|| true` matters: this script runs under `set -e`, and a
            # failing command substitution in an assignment takes the whole
            # gate down silently, which is exactly what it did once.
            wt=$(git -C "$ROOT/$repo" hash-object --no-filters -- "$rel" 2>/dev/null || true)
            hd=$(git -C "$ROOT/$repo" rev-parse "HEAD:$rel" 2>/dev/null || true)
            if [ -n "$wt" ] && [ -n "$hd" ] && [ "$wt" != "$hd" ]; then
                divergent="$divergent $name"
            fi
        done < "$ROOT/$repo/$s"

        if [ -n "$divergent" ]; then
            echo "  FAIL $repo/${s#./}"
            echo "         working tree differs from the committed bytes:$divergent"
            echo "         Whatever this digest says, it is not describing what"
            echo "         a fresh clone gets. Refresh the checkout (rm the file"
            echo "         and 'git checkout --' it) before trusting any result"
            echo "         here; do NOT regenerate the digest from these bytes."
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

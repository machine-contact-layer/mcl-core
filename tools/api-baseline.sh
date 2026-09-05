#!/bin/sh
#
# Release gate item 14: the public API surface, baselined and diffable.
#
# WHAT MCL PROMISES, AND WHAT IT DOES NOT
#
# V1_SCOPE.md section 4.5: v1.0 promises SOURCE compatibility, not binary ABI
# compatibility. Code written against v1.0 headers continues to compile against
# later 1.x headers. It is NOT promised that a binary linked against 1.0 keeps
# working against a later 1.x shared library -- MCL ships static libraries of
# caller-owned structs, and struct layout is deliberately not frozen.
#
# So this baseline exists to catch a SOURCE break: a public function that
# disappeared or changed name. A symbol appearing is additive and allowed within
# a major; a symbol disappearing is not.
#
#   ./api-baseline.sh              compare against the committed baseline
#   ./api-baseline.sh --update     rewrite the baseline (a deliberate act)
#
# Exit 0 when the surface is unchanged or has only grown; 1 when a symbol was
# removed or renamed.

set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
BASELINE="$ROOT/mcl-core/conformance/api-baseline-v1.txt"
WORK=${TMPDIR:-/tmp}/mcl-api-baseline
CURRENT="$WORK/current.txt"

UPDATE=0
if [ "$1" = "--update" ]; then
    UPDATE=1
fi

rm -rf "$WORK"
mkdir -p "$WORK"

# A missing compiler must stop the run, not colour it.
#
# The loop below tolerates one source that fails to compile, because a source
# that cannot stand alone contributes nothing to the linkable surface and
# saying so is useful. It does NOT tolerate a toolchain that is absent: with no
# `cc`, EVERY source is skipped, the extracted surface is empty, and the script
# reports the entire public API as removed. That is a frightening and
# completely false result, and it is the failure mode most likely to be
# believed, because "API BASELINE CHECK FAILED" is exactly what a real source
# break looks like.
for tool in cc nm; do
    if ! command -v "$tool" > /dev/null 2>&1; then
        echo "CANNOT RUN: '$tool' is not on PATH." >&2
        echo >&2
        echo "This gate compiles every protocol-facing source and reads the" >&2
        echo "symbols it defines. Without a toolchain it would extract an" >&2
        echo "empty surface and report the whole API as deleted. Refusing" >&2
        echo "rather than reporting that." >&2
        exit 2
    fi
done

# Every protocol-facing translation unit in the eight repositories. Compiled
# rather than parsed: a header declaration that no source defines is not part of
# the linkable surface, and grepping headers would report one.
for repo in mcl-wire mcl-link mcl-sdk mcl-ip mcl-ble mcl-uwb mcl-ap; do
    [ -d "$ROOT/$repo/src" ] || continue
    for source in "$ROOT/$repo"/src/*.c; do
        [ -e "$source" ] || continue
        if cc -std=c99 -c \
              -I "$ROOT/$repo/include" \
              -I "$ROOT/mcl-wire/include" \
              -I "$ROOT/mcl-link/include" \
              -I "$ROOT/mcl-sdk/include" \
              -o "$WORK/object.o" "$source" 2> "$WORK/cc.log"; then
            nm -g --defined-only "$WORK/object.o" | awk '{print $3}'
        else
            echo "WARNING: $source did not compile standalone; skipped" >&2
            tail -3 "$WORK/cc.log" >&2
        fi
    done
done | grep '^mcl_' | sort -u > "$CURRENT"

count=$(wc -l < "$CURRENT" | tr -d ' ')

if [ "$UPDATE" -eq 1 ]; then
    {
        echo "# MCL public API baseline"
        echo "#"
        echo "# Every mcl_* symbol defined by a protocol-facing translation"
        echo "# unit in the eight repositories, sorted."
        echo "#"
        echo "# v1.0 promises SOURCE compatibility, not binary ABI. A symbol"
        echo "# ADDED within a major is allowed. A symbol REMOVED or RENAMED is"
        echo "# a source break and requires a new major."
        echo "#"
        echo "# Regenerate deliberately: mcl-core/tools/api-baseline.sh --update"
        echo "# Never regenerate to make a diff go away."
        echo "#"
        echo "# symbols: $count"
        cat "$CURRENT"
    } > "$BASELINE"
    echo "baseline updated: $count symbols"
    exit 0
fi

if [ ! -f "$BASELINE" ]; then
    echo "no baseline at $BASELINE; run with --update to create one"
    exit 1
fi

# The committed baseline is a text file, and a Windows checkout with
# core.autocrlf=true hands it back with CRLF endings. The symbols read from
# `nm` never carry a carriage return, so an unstripped baseline makes every
# single symbol look renamed -- 143 false source breaks, in the exact shape
# of a real one. Strip at the read, the same way build-spec-index.sh does.
tr -d '\r' < "$BASELINE" \
    | grep -v '^#' | grep -v '^[[:space:]]*$' | sort -u > "$WORK/baseline.txt"

removed=$(comm -23 "$WORK/baseline.txt" "$CURRENT")
added=$(comm -13 "$WORK/baseline.txt" "$CURRENT")

echo "=== MCL public API surface ==="
echo "baseline: $(wc -l < "$WORK/baseline.txt" | tr -d ' ') symbols"
echo "current:  $count symbols"
echo

if [ -n "$added" ]; then
    echo "ADDED (allowed within a major -- additive):"
    echo "$added" | sed 's/^/    + /'
    echo
fi

if [ -n "$removed" ]; then
    echo "REMOVED OR RENAMED (a source break):"
    echo "$removed" | sed 's/^/    - /'
    echo
    echo "v1.0 promises source compatibility. Removing or renaming a public"
    echo "symbol breaks it and requires a new major version. If the removal is"
    echo "intended and the major is being cut, run --update deliberately."
    echo
    echo "API BASELINE CHECK FAILED"
    exit 1
fi

if [ -z "$added" ]; then
    echo "unchanged."
fi
echo "API BASELINE CHECK PASSED"

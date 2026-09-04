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

grep -v '^#' "$BASELINE" | grep -v '^[[:space:]]*$' | sort -u > "$WORK/baseline.txt"

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

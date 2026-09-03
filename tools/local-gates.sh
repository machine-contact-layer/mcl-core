#!/usr/bin/env bash
#
# Local quality gates for the MCL suite.
#
# This project has no hosted CI and will not gain any: a governing
# interoperability layer whose verification depends on one vendor's build
# service has a dependency it did not declare. The gates are run by hand, and
# this script is what "run the gates" means.
#
# Requires a Linux environment with gcc, clang, llvm-nm, cmake and ninja. On
# Windows, WSL. Point it at a checkout containing all eight repositories as
# sibling directories, or set MCL_ROOT.
#
#   bash mcl-core/tools/local-gates.sh
#   MCL_ROOT=/path/to/mcl bash local-gates.sh
#
# What it covers, and why each one is here:
#
#   1. GCC and Clang, strict C99 with warnings as errors, every repository,
#      full test suite. Two compilers because each sees things the other does
#      not: Clang's -Wunneeded-internal-declaration found a test constant that
#      was used only for its length while reading as though it carried real
#      protocol bytes.
#   2. ASan and UBSan on the protocol repositories. Decoders parse
#      attacker-reachable input; a bounds error here is not a crash, it is a
#      remote one.
#   3. Freestanding cross-compiles to ARM Cortex-M0 and RV32IM, then
#      undefined-symbol inspection. Source inspection cannot establish
#      libc-freedom, because an optimising compiler synthesises calls that do
#      not appear in the source. See IMPLEMENTATION_CONTRACT.md 2.2.
#   4. C++ header compiles under both compilers, since integrators embed these
#      headers in C++ translation units.
#
# It does not run the hardware experiments, and passing it establishes nothing
# about physical evidence. Software conformance and evidence advance
# separately.
set -u

ROOT="${MCL_ROOT:-$(cd "$(dirname "$0")/../.." && pwd)}"
WORK=/tmp/mclgates
REPOS="mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb"

STRICT="-std=c99 -Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wundef -Werror"
FAILURES=0

note()  { printf '\n=== %s ===\n' "$*"; }
fail()  { printf 'GATE FAILED: %s\n' "$*"; FAILURES=$((FAILURES+1)); }

rm -rf "$WORK"; mkdir -p "$WORK"

# ---------------------------------------------------------------- 1. GCC + Clang strict builds and full ctest
for CC_NAME in gcc clang; do
  note "$CC_NAME strict C99, warnings as errors, full suite"
  for repo in $REPOS; do
    B="$WORK/$CC_NAME/$repo"
    mkdir -p "$(dirname "$B")"
    if ! cmake -S "$ROOT/$repo" -B "$B" -G Ninja \
         -DCMAKE_BUILD_TYPE=Release \
         -DCMAKE_C_COMPILER="$CC_NAME" \
         -DCMAKE_C_FLAGS="$STRICT" > "$B.cfg.log" 2>&1; then
      fail "$CC_NAME configure $repo"; tail -20 "$B.cfg.log"; continue
    fi
    if ! cmake --build "$B" > "$B.bld.log" 2>&1; then
      fail "$CC_NAME build $repo"; tail -30 "$B.bld.log"; continue
    fi
    if ! ( cd "$B" && ctest --output-on-failure > "$B.tst.log" 2>&1 ); then
      fail "$CC_NAME ctest $repo"; tail -30 "$B.tst.log"; continue
    fi
    printf '  %-9s %s\n' "$repo" "$(grep -o '[0-9]* tests passed' "$B.tst.log" | head -1)"
  done
done

# ---------------------------------------------------------------- 2. ASan + UBSan
# Every repository, not only the core four. The binding parsers -- the BLE
# advertising-data scanner and fragment reassembler, the IP endpoint and
# datagram/stream decoders, the UWB endpoint and ranging decoders -- all read
# bytes chosen by a peer or by whatever else is transmitting nearby. A bounds
# error there is not a crash, it is a remote one.
note "ASan + UBSan (clang), all repositories"
SAN="-fsanitize=address,undefined -fno-omit-frame-pointer -fno-sanitize-recover=undefined -g -O1"
for repo in $REPOS; do
  B="$WORK/san/$repo"
  mkdir -p "$(dirname "$B")"
  if ! cmake -S "$ROOT/$repo" -B "$B" -G Ninja \
       -DCMAKE_BUILD_TYPE=Debug \
       -DCMAKE_C_COMPILER=clang \
       -DCMAKE_C_FLAGS="$STRICT $SAN" \
       -DCMAKE_EXE_LINKER_FLAGS="$SAN" > "$B.cfg.log" 2>&1; then
    fail "san configure $repo"; tail -20 "$B.cfg.log"; continue
  fi
  if ! cmake --build "$B" > "$B.bld.log" 2>&1; then
    fail "san build $repo"; tail -30 "$B.bld.log"; continue
  fi
  if ! ( cd "$B" && ctest --output-on-failure > "$B.tst.log" 2>&1 ); then
    fail "san ctest $repo"; tail -40 "$B.tst.log"; continue
  fi
  printf '  %-9s %s\n' "$repo" "$(grep -o '[0-9]* tests passed' "$B.tst.log" | head -1)"
done

# ---------------------------------------------------------------- 3. Freestanding cross-compiles + undefined symbols
note "Freestanding cross-compile and undefined-symbol inspection"

FREE="-std=c99 -Os -ffreestanding -fno-builtin -Wall -Wextra -Werror"
INC="-I$ROOT/mcl-wire/include -I$ROOT/mcl-link/include -I$ROOT/mcl-sdk/include \
     -I$ROOT/mcl-ip/include -I$ROOT/mcl-ble/include -I$ROOT/mcl-uwb/include"

SRCS="$ROOT/mcl-wire/src/wire.c $ROOT/mcl-wire/src/extension.c \
      $ROOT/mcl-link/src/link.c $ROOT/mcl-link/src/contact.c \
      $ROOT/mcl-link/src/rendezvous.c $ROOT/mcl-link/src/handoff.c \
      $ROOT/mcl-link/src/control.c \
      $ROOT/mcl-sdk/src/sdk.c \
      $ROOT/mcl-ip/src/ip_binding.c $ROOT/mcl-ble/src/ble_binding.c \
      $ROOT/mcl-uwb/src/uwb_binding.c"

# Anything in this list means a libc or OS dependency crept back in.
BANNED='memcpy|memset|memmove|memcmp|malloc|calloc|realloc|free|printf|fprintf|puts|fopen|fread|fwrite|strlen|strcmp|strcpy|abort|exit|__stack_chk'

for TARGET in "arm-none-eabi -mcpu=cortex-m0 -mthumb" "riscv32-none-elf -march=rv32im -mabi=ilp32"; do
  set -- $TARGET
  TRIPLE=$1; shift
  ARCHFLAGS="$*"
  OUT="$WORK/free/$TRIPLE"; mkdir -p "$OUT"
  note "  target $TRIPLE $ARCHFLAGS"
  ok=1
  for src in $SRCS; do
    obj="$OUT/$(basename "${src%.c}").o"
    if ! clang --target=$TRIPLE $ARCHFLAGS $FREE $INC -c "$src" -o "$obj" \
         > "$obj.log" 2>&1; then
      fail "cross-compile $TRIPLE $(basename "$src")"; tail -20 "$obj.log"; ok=0; continue
    fi
  done
  [ $ok -eq 1 ] || continue

  for obj in "$OUT"/*.o; do
    undef=$(llvm-nm -u "$obj" 2>/dev/null | sed 's/^ *U *//' | tr -d ' ')
    banned=$(printf '%s\n' "$undef" | grep -Ei "$BANNED" || true)
    if [ -n "$banned" ]; then
      fail "$(basename "$obj") on $TRIPLE has forbidden undefined symbols:"
      printf '%s\n' "$banned" | sed 's/^/      /'
    else
      # Print the actual names rather than asserting they are fine. A symbol
      # that is neither banned nor an MCL symbol would otherwise be labelled
      # "MCL-internal" by a script that never checked.
      # IMPLEMENTATION_CONTRACT.md 2.2: "Toolchain artifacts such as stack-cookie
      # or image-base references are expected and are not libc dependencies."
      # AEABI/compiler-rt helpers are that category -- Cortex-M0 has no divide
      # instruction, so any `/` on a runtime value becomes __aeabi_uidiv. An
      # integrator for such a target links compiler-rt or libgcc, which is
      # normal for freestanding ARM and is not a libc dependency.
      TOOLCHAIN='^(__aeabi_|__udivsi3|__umodsi3|__divsi3|__modsi3|__muldi3|__udivdi3|__umoddi3|__stack_chk_guard|__ImageBase|_fltused)'
      nonmcl=$(printf '%s\n' "$undef" | grep -v '^$' | grep -v '^mcl_' \
               | grep -Ev "$TOOLCHAIN" || true)
      if [ -n "$nonmcl" ]; then
        fail "$(basename "$obj") on $TRIPLE has non-MCL undefined symbols:"
        printf '%s\n' "$nonmcl" | sed 's/^/      /'
      else
        mcl=$(printf '%s\n' "$undef" | grep -c '^mcl_' || true)
        tool=$(printf '%s\n' "$undef" | grep -Ec "$TOOLCHAIN" || true)
        printf '    %-18s %s mcl_*, %s toolchain helper(s)\n' \
               "$(basename "$obj")" "$mcl" "$tool"
        if [ "$tool" -gt 0 ]; then
          printf '%s\n' "$undef" | grep -E "$TOOLCHAIN" | sed 's/^/        /'
        fi
      fi
    fi
  done
done

# ---------------------------------------------------------------- 4. C++ header compile
note "C++ header smoke compile"
cat > "$WORK/hdr.cpp" <<'CPPEOF'
#include "mcl/wire.h"
#include "mcl/extension.h"
#include "mcl/link.h"
#include "mcl/contact.h"
#include "mcl/rendezvous.h"
#include "mcl/handoff.h"
#include "mcl/control.h"
#include "mcl/sdk.h"
#include "mcl/ip_binding.h"
#include "mcl/ble_binding.h"
#include "mcl/uwb_binding.h"
int main() { mcl_handoff_control_t c; c.operation = MCL_HANDOFF_OP_COMMIT; return int(c.operation) - 3; }
CPPEOF
for CXX in g++ clang++; do
  if $CXX -std=c++17 -Wall -Wextra -Werror $INC -c "$WORK/hdr.cpp" -o "$WORK/hdr.$CXX.o" \
       > "$WORK/hdr.$CXX.log" 2>&1; then
    printf '  %s OK\n' "$CXX"
  else
    fail "$CXX header compile"; tail -20 "$WORK/hdr.$CXX.log"
  fi
done

# ---------------------------------------------------------------- summary
note "SUMMARY"
if [ "$FAILURES" -eq 0 ]; then
  echo "ALL GATES PASSED"
  echo
  echo "WHAT THIS DOES NOT COVER, stated so the result is not read as more"
  echo "than it is:"
  echo "  - MSVC. This script needs a POSIX shell and the GNU/LLVM toolchain."
  echo "    The MSVC gate is a separate run on the Windows side; see"
  echo "    tools/local-gates-msvc.ps1. A claim of \"all compilers\" needs both."
  echo "  - Hardware. No experiment runs here. Software conformance and"
  echo "    physical evidence advance separately and passing this establishes"
  echo "    nothing about the latter."
  # Counted from the registry rather than restated. This line said "Sixteen of
  # the 21" and went on saying it after ttl, validity and capability_tag were
  # settled. A hardcoded number in a script that reports results is the same
  # trap as a hardcoded test count, and this project has been caught by that
  # twice already.
  REGISTRY="$ROOT/mcl-core/registries/tier0-fields-v0.1.json"
  if [ -f "$REGISTRY" ]; then
    # Count the SETTLED fields and subtract. Counting provisional-or-open
    # directly also matches the registry's own root-level "status":
    # "provisional", which reported 14 unsettled fields out of 21 when there
    # are 13 -- an off-by-one produced by the very habit this block replaced.
    # Only field entries carry "width_bits", so the total is safe to grep.
    total=$(grep -c '"width_bits":' "$REGISTRY")
    settled=$(grep -c '"status": "assigned"' "$REGISTRY")
    unsettled=$((total - settled))
    echo "  - Meaning. Every check here is about BYTES. $unsettled of the $total"
    echo "    Tier-0 fields carry values two independent implementations would"
    echo "    not agree on; see mcl-core/registries/tier0-fields-v0.1.json."
  else
    echo "  - Meaning. Every check here is about BYTES, not about whether two"
    echo "    independent implementations would agree what the values mean."
  fi
else
  echo "$FAILURES GATE(S) FAILED"
fi
exit "$FAILURES"

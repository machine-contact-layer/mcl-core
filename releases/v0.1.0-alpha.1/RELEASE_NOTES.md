# MCL v0.1.0-alpha.1

**Status**: ALPHA / PRE-RELEASE  
**Date**: 2026-09-01  
**License**: BLOCKED — awaiting owner license selection  
**Visibility**: PRIVATE — no visibility changes made  

> [!WARNING]
> MCL is NOT a stable specification, NOT an adopted standard, and has NOT been
> independently validated for interoperability. No acoustic physical-layer profile
> has been experimentally confirmed. This release documents the current state of
> the reference implementation only.

## What This Release Contains

### MCL-Core
- Provisional Tier-0 semantic registry (`semantic-codes-v0.2.json`)
- C validator with overflow and file-truncation hardening

### MCL-Wire
- Freestanding C99 reference codec (Wire major 0, experimental)
- Bit-level encode/decode for 6 Tier-0 semantics
- Extension framework (no registered extensions)
- Known test vectors, randomized fuzz decode, malformed-input testing
- Zero heap allocation, zero global mutable state

### MCL-Link
- C99 reference state machine: 9-state lifecycle
- Context install/authorize/compare
- Wire major mask: `uint32_t` input, no narrowing
- Context lifetime invariant enforced (IDLE, DISCOVERED, CLOSED reject install)
- Coexistence tested with Wire in the same translation unit

### MCL-SDK
- C99 reference SDK: node init/reset, Tier-0 send/receive
- Narrow Link lifecycle wrappers
- Correctly modelled CMake consumer dependencies (`mcl_wire_dep` and `mcl_link_dep` public to `mcl_sdk`)
- Transport callback delivers raw canonical Wire bytes only (no Link binary frame)
- Policy sovereignty: AUTHORITY_CLAIM and REQUEST produce decoded objects only
- Zero heap allocation, caller-owned buffers
- Freestanding binary metrics: `.text`: 521 bytes, `.data`: 0, `.bss`: 0

### MCL-AP
- Analytical channel model (ISO 9613-1 attenuation, spherical spreading, Doppler)
- **Experiment 001 (LAB/EXPERIMENTAL)**:
  - Freestanding binary FSK modulation (3000/5000 Hz, 300 baud, 48 kHz mono PCM)
  - 4 preamble candidates: LFM chirp, Zadoff-Chu, PN/m-sequence, frequency-diverse
  - Preamble bakeoff under AWGN, clipping, and sample-rate offset sweeps
  - Clean channel Wire -> Acoustic -> Wire bit-perfect across all 6 Tier-0 kinds
  - Offline WAV decoder tool (`decode_wav.c`)
  - Retained E3 source WAV (`exp001_e3_source.wav`, SHA256: `7B4D7B038F4C6ABB496BAFBFFA4E307AAE70DFAAD1176E02BB0356225ECBBF69`)
  - **NOT normative. AP-B0 is NOT selected.**

### MCL-IP / MCL-BLE / MCL-UWB
- Draft binding specifications only, no implementation

## Conformance Evidence

| ID | Description | Status | Detail |
|----|-------------|--------|--------|
| C0 | Static registry validation | LOCAL_EVIDENCE | `semantic-codes-v0.2.json` validated |
| C1 | Canonical encoding (6 semantics) | LOCAL_EVIDENCE | Bit-perfect encode/decode + vectors |
| C2 | Negative decoding | LOCAL_EVIDENCE | Truncated, malformed, noncanonical |
| C3 | Link state tests | LOCAL_EVIDENCE | 9 states, context lifecycle, mask |
| C4 | Independent interoperability | NOT_RUN | No independent implementation |
| C5 | AP physical/profile conformance | NOT_RUN | No normative AP profile defined |
| C6 | Device/ecosystem robustness | NOT_RUN | No multi-device testing |

## AP Evidence

| ID | Description | Status | Detail |
|----|-------------|--------|--------|
| E0 | Analytical model | AVAILABLE | ISO 9613-1 attenuation, delay, Doppler |
| E1 | Deterministic simulation | LOCAL_EVIDENCE | Exp 001: FSK + 4 preambles + bakeoff |
| E2 | Replay evidence | NOT_RUN | No acoustic replay captures |
| E3 | Controlled over-air MCL frame | READY_FOR_EXECUTION | Source WAV generated; awaiting physical speaker->air->mic session |
| E4 | Multi-device | NOT_RUN | Not run |
| E6 | Independent interoperability | NOT_RUN | Not run |

## Compiler Verification

| Compiler / Target | Status | Detail |
|-------------------|--------|--------|
| MSVC 19.51 (Host x64) | PASS | All test suites pass under `/W4 /WX /std:c11` |
| Clang 17 (Host x64) | PASS | Strict `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wundef -Werror` — all 8 test suites pass |
| Clang ARM Cortex-M0 | PASS | `--target=arm-none-eabi -mcpu=cortex-m0 -mthumb -std=c99 -Os -ffreestanding -fno-builtin` — `llvm-nm` verified zero libc/OS undefined symbols |
| Clang RV32IM | PASS | `--target=riscv32-none-elf -march=rv32im -mabi=ilp32 -std=c99 -Os -ffreestanding -fno-builtin` — `llvm-nm` verified zero libc/OS undefined symbols |
| GCC | UNVERIFIED | GCC not installed on host |

## What This Release Does NOT Claim

- ❌ Stable specification
- ❌ Adopted standard
- ❌ Independent interoperability
- ❌ Physical acoustic validation (E3 pending physical audio session)
- ❌ Public availability (license not selected)
- ❌ Multi-device or ecosystem-scale testing
- ❌ Transport binding implementation (IP, BLE, UWB)

## Files

- `manifest.json` — Machine-readable manifest with exact commit SHAs
- `ics-alpha.json` — Implementation Conformance Statement

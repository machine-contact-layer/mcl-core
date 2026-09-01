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
- Provisional Tier-0 semantic normalization assignments spanning 6 core message categories and associated opcode registries (`semantic-codes-v0.2.json`)
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
  - 4 preamble candidates: LFM chirp, Zadoff-Chu derived, PN m-sequence (verified 7-bit LFSR, period 127), frequency-diverse
  - Exact length invariant: all preambles produce exactly $N = \text{round}(\text{duration} \times f_s)$ samples (N=4800 for 0.1s @ 48 kHz)
  - Equalized resource budget: identical RMS energy (0.6325), sample count, and peak amplitude limit
  - Quadrature magnitude detection ($\sqrt{C_I^2 + C_Q^2}$) guaranteeing polarity and phase invariance
  - Empirical false-alarm rate calibration: noise trials establishing threshold $\gamma$ for target empirical $P_{fa} = 0.01$
  - Symbol timing acquisition over 16-bit alternating training sequence
  - Out-of-place SRO resampler analytically verified across -500 to +500 ppm
  - Expanded impairments: colored noise, 2-path multipath (5 ms), 5-path multipath (0-30 ms), band attenuation (-10 dB notch @ 4 kHz), clipping, and combined mild impairments
  - Clean channel Wire -> Acoustic -> Wire bit-perfect across all 6 Tier-0 kinds
  - Offline WAV decoder tool (`decode_wav.c`)
  - Retained E3 source WAV (`exp001_e3_source.wav`, SHA256: `1BCA567F7F68F5A18F41ADD8CDE03863C336D50F332097F8361262F56ECA1241`)
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
| E1 | Deterministic simulation | LOCAL_EVIDENCE | Exp 001: Corrected bakeoff under equalized resources, empirical $P_{fa}$ calibration, SRO timing acquisition, expanded impairments. Prior uncalibrated comparison superseded. |
| E2 | Replay evidence | NOT_RUN | No acoustic replay captures |
| E3 | Controlled over-air MCL frame | READY_FOR_EXECUTION | Source WAV generated with training sequence; awaiting physical speaker->air->mic session |
| E4 | Multi-device | NOT_RUN | Not run |
| E6 | Independent interoperability | NOT_RUN | Not run |

## Compiler Verification

| Compiler / Target | Status | Detail |
|-------------------|--------|--------|
| MSVC 19.51 (Host x64) | PASS | All test suites pass under `/W4 /WX /std:c11` |
| Clang 17 (Host x64) | PASS | Strict `-Wall -Wextra -Wpedantic -Wconversion -Wsign-conversion -Wshadow -Wundef -Werror` — all test suites pass 100% |
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

- `manifest.json` — Machine-readable manifest with exact commit SHAs and release ref
- `ics-alpha.json` — Implementation Conformance Statement

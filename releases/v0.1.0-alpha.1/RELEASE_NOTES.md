# MCL v0.1.0-alpha.1

**Status**: ALPHA / PRE-RELEASE  
**Date**: 2026-09-02
**License**: BLOCKED — awaiting owner license selection  
**Visibility**: PRIVATE — no visibility changes made  

> [!WARNING]
> MCL is NOT a stable specification, NOT an adopted standard, and has NOT been
> independently validated for interoperability. No acoustic physical-layer profile
> has been experimentally confirmed. This release documents the current state of
> the reference implementation only.

## What This Release Contains

### MCL-Core
- Core semantic normalization registry with six currently implemented Tier-0 reference semantics (`semantic-codes-v0.2.json`)
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
  - Host-side research testbed (uses hosted C math/WAV/stdio; protocol-facing Wire, Link, and SDK libraries remain freestanding C99)
  - Binary FSK modulation (3000/5000 Hz, 300 baud, 48 kHz mono PCM)
  - 4 preamble candidates: LFM chirp, Zadoff-Chu derived, PN m-sequence (verified 7-bit LFSR, period 127), frequency-diverse
  - Exact length invariant: all preambles produce exactly $N = \text{round}(\text{duration} \times f_s)$ samples (N=4800 for 0.1s @ 48 kHz)
  - Equalized resource budget: identical RMS energy (0.6325), sample count, and peak amplitude limit
  - Quadrature magnitude detection ($\sqrt{C_I^2 + C_Q^2}$) guaranteeing polarity and phase invariance
  - Preliminary small-sample empirical false-alarm calibration: 100 noise trials per candidate establishing threshold $\gamma$ for target empirical $P_{fa} = 0.010$
  - Symbol timing acquisition over 16-bit alternating training sequence
  - Out-of-place SRO resampler analytically verified across -500 to +500 ppm
  - Verified impairment harness:
    - AWGN power verified across 30, 20, 10, 5, and true 0 dB (where noise power equals signal power within 0.5%)
    - Colored noise power measured and scaled post-filter to achieve exact requested SNR (30, 20, 15, 10, 5, 0 dB)
    - Deterministic 2nd-order IIR peaking/notch filter verified via sine probes (3000, 3800, 4000, 4200, 5000 Hz) with measured -10.00 dB center notch at 4000 Hz
    - 2-path multipath (5 ms), 5-path multipath (0-30 ms), clipping, and combined mild impairments
  - Hardened RIFF WAV chunk parser with unknown chunk skipping, mono/PCM16/48kHz enforcement, and strict format rejection
  - Clean channel Wire -> Acoustic -> Wire bit-perfect across all 6 Tier-0 kinds
  - Offline WAV decoder tool (`decode_wav.c`) with strict sample rate checking
  - Retained E3 source WAV (`exp001_e3_source.wav`, SHA256: `1BCA567F7F68F5A18F41ADD8CDE03863C336D50F332097F8361262F56ECA1241`)
  - Retained same-laptop frequency-response, raw-capture, decoder, and SHA-256 evidence
  - **E3 RUN — NOT RECOVERED**: one raw channel acquired at correlation 0.624806 but no capture achieved valid frame CRC, exact Wire bytes, or semantic recovery
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
| E1 | Deterministic simulation | LOCAL_EVIDENCE | Exp 001: Hosted C research testbed. Equalized resources, preliminary small-sample empirical $P_{fa}$ calibration (100 trials/candidate), verified 0 dB AWGN (measured noise power = signal power), scaled colored noise, verified -10 dB notch filter, hardened WAV chunk scanner. All 4 candidates achieved $P_d=1.000$, $0.00$ mean timing error, 12/12 CRC valid. Prior uncalibrated/unverified comparison superseded. |
| E2 | Replay evidence | LOCAL_NEGATIVE_EVIDENCE | Retained physical captures replayed through the decoder; exact recovery failed |
| E3 | Controlled over-air MCL frame | RUN_NOT_RECOVERED | Same-laptop speaker/air/microphone attempts retained; no valid frame CRC, exact Wire bytes, or semantic recovery |
| E4 | Multi-device | NOT_RUN | Not run |
| E6 | Independent interoperability | NOT_RUN | Not run |

## Compiler Verification

| Compiler / Target | Status | Detail |
|-------------------|--------|--------|
| MSVC 19.51 (Host x64) | PASS | Core/Wire/Link/SDK/AP: 15/15 CTests under `/W4 /WX` |
| Clang 18.1.3 (WSL host) | PASS | Strict C99 warnings as errors; Core/Wire/Link/SDK/AP: 15/15 CTests |
| GCC 13.3.0 (WSL host) | PASS | Strict C99 warnings as errors; 15/15 CTests; Wire 5/5 under ASan+UBSan |
| Clang ARM Cortex-M0 | PASS | `--target=arm-none-eabi -mcpu=cortex-m0 -mthumb -std=c99 -Os -ffreestanding -fno-builtin` — `llvm-nm` verified zero libc/OS undefined symbols |
| Clang RV32IM | PASS | `--target=riscv32-none-elf -march=rv32im -mabi=ilp32 -std=c99 -Os -ffreestanding -fno-builtin` — `llvm-nm` verified zero libc/OS undefined symbols |

## What This Release Does NOT Claim

- ❌ Stable specification
- ❌ Adopted standard
- ❌ Independent interoperability
- ❌ Successful physical acoustic validation (E3 run; exact recovery not achieved)
- ❌ Public availability (license not selected)
- ❌ Multi-device or ecosystem-scale testing
- ❌ Transport binding implementation (IP, BLE, UWB)

## Files

- `manifest.json` — Machine-readable manifest with exact commit SHAs and release ref
- `ics-alpha.json` — Implementation Conformance Statement

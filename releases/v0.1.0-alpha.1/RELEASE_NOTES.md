# MCL v0.1.0-alpha.1

**Status**: ALPHA / PRE-RELEASE  
**Date**: 2026-09-02
**License**: Apache-2.0 (selected 2026-09-02)  
**Visibility**: PRIVATE — publication deferred by owner until v1.0. Not tagged.  

> [!WARNING]
> MCL is NOT a stable specification, NOT an adopted standard, and has NOT been
> independently validated for interoperability. No acoustic physical-layer profile
> has been selected: AP-B0 remains open. A single experimental waveform has now
> survived a controlled over-air path on one device pair, which is E3 evidence and
> nothing more. This document records the current state of the reference
> implementation only.

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
- **Link frame v0 canonical layout**, the carriage unit every binding maps onto: 8 bytes minimum, flag-selected destination, session, sequence, freshness and a CRC-32 frame check; maximum 1048 bytes, which every binding sizes its carriage against
- Strict decoding: unknown link major, unassigned frame class, reserved flag bits, truncation at any length, and frame-check failure are all rejected rather than interpreted. Truncation is reported distinctly from permanent malformation, because a stream carriage must tell "wait for more bytes" apart from "resynchronise"
- Absence of a frame check makes a frame unchecked, not trusted. Presence of one makes it undamaged, not authentic

**Renamed since the snapshot was first prepared.** `MCL_LINK_FLAG_INTEGRITY` is now `MCL_LINK_FLAG_FRAME_CHECK`, and `MCL_LINK_ERR_INTEGRITY` is `MCL_LINK_ERR_FRAME_CHECK`. A CRC-32 detects accidental corruption and stops no attacker, who simply recomputes it. The wire bit is unchanged. This is an API-breaking rename, taken deliberately while nothing is tagged, under Architecture Charter §2.11: a mechanism is never named for a property it does not provide
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
- Framed contact path over Link frames, alongside the raw-Wire path a bearer like MCL-AP uses
- Transmit sequence advances only after the transport accepted the frame; a session reference requires an installed context
- Policy sovereignty: AUTHORITY_CLAIM and REQUEST produce decoded objects only, and reception changes no link state
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
  - Symbol boundaries rounded to nearest rather than truncated (fractional samples-per-symbol is unavoidable once transmit and receive clocks are independent)
  - **E3 RECOVERED**: first over-air recovery of an exact MCL frame. Laptop speaker -> air -> DFR1154 ESP32-S3 PDM microphone -> USB CDC (CRC-32 verified) -> offline decoder. 10 trials against the frozen receiver: 10/10 preamble acquisition (correlation 0.874086-0.877460), 10/10 PHY header, 8/10 exact Wire bytes and exact PRESENCE object; 3/3 on a prior pilot
  - Residual failure mode measured, not guessed: the PDM microphone attenuates the 5 kHz mark tone ~12.4 dB relative to 3 kHz, leaving ~0.3 log-energy margin on end-of-frame symbols. Both failures acquired cleanly and decoded all 24 header bits correctly
  - **NOT normative. AP-B0 is NOT selected.** Single operator, single device pair, short range. Not multi-device (E4).

### MCL-IP
- Endpoint offer with family-consistent address sizing; an IPv4 family claiming 16 address bytes is rejected, not half-accepted
- Opaque local reference, so first contact need not force a peer to disclose a routable address
- Datagram carriage: the datagram boundary is the frame boundary, trailing bytes rejected
- Stream carriage: length-prefixed, preserving synchronisation across a frame that cannot be decoded
- MTU accounting for IPv4 and IPv6
- Freestanding C99, no sockets, no libc symbols

### MCL-BLE
- Fixed 14-byte endpoint offer; a resolvable private address is documented as never being an identity
- Explicit fragmentation and reassembly for the 20-byte default ATT payload: START/END plus a sequence modulo 64
- Reassembly discards rather than splices on a sequence gap, reordering, an orphaned continuation, a non-zero START or overflow
- A Tier-0 PRESENCE Link frame fits 31-byte connectionless advertising data
- Freestanding C99, no Bluetooth stack, no libc symbols

### MCL-UWB
- Fixed 16-byte endpoint offer; one Link frame per UWB data frame
- Ranging-evidence record exposing **no** verified distance and **no** proximity-proved flag
- Admissibility requires performed ranging, a drift-cancelling method, authenticated scrambled timestamps and moderate confidence
- Distance conversion refuses overflow rather than wrapping into a small, plausible distance
- No distance bounding implemented or claimed; relay and distance-reduction attacks remain possible
- Freestanding C99, no UWB driver, no libc symbols

## Transport Evidence

Added after this snapshot was first prepared. Kept separate from AP Evidence so
it stays clear which medium each result describes.

| Binding | Level | Result |
|---|---|---|
| **mcl-ip** | `E4 MULTI_DEVICE_OVER_AIR` | 2.4 GHz UDP, Windows host ↔ ESP32-S3 SoftAP. 28 checks, 0 failed. 111 datagrams each way, 103 accepted, **8 malformed refused**, zero loss |
| **mcl-ble** | `E4 MULTI_DEVICE_OVER_AIR` | Bluetooth LE, connectionless and GATT. 35 checks, 0 failed, 20/20 sustained. Fragmented at MTU 23, the minimum BLE permits. **4 malformed fragment sequences discarded rather than spliced**, plus recovery asserted afterward |
| **mcl-uwb** | none | Unit-tested carriage mapping only |

In both runs the refusals are the result that matters. A binding that accepted
any of those inputs would have passed a happy-path demonstration and failed in
the field.

**Both ends compile the same sources.** A shared misreading of the specification
would be accepted by both peers and would be invisible in these numbers. None of
this is independent interoperability.

Two failures recorded in the evidence directories were ours rather than the
bindings': a 24-bit field initialised with a 32-bit constant on both ends, which
the Wire range check correctly refused; and a firmware logger that blocked on a
full USB CDC buffer and overflowed the receive queue while it stalled,
presenting as 36% packet loss. An independent ICMP baseline over the same link
measured 0% loss on 200 packets, which is what separated the instrument from the
radio.

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
| E2 | Replay evidence | LOCAL_EVIDENCE | Retained DFR1154 capture replays to exact Wire bytes, but through a receiver changed after capture — replay only |
| E3 | Controlled over-air MCL frame | LOCAL_EVIDENCE | 10 fresh trials vs frozen receiver: 10/10 acquisition, 10/10 header, **8/10 exact Wire + semantic**. 3/3 pilot. Same-laptop Realtek mic still fails |
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
- ❌ A selected or normative acoustic profile (E3 achieved on one device pair; AP-B0 still unselected)
- ❌ Public availability (Apache-2.0 selected, but publication deferred to v1.0)
- ❌ Ecosystem-scale testing (three transports have run between two machines, but with one board model, one host, no third-party peer and no multi-node contention)
- ❌ Any UWB hardware (that binding is unit-tested C99 that has never met a radio)
- ❌ **Any security property whatsoever** — no confidentiality, no cryptographic authenticity, no peer authentication, no contact continuity. The BLE run used Bluetooth Just Works pairing: encrypted against a passive listener, unauthenticated against an active one
- ❌ A normative transport profile for IP or BLE (their over-air runs are evidence toward a future C5, not a C5 pass)

## Files

- `manifest.json` — Machine-readable manifest with exact commit SHAs and release ref
- `ics-alpha.json` — Implementation Conformance Statement

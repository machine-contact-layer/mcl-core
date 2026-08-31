# MCL Low-Level Reference Implementation Plan

Status: pre-v0.1 implementation plan

This document governs the first executable MCL reference stack.

## Language and runtime contract

The primary MCL reference implementation is portable freestanding C99.

The mandatory low-level stack MUST NOT require:

- a hosted language runtime;
- an operating system;
- dynamic allocation;
- libc at runtime;
- threads;
- exceptions;
- RTTI;
- filesystem access;
- sockets;
- GitHub Actions or any hosted CI/CD service.

The implementation SHOULD use:

- caller-owned state;
- caller-owned input/output buffers;
- fixed-width integer types;
- explicit byte/bit encoding;
- deterministic error codes;
- bounded loops and bounded storage;
- narrow platform callbacks only where physical I/O or time is actually required.

Do not serialize C structs directly. Do not use compiler bitfields or packed-struct layout as the wire format. Canonical bytes are produced and consumed explicitly.

High-level language bindings may be added later over the public C ABI. They are not part of the foundational implementation.

## Local validation only

GitHub stores source. The developer machine runs tests.

No `.github/workflows/` files are permitted for the current project.

Local validation should include, where toolchains are available:

```text
GCC C99 warnings-as-errors
Clang C99 warnings-as-errors
ASan / UBSan host tests
seeded deterministic stress tests
malformed-input stress tests
ARM Cortex-M freestanding compile
RV32 freestanding compile
size / nm / objdump inspection
```

The low-level libraries must not gain hidden undefined references to heap, OS, filesystem, networking, or hosted runtime functions.

## Repository responsibilities

### mcl-core

Owns meaning, shared primitives, assigned-value registries and conformance definitions.

Executable Core work is intentionally small. It should expose the common semantic identifiers and bounded primitive representations needed by the reference stack, but reference code never becomes the authority for protocol meaning.

### mcl-wire

Owns canonical bytes and deterministic rejection.

The current C99 Wire reference is the first executable foundation. It must remain:

- allocation-free;
- OS-free;
- libc-free at runtime;
- endian-independent;
- alignment-independent;
- canonical;
- usable on small MCUs.

### mcl-link

Next implementation target.

Build a freestanding C99 Link state/context library around the already-defined version/context safety rules.

It must own only logical contact/session/context behavior. It must not invent a physical transport, scheduler thread, socket API, or mandatory binary Link header merely to make the demo complete.

State is caller-owned. Time is supplied as explicit values or via an optional callback. Transport output is returned through caller buffers/callbacks.

### mcl-ap

AP has two distinct surfaces:

1. portable runtime/reference DSP primitives in C99;
2. experimental host-side analysis executables written in C/C++ only when heavier numerical work is genuinely necessary.

The shipping/reference path should stay C-first. Platform DSP accelerators such as CMSIS-DSP may be optional backends, never protocol requirements.

Do not freeze a waveform before the experiment earns it.

### mcl-sdk

The SDK is a C developer interface over Core + Wire + Link + bindings.

It should eventually provide a small public API around caller-owned `mcl_node_t`-style state and callbacks while preserving the ability to use lower layers directly.

The SDK must not hide allocation, threads, event loops, sockets, or policy decisions.

### mcl-ip / mcl-ble / mcl-uwb

Remain thin binding specifications until the Core/Wire/Link/SDK vertical slice is working.

## Implementation order

### Step 0: resynchronize the local workspace

The remote histories were intentionally rewritten to remove discarded hosted-language guidance. The local IDE workspace may still contain commits from that discarded path.

Before implementation, for every repository:

1. fetch origin;
2. inspect local-only commits and working changes;
3. preserve nothing from the discarded hosted-language implementation unless explicitly reviewed as specification/data evidence;
4. reset the local branch to current `origin/main`;
5. remove generated caches/build artifacts;
6. confirm `git status` is clean.

Do not push the discarded local normalization implementation.

### Step 1: finish and audit mcl-wire C99

Treat the existing C99 Wire reference as the foundation.

Required local gates:

- all 65,536 common-header states round-trip;
- the six measured Tier-0 layouts round-trip;
- exact positive vectors pass;
- malformed/truncated/noncanonical inputs reject deterministically;
- extension parsing preserves canonical ordering, criticality and length semantics;
- seeded randomized testing passes;
- sanitizer stress passes on host;
- freestanding Cortex-M and RV32 object builds contain no hosted-runtime undefined symbols;
- byte sizes remain documented.

Port any remaining result-producing benchmark tooling before deleting its predecessor. Preserve benchmark result files and historical research notes.

### Step 2: implement mcl-link in freestanding C99

Promote the context safety model into C.

Suggested public concepts:

```c
typedef struct {
    uint8_t wire_major;
    uint8_t context_id;
    uint8_t generation;
    uint32_t ruleset_digest;
} mcl_context_key_t;

typedef struct {
    uint8_t state;
    uint8_t context_valid;
    mcl_context_key_t context;
} mcl_link_t;
```

Exact representation is implementation-local unless/until specified. Do not memcpy these structs onto the wire.

Required behavior:

- self-contained Wire objects need no active context;
- compressed/context objects require exact accepted context;
- wrong ID rejects;
- stale generation rejects;
- wrong digest rejects;
- incompatible major version rejects;
- reset clears context authorization;
- failed context bytes are never reinterpreted under another schema;
- reception never creates authority/trust automatically.

Use explicit return codes. No heap. No threads. No clocks hidden inside the library.

Port the existing context tests to C and reproduce their properties before removing the old implementation files.

### Step 3: replace Core validators with native local tooling

Core itself is specification/data first.

Replace remaining hosted-runtime validators with a small native validation executable or build-time C tool.

It must validate at least:

- duplicate category/opcode assignments;
- invalid ranges;
- registry collisions;
- common-header vectors;
- provisional value-code registries when introduced.

Do not put a JSON parser into the embedded runtime merely to validate repository files. Repository validation tooling and embedded runtime are separate artifacts.

If a small standalone parser is required for local validation, keep it in tools and out of the runtime library.

### Step 4: create the C SDK vertical slice

After Wire and Link pass independently, create the first end-to-end developer API.

The vertical slice is:

```text
bounded semantic value
 -> explicit normalization
 -> Wire encode
 -> Link logical send path
 -> byte-only transport callback/test double
 -> peer Link
 -> Wire decode
 -> bounded semantic value
```

Initial executable scope remains the six measured Tier-0 layouts:

- PRESENCE
- HAZARD
- REQUEST
- AUTHORITY_CLAIM
- DEGRADED_STATE
- TRANSPORT_OFFER

The SDK must not fall back to strings, JSON, dynamic dictionaries or opaque object serialization.

Use caller-owned buffers and callbacks.

### Step 5: port AP physics before implementing a modem

Replace the current analytical channel scripts with native C/C++ research executables while preserving numerical results.

Reproduce:

- propagation delay;
- sound-speed calculations;
- ISO-style atmospheric attenuation used by the current research model;
- Doppler/effective time-scale calculations;
- distance/frequency sweeps.

Only after numerical equivalence is demonstrated should the old analysis implementation be removed.

Then build the impairment/synchronization harness and eventually the real-air test path.

### Step 6: first full reference stack

The first software milestone is:

```text
Core meaning
 -> C Wire
 -> C Link
 -> C SDK byte transport
 -> peer
 -> identical normalized meaning
```

The first physical milestone is later:

```text
Core meaning
 -> C Wire
 -> C Link
 -> AP frame/waveform
 -> speaker
 -> air
 -> microphone
 -> AP decode
 -> C Link
 -> C Wire
 -> identical normalized meaning
```

Do not merge software-conformance claims with over-air evidence claims.

## Portability targets

The reference implementation should be continuously designed so it can plausibly compile for:

- bare-metal Cortex-M0/M0+/M3/M4/M7/M33-class systems;
- common RTOS environments without depending on the RTOS;
- RV32 embedded targets;
- Linux/macOS/Windows host test programs;
- larger edge processors.

Architecture-specific acceleration is optional and must sit behind portable interfaces.

## API rules

Prefer patterns such as:

```c
mcl_status_t mcl_wire_encode(...,
                             uint8_t *out,
                             size_t out_capacity,
                             size_t *out_size);

mcl_status_t mcl_wire_decode(const uint8_t *data,
                             size_t data_size,
                             ...);
```

Avoid:

- returned heap pointers;
- global mutable state;
- hidden singleton contexts;
- implicit background work;
- signal handlers;
- OS handles in protocol structures;
- architecture-dependent integer widths;
- compiler-defined struct layout on the wire.

## Evidence discipline

A local implementation test is implementation evidence, not independent interoperability.

Analytical results remain E0.
Deterministic simulation remains E1.
Recorded-channel replay remains E2.
Controlled over-air remains E3.
Independent implementations remain a later interoperability gate.

## Immediate IDE task

After local repositories are reset to current `origin/main`, do not redesign the architecture.

1. run and document all local C Wire tests;
2. inspect the Wire C API for heap/libc/OS/global-state violations;
3. cross-compile it for available Cortex-M and RV32 targets;
4. inspect object undefined symbols and sizes;
5. fix only real defects exposed by those checks;
6. then implement the Link context/state library in C99 and port its existing safety tests;
7. stop after Link passes locally.

Do not begin AP or SDK integration in the same uncontrolled edit.

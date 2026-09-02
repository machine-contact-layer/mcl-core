# MCL Reference Implementation Contract

Status: **Research Governance Draft**

[`ARCHITECTURE_CHARTER.md`](ARCHITECTURE_CHARTER.md) governs what MCL means. This document governs
what an MCL *reference implementation* is allowed to require of the machine running it.

The two are deliberately separate. The charter states that reference code is subordinate to the
specification (charter §2.9). This document states the engineering constraints that keep the
reference code implementable on the smallest machine that could plausibly need to make contact.

## 1. Why a runtime contract exists

MCL is intended for first contact between machines that were not designed together. The weaker
of the two peers sets the floor. If the reference implementation of the protocol-facing layers
requires an operating system, an allocator, or a language runtime, then that floor is raised for
every implementer, and the layer stops being deployable exactly where contact matters most.

The constraint is therefore normative for the reference stack, not a stylistic preference.

## 2. Runtime constraints

The protocol-facing layers — Core primitives, Wire, Link, and the transport bindings — are
portable freestanding C99.

They MUST NOT require:

- a hosted language runtime;
- an operating system;
- dynamic allocation;
- libc at runtime;
- threads;
- exceptions or RTTI;
- filesystem access;
- sockets;
- a hosted CI/CD service.

They MUST use:

- caller-owned state;
- caller-owned input and output buffers;
- fixed-width integer types for all protocol values;
- explicit byte-order and bit-order encoding;
- deterministic status codes;
- bounded loops and bounded storage;
- narrow platform callbacks only where physical I/O or time is genuinely required.

They MUST NOT use:

- returned heap pointers;
- global mutable state or hidden singleton contexts;
- implicit background work or signal handlers;
- C bitfields, packed structs, or compiler-defined struct layout as a wire format;
- unaligned loads or type-punning tricks;
- architecture-dependent integer widths in protocol values;
- OS handles inside protocol structures;
- required compiler extensions.

Canonical bytes are produced and consumed explicitly, field by field. A C struct is never
serialized by copying its memory.

Headers remain usable from C++ through `extern "C"`.

### 2.1 Which objects the constraint binds

The libc-free requirement applies to the objects on the frame path: Wire, Link, the transport
bindings, and the SDK. It does not apply to channel modelling, experiment analysis, benchmark
harnesses, or repository validation tooling, which are host-side artifacts by construction.
`mcl-ap`'s channel model is the explicit case: it evaluates ISO 9613-1 atmospheric absorption in
double precision and therefore depends on libm. It informs deployment planning and is never
invoked to encode or decode a frame, so it is out of scope here and MUST stay out of the frame
path.

### 2.2 The libc-free requirement in practice

Optimising compilers rewrite ordinary indexed byte loops into calls to `memcpy` and `memset`.
This silently reintroduces a libc dependency into an object that must link on a target where no
C library is present, and the breakage appears only at link time on the real hardware.

The established remedy in this codebase is a fill/copy helper whose destination pointer is
`volatile`, which the rewrite cannot be applied to.

Source inspection does not establish compliance, because the call does not appear in the source.
Implementations MUST verify by compiling at the optimisation level they ship and inspecting the
undefined external symbols of the resulting objects:

```text
dumpbin /symbols <obj> | findstr UNDEF      # MSVC
nm -u <obj>                                 # GCC / Clang
```

The result must contain no `memcpy`, `memset`, `malloc`, `free`, or stdio symbol. Toolchain
artifacts such as stack-cookie or image-base references are expected and are not libc
dependencies.

## 3. Separation of runtime and tooling

Repository validation tooling, benchmark harnesses, and experiment analysis programs are separate
artifacts from the runtime libraries. They may use a hosted environment freely.

A parser needed to validate repository JSON MUST NOT be linked into the embedded runtime in order
to make validation convenient.

Host-side experiment executables may use heavier numerical work where it is genuinely necessary.
The shipping reference path stays C-first, and platform DSP accelerators are optional backends,
never protocol requirements.

## 4. Layer implementation responsibilities

These refine the layer ownership in charter §3 with implementation-specific limits.

**mcl-core** — meaning, shared primitives, assigned-value registries, conformance definitions.
Executable Core work is intentionally small. Reference code never becomes the authority for
protocol meaning.

**mcl-wire** — canonical bytes and deterministic rejection. Allocation-free, OS-free, libc-free
at runtime, endian-independent, alignment-independent, canonical, usable on small MCUs.

**mcl-link** — logical contact, session, context and framing behavior only. Link MUST NOT invent
a physical transport, a scheduler thread, or a socket API in order to make a demonstration
complete. State is caller-owned. Time is supplied as explicit values or through an optional
callback.

**Transport bindings** — medium-specific carriage of Link frames and medium-specific physical
metrics. A binding maps; it does not reinterpret. A binding MUST NOT expose a physical
measurement as a semantic or trust conclusion.

**mcl-ap** — portable reference DSP primitives in C99, a double-precision channel model for
deployment planning, and host-side experiment executables. The channel model is analysis, not
carriage, and the separation in §2.1 depends on it staying that way. A waveform is not frozen
before an experiment earns it.

**mcl-sdk** — a C developer interface over Core, Wire, Link and the bindings. The SDK MUST NOT
hide allocation, threads, event loops, sockets, or policy decisions, and MUST preserve the
ability to use the lower layers directly. It MUST NOT fall back to strings, JSON, dynamic
dictionaries, or opaque object serialization.

## 5. Validation gates

Validation is local. Passing gates is a precondition for a protocol-facing commit, not a
release ceremony.

Where the toolchain is available:

```text
strict C99 host build, warnings as errors
second independent compiler, warnings as errors
ASan / UBSan host tests
seeded deterministic stress tests
malformed-input stress tests
freestanding cross-compilation for an ARM Cortex-M target
freestanding cross-compilation for an RV32 target
undefined-symbol and size inspection of the resulting objects
```

Warning flags MUST NOT be weakened to make a change pass. The conversion, aliasing, lifetime,
bounds or portability defect that the warning exposes is fixed instead.

Historical conformance vectors and benchmark result files MUST NOT be edited so that new code
appears compatible. When bytes legitimately change, a new versioned artifact is created and the
previous one is retained.

## 6. Deterministic rejection

Every decoder MUST reject, rather than interpret, at minimum:

- truncated input;
- an output buffer too small for the result;
- numeric fields outside their assigned width;
- unsupported categories, opcodes, or classes;
- non-zero canonical padding and reserved bits;
- duplicate or out-of-order extensions;
- reserved or zero extension identifiers;
- non-canonical variable-length integers;
- trailing bytes after a complete object where the carriage defines an exact boundary.

An unknown critical extension is never treated as safely ignorable.

## 7. Portability targets

The reference implementation is continuously designed so that it can plausibly compile for:

- bare-metal Cortex-M0/M0+/M3/M4/M7/M33-class systems;
- common RTOS environments, without depending on the RTOS;
- RV32 embedded targets;
- Linux, macOS and Windows host test programs;
- larger edge processors.

Architecture-specific acceleration sits behind portable interfaces and is always optional.

## 8. Evidence discipline

A local implementation test is implementation evidence. It is not independent interoperability
evidence, and it is not physical evidence.

The conformance ladder (C-levels) and the evidence ladder (E-levels) defined in
[`../conformance/CONFORMANCE_MODEL.md`](../conformance/CONFORMANCE_MODEL.md) are reported
separately and MUST NOT be blurred. A passing test suite does not raise an evidence level, and a
successful over-air trial does not raise a conformance level.

Software-conformance claims are never merged with over-air evidence claims in the same statement.

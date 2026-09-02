# Contributing

MCL is a candidate interoperability specification. That shapes everything about
how changes are made: the specification is the product, and the reference code
serves it rather than the other way round.

## The one rule everything else follows from

> **Freeze only what future implementers must agree on.**

If two independent implementations do not need to agree on something, it does
not belong in the specification. This is why the Link frame's bit layout stayed
undefined until a frame had actually survived a physical channel, and why the
acoustic waveform is still not frozen.

Adding is easy and permanent. Every field, flag and assigned value is a
commitment that outlives whoever proposed it.

## Where a change belongs

| Change | Where |
|---|---|
| What machines can mean | `mcl-core` |
| How meaning becomes bytes | `mcl-wire` |
| Contact, sessions, framing, handoff | `mcl-link` |
| Carrying frames over a medium | the binding repository |
| Developer-facing API | `mcl-sdk` |

Dependencies run one way: `core → wire → link → bindings → sdk`. A lower layer
never redefines a higher layer's meaning, and physical technology never leaks
into Core. Frequencies, modulation, MTUs and transducer classes are profile
concerns; if one appears in a Core proposal, the proposal is misplaced.

## Reference code is subordinate to the specification

A bug or shortcut in the reference implementation does not redefine the
protocol. Normative text, registries and conformance vectors define MCL.

The practical consequence: if the code and the specification disagree, that is a
bug report against the code — unless the specification is wrong, in which case
say so explicitly and change the specification first.

The project's success condition is that **independent builders can implement MCL
without copying our code.** A change that only works if you use our
implementation has failed regardless of how well it works.

## Implementation rules

Protocol-facing code — Wire, Link, the bindings, the SDK — is portable
freestanding C99. The full contract is
[`governance/IMPLEMENTATION_CONTRACT.md`](governance/IMPLEMENTATION_CONTRACT.md);
the parts contributors trip over most:

- **No heap, no libc at runtime, no OS, no threads, no hidden globals.** Caller
  owns all state and all buffers.
- **Verify libc-freedom by inspecting undefined symbols, not by reading the
  source.** Optimising compilers rewrite plain indexed byte loops into `memcpy`
  and `memset` calls. This has already happened once in `mcl-link`, and it
  breaks only at link time on real hardware. The house fix is a fill/copy helper
  with a `volatile` destination.
- **Never serialize a struct.** Canonical bytes are written field by field with
  explicit byte order. No bitfields, no packed structs, no unaligned loads.
- **Deterministic rejection.** Truncated input, out-of-range values, unknown
  classes, non-zero reserved bits, non-canonical encodings and trailing bytes
  past a declared boundary are all refused, never interpreted.
- **Do not weaken warning flags to make a change pass.** Fix the conversion,
  aliasing, lifetime or bounds defect the warning exposed.

Host tooling — validators, benchmark harnesses, experiment analysis — is exempt
and may use a hosted environment freely. Keep the two separate.

## Naming

**A mechanism is never named for a property it does not provide.** An
error-detecting code is not integrity; an encrypted channel is not an
authenticated peer; a verified credential is not an authorization; a
measurement is not a proof.

This has already caught one shipped defect, and it is worth more scrutiny than
it usually gets in review.

## Testing

Before a protocol-facing commit, locally:

```text
strict C99 build, warnings as errors
a second independent compiler, warnings as errors
ASan / UBSan host tests
seeded deterministic stress tests
malformed-input stress tests
freestanding cross-compilation, ARM Cortex-M and RV32
undefined-symbol and size inspection of the objects
```

Validation is local. There are no hosted CI workflows and none are wanted.

**Historical conformance vectors and benchmark results are never edited to make
new code look compatible.** When bytes legitimately change, create a new
versioned artifact and keep the old one.

A test that documents behaviour is worth more than a test that merely passes.
Say in the test what would break if the assertion failed.

## Evidence discipline

Two ladders, and blurring them is the most serious documentation error you can
make here.

- **Conformance (C0–C6)** — does an implementation obey the specification?
- **Evidence (E0–E6)** — how physically real is a result?

A passing test suite never raises an evidence level. A successful over-air trial
never raises a conformance level. Never state a software-conformance claim and
an over-air claim in the same sentence.

When reporting an experiment:

- **Say what you did not test.** Every evidence record in this project names its
  own limits. Both ends of the over-air runs compile the same sources, so none
  of them is independent interoperability, and each record says so.
- **Retain raw artifacts and digests**, including failed runs.
- **Report instrument failures as instrument failures.** Two published runs
  produced numbers that looked like protocol defects and were not — a logger
  that blocked and overflowed a receive queue, and a harness that misread a late
  reply as the next one. Both are written down. Attributing your own measurement
  error to the protocol is worse than a failed experiment.
- **Never report a simulated or fitted result as physical evidence.**

## Proposing a specification change

1. State the problem before the solution, and say which implementations would
   have to agree.
2. Classify it: editorial, clarification, compatible extension, behavioural
   revision, or wire-breaking. See
   [`governance/SPECIFICATION_PROCESS.md`](governance/SPECIFICATION_PROCESS.md).
3. Include negative cases. A change that says what to accept and not what to
   reject is half a change.
4. For assigned values, follow
   [`governance/REGISTRY_POLICY.md`](governance/REGISTRY_POLICY.md). Stable
   identifiers are never reused or reinterpreted; deprecation leaves the value
   permanently reserved.
5. For anything security-related, read [`SECURITY.md`](SECURITY.md) first. MCL
   adopts reviewed cryptographic constructions and invents none.

## What will be turned down

- Anything that makes MCL depend on a specific vendor, radio, model, or OS.
- A single `trusted` indicator, or any field that summarises several security
  properties into one.
- Physical-layer detail in Core.
- A new capability that could be an extension.
- Freezing something no independent implementer needs to agree on yet.
- A convenience that requires an allocator on the protocol path.

None of these are judgements about quality. They are all the same judgement:
MCL has to still be implementable, and still mean the same thing, on hardware
and in a decade nobody has seen yet.

# Machine Contact Layer

**A transport-independent layer for machines that have never met.**

Two machines, built by different companies, that were never designed to work
together, end up in the same place. Neither knows what the other is, what it can
do, whether it is safe to be near, or whether anything it says should be
believed. There is no shared network, no common credential system, and nobody
around to introduce them.

MCL is the layer that gets them from *I do not know you* to *I know enough about
you to decide what happens next* — and then out of the way.

```text
UNKNOWN MACHINE
      │  acoustic, BLE advertisement, or whatever medium exists
      ▼
FIRST CONTACT ............ presence, capabilities, hazards
      │
      │  negotiate a better transport
      ▼
PERSISTENT CONTACT ....... richer, private, higher rate
      │
      │  authenticate, verify, decide
      ▼
LOCAL AUTHORIZATION ...... your policy, your machine, your call
      │
      ▼
YOUR OWN PROTOCOL ........ MCL steps aside
```

MCL is infrastructure for builders. It is not a product, a fleet manager, an
autonomy stack, a credential authority, or a modem.

## What makes this different from just picking a protocol

**It assumes no prior relationship.** Not a shared network, not a common PKI,
not a pairing step someone performed in a factory. That assumption is what
everything else follows from.

**Meaning does not depend on the medium.** A `HAZARD` means the same thing
whether it arrived through a loudspeaker, a Bluetooth advertisement, or a UDP
datagram. Transports are bindings; they never redefine semantics.

**It works without AI.** Every normative object can be produced and consumed by
deterministic software on a microcontroller. Learned systems may map their
internal state to and from MCL objects; they do not define what the bytes mean.

**Reception is not permission.** MCL keeps these strictly apart:

```text
reception ≠ identity ≠ authenticity ≠ authority ≠ trust ≠ obligation
```

A machine that receives an `AUTHORITY_CLAIM` has received a claim. Nothing in
MCL can cause that claim to become authority. Your policy decides, locally,
always.

**Unknown critical meaning fails loudly.** An unknown opcode, a stale context,
an incompatible version, a reserved bit that should be zero — all rejected, never
guessed. For machines that move in physical space, accepting an ambiguous frame
is worse than dropping a valid one.

## What MCL is not

Stated plainly, because scope creep is how interoperability layers die.

- **Not an authentication protocol.** It makes strong authentication *possible*
  without sensitive material crossing an exposed channel. It does not own
  credential ecosystems, and it never will.
- **Not a robot ontology.** It standardizes the minimum physical-world meaning
  unrelated machines need at contact, not a world model.
- **Not a replacement for your protocol.** After authorization, hand off. MCL
  may remain as a narrow safety and control side-channel, but that is a
  capability, not a requirement.
- **Not a modem.** MCL-AP is one binding among several. Acoustics is a
  universally available rendezvous medium, not the definition of MCL.
- **Not adopted, not standardized, not stable.** See Status.

## Start here

### If you are a builder integrating MCL into a machine

Read [`spec/core-v0.md`](spec/core-v0.md) for what MCL can say, then
[`../mcl-sdk`](https://github.com/machine-contact-layer/mcl-sdk) for the
developer API. The integration model that matters:

```text
┌──────────────── YOUR MACHINE ────────────────┐
│  autonomy · control · filesystem · fleet     │
│                    ▲                         │
│                    │  scoped handoff only    │
│              ┌─────┴─────┐                   │
│              │  policy   │                   │
│              └─────▲─────┘                   │
│         ┌──────────┴──────────┐              │
│         │    MCL boundary     │              │
│         │  contact · security │              │
│         │  transport · policy │              │
│         └───┬──────┬──────┬───┘              │
│            AP     BLE    IP                  │
└─────────────┼──────┼──────┼──────────────────┘
              └──────┴──────┘
             unknown machines
```

An unknown peer talks to MCL. It does not talk to your actuators, your CAN bus,
your filesystem, or your fleet credentials. MCL is a quarantine boundary as much
as a protocol. The specification recommends this isolation and deliberately does
not mandate an MPU, TEE, or separate MCU — hardware neutrality outlives any
current hardware.

### If you are a developer implementing MCL

The reference stack is **portable freestanding C99**: no OS, no heap, no libc at
runtime, no threads, no hidden globals. The weaker of two peers sets the floor,
and if the reference implementation needed an operating system, MCL would stop
being deployable exactly where contact matters most.

- [`governance/IMPLEMENTATION_CONTRACT.md`](governance/IMPLEMENTATION_CONTRACT.md)
  — the runtime constraints and validation gates that bind reference code
- [`conformance/CONFORMANCE_MODEL.md`](conformance/CONFORMANCE_MODEL.md)
  — C0–C6 test classes; there is deliberately no vague "MCL compatible" claim
- [`registries/semantic-codes-v0.2.json`](registries/semantic-codes-v0.2.json)
  — machine-readable assigned values

You do not need our code. You need the specification, the registries, and the
conformance vectors. That is the point — see
[`CONTRIBUTING.md`](CONTRIBUTING.md) for how the reference implementation is
subordinate to the spec.

### If you are a scientist or researcher

Two ladders, kept rigorously separate. Conformance (C0–C6) measures whether an
implementation obeys the specification. Evidence (E0–E6) measures how physically
real a result is. **A passing test suite never raises an evidence level, and a
successful over-air trial never raises a conformance level.**

```text
E0 analytical    E1 simulation    E2 recorded replay
E3 controlled over-air            E4 multi-device over-air
E5 operational environment        E6 independent interoperability
```

Every experiment retains raw captures and digests, including the runs that
failed and the ones where our own instruments produced misleading numbers. See
[`../mcl-ap/research/EVIDENCE_LEDGER.md`](https://github.com/machine-contact-layer/mcl-ap)
and the `evidence/` directories in the binding repositories.

## Status

**Pre-v0.1 candidate specification. Private research. Nothing is tagged, nothing
is standardized, nothing is stable.** No private research draft is an adopted
standard.

| Layer | Implementation | Physical evidence |
|---|---|---|
| Core — semantics | Registries, validator | — |
| Wire — canonical bytes | C99, 5 test targets | — |
| Link — contact and framing | C99, 4 test targets | — |
| SDK — developer API | C99, 3 test targets | — |
| AP — acoustic | C99 + experiments | **E3 / E4** |
| IP — network | C99, host tool | **E4** — 2.4 GHz UDP, two machines |
| BLE — Bluetooth LE | C99, host tool | **E4** — GATT fragmentation, two machines |
| UWB — ultra-wideband | C99 | none — software binding only |

What that table does **not** say: nothing here is independent interoperability.
Both ends of every over-air run compile the same sources, so a shared
misreading of the specification would pass on both sides and be invisible. C4
and E6 require a second implementation written from the specification by someone
else.

**MCL currently provides no confidentiality, no cryptographic authenticity, and
no peer authentication.** See [`SECURITY.md`](SECURITY.md) before assuming
otherwise.

## Repositories

| | |
|---|---|
| **mcl-core** | semantics, registries, governance, conformance model |
| `mcl-wire` | canonical bytes, deterministic rejection, context and delta |
| `mcl-link` | contact lifecycle, the Link frame, sessions, handoff |
| `mcl-ap` | acoustic binding — the medium that needs no prior network |
| `mcl-ip` | IP binding — datagram and stream carriage |
| `mcl-ble` | BLE binding — fragmentation is the whole problem |
| `mcl-uwb` | UWB binding — ranging as evidence, never as proof |
| `mcl-sdk` | developer API over Core, Wire, Link and the bindings |

Dependencies run one way: `core → wire → link → bindings → sdk`. A lower layer
never redefines a higher layer's meaning.

## Governance

- [`governance/ARCHITECTURE_CHARTER.md`](governance/ARCHITECTURE_CHARTER.md) — the invariants no future specification may casually violate
- [`governance/IMPLEMENTATION_CONTRACT.md`](governance/IMPLEMENTATION_CONTRACT.md) — runtime constraints binding on reference implementations
- [`governance/SPECIFICATION_PROCESS.md`](governance/SPECIFICATION_PROCESS.md) — maturity, change classes, errata
- [`governance/REGISTRY_POLICY.md`](governance/REGISTRY_POLICY.md) — assigned-number policy
- [`governance/ORGANIZATION_MODEL.md`](governance/ORGANIZATION_MODEL.md) — the multi-party model this is heading toward
- [`governance/PUBLICATION_POLICY.md`](governance/PUBLICATION_POLICY.md) — immutable releases
- [`governance/IPR_PRINCIPLES.md`](governance/IPR_PRINCIPLES.md) — royalty-free implementation direction

The governing rule for all of it:

> **Freeze only what future implementers must agree on.**

## Licence

Apache-2.0. See [`LICENSE`](LICENSE).

The project succeeds when independent builders can implement MCL without copying
our code, exchange the same semantic objects, reject incompatible input
deterministically, and extend it through published processes without
fragmenting the ecosystem.

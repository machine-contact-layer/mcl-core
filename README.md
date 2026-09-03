# Machine Contact Layer

**A transport-independent layer for machines to meet, and to keep talking.**

Two machines end up in the same place. They may have been built by different
companies and never designed to work together; or they may both be yours, and
simply have no network in common at this moment. Either way there is no shared
bus, no common credential system, and nobody around to introduce them.

**MCL gives them something they can speak first** — a common language available
when no better shared channel exists. What happens after that is yours to decide.

```text
ANOTHER MACHINE
      │  acoustic, BLE advertisement, Wi-Fi — whatever medium exists
      ▼
FIRST CONTACT ............ presence, capabilities, hazards
      │
      │  optional: negotiate a different transport
      ▼
CONTINUING CONTACT ....... often richer or more private — or still acoustic
      │
      ├─▶ STAY ON MCL ......... MCL remains the channel, indefinitely
      ├─▶ SECURITY PROFILE .... optional: establish who you are talking to
      └─▶ HAND OFF ............ your own protocol takes over
```

Those three endings are alternatives, not stages. A deployment may take any of
them, or more than one, or stop at first contact and never migrate at all.

MCL is infrastructure for builders. It is not a product, a fleet manager, an
autonomy stack, a credential authority, or a modem.

## The same layer, configured differently

A gatekeeper machine at an office entrance, a domestic assistant, and a
warehouse quadruped can all use MCL as their first interaction layer while
agreeing on almost none of their behaviour:

| | Gatekeeper | House agent | Warehouse quadruped |
|---|---|---|---|
| **First contact** | acoustic | acoustic | acoustic or BLE |
| **Migrates transport** | yes, to verify | rarely | yes, fleet Wi-Fi |
| **Authenticates the peer** | always | for anything privileged | already known peers |
| **Hands off** | to the access system | almost never | to the fleet protocol |
| **Typical ending** | handoff | stay on MCL | handoff |

None of that is protocol. It is configuration, and it is the deployment's to
choose — Architecture Charter §2.10.1. Differently configured peers stay
interoperable at the frame and semantic layers; they simply refuse each other at
different points, which is a policy outcome rather than an interoperability
failure.

What you configure:

- **Which transports** you will speak, and whether you will migrate at all
- **What may be disclosed** at each stage, and over which medium
- **Whether a security profile runs**, and what must pass before it does
- **Which cryptography, if any** — MCL defines the interface a mechanism plugs
  into, never the mechanism. Bring your own stack, your secure element, or a
  named profile for talking to strangers. MCL never holds a private key
- **Whether you hand off**, or keep MCL as the ongoing channel

## Three ways people use it

All three are first-class. None is a degraded version of another.

**Open contact, no security.** Presence, hazard broadcast and capability
discovery in a shared space. You are addressing unknown listeners on purpose, so
authenticating them is not meaningful. The real machine stays behind the MCL
boundary and only MCL talks — which is the point.

**Machines that already know each other.** Same owner, same fleet, provisioned
at manufacture, or trusted by some means entirely outside MCL. They need a way
to meet when no network is shared, and a way to move to a better one. They do
not need MCL to authenticate anything.

**Unrelated machines that do need to establish trust.** MCL carries an optional
security profile, so that sensitive material never has to cross the exposed
first-contact medium. Two machines can introduce themselves acoustically, agree
how to reach each other over BLE or Wi-Fi, and complete verification there.

> Today MCL supports the first two shapes and the transport migration the third
> one needs. **The security profile itself does not exist yet** — no
> cryptography is implemented in any repository. See [`SECURITY.md`](SECURITY.md).

## What makes this different from just picking a protocol

**It requires no prior relationship — and does not forbid one.** No shared
network, no common PKI, no pairing step someone performed in a factory. Machines
that already know each other are equally at home here; they just skip the parts
they do not need.

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

- **Not a robot ontology.** It standardizes the minimum physical-world meaning
  unrelated machines need at contact, not a world model.
- **Not an authentication protocol.** MCL can be configured to *carry* one, and
  is designed so that strong authentication is possible without sensitive
  material crossing an exposed channel. It does not define the exchange and does
  not own credential ecosystems. Authentication is a thing MCL can do, not what
  MCL is for.
- **Not a mandated sequence.** MCL does not tell you when to disclose what, when
  to migrate, or whether to verify anything at all. That is your design.
- **Not obliged to leave.** Handing off to your own protocol is one supported
  ending. Remaining as the channel between two machines that share no other
  protocol is another, and it is not a lesser one.
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

A peer talks to MCL. It does not talk to your actuators, your CAN bus, your
filesystem, or your fleet credentials — and that holds whether the peer is a
stranger or a machine you own. MCL is a quarantine boundary as much as a
protocol, and in a deployment that never authenticates anyone, the boundary is
doing all of the work. The specification recommends this isolation and deliberately does
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
| Core — semantics | Registries, 2 validators | — |
| Wire — canonical bytes | C99, 7 test targets | — |
| Link — contact and framing | C99, 9 test targets | — |
| SDK — developer API | C99, 5 test targets | **E4** — one contact across 104 changes of medium |
| AP — acoustic | C99 + experiments | **E3 / E4** |
| IP — network | C99, host tool | **E4** — 2.4 GHz UDP, two machines |
| BLE — Bluetooth LE | C99, host tool | **E4** — GATT fragmentation, two machines |
| UWB — ultra-wideband | C99 | none — software binding only |

Test counts are read from `ctest -N`, not remembered. A count written from
memory has been wrong twice in this project's history, in both directions.

The SDK row is the newest and the least obvious: migration was exercised between
two machines with **both media live on both peers at once**, which is the only
arrangement in which a contact can actually change medium. A single-transport
rig cannot construct the case that matters.

What the v1.0 release will and will not claim about each of these is decided in
[`governance/V1_SCOPE.md`](governance/V1_SCOPE.md).

What that table does **not** say: nothing here is independent interoperability.
Both ends of every over-air run compile the same sources, so a shared
misreading of the specification would pass on both sides and be invisible. C4
and E6 require a second implementation written from the specification by someone
else.

**MCL currently provides no confidentiality, no cryptographic authenticity, and
no peer authentication.** The two shapes that do not need them — open contact,
and machines that already know each other — are usable today. A deployment that
needs the security profile is waiting on work that has not been done. See
[`SECURITY.md`](SECURITY.md) before assuming otherwise.

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

# MCL Conformance Profiles v1

Status: **Candidate**

Defines the named claims an implementation may make about itself, and what each
one guarantees to a machine that has never met it.

This document may not be promoted past Candidate while any layer it names holds
an unresolved forward reference. §5.2 currently holds one, and names it.

## 1. Why this exists

`research/TWO_BUILDER_AUDIT.md` asked whether two builders who never coordinate
can build to the published package and still be guaranteed a common
first-contact path. They cannot. Every transport binding is individually
optional, so an implementation carrying MCL-IP and MCL-AP and one carrying
MCL-BLE and MCL-UWB both conform to v1 completely and share nothing.

The vocabulary was missing. "Implements MCL" describes a legal implementation;
it does not describe an implementation another machine can rely on. A
conformance profile is the second statement.

The governing rule, from `governance/V1_SCOPE.md` §5.10:

> For every configurable choice, ask whether two conformant implementations can
> independently choose different values and consequently fail to communicate. If
> they can, either a layer mandates a common baseline or a deployment profile
> selects one.

## 2. Three kinds of profile, which are not the same thing

Readers conflate these, and the registries make it easy to. They answer
different questions and are assigned by different means.

| | Answers | Assigned in | Example |
|---|---|---|---|
| **Transport profile** | How do bytes cross *this* medium? | a per-transport registry, by number | `IP-DATAGRAM = 1` under `transport_id = 2` |
| **Conformance profile** | What may another machine assume I implement? | this document, by name | `MCL Base 1` |
| **Deployment profile** | Which optional pieces are mandatory *here*? | a deployment authority, by publication, against `spec/deployment-profile-v1.md` | a city's required bearer |

A transport profile makes one medium unambiguous. It cannot make two
implementations meet, because implementing it is optional. A conformance profile
fixes what is mandatory for everyone claiming it. A deployment profile narrows
further, for one place, without changing MCL.

Conformance profiles are named rather than numbered because they are claims made
in documentation and conformance statements, not values carried in a frame. §7
explains why that distinction is deliberate.

## 3. Rules common to every layer

1. **Layers are cumulative.** Claiming a layer claims every requirement of the
   layers it extends.
2. **A claim is all or nothing.** An implementation that meets part of a layer
   claims the layer below it. There is no partial claim, and no "claims X except".
3. **A claim is about an implementation, not a deployment.** Configuration that
   disables a mandatory capability at runtime does not withdraw the claim; the
   implementation still contains it. An implementation that cannot perform a
   requirement *at all* may not claim the layer, whatever it is configured to do.
4. **Refusal is conformant behaviour.** A layer requires that a machine can
   speak; it never requires that a machine agrees. Policy refusals at any point
   are conformant — `governance/ARCHITECTURE_CHARTER.md` §2.10.1.
5. **Every requirement below is testable.** A requirement that cannot be
   checked by the conformance kit does not belong in a conformance profile, and
   §8 records the obligation for each.

## 4. MCL Base 1

**Claim:** *given a bearer both machines already share, two `MCL Base 1`
implementations interoperate.*

### 4.1 Required

- **Wire major 1**, encode and decode, including the canonical-encoding and
  zero-padding checks, and refusal of every unassigned major.
- **The Stable Tier-0 kernel:** `PRESENCE`, `TRANSPORT_OFFER`,
  `TRANSPORT_ACCEPT`, produced and consumed, at major 1.
- **Link major 1**, the frame layout, and the frozen class dispositions of
  `spec/link-class-disposition-v1.md`.
- **Capability and version negotiation** as specified in
  `mcl-link/spec/link-negotiation-v1.md`, including the selection function and
  the floor.
- **Refusal semantics.** Unknown opcode, unassigned major, reserved non-zero
  bit, stale context and inadmissible object are refused, never guessed.
- **At least one transport binding**, so that the implementation can be made to
  communicate at all. Which one is unconstrained, and that is exactly why Base 1
  guarantees nothing about meeting a stranger.

### 4.2 Not required

A bearer in common with anyone; a microphone or speaker; discovery of any kind;
migration; cryptography.

### 4.3 What this layer is honestly for

Fleets provisioned by one owner, machines paired at manufacture, deployments
where a bearer is arranged out of band, simulation and test harnesses, and
libraries embedded in a larger product. This is the majority of real use today
and it is a first-class claim, not a degraded one.

**Base 1 does not permit any statement about meeting an unknown machine.** An
implementation claiming only Base 1 must not describe itself as capable of
stranger contact.

## 5. MCL Stranger-Contact 1

**Claim:** *two `MCL Stranger-Contact 1` implementations placed within physical
range of one another, given no prior configuration, no shared network, no shared
credential and no operator, will detect one another and exchange first contact.*

Extends Base 1.

### 5.1 Required

- Everything in Base 1.
- **`AP-BOOTSTRAP-1`**, implemented in both directions: emit and receive. This
  is the single mandatory-to-implement rendezvous path and it is what makes the
  claim above true. A layer that let an implementation choose *which* rendezvous
  profile to implement would reproduce the empty intersection this document
  exists to remove.
- **Reception and generation of `TRANSPORT_OFFER` and `TRANSPORT_ACCEPT`** over
  the bootstrap path, so a richer bearer can be proposed and answered.
- **Shared-medium behaviour** as `AP-BOOTSTRAP-1` specifies it:
  listen-before-transmit, reply scheduling, duplicate suppression, and backoff.
  A machine that answers every `PRESENCE` immediately is not conformant, because
  a street with ten of them is a street with no contact.
- **Round ownership**, `AP-BOOTSTRAP-1` §8.1. A machine that has emitted this
  round's `PRESENCE` is the solicitor and may not also respond to another; a
  machine responding to somebody's solicitation may not consume a fellow
  responder's offer. **This is required, not advisory, and it is not a
  refinement of contention.** Without it two machines still converge — the
  roles they land in happen to be complementary — and three do not, at all: 600
  simulated seconds of three machines produced 36 bearer agreements, zero path
  validations and zero migrations, in a stable cycle where every machine was an
  acceptor and none was ever a controller. A layer that guaranteed contact
  between two implementations and not among three would be guaranteeing the
  easy case.
- **A random `migration_ref`**, `AP-BOOTSTRAP-1` §8.2, because on this medium
  it is what selects one responder out of several. A value derived from
  `source_ref` is not sufficient: `source_ref` carries no uniqueness property,
  so two builders may legally share one and a derived reference then names both
  of their contenders with a single acceptance.
- **The timing parameters of `AP-BOOTSTRAP-1` §7.2, unmodified.** None of them
  appears on the wire, so two builders who chose differently each behave
  correctly by their own lights, contend by neither's, and cannot detect it.
- **An explicit no-common-bearer outcome.** Where the offer and accept find no
  bearer in common, the implementation must report that as a distinct, legible
  result. Silence is not conformant. This is the difference between a failure
  a builder can diagnose and one they cannot.

### 5.2 The forward reference, and what became of it

**Resolved on 2026-09-06.** `AP-BOOTSTRAP-1` now exists:
`mcl-ap/spec/ap-bootstrap-1.md`, normatively complete and implementable from
that document alone. This section previously said the profile did not exist and
that no implementation could claim `MCL Stranger-Contact 1` as a result. That is
no longer true, and the section is rewritten rather than quietly deleted,
because what the layer guarantees changed.

It is still **not** `AP-LAB-FSK-EXPERIMENTAL` (profile 192), which carries raw
Wire bytes, sits in the Experimental Use range, and under
`governance/GOVERNANCE.md` §4.3 is never relabelled Stable. Profile 192 was not
mutated.

**The profile is Candidate, and the claim inherits that.** An implementation may
now claim `MCL Stranger-Contact 1`, and the claim carries the caveat that its
bootstrap profile is not frozen — `MCL_CONFORMANCE_CAVEAT_BOOTSTRAP_CANDIDATE`
in `mcl-sdk/include/mcl/conformance.h`, so the qualification travels in code and
not only in prose.

The reason is stated in §11 of the profile and is not a documentation gap: every
measurement of that waveform comes from **one transmitter class**, and there is
direct evidence the choice does not travel — a laptop speaker with a measured
notch at one of the two tones recovered 1 of 3 where the reference transmitter
recovers 9 of 15. Promotion needs a band swept on transmitters that are not the
reference one, a clean-room receiver, PCM vectors, a contention campaign and an
assigned identifier.

Granting the claim outright would overstate it; refusing it now would understate
it, because the specification a builder needs is in the tree and implementable.
The caveat is how both are avoided.

### 5.3 What this layer does NOT guarantee

**It guarantees meeting. It does not guarantee continuing.**

Two Stranger-Contact 1 machines are guaranteed to detect one another and
exchange first contact. Whether they can then migrate to a richer bearer depends
on their having one in common, and no layer can mandate that: a roadside unit
may reasonably have Ethernet and no radio, and a field sensor may reasonably
have BLE and no network. Requiring both of every machine would exclude honest
implementations to buy a guarantee that a deployment profile provides better.

So continuation is **best-effort at this layer and guaranteed by a deployment
profile**, which is what §2 says a deployment profile is for. That schema now
exists — `spec/deployment-profile-v1.md`, with a validator and fixtures — and it
derives the guarantee from the profile's content rather than letting a
deployment declare one. The failure, when it happens, is explicit by §5.1.

**Even a bearer both machines hold may not be reachable, and that gap is one
layer down.** Agreement names a bearer; it does not open one. For BLE the
asymmetry is structural rather than accidental: `TRANSPORT_OFFER` carries an
`endpoint_token` and `TRANSPORT_ACCEPT` does not, so the acceptor can find the
offerer and the offerer cannot find the acceptor — and `BLE-GATT-1`, correctly
for a carriage profile, makes advertising explicitly optional. Two conformant
builders can therefore each wait for the other to connect.
`mcl-ble/spec/ble-activate-1.md` closes it and is **Candidate**, so until it or
an equivalent is Stable, continuation over a BLE candidate bearer is not
guaranteed between builders who never coordinate. Stated here because it is
exactly the kind of thing a layer like this exists to stop being a surprise.

It also guarantees nothing about identity, authenticity or authority. Acoustic
reception is proximity evidence and never proof of co-presence; the medium is
observable, injectable and relayable.

## 6. MCL Secure-Stranger 1

**Reserved name. Not specified.**

Extends Stranger-Contact 1 and will require: a common continuing bearer selected
by the deployment profile, a named MCL security profile, a credential-reference
and proof format, a trust-anchor interface, and the separation of cryptographic
proof from trust from authorisation that `ARCHITECTURE_CHARTER.md` requires.

It is named here so the layer above Stranger-Contact has one name rather than
several, and so that nobody assigns the name to something else. It is not
specifiable until the security carrier (`V1_SCOPE.md` §5.10, and
`research/TWO_BUILDER_AUDIT.md` §3.6) is settled and a suite is selected by
measurement.

## 7. Why the layer is not carried on the wire

An implementation's conformance profile is declared in its conformance
statement. It is **not** a field, a flag, or a feature bit.

**It could not do its job as one.** The layer guarantees a precondition that
must hold *before* any exchange occurs. A value readable only after two machines
have already met cannot guarantee that they can meet.

**And it would be a claim, not a fact.** `mcl-link/spec/link-negotiation-v1.md`
§7 is explicit that a `CAPABILITY` frame is a claim and that reception is not
verification. A conformance bit would add a second unverifiable claim whose only
effect would be to invite implementations to trust it.

Two mechanisms are specifically not to be reached for:

- **Feature bits.** `features` exists and its table is empty by design, with
  unknown bits failing closed by construction. Assigning one to mean "I am
  Stranger-Contact 1" would put an implementation-wide property into a
  per-contact negotiation, where it would be both unverifiable and too late.
- **`capability_tag`.** `V1_SCOPE.md` §4.2 defines it as a sender-controlled
  opaque revision token that a receiver MUST scope to one peer and MUST NOT
  compare across peers as a capability identity. It cannot carry this and must
  not be made to.

What *is* discovered on the wire stays discovered on the wire: which bearers a
peer offers is what `TRANSPORT_OFFER` is for, and no new mechanism is needed.

## 8. Test obligations

The conformance kit must be able to decide each claim from outside the
implementation.

| Requirement | How it is checked |
|---|---|
| Base 1, Wire major 1 and the Stable kernel | C4 cross-decode against the clean-room implementation, both directions, including matching refusals |
| Base 1, Link major 1 and class dispositions | C4, plus the frozen vectors |
| Base 1, negotiation and the floor | the negotiation suite, both roles |
| Base 1, refusal semantics | the negative vectors; a refusal that decodes is a failure |
| Stranger-Contact 1, bootstrap carriage | PCM vectors decoded, and emitted PCM decoded by an implementation that shares no code |
| Stranger-Contact 1, shared-medium behaviour | a multi-responder campaign, three machines or more, measuring that contact survives contention |
| Stranger-Contact 1, no-common-bearer outcome | an offer naming only bearers the peer lacks; the distinct result is required output |
| The end-to-end claim | `V1_SCOPE.md` §5.10, two implementations given only the release, a deployment profile and its trust anchors |

A layer whose obligations have not been run is not claimed. The conformance
statement records which were run and against what.

## 9. Assignment and change control

Layer names are assigned by MCL Standards Action in this document. There is no
numeric registry, because these values are never carried in a frame (§7) and a
registry of unassignable numbers would invite exactly the wire encoding this
document forbids.

Adding a layer, or changing what an existing layer requires, is a change to this
document under `governance/SPECIFICATION_PROCESS.md`. **A layer's requirements
may not be weakened after any implementation has claimed it**: an implementation
that met the claim must not silently come to mean less than it did. A weaker
guarantee gets a new name.

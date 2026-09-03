# MCL v1.0 scope

**Status:** Governance decision record. Normative for what the v1.0 release
claims, not for how anything is encoded.
**Revision:** 0.1
**Date:** 2026-09-03

---

## 1. Why this document exists, and what it is allowed to do

MCL spans eight repositories. Without one authoritative statement of what
"MCL v1.0" covers, the tag would be read as a claim about all of them, and the
weakest corner would silently define the strength of the whole.

This document exists to make that impossible. For every area it records exactly
one disposition, and the release is judged against these entries rather than
against what any README, research note or working implementation happens to say.

**v1.0 does not need to stabilise everything. It needs to be completely
unambiguous about what is Stable.** That is the entire purpose here.

This document decides *scope*. It does not decide bytes, and it cannot promote
anything by itself: the promotion gates in
[`ARCHITECTURE_CHARTER.md`](ARCHITECTURE_CHARTER.md) §6 still apply to every
entry marked Stable, including the requirement for two independent
implementations before Interoperability Candidate.

## 2. Disposition vocabulary

The charter's maturity ladder (§5) describes how a *specification* matures. This
table describes what the *v1.0 release* claims about each area, using four
dispositions that map onto it:

| Disposition | Meaning in the v1.0 release |
|---|---|
| **Stable** | Frozen. One unambiguous meaning, one authoritative specification, machine-readable assignments, positive and negative vectors, deterministic failure behaviour, and independent interoperability evidence. Bytes may not change without a new major version. |
| **Candidate** | Specified and implemented well enough for an independent implementation to be written, but **not** claimed independently interoperable. May change before it is ever called Stable. |
| **Experimental** | Exists, works, is useful, and is explicitly not a basis for cross-vendor interoperability. Values come from Experimental Use ranges. |
| **Deferred** | Deliberately not in v1.0. Recorded here so its absence is a decision rather than an oversight. |

A reader may rely on Stable. A reader may implement Candidate at their own risk.
A reader must not build cross-vendor behaviour on Experimental.

## 3. The disposition table

### 3.1 Core

| Area | Disposition | Note |
|---|---|---|
| Architecture charter and its invariants | **Stable** | The constitutional distinctions are the point of the project. |
| Conformance model (C0–C6) and evidence ladder (E0–E6) | **Stable** | |
| Registry policy and allocation procedure | **Stable** | Requires §5.2 below to be completed first. |
| Shared primitives: length, duration, confidence | **Stable** for the primitives the Stable objects use | Primitives used only by Candidate objects stay Candidate. |
| Tier-0 semantic code registry | **Stable** for the Stable subset in §3.2 | Codes for Candidate objects remain assigned but Candidate. |
| Tier-1 / Tier-2 richer semantics | **Deferred** | No layouts exist. Nothing is lost by saying so. |

### 3.2 The Stable Tier-0 object subset

**This is the most consequential entry in this document.** Seven object layouts
are implemented. Implementation is not the test; the test is whether two
unrelated vendors would read every field identically.

| Object | Disposition | Why |
|---|---|---|
| `PRESENCE` | **Stable** | The first-contact announcement. Nothing else in the protocol works without it. The duration encoding and the `capability_tag` rename (§4.2) are closed; `machine_class` is subject to a necessity audit recommending removal from the major-1 body (§5.1). |
| `TRANSPORT_OFFER` | **Stable** | Migration is proven over real radios and is the property that makes MCL a contact layer rather than a message format. Requires the duration encoding and Stable profile identifiers. |
| `TRANSPORT_ACCEPT` | **Stable** | The other half of the same exchange. Without it two implementations cannot complete a migration. |
| `HAZARD` | **Candidate** | `hazard_class` has no cross-vendor vocabulary; `severity` and `confidence` have ranges but no calibration. Keeps its v0 layout, coordinates included; §4.1 governs the Stable surface only and does not reach a Candidate object. Layout is frozen-quality; **meaning is not**. |
| `REQUEST` | **Candidate** | `request_class` has no vocabulary. Keeps its v0 layout, coordinates included, for the same reason as `HAZARD`. |
| `AUTHORITY_CLAIM` | **Candidate** | `authority_class` has no vocabulary and `jurisdiction` has no settled *namespace* — the registry cannot yet say whether it names a legal jurisdiction, a site, an operator or a fleet. Those are not interchangeable. |
| `DEGRADED_STATE` | **Candidate** | `affected_capability` has no namespace; `health` has no calibration. |

**What this means in one sentence:** MCL v1.0 stabilises *first contact and
contact continuity*. It does not stabilise the *safety and coordination
vocabulary*, because that vocabulary does not exist yet and inventing it alone
would be inventing it wrongly.

This is a defensible v1 and an honest one. The four Candidate objects keep their
layouts, their codes, their vectors and their tests; what they do not get is a
claim that two unrelated OEMs would act on them the same way. Closing a
cross-vendor hazard taxonomy is a domain-standards effort with domain experts in
the room, and it must not be done as a side effect of cutting a release.

> **Flagged for owner review.** Everything else in this document follows the
> reviewed advice or a settled decision. This entry is the one place where the
> scope could reasonably be drawn differently — a larger Stable set is possible
> if the four vocabularies are closed first, at the cost of putting a
> standards-committee-shaped problem on the v1 critical path.

### 3.3 Wire

| Area | Disposition | Note |
|---|---|---|
| Common header | **Stable** at major 1 | Major 0 is reserved for pre-standard work by the project's own version policy; publishing Stable on major 0 would contradict it. |
| Stable object body layouts | **Stable** at major 1 | The three objects in §3.2 only. |
| Canonical encoding rules: padding, signed representation, size limits | **Stable** | |
| Unknown-critical-extension behaviour | **Stable** | |
| Version rejection rules | **Stable** | |
| Extension envelope | **Stable** | The mechanism. See §5.2 for the registry that must accompany it. |
| Assigned Stable extension IDs | **None in v1.0** | Zero Stable extensions is a correct outcome. The mechanism and its governance must be ready; the table may be empty. |
| Context compression / delta encoding | **Deferred** | No codec exists. Building negotiation controls for a format that does not exist would be control machinery around nothing. |

### 3.4 Link

| Area | Disposition | Note |
|---|---|---|
| Link frame v0 canonical layout | **Stable** at major 1 | |
| Contact lifecycle and ownership model | **Stable** | |
| Migration: offer / accept / challenge / response / commit / confirm | **Stable** | E4 evidence over real radios, 104 migrations, both media live. |
| Idempotence and retransmission rules | **Stable** | |
| `session_ref` persistence across migration | **Stable** | |
| Frame classes | **Stable per class**, dispositioned individually in §5.3 | No class may be accepted by a Stable decoder while its semantics are merely implied. |
| Minimum capability / version negotiation | **Stable**, small and deterministic | §5.4. A specification that says peers negotiate X while no interoperable way to negotiate X exists is the one outcome that cannot survive. |
| Context negotiation controls | **Deferred** | Follows context compression. |
| Cryptographic contact binding | **Deferred** | §4.4. |

### 3.5 Transport bindings

| Binding | Disposition | Note |
|---|---|---|
| IP datagram carriage | **Stable** | Carriage only. No globally reserved port — see §4.3. |
| IP stream carriage | **Experimental** | |
| Autonomous IP peer discovery | **Deferred** to a separate profile | §4.3. |
| BLE GATT connected profile | **Stable** | Service and characteristic UUIDs, fragmentation framing, reassembly limits, MTU assumptions and malformed-fragment behaviour all freeze together. E4 evidence exists. |
| BLE connectionless advertising profile | **Experimental** | |
| AP (acoustic) | **Experimental** | E3/E4 physical evidence is real; AP-B0 is unselected, so physical profile conformance is not achieved. The interoperability layer must not wait for a PHY. |
| UWB | **Experimental** | No UWB hardware has ever been exercised. The registry correctly assigns no profile. |

### 3.6 SDK

| Area | Disposition | Note |
|---|---|---|
| Public C API for the Stable protocol surface | **Stable** | |
| Transport-aware TX/RX, three-way TX outcome, quiescence | **Stable** | |
| Caller-owned memory, freestanding C99, no heap | **Stable** | Implementation contract. |
| One contact per node, several nodes for several contacts | **Stable** as the documented model | Requires isolation evidence — §5.5. |
| Installable package with exported targets | **Required for v1.0** | Not a protocol property; a release property. |
| API/ABI promise | **Source compatibility only** | §4.5. |

### 3.7 Security

| Area | Disposition |
|---|---|
| Statement that MCL provides no confidentiality, no peer authentication and no cryptographic continuity | **Stable** — and it must stay conspicuous |
| Optional security profile mechanism | **Deferred** |
| Public vulnerability disclosure process for the project | **Required for v1.0** — §5.7 |

## 4. Decisions recorded

Each of these was open and is now closed. They are recorded here with their
reasoning so that a future reader can see what was decided rather than
rediscovering the argument.

### 4.1 Coordinates leave Stable Tier-0

**Decision:** `x`, `y`, `z` are removed from the Stable Tier-0 object bodies. A
spatial extension carrying an explicit frame declaration is the declared future
path and remains Experimental until a real requirement arrives.

**Reasoning:** MCL's premise is first contact between machines with no prior
relationship. Such machines share no origin, no axes and no quantization *by
construction*. A 12-bit signed `x` currently means plus or minus 2047 of
something, measured from somewhere. Being decodable with no prior shared state is
Tier-0's defining property, and a coordinate that needs an external frame is not
that.

The alternative — keeping the fields with a permanent "MUST NOT act on these"
rule — ships a Stable field that nobody is allowed to use, which is an invitation
to use it anyway. A hazard placed at the wrong origin is worse than one never
reported.

**Cost, stated plainly:** `HAZARD` is Candidate for v1 and keeps its v0 layout,
coordinates included (§3). This decision governs the *Stable* surface, so its
cost is paid later: if and when `HAZARD` is promoted, it will be able to say what
kind of hazard, how bad, how confident, how big and for how long — but not
*where*. That is what first contact can honestly support without a shared frame.
The registry entry for `x, y, z` records the decision on a scope axis separate
from its meaning status, because descoping a field does not settle what it
means.

### 4.2 `capability_digest` becomes `capability_tag`

**Decision:** rename, and specify it as a sender-controlled opaque revision
token. Normative semantics:

```text
capability_tag: 24-bit sender-controlled opaque capability revision token.

The sender MUST change capability_tag when the set or meaning of
capabilities it advertises for the current contact changes.

A receiver MUST scope the tag to the advertising source/contact.
It MUST NOT compare tags from different peers as capability identities.

The tag provides no authenticity, integrity, uniqueness, or
cryptographic collision resistance.

A receiver MAY use equality only as a cache/renegotiation hint.
```

No randomness and no hashing are required; incrementing, or any other
sender-defined mechanism, is conforming.

**Reasoning:** "digest" asserts that equal values imply equal capabilities.
Nothing provides that property, and charter §2.11 forbids naming a mechanism for
a property it lacks. Defining a real digest would require a canonical capability
serialisation, an algorithm with its own versioning, and collision semantics for
a 24-bit space whose birthday bound is around 4096 distinct capability sets —
unnecessary machinery for what `PRESENCE` actually needs.

`capability_revision` was considered and rejected in favour of `capability_tag`,
which does not imply monotonicity.

### 4.3 No globally reserved MCL UDP port

**Decision:** the Stable IP datagram profile defines **carriage** — one Link
frame per UDP datagram, exact framing and error behaviour — and defines no
globally reserved port. The endpoint is supplied or resolved externally. Port
49913 is retained as an experimental reference-harness default, explicitly not an
assigned MCL protocol value and not required for conformance.

Autonomous discovery of an unknown MCL peer directly over IP is **deferred to a
separate profile**.

**Reasoning:** a cross-OEM Stable standard must not effectively say "everyone
defaults to this unregistered port". Configurability does not rescue it, because
two strangers still need to know *which* configurable value the other chose — so
a configurable default solves nothing that a fixed default did not, while still
letting an experiment port fossilise into the protocol.

Separating carriage from discovery is what makes this clean. In the normal case
the IP endpoint arrives through an existing MCL contact, in a `TRANSPORT_OFFER`,
so Stable IP datagram needs **no autonomous discovery mechanism at all**. Both
future routes stay open without a wire change: pursue a real assignment once
adoption justifies it, or standardise discovery separately.

### 4.4 Cryptography is deferred, and stays conspicuous

**Decision:** v1.0 ships with no confidentiality, no peer authentication and no
cryptographic continuity, and says so prominently.

This is legitimate provided the statement is unmissable. It is not a gap being
glossed; it is a scope boundary the charter already draws, and
`SECURITY.md` already states it well.

### 4.5 v1.0 promises source compatibility, not ABI

**Decision:** the v1.0 tag promises **C source/API compatibility** within the 1.x
line. No binary ABI stability is promised.

**Reasoning:** the public structures are caller-owned and deliberately visible,
which is what makes the no-heap model work; that same visibility makes ABI
promises expensive and easy to break by accident. SemVer 1.0.0 defines the first
public API, so the promise must be explicit before the tag is cut — and a promise
nobody intended is worse than a narrower one stated clearly.

### 4.6 One duration encoding for `ttl` and `validity`

**Decision:** `ttl` and `validity` share one deterministic 8-bit
exponent/mantissa duration encoding.

**Reasoning:** linear seconds in 8 bits gives about four minutes, which is too
short for `PRESENCE` and needlessly coarse elsewhere. Two duration fields with
different scales in one protocol is a defect waiting to be written.

### 4.7 A Stable major carries only Stable semantics

**Decision:** Wire major 1 carries only semantic objects whose body contract is
part of the major-1 Stable set. Candidate objects continue to be carried under
the experimental major. A major-1 decoder receiving a category/opcode that is
not assigned in the major-1 Stable set MUST reject it.

```text
Wire major 0     evolving bytes: Candidate and research objects
Wire major 1     frozen bytes: PRESENCE, TRANSPORT_OFFER, TRANSPORT_ACCEPT
```

**The gap this closes.** §3.2 disposes four objects as Candidate while §3.3
makes the Stable layouts major 1, and nothing said which major the Candidate
bytes travel under. Left unanswered, the natural reading is that a major-1 frame
may carry `HAZARD`, because its layout exists and its vectors pass. But `HAZARD`
is Candidate precisely so that it may still change. If its body changed without
a major bump, two decoders both correctly implementing "major 1" would read the
same category/opcode under different layouts. That is the exact failure a major
version exists to make impossible, and it would be introduced by silence rather
than by decision.

**Why not the alternative.** Carrying Candidate objects inside major 1 under a
code range documented as unstable was considered and rejected. It makes the
major version insufficient to determine whether a layout can be trusted — a
decoder would have to consult a range table to know what its own version
guarantees. The project already draws this line for extension IDs, where
Experimental Use values are explicitly not globally interoperable assignments.
Semantic codes get the same treatment for the same reason.

**Consequence, stated because implementers will hit it.** A node that does
first contact under major 1 and also reports hazards emits objects of two
different majors, and this is permitted: the major is a per-object header field,
not a per-link property. What a peer may *not* do is infer support for one major
from having seen the other. This is not a limitation of the split; it is the
honest statement that MCL v1.0 stabilised first contact and did not stabilise
the safety vocabulary, made visible in the bytes instead of only in prose.

**Status:** the codec currently accepts only the experimental major and rejects
every other value, so no implementation change is required today. The rule must
be written into the Wire specification and enforced by the decoder **before**
major-1 vectors are generated (§5.8). Freezing vectors first would fix the
ambiguity into the artifacts that define the release.

## 5. Work this scope requires

Everything below is a consequence of the dispositions above. This is the v1
critical path, in order.

### 5.1 Close the Stable Tier-0 meanings
Only the fields used by the three Stable objects must close. The Candidate
objects' vocabularies explicitly need not.

| Field | State |
|---|---|
| shared `ttl` / `validity` duration encoding | **done** — `mcl-wire/spec/duration-v0.1.md` |
| `capability_tag` rename and semantics (§4.2) | **done** — no bytes changed |
| `machine_class` vocabulary | **superseded by an audit finding** — see below |
| Stable `profile_id` semantics | open, and coupled to §5.6 |

`machine_class` was listed here as "write the vocabulary". A necessity audit was
run first and recommends against writing one:
[`MACHINE_CLASS_AUDIT.md`](MACHINE_CLASS_AUDIT.md). No code in any of the eight
repositories consumes the value — all 21 references are constant writes, codec
plumbing, or round-trip asserts — the research corpus contains three `PRESENCE`
messages carrying two distinct classes, and both specifications that mention the
field already mark it optional. The recommendation is to remove it from major-1
`PRESENCE` (v0 untouched), on the same reasoning §4.1 used to remove
coordinates: a Stable field nobody may act on is an invitation to act on it.

**Owner decision required.** Until it is taken, no `machine_class` vocabulary is
written, and §5.1 is blocked only on `profile_id`.

### 5.2 Registry governance and the extension registry
Every Stable registry gets a named change controller, an application procedure,
review criteria, a promotion procedure, a deprecation procedure with permanent
tombstones, and a permanent specification reference for every Stable assignment.
Create the extension-ID registry and its allocation policy; it may be empty.
`REGISTRY_POLICY.md` still describes the extension envelope as unfrozen and must
be reconciled with Wire, which has since implemented and specified it.

### 5.3 Disposition every Link frame class
**Done** — `mcl-link/spec/link-class-disposition-v1.md`.

Seven Stable, one reserved, two conditional. `CONTACT`, `DATA`, `ACK`, `NACK`,
`HANDOFF` and `CLOSE` are Stable with contracts that already exist and are
tested; `KEEPALIVE` is Stable but optional to emit; `ADAPT` stays reserved and
refused, as a permanent tombstone rather than a recycled value.

`CAPABILITY` and `NEGOTIATION` are the only open entries, and both branches are
decided in advance. Today they are accepted and handed to the Wire Tier-0
decoder while no `CAPABILITY` semantic object exists — the class has a transport
but no contract, which is precisely what §3.4 forbids a Stable decoder to
accept. Either §5.4 lands first and they carry its control payloads, or they are
**reserved and refused** at Link major 1 exactly as `ADAPT` is. Shipping them as
they stand is not an option, and committing to the fallback now keeps that
choice from being made under release pressure.

### 5.4 Minimum capability and version negotiation
A small deterministic exchange covering Wire major, transport profile, maximum
frame size and an explicit feature set. Small enough to be obviously correct.

**Do not reuse the context-negotiation draft.** `CONTEXT_OFFER`/`CONTEXT_ACCEPT`
is a Research Draft with unfrozen field widths, and it negotiates a context
compression codec that §3.3 defers and that does not exist. Building this
mechanism out of that one would import control machinery for a feature v1 does
not ship. No `context_id`, no ruleset digest.

**Encode the feature set as an ordinary bitmask.** A compact class-interval
encoding — the compressed-subset idea from the semantic-grammar research — was
evaluated and loses at MCL's scale. Cost model
`ceil(log2(n+1)) + 2·runs·ceil(log2 n)` against a flat bitmap, exhaustively over
every subset:

| Capability universe | Bitmap | Interval mean | Result |
|---|---:|---:|---|
| n = 4 (today's transport families) | 4 bits | 8.00 bits | 2.0× worse |
| n = 8 | 8 bits | 17.50 bits | 2.2× worse |

Both rows are exhaustive over all 2^n subsets, so they are exact rather than
sampled. Interval coding only begins to win when the universe reaches roughly
16–32 members *and* real capability sets cluster tightly under one shared
ordering. Under a synthetic domain shift — the same code ordering, sets drawn
from a different clustering — the interval cost rose above the bitmap at both
n = 16 and n = 32 while the bitmap stayed invariant by construction. A code that
gets worse when it meets a vendor it was not fitted to is the wrong code for a
cross-vendor first-contact standard.

Reproduce with `mcl-core/research/capability-coding/interval_vs_bitmap.py`.
This forecloses the option for v1; it does not forbid revisiting it if MCL ever
accumulates hundreds of real cross-vendor capability sets to fit against, with
vendors held out.

### 5.5 Multi-contact isolation campaign
The architecture says "instantiate several nodes". That needs evidence, not
assertion: several simultaneous contacts on one bearer, the same `migration_ref`
in different contacts, wrong `session_ref`, wrong `destination_ref`, a candidate
endpoint swapped between contacts, one contact migrating while another sends
data, glare and the exact tie, a delayed frame from a dead contact, and a new
contact reusing an old reference.

### 5.6 Freeze the two Stable transport profiles
IP datagram carriage per §4.3, and the BLE GATT profile as one frozen unit.

**A dependency loop has to be broken here, and the order matters.** Both
transport profile registries state that an experimental profile may be proposed
for a Standards Action assignment *only once a second independent implementation
has interoperated with it* (`mcl-ip/registries/ip-profiles-v0.1.json`,
`mcl-ble/registries/ble-profiles-v0.1.json`). But §5.8 puts the independent
implementation after profile freezing. Read literally:

```text
Stable profile ID  ->  needed before independent implementation
independent impl   ->  needed before Stable profile assignment
```

**Resolution — separate the specification from the promotion.** They are
different acts and only the second one needs the interoperability evidence:

```text
1. Write the normative profile specification, complete and frozen in content,
   published at Candidate. Parameters fixed BY THE SPECIFICATION, not by
   whatever the reference implementation happens to do.
2. Interoperate the independent implementation against exactly that
   specification, using the existing Experimental Use profile value.
3. That interoperability satisfies the registries' promotion gate.
4. Perform the Standards Action assignment of the final Stable profile value.
5. Re-run the final C4/C5 cases with the final assigned bytes on the wire.
```

Step 5 is not ceremony. The profile identifier travels in
`TRANSPORT_OFFER`/`TRANSPORT_ACCEPT`, so changing it changes the bytes that were
tested; evidence gathered under the experimental value is evidence about the
experimental value. If the governance model later permits reserving a Candidate
value inside the Standards Action range, steps 2–5 collapse and the final bytes
are exercised from the start — that is the better outcome and should be
preferred if available.

**What must not happen:** relabelling the existing experimental profile value as
Stable. `REGISTRY_POLICY.md` is explicit that Experimental Use values are not
globally interoperable assignments, and renaming one does not make it one.

### 5.7 Release-shaped work
Installable SDK package and an external-consumer build test; public vulnerability
disclosure process with commitments the project can actually meet; legal and IPR
closure; documentation status promotion and a specification index; a feature
traceability ledger; and a `releases/v1.0.0/` bundle that does not mutate
historical evidence to look current.

### 5.8 The gates that cannot be skipped
Cut Wire major 1 and Link major 1 only after the meanings close. Generate a new
immutable major-1 vector family rather than editing the v0 vectors. Then an
independent clean-room implementation, and C4/C5 cross-implementation testing.
The charter does not permit going from private research to Stable without
passing Candidate and Interoperability Candidate.

## 6. The go/no-go rule

> MCL v1.0.0 ships only when every feature called **Stable** has one unambiguous
> meaning, one authoritative specification, one canonical representation where
> applicable, deterministic failure behaviour, machine-readable assignments,
> reference tests, and independent interoperability evidence. Anything not
> meeting that threshold is explicitly Candidate, Experimental or Deferred.

This rule cuts both ways on purpose. It stops AP, UWB, cryptography, context
compression and the richer semantics from artificially blocking a release they
are not part of. It also stops the family being called "1.0" while a Stable
profile, a Core meaning or interoperability itself still depends on whatever the
reference C implementation happens to do.

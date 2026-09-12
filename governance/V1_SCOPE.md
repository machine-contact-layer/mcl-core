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
| `PRESENCE` | **Stable** | The first-contact announcement. Nothing else in the protocol works without it. The duration encoding and the `capability_tag` rename (§4.2) are closed; `machine_class` is **removed from the major-1 body** (§4.8), so the Stable `PRESENCE` is 10 bytes. |
| `TRANSPORT_OFFER` | **Stable** | Migration is proven over real radios and is the property that makes MCL a contact layer rather than a message format. Requires the duration encoding and Stable profile identifiers. |
| `TRANSPORT_ACCEPT` | **Stable** | The other half of the same exchange. Without it two implementations cannot complete a migration. |
| `HAZARD` | **Candidate** | `hazard_class` has no cross-vendor vocabulary; `severity` and `confidence` have ranges but no calibration. Keeps its v0 layout, coordinates included; §4.1 governs the Stable surface only and does not reach a Candidate object. Layout is frozen-quality; **meaning is not**. |
| `REQUEST` | **Candidate** | `request_class` has no vocabulary. Keeps its v0 layout, coordinates included, for the same reason as `HAZARD`. |
| `AUTHORITY_CLAIM` | **Candidate** | `authority_class` has no vocabulary and `jurisdiction` has no settled *namespace* — the registry cannot yet say whether it names a legal jurisdiction, a site, an operator or a fleet. Those are not interchangeable. |
| `DEGRADED_STATE` | **Candidate** | `affected_capability` has no namespace; `health` has no calibration. |

**What this means in one sentence:** MCL v1.0 stabilises *contact signalling and
contact continuity*, whether peers already share a bearer or use the optional
Stranger-Contact ingress. It does not stabilise the *safety and coordination
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
| Extension envelope | **Candidate** | Implemented and specified, but its only specification remains Research Draft and it has no independent decoder. It is not part of the Stable major-1 contract in v1.0. |
| Assigned Stable extension IDs | **None in v1.0** | No Stable extension mechanism or assignment ships in v1.0. Experimental/Candidate extension work remains available at major 0. |
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

**Reasoning:** The Stable Tier-0 surface must remain interpretable by any
conforming peer, including a Stranger-Contact peer with no agreed spatial
frame. Such peers share no origin, axes or quantization *by construction*. A
12-bit signed `x` currently means plus or minus 2047 of something, measured
from somewhere. A coordinate that needs an external frame is therefore not
part of the Stable common surface.

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

### 4.8 `machine_class` leaves the Stable body

**Decision:** Wire major-1 `PRESENCE` does not carry `machine_class`. 11 bytes
become 10. Major 0 keeps the field permanently, along with its published vectors
and the E3/E4 over-air evidence recorded against it.

**Decided from evidence, not preference.** `MACHINE_CLASS_AUDIT.md` asked what
Stable-v1 decision becomes impossible without the field. The answer was none:

- All 21 references across the eight repositories are constant writes, codec
  plumbing, or round-trip asserts. Nothing dispatches, filters or negotiates on
  the value. Five different constants are in use with no shared meaning, because
  none exists.
- The research corpus contains three `PRESENCE` messages carrying two distinct
  classes — no basis for a 256-value cross-vendor taxonomy.
- Both specifications that mention the field already wrote it `machine_class?`,
  optional, independently and before the audit.
- A flat 8-bit code over orthogonal axes (mobile/stationary,
  ground/aerial/surface/underwater, autonomous/remote/worn) encodes their
  cross-product, which grows every time a new axis is recognised. A
  first-contact field that must be updated to meet a new kind of machine defeats
  the purpose of first contact.

**This is §4.1 applied consistently.** That decision rejected keeping a Stable
field under a permanent "MUST NOT act on this" rule, because *a Stable field
nobody may act on is an invitation to act on it*. A `machine_class` with no
assigned values is precisely that field, and the argument is stronger here, not
weaker: a Candidate object can still change, a Stable one cannot.

**No replacement taxonomy is defined.** Machine typing moves to capability
metadata exchanged after contact, where a vocabulary can be domain-scoped and
versioned instead of universal and frozen. Mature interoperability standards
layer domain identity over common infrastructure rather than enumerating it in
the base; MCL does the same.

**Propagated to:** `mcl-wire/spec/tier0-layout-v0.2.md` §4.1 (both layouts),
`mcl_wire_tier0_encoded_size_at_major`, `mcl-wire/tests/test_major_rule.c`, and
the field registry's `v1_disposition`. The registry `status` deliberately stays
`provisional`: the meaning was never settled, and deleting a field does not
settle it.

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
| `machine_class` vocabulary | **resolved: removed from major-1 PRESENCE** — §4.8 |
| Stable `profile_id` semantics | open, and coupled to §5.6 |

`machine_class` was listed here as "write the vocabulary". A necessity audit was
run first, found no consumer, and the field was **removed from the major-1
`PRESENCE` body** rather than given a taxonomy. Decision and reasoning in §4.8;
evidence in [`MACHINE_CLASS_AUDIT.md`](MACHINE_CLASS_AUDIT.md).

§5.1 is therefore closed except for `profile_id`, which §5.6 carries.

### 5.2 Registry governance and the extension registry
Every Stable registry gets a named change controller, an application procedure,
review criteria, a promotion procedure, a deprecation procedure with permanent
tombstones, and a permanent specification reference for every Stable assignment.
The extension registry governs Candidate/Experimental extension work in v1.0.
No extension bytes or identifiers are claimed Stable until a separately
promoted specification and independent implementation exist.

### 5.3 Disposition every Link frame class
**Done** — `mcl-link/spec/link-class-disposition-v1.md`.

Nine Stable, one reserved. `CONTACT`, `DATA`, `ACK`, `NACK`,
`HANDOFF` and `CLOSE` are Stable with contracts that already exist and are
tested; `KEEPALIVE` is Stable but optional to emit; `ADAPT` stays reserved and
refused, as a permanent tombstone rather than a recycled value.

`CAPABILITY` and `NEGOTIATION` were the two conditional entries: they were
accepted and handed to the Wire Tier-0 decoder while no `CAPABILITY` semantic
object exists — a transport with no contract, which is precisely what §3.4
forbids a Stable decoder to accept. **§5.4 has since landed**, so they now carry
its control payloads and are Stable. The SDK no longer passes them to the Tier-0
decoder. The fallback — reserved and refused, as `ADAPT` is — was committed in
advance and did not need to be taken.

**Nine Stable, one reserved, none excluded.**

### 5.4 Minimum capability and version negotiation
**Done** — `mcl-link/spec/link-negotiation-v1.md`, `mcl-link/src/negotiation.c`,
`mcl-link/tests/test_negotiation.c` (4241 checks, 0 failed).

`CAPABILITY` carries 9 bytes, `NEGOTIATION` 7. Together they settle Wire major,
Link major, maximum frame size and a feature set. Transport and profile
selection is deliberately **not** here — `TRANSPORT_OFFER`/`TRANSPORT_ACCEPT`
already carry `transport_id` and `profile_id`, and a second way to select a
transport would be a second vocabulary for one concept.

**The design property:** the selection function is symmetric — `min` and `&`
are commutative, and the highest set bit of `A & B` does not depend on operand
order. Both peers compute the same answer from the same two inputs, so **glare
needs no tiebreaker**, unlike migration where two offers propose different
transports and cannot both proceed. Verified exhaustively over 675 ordered
capability pairs: 0 disagreements.

**Unknown feature bits fail closed by construction.** The outcome is
`local.features & peer.features`, so a bit this implementation does not know is
a bit it did not set, and the `AND` clears it. There is no unknown-feature rule
to get wrong. Zero feature bits are assigned in v1 — the mechanism ships, the
table is empty, exactly as the extension-ID registry does.

The negotiated frame floor is **derived** from
`FRAME_MIN_SIZE + FRAME_MAX_OPTIONAL + HANDOFF_CONTROL_MAX_SIZE` and asserted by
test, never written as a literal: below it a link cannot carry MCL's own
migration frames, and a negotiation that produced one would succeed and then
fail at the worst moment.

**Stated limit:** the check without the peer's advertisement is weaker — it can
verify a selection is legal locally, not that the peer chose the highest common
major. Nothing here is authenticated, so this is **not** downgrade protection
and §7 of the specification says so rather than letting a reader infer it.

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
**Done** — `mcl-sdk/tests/test_multi_contact.c` (50 checks, 0 failed) and
`mcl-sdk/tests/MULTI_CONTACT_MUTATIONS.md`.

All nine cases covered. The harness is a **broadcast bus**: every frame is
offered to every node, so isolation has to come from the protocol rather than
from the harness routing frames to their intended recipient.

**Mutation-tested, and it found a gap.** The campaign passed on its first run,
which is when a campaign is most likely to be testing itself, so each mechanism
was deliberately broken in turn. Removing the `migration_ref` check on
`mcl_contact_agree`'s *retransmission* branch **escaped** — the campaign only
reached the copy on the `OFFERED` path. That branch is the more dangerous one:
it decides whether a delayed acceptance belonging to another contact is mistaken
for a retransmission of this one, at a contact already validating. The case was
extended to reach it, and re-running the mutation now fails the campaign.

**Not claimed:** this is host-side software conformance. Several real peers on
one radio is a separate experiment, and no physical evidence is asserted. The E4
dual-transport evidence covers one contact across two media, a different
property.

### 5.6 Freeze the two Stable transport profiles
**Specifications done, at Candidate.** Promotion to Stable is steps 2–5 below
and needs the independent implementation (§5.8).

- `mcl-ip/spec/ip-datagram-profile-v1.md` — carriage only per §4.3, no port
  assigned, discovery deferred to a separate profile.
- `mcl-ble/spec/ble-gatt-profile-v1.md` — service, two directional
  characteristics, fragmentation, the 23-byte MTU floor, the discard table.

Writing them closed the homeless `frame_check` requirement that
`link-class-disposition-v1.md` §6 recorded: it is now **required by each
profile** and enforced, for different reasons. IP because the UDP checksum is
optional over IPv4 and weak; BLE because a frame crosses up to 56 PDUs that are
each individually correct, so a mis-spliced *fragment* corrupts a frame that no
link-layer CRC can catch. Neither change contradicts recorded evidence — both
over-air harnesses already set the flag on every frame.

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

**All five steps are complete as of 2026-09-04.**

| Step | What closed it |
|---|---|
| 1 | Both profile specifications, complete, published at Candidate. |
| 2 | `conformance/independent/test_profiles_c5.py` interoperated on the Experimental Use value 192. |
| 3 | The registries' promotion gate, satisfied by step 2 and by the parameters being fixed by document rather than by code. |
| 4 | `IP-DATAGRAM = 1` and `BLE-GATT = 1`, MCL Standards Action, recorded in each registry with the five §2 requirements answered individually. |
| 5 | C4 (803 checks) and C5 (108 checks) re-run on the assigned bytes; the major-1 vector family regenerated to carry them. |

Both specifications are now **Stable**.

**The transport identifiers they are scoped to were frozen on the same
evidence, and had to be.** `profile_id` is transport-scoped: `IP-DATAGRAM = 1`
means nothing unless `transport_id = 2` is itself fixed, because profile 1 under
another transport is an unrelated assignment. A Stable profile hanging off a
provisional identifier is an incoherent pair, and for one day this project
shipped exactly that — the compatibility matrix called transports 2 and 3
Stable while `mcl-link/registries/transport-ids-v0.1.json` still marked all four
provisional. The registry was the authoritative source, so the registry is what
changed:

| Value | Disposition |
|---|---|
| `transport_id = 2` (`MCL_IP`) | **Stable.** MCL Standards Action, 2026-09-04. `mcl-ip/spec/ip-datagram-profile-v1.md`, a Stable document, names the value normatively. |
| `transport_id = 3` (`MCL_BLE`) | **Stable.** Same date, same treatment, `mcl-ble/spec/ble-gatt-profile-v1.md`. |
| `transport_id = 1` (`MCL_AP`), `= 4` (`MCL_UWB`) | **Provisional.** AP-B0 is unselected and no UWB hardware has been run, so neither has the evidence the other two have. Assigned for use; not frozen. |

No byte changed: transports 2 and 3 were already the values under test in C4 and
C5. What changed is that the registry now says they are frozen, and that saying
so costs something — `validate_transport_registry.c` refuses a row marked
`stable` that cites no normative specification or cites one that is not itself
Stable, and `test_profiles_c5.py` fails if either transport stops being stable
or if AP or UWB is quietly promoted alongside them. Both guards were verified by
making the edits and watching them fail, not by assertion.

Step 5 was not ceremony. The profile identifier travels in
`TRANSPORT_OFFER`/`TRANSPORT_ACCEPT`, so changing it changed the bytes that were
tested; evidence gathered under the experimental value is evidence about the
experimental value, and it is retained as exactly that rather than being
re-labelled as evidence about profile 1.

**What did not happen, and must not:** relabelling the experimental value as
Stable. 192 remains Experimental Use permanently in both registries, and C5
asserts that against the registry files themselves — the check fails the day
anybody edits that status. Promotion assigned a *new* value in the Standards
Action range, which is what `REGISTRY_POLICY.md` requires.

**What this assignment rests on, stated plainly.** The independent
implementation in step 2 is independent *of the reference code* — different
language, no shared source, no shared build — and it found three real
specification-reading defects. It was written by the same author. So the
assignment rests on evidence that these documents can be implemented from the
text alone, and **not** on evidence that two organisations have interoperated.
§5.9 states what v1.0.0 therefore claims and does not claim.

### 5.7 Release-shaped work
Installable SDK package and an external-consumer build test; public vulnerability
disclosure process with commitments the project can actually meet; legal and IPR
closure; documentation status promotion and a specification index; a feature
traceability ledger; and a `releases/v1.0.0/` bundle that does not mutate
historical evidence to look current.

### 5.8 The gates that cannot be skipped
Cut Wire major 1 and Link major 1 only after the meanings close. Generate a new
immutable major-1 vector family rather than editing the v0 vectors.

**The major-1 vectors MUST carry expected field values, not only `name`,
`length` and `hex`.** The clean-room implementation proved why: it decoded
`AUTHORITY_CLAIM` with an 8-bit `authority_class` and a 16-bit `jurisdiction`
instead of 6 and 12, and because the object also carries 6 bits of padding
*both* layouts consume exactly 14 bytes. Every length check, every "bytes
consumed" assertion and the published vector itself passed while every field
after `source_ref` was being misread. A vector that is a length and a hex string
cannot catch that; only comparing decoded values can. See
`mcl-core/conformance/independent/SPEC_GAPS.md`. Then an
independent clean-room implementation, and C4/C5 cross-implementation testing.
The charter does not permit going from private research to Stable without
passing Candidate and Interoperability Candidate.

### 5.9 What v1.0.0 claims about interoperability, and what it does not

The release gate was first written with three rows that require acts by people
outside this project: publish the repositories, have **someone else's**
implementation interoperate, and have third parties review the published
Candidate. Those rows describe how a standards body validates a specification.
This project is one maintainer with two laptops, a development board, two
speakers and two microphones, and it has no third parties yet — not because the
bar is unreasonable but because a bar that can only be cleared by people who do
not know the project exists cannot be cleared before publication.

**Decision.** v1.0.0 ships as a *functional first release* with its claim
boundary stated in the release itself, and review happens after publication
through the errata process in `GOVERNANCE.md` §6. That is the order in which
protocols are actually reviewed: publish something implementable, and let the
first implementer file the first defect.

**This narrows what the release claims. It does not lower a gate.** Every check
in `RELEASE_GATE_V1.md` still has to pass, and none was rewritten to be easier.
What changed is that the release states what its evidence supports instead of
claiming a validation nobody performed.

#### What v1.0 requires as interoperability evidence

Three parts, all internally achievable, all mandatory:

```text
(a) two implementations independent OF EACH OTHER'S CODE cross-decode,
    in both directions, including matching refusals            DONE
(b) over-air carriage between two physically distinct devices, measured in
    both directions, on real transports                        DONE
(c) the reference implementation, compiled by a DIFFERENT TOOLCHAIN for a
    DIFFERENT ARCHITECTURE, running on an embedded target, interoperating
    over a physical channel with the host implementation        DONE
```

| | Evidence |
|---|---|
| (a) | `conformance/independent/` — C4 803 checks, C5 108 checks, both directions, matching refusals. |
| (b) | IP `mcl-ip/evidence/e4-udp-2g4-20260902/` and `mcl-ip/evidence/e4-android-udp-20260904/`, BLE `mcl-ble/evidence/e4-ble-gatt-20260902/`, migration `mcl-sdk/evidence/e4-dual-transport-migration-20260903/`, acoustic `mcl-ap/experiments/003-band-informed-candidate/evidence/`. Three device families now, not two: an ESP32-S3, a Windows laptop and a commodity Android handset running a vendor build this project did not choose. |
| (c) | `mcl-ap/experiments/008-embedded-node/` — the DFR1154 builds a major-1 `PRESENCE` with `mcl-wire`, wraps it in a major-1 Link frame with `mcl-link`, modulates, emits, and in the other direction acquires, demodulates, verifies, decodes and reports field values with no host in the loop. Ten trials per cell: board→host 9/10 at 10 bytes and 2/10 at 24; host→board 6/10 and 7/10, decoded on the microcontroller. All four cells acquired 10/10. |

Each answers a different question, and none substitutes for another:

| | Question it answers |
|---|---|
| (a) | Can the specifications be implemented from the text, or only by reading the reference code? |
| (b) | Do the bytes survive a real medium between real devices, rather than a loopback? |
| (c) | Is the freestanding C99 claim true — does the stack run where there is no host, no heap and no libc, and does a machine there understand a machine here? |

(c) is not a second implementation and this document does not call it one. It
shares source with the reference. What it demonstrates is **portability and
end-to-end operation**: an ESP32-S3 encoding a Tier-0 object itself, modulating
it itself, and a host decoding it — and the reverse. That is the thesis of MCL
reduced to its smallest honest demonstration, and it is worth more to a first
release than a third review of the same documents.

Recovery rates of 2/10 to 9/10 are **not a usable link**, and the release does
not claim one. What (c) establishes is that the stack runs and that both ends
agree about bytes that crossed a room; the acoustic transport remains
Experimental and AP-B0 remains unselected. A link good enough to depend on is a
question for the AP profile work, not for whether v1.0 ships.

#### What v1.0.0 therefore does NOT claim

```text
NOT claimed: two ORGANISATIONS have interoperated
NOT claimed: anyone outside this project has implemented these specifications
NOT claimed: anyone outside this project has reviewed them
NOT claimed: the specifications are free of defects a fresh reader would find
```

The independent implementation in `conformance/independent/` shares no code, no
language and no build system with the reference C, and it found three real
specification-reading defects — which is precisely why the fourth line above is
written as it is. A reader who is not the author will find more. The errata
process exists for exactly that. Public external review is required before the
Stable v1.0.0 tag; later implementation reports may be tracked as v1.1 errata.

#### What would change the claim

One thing: an implementation built by someone else, interoperating. When that
happens it is recorded as evidence and the claim widens. Until then the release
says so in `ICS.md`, in `mcl-core/README.md`, and in the release manifest — in
the same words, so a reader cannot find a weaker version of the statement by
looking somewhere else.

### 5.10 The builder-interoperability floor

§5.9 answers "can these specifications be implemented from the text". It does
not answer a second question, which went unasked until `research/TWO_BUILDER_AUDIT.md`
put it plainly:

> Can two builders who never coordinate with each other build to the published
> MCL package and still be **guaranteed** a common first-contact path?

Today the answer is no, and not because of a defect in any binding. Transports
are individually optional, so a product implementing IP and AP and a product
implementing BLE and UWB are both fully conformant and share nothing. BLE
rendezvous advertising is conformant to omit. IP assigns no port and defers
discovery. The one bearer needing no prior arrangement is acoustic, and it is
Experimental. **The guaranteed intersection of two conformant v1 implementations
is empty.**

**Decision.** The floor is raised before v1.0.0 rather than documented as a
limitation. A release that says "bring your own prearranged bearer" would be
truthful and would not be the layer `README.md` describes.

#### The acceptance criterion

Two implementations receive only the MCL release, the same deployment profile,
and that deployment's trust anchors. They receive **no** peer address, port, MAC,
`source_ref`, `endpoint_token`, shared secret, manual pairing step, or hidden
test configuration. They are powered on in one another's presence and must
reach, unaided:

```text
mutual detection
    -> bootstrap acquisition
    -> PRESENCE exchanged
    -> a common richer bearer identified
    -> TRANSPORT_OFFER / TRANSPORT_ACCEPT
    -> candidate path validated
    -> contact migrated to that bearer
    -> authentication, where the deployment requires it
    -> security evidence surfaced separately from trust and authorisation
    -> local policy decides: continue on MCL, or hand off
```

A three-or-more machine variant must also pass, to establish that shared-air
contention does not collapse first contact into a reply storm.

**Contention interpretation clarified 2026-09-09.** The third participant
requires its own physical microphone/speaker path, canonical AP waveform and
rendezvous rules, independent clock/RNG/source reference, and actual shared-air
transmission and reception without peer-specific coordination. It need not
implement the continuation bearer. The selected DFR/Android pair must still
validate, undergo explicit policy admission and migrate. This does not qualify
Windows as a complete BLE port or its damaged speaker for transmitter diversity.

**Owner scope clarification, 2026-09-10.** The later three-cell stress matrix
is informative robustness work, not three additional release requirements.
The original invariant above remains the acceptance criterion. The retained
E0585224 run has three independently operating physical AP participants,
competing ACCEPTs, first-selection retention, no observed three-edge cycle,
and validated, policy-admitted DFR/Android migration. It satisfies this
bounded physical variant. Failed stress experiments remain retained; this is
not a guarantee of convergence in every hostile 120-second scenario.

#### What this changes

1. Interoperability is claimed **under a named conformance layer**, never as
   "implements MCL". A machine with no microphone may truthfully claim the
   foundation layer; it may not claim the stranger-contact layer. The layers are
   specified in `spec/conformance-profiles-v1.md`: **`MCL Base 1`** is complete
   and claimable now, **`MCL Stranger-Contact 1`** is normatively complete and,
   since `AP-BOOTSTRAP-1` landed on 2026-09-06, **claimable with a caveat** —
   the bootstrap profile is Candidate, and the claim carries that rather than
   sounding frozen — and
   **`MCL Secure-Stranger 1`** is a reserved name. The **deployment-profile
   schema now exists** — `spec/deployment-profile-v1.md`, with
   `tools/validate_deployment_profile.c`, a reference deployment and nine
   negative fixtures in the gates — so a deployment can guarantee *continuation*
   where no conformance layer honestly can. The mandatory rendezvous profile,
   the security carrier and the named security profile remain, in the dependency
   order of `research/TWO_BUILDER_AUDIT.md` §5.
   **Base 1 alone does not close this row.** It names the honest claim for the
   arranged-bearer case; the criterion is about strangers, so row 35 closes on
   Stranger-Contact 1.
2. This criterion is a **release gate**, not an aspiration. v1.0.0 is not tagged
   until it passes under a named conformance profile.
3. Nothing in §5.9 is weakened or withdrawn. (a), (b) and (c) remain required
   and remain satisfied; this is a fourth requirement they never covered,
   because they measure whether *these* specifications can be implemented, not
   whether two independent products are guaranteed to meet.
4. The acoustic bootstrap this requires carries no credentials and no sensitive
   identity material. First contact stays public and minimal; authentication
   happens after migration, on the richer bearer. That was always the intended
   architecture and it is what keeps the criterion affordable — a bare Ed25519
   signature does not fit in an acoustic frame, and under this design nothing
   asks it to.

#### Status

`DONE` for the original builder-interoperability floor under
MCL-REFERENCE-DEPLOYMENT-1 with the Candidate-profile caveat. Both BLE
orientations passed, and E0585224 satisfies the original three-machine
shared-air variant. See `../conformance/independent/20260910-private-rc/README.md`
and its executable receipt. The previously added per-cell stress requirement
is superseded by the owner scope clarification above. Public review and Stable
promotion remain separate; no negative run is erased.

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

"Independent interoperability evidence" in that rule means the three-part
requirement in §5.9 — (a) implementations independent of each other's code, (b)
over-air between distinct devices, (c) a different toolchain and architecture on
an embedded target. It does not mean organisational independence, and §5.9 says
so in the release rather than leaving a reader to assume the stronger reading.


### Bounded contention campaign receipt, 2026-09-10

The final traced campaign reached DFR/Android migration with Windows physically
present in three runs: E0585224, 46269E56 and 08810099. The first run includes
valid AP transmission/reception by all three and an ignored later Windows
ACCEPT. A board readiness-ordering defect found during this campaign was fixed
and exercised by the second run. These results supersede the earlier claim
that no three-device run migrated. They do not establish every requested
collision and third-party-traffic predicate; Row 35 remains ACTIVE. See
`../conformance/independent/20260909-contention-closure/README.md`
for the exact successful results, failed attempts and remaining limits.
No third complete BLE port is required by this interpretation.

The dated 2026-09-09 and earlier 2026-09-10 notes below are historical; the owner scope clarification and current Status above supersede their Row 35 verdict.

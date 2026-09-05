# The Two Independent Builders Test

Status: **Audit finding.** Not a specification, and it freezes nothing.

It records what two unrelated builders can and cannot achieve with the state of
the tree on 2026-09-05, classifies every point where the answer is "the builder
decides", and states the acceptance question that `V1_SCOPE.md` §5.10 now makes
a release gate.

## 1. The test

Builder A ships a street-maintenance robot; Builder B ships a delivery vehicle.
Different MCU, OS, radio stack, cryptographic library, application. They have
never spoken. Each has only the released artifacts and the published documents.
Both machines are placed on the same street.

The question is not "is each implementation legal". It is:

> Do two builders, each making only legal choices, independently and without
> coordination, end up sharing at least one working path?

Any configurable choice where the answer can be "no" is either a missing MCL
baseline or a missing deployment selection. That is the whole test.

## 2. What was checked

Read, not inferred: `mcl-sdk/include/mcl/sdk.h`, `mcl-sdk/examples/`,
`mcl-ap/include/mcl/{ap_modem,ap_listen,ap_channel}.h`, `mcl-ap/src/ap_modem.c`,
`mcl-ap/registries/ap-profiles-v0.1.json`, `mcl-ap/spec/*`,
`mcl-ip/spec/ip-datagram-profile-v1.md`, `mcl-ble/spec/ble-gatt-profile-v1.md`,
`mcl-ble/include/mcl/ble_binding.h`, `mcl-link/include/mcl/*.h`,
`mcl-wire/include/mcl/wire.h`, `mcl-core/governance/{V1_SCOPE,ARCHITECTURE_CHARTER}.md`,
`mcl-core/SPECIFICATION_INDEX.md`, `mcl-core/README.md`.

## 3. Findings

### 3.1 Acoustic is not one first-contact option among several. It is the only one.

IP carriage is frozen, but `ip-datagram-profile-v1.md` §8 puts discovery out of
scope and §3 assigns no port: an IP peer is reachable because a
`TRANSPORT_OFFER` already carried an `endpoint_token`.

BLE is better than a bare carriage profile. `ble-gatt-profile-v1.md` §4 assigns
a 128-bit MCL service UUID (`6d636c00-0001-4d43-4c00-6d636c626c65`) and §7
defines a 26-byte rendezvous advertisement carrying the beacon. A scanner is not
ignorant of what to look for. But §7 closes with the decisive word: *"an
implementation that never advertises is fully conformant."*

So every richer bearer in v1.0 either presupposes that something else already
carried an offer, or relies on an optional behaviour the peer may legally never
perform. The only bearer that needs no prior configuration, no shared network
and no prior relationship is acoustic.

The README's central claim — machines that were never designed to work
together, with no shared network and no common credential system — therefore
rests entirely on MCL-AP, which is the one binding that is not frozen.

Worse, transports are individually optional. Builder A implementing IP and AP
and Builder B implementing BLE and UWB are both fully conformant and share
nothing. **Two Base-v1 implementations are not currently guaranteed to share
any path at all.** This is the load-bearing finding; everything below is
downstream of it.

### 3.2 The acoustic waveform is deterministic. The gap is governance, not physics.

`mcl_ap_modem_default_config()` fixes every parameter: FSK 3000/6000 Hz,
300 baud, 48 kHz, 0.2 s LFM chirp 2-6 kHz, 16 training bits, threshold 0.40,
CRC-16/CCITT-FALSE, frame `[silence][chirp][training][len|crc16][payload][silence]`.
Two builders that link `mcl-ap` and take the defaults **do** interoperate. The
claim that two builders could both "implement MCL-AP" and produce mutually
undecodable audio is false for anyone using this source.

What is missing is different, and still disqualifying:

1. **No prose specification of the waveform.** An independent implementer must
   reverse-engineer C. `mcl-ap/spec/ap-v0.md` is a Research Draft and does not
   contain these parameters.
2. **The only assigned profile is 192, Experimental Use.** `GOVERNANCE.md` §4.3
   states an Experimental Use value is *never* relabelled Stable; promotion
   assigns a **new** value. A builder shipping profile 192 is shipping something
   the project has already committed to replacing.
3. **Profile 192 carries raw Wire bytes, not Link frames** — its own registry
   entry says so.

The honest statement is not "acoustic does not interoperate". It is: *the one
path two strangers can take is implemented, measured, and deliberately not
promised.*

This does **not** license writing the current waveform down and calling it
AP-B0. The registry entry is explicit that 3/6 kHz must not be standardised
merely because it rescued one hardware campaign, and the retained evidence
shows sharp degradation with frame length — Experiment 008 recorded 9/10 at 10
bytes and 2/10 at 24 bytes on the board-to-host cell. A bootstrap profile must
be selected from a bake-off, not inherited from the instrument that produced
the evidence.

### 3.3 The acoustic frame cap, not airtime, is the near-term carriage limit.

Stable major-1 `PRESENCE` is **10 bytes** (`V1_SCOPE.md` §4.8; major 0 was 11).
`MCL_WIRE_TIER0_MAX_SIZE` is 17 bytes, the Tier-0 ceiling rather than the size
of any Stable object. `MCL_AP_MODEM_MAX_PAYLOAD_BYTES` is **64**.

MCL-BLE defines fragmentation and reassembly with a one-byte START/END/SEQ
header. **MCL-AP defines none** — there is no fragmentation anywhere in
`mcl-ap/include` or `mcl-ap/src`.

At the default config, fixed overhead is 0.933 s (0.1 s lead + 0.2 s chirp + 40
bits of training and PHY header at 300 baud + 0.5 s trail); payload adds
bytes x 8 / 300 seconds.

| payload | on-air time | fits an AP frame |
|---|---|---|
| 10 B major-1 `PRESENCE` | 1.20 s | yes |
| 17 B Tier-0 ceiling | 1.39 s | yes |
| 64 B AP maximum | 2.64 s | yes, exactly |
| 10 B + Ed25519 signature (64 B) = 74 B | 2.90 s | **no** |
| 10 B + ML-DSA-44 signature (2420 B) | ~65 s | **no** |

**A bare Ed25519 signature does not fit in an MCL acoustic frame.** Not
slowly — not at all.

The correct response is *not* to make acoustic carry credentials. See §6.

### 3.4 Fragmentation alone would not carry large cryptography anywhere.

`MCL_LINK_FRAME_MAX_PAYLOAD` is 1024 and `MCL_LINK_FRAME_MAX_SIZE` is
8 + 16 + 1024 = **1048**. Both Stable transport profiles use that ceiling.

So a 2420-byte post-quantum signature is not "38 acoustic fragments of one Link
frame". It does not fit in one Link frame on **any** bearer, including IP. Any
security design that assumes large credentials travel whole needs
security-message segmentation above Link, on every transport — or, far better
for constrained machines, credential *references* and compact exchanges instead
of transporting credentials wholesale.

This is an argument for evaluating established constrained-security work
(EDHOC's credential references and compact mutual authentication; COSE's
compact signature, MAC, encryption and key structures) rather than inventing
MCL cryptography. Evaluation means measured message and code sizes, not
preference.

### 3.5 The README claims a cryptographic interface that does not exist.

`mcl-core/README.md`, in a present-tense list titled "What you configure":

> **Which cryptography, if any** — MCL defines the interface a mechanism plugs
> into, never the mechanism.

There is no such interface. No `sign`, `verify`, `aead_seal`, `aead_open`,
`random` or credential-lookup callback exists in any public header in any of
the eight repositories. A blockquote 25 lines later does say the security
profile does not exist yet, but a reader assembling a build list from the
configuration bullets will look for a header that is not there.

### 3.6 There is no legal carrier for security messages.

Even once a provider interface exists, the question of *where the handshake
bytes travel* is unanswered. Link major 1 defines `DATA` as carrying a
canonical Wire Tier-0 object; `CAPABILITY` and `NEGOTIATION` have fixed control
formats; there is no Stable `SECURITY` class and no feature bits are assigned.

The chain is therefore missing its middle term:

```text
security protocol  ->  MCL carrier  ->  crypto provider
```

The carrier must be settled before any callback is implemented, because
authentication is communication and control state rather than a physical bearer
concern or a Core semantic object.

### 3.7 Shared air has no contention behaviour.

Ten machines that hear the same acoustic `PRESENCE` and answer at once defeat a
perfect modem. Nothing in `mcl-ap` defines listen-before-transmit, reply
scheduling, backoff, duplicate suppression, retry limits or multi-responder
behaviour. A bootstrap profile is protocol behaviour on a shared medium, not
only modulation, and the physical bake-off must cover contention alongside
coding.

### 3.8 After contact, there is almost nothing to say.

Stable Tier-0 is `PRESENCE`, `TRANSPORT_OFFER`, `TRANSPORT_ACCEPT`
(`V1_SCOPE.md` §3.2). Two machines can establish contact, move to a better
bearer, and keep the contact alive across the move. They cannot state what they
are, what they can do, or what they want. That was the correct call — the
alternative was freezing unresearched `HAZARD` / `REQUEST` / `AUTHORITY_CLAIM` —
but it bounds what "two machines cooperate" can mean in v1.0.

### 3.9 One node, one contact.

`mcl_node_t` tracks a single contact; several concurrent peers need several
nodes, and multi-contact isolation is unfinished (`V1_SCOPE.md` §5.5). A city
street is the multi-peer case by definition.

### 3.10 Normative maturity does not match what v1 calls Stable, in both directions.

This is a release-gate defect independent of the two-builder question.

**Downward.** `V1_SCOPE.md` calls Wire major 1 and Link major 1 Stable, while
the documents defining them are below Stable: `core-v0.md` and `wire-v0.md` and
`link-v0.md` are **Research Draft**, `link-negotiation-v1.md` is **Candidate**,
and `link-class-disposition-v1.md` is **proposed** while describing nine Stable
Link classes. `ARCHITECTURE_CHARTER.md` is itself a **Research Governance
Draft** while `V1_SCOPE.md` treats its invariants as Stable.

**Upward.** `ip-datagram-profile-v1.md` and `ble-gatt-profile-v1.md` are
labelled `Status: Stable`, but `ARCHITECTURE_CHARTER.md` §6 requires of a Stable
Specification, among other things, **public review** and **evidence that the
specification is useful beyond one demo implementation**. The repositories are
private and `V1_SCOPE.md` §5.9 states in terms that nobody outside the project
has implemented or reviewed these specifications. Those two promotions did not
pass the charter's own stated gate.

`build-spec-index.sh` verifies that `SPECIFICATION_INDEX.md` reflects the status
lines in the tree. Nothing verifies that those status lines agree with the
maturity `V1_SCOPE.md` claims, or that a promotion satisfied the charter's
conditions. That check does not exist and must.

## 4. The classification

| Choice point | Two independent builders | Whose problem |
|---|---|---|
| Wire major 1 encoding | converge | settled |
| Link major 1 lifecycle, negotiation, migration | converge | settled |
| Stable Tier-0 object set | converge | settled |
| IP datagram carriage | converge | settled |
| BLE GATT carriage and fragmentation | converge | settled |
| BLE / socket / audio driver code | diverge, harmlessly | **builder's** |
| Private key storage, secure element | diverge, harmlessly | **builder's** |
| Which cryptographic library implements a suite | diverge, harmlessly | **builder's** |
| Application behaviour, local policy | diverge, harmlessly | **builder's** |
| Trust roots, credential issuance, revocation | diverge | **deployment's** |
| Which bearers are mandatory here | diverge | **deployment's**, and no object expresses it |
| Which transports a product implements at all | diverge, fatally | **MCL's** — no conformance layer requires an intersection |
| Whether a BLE peer ever advertises | diverge | **MCL's** — conformant either way |
| IP port, finding an unknown IP peer | diverge | resolved only by an offer on another bearer |
| Acoustic waveform parameters | converge *if* both take the shipped default | **MCL's** — undocumented, unpromised |
| Acoustic profile identifier | 192 today, guaranteed to be replaced | **MCL's** |
| Acoustic carriage above 64 bytes | impossible | **MCL's** — no fragmentation |
| Shared-air contention, reply storms | undefined | **MCL's** |
| Which security protocol appears on the wire | diverge, fatally | **MCL's** — no profile, no carrier, no registry |
| Credential presentation and proof format | impossible | **MCL's** |
| What a machine can do, or wants | not expressible | **MCL's**, deferred deliberately |

## 5. What is missing, in dependency order

**A. Conformance layers.** Named, layered claims that guarantee an
intersection: `MCL Base 1` (Wire 1, Link 1, Stable kernel, no required bearer —
honest when a bearer is prearranged), `MCL Stranger-Contact 1` (Base 1 plus a
mandatory rendezvous path), and, if the security research survives,
`MCL Secure-Stranger 1`. A machine with no microphone can truthfully claim Base
and must not claim Stranger-Contact. Making AP Stable is not sufficient while AP
remains optional; this is the abstraction that was missing.

**B. `AP-BOOTSTRAP-1`.** Small, robust, raw major-1 Wire first contact only:
`PRESENCE`, `TRANSPORT_OFFER`, `TRANSPORT_ACCEPT`, which fit inside 64 bytes
today. It **forbids** credentials and sensitive identity material by
construction. Selected by bake-off over the retained captures and synthetic
impairments, covering coding, repetition/FEC, contention and backoff; then
written as an independent normative specification; then a clean-room
encoder/decoder built from that prose with PCM vectors and negative tests; then
a physical cross-implementation campaign; then a **new** Standards Action
identifier. Profile 192 stays historically Experimental forever and is not
mutated.

**C. A deployment profile schema.** A machine-readable selection of the
mandatory intersection — foundation layer, required rendezvous, required and
optional continuing bearers, security profile, credential domain, trust anchors,
Wire and Link majors. Two companies then implement *the same deployment
profile* rather than coordinating with each other, and no city name enters Core
semantics. One synthetic `CITY-REFERENCE-1` for conformance, plus worked
examples.

**D. A Link security carrier.** Where named security messages legally travel,
without violating the `DATA` contract or the orthogonality rules, with security
state held separately from Link state.

**E. A named security profile (`MCL-S1`), selected not invented.** Benchmark
EDHOC/COSE and alternatives on message size, code size, credential-reference
support, replay and downgrade properties, and transcript binding to MCL
contact state, before selecting.

**F. A crypto provider API.** sign / verify / aead / random / credential lookup,
so a builder brings mbedTLS, PSA, a TPM or a secure element and MCL stays out
of key custody. Built around the selected standard, after D and E.

**G. A builder facade and integration guide.** Today the only worked example is
an 89-line in-memory pipe. A builder should supply audio, BLE, socket and crypto
callbacks plus caller-owned storage — not reimplement migration, fragmentation,
acoustic DSP or security framing. Two independent integration examples starting
from zero prior peer knowledge.

**H. Maturity repair and a gate for it.** Reconcile §3.10 in both directions and
extend the spec-sync gate so a Stable `V1_SCOPE.md` entry backed only by a
Candidate, proposed or Research document fails automatically.

**I. Later, not now: `AP-LINK-1`** (fragmentation, sessions, full Link frames,
secure acoustic operation) and **semantic capability modules** (compositional,
above the kernel, not another `machine_class`). Neither blocks stranger
bootstrap unless indefinite secure acoustic-only contact becomes a v1 promise.
It is not one.

## 6. Disposition

Documenting the empty floor as a limitation would make the release truthful and
leave it narrower than what the README describes. The decision recorded here is
to **raise the floor before v1.0**.

The architecture that makes this affordable was already the intended one:
acoustic first contact stays public, minimal and credential-free; the contact
migrates to BLE or IP; authentication and any sensitive exchange happen there.
Nothing forces a signature through air, which is why B is a bootstrap profile
rather than fragmented Link-over-acoustic, and why §3.3 is a bound on ambition
rather than a blocker.

`V1_SCOPE.md` §5.10 records the resulting acceptance criterion. Until it passes
under a named conformance profile, v1.0.0 is not tagged.

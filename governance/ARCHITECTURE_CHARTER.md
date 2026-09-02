# MCL Architecture Charter

Status: **Research Governance Draft**

This charter defines the invariants that future Machine Contact Layer specifications, profiles, extensions, SDKs, and conformance programs are not allowed to violate casually.

MCL is intended to remain useful across decades of changing hardware and transports. Therefore this charter freezes architectural principles before it freezes implementation details.

## 1. Mission

Machine Contact Layer (MCL) is a transport-independent interoperability layer for bounded first contact and physical-world coordination between machines that share no common protocol at the moment they meet.

Those machines may be unrelated, or may already be known to each other; MCL does not distinguish, and the deployment decides what follows from the difference. A contact may end at first exchange, persist over MCL indefinitely, or hand off to another protocol.

MCL is infrastructure for builders. It is not a product, fleet manager, autonomy stack, credential authority, modem brand, or application.

## 2. Constitutional invariants

### 2.1 Semantic meaning is transport-independent

The meaning of an MCL Core object MUST NOT depend on whether it is carried over acoustics, IP, BLE, UWB, or a future binding.

A transport MAY expose additional physical evidence or metrics, but those observations MUST NOT silently alter Core semantics.

### 2.2 The deterministic boundary survives without AI

Every normative Core/Wire object MUST be constructible and consumable by deterministic software without requiring an LLM or learned model.

Learned systems MAY map internal state to and from MCL objects. They do not define the wire meaning.

### 2.3 Reception is not authority

MCL distinguishes:

`reception != identity != authenticity != authority != trust != obligation`

No transport, message class, or profile MAY cause a receiver to treat a request or authority claim as automatically binding. Local policy remains sovereign.

### 2.4 Unknown critical meaning fails explicitly

An implementation MUST NOT silently reinterpret an unknown core opcode, unknown mandatory extension, stale context, or incompatible major wire version.

Unknown optional extensions MAY be ignored when their extension contract explicitly permits that behavior.

### 2.5 Assigned meanings are immutable after stabilization

Once an identifier is published in a Stable MCL registry:
- its meaning MUST NOT be changed incompatibly;
- it MUST NOT be reassigned to a different meaning;
- deprecation leaves the value permanently reserved.

New meaning requires a new identifier.

### 2.6 Extensibility is designed, not improvised

Core has bounded standardized categories and opcodes.
Domain/vendor/research extensions use explicit extension namespaces or experimental ranges.

Extensions MUST declare whether they are critical to interpretation. A receiver that does not understand a critical extension MUST reject that object rather than guess.

### 2.7 Context is earned

Context compression MUST be explicitly established and version-guarded.
A first-contact receiver MUST have a deterministic non-context path.

Context identifiers are state references, not identity proofs.

### 2.8 Core is not optimized around one physical era

Frequencies, modulation, FEC, audio sample rates, RF technologies, transducer classes, model architectures, CPU/GPU choices, and operating systems are profile/implementation concerns.

They MUST NOT become Core invariants.

### 2.9 Reference code is subordinate to the specification

A bug or shortcut in the reference implementation does not redefine the protocol.
Normative text, registries, and conformance vectors define the candidate specification.

### 2.10 MCL neither requires nor establishes trust

MCL MUST be usable whether or not the two machines have a prior relationship,
and MUST NOT itself create one.

Both halves of that bind. A deployment whose peers already know each other —
same owner, same fleet, provisioned at manufacture, or trusted by some means
entirely outside MCL — is as normal a use of MCL as a contact between strangers,
and MUST NOT be specified as a degenerate case of it. Equally, no transport,
message class, or profile MAY cause trust to come into existence: establishing a
transport, completing a pairing, or joining a network MUST NOT by itself
establish identity, authority, or trust.

Because a first-contact medium MUST be assumed observable by anyone in range,
first contact MUST be possible without disclosing sensitive identity material,
credentials, or private network configuration. This requirement follows from the
medium being open, not from the peers being unknown to each other, and therefore
holds equally for machines that are already mutually known.

MCL MAY negotiate migration of an existing contact to a more private or more
capable transport, and the same MCL contact MAY continue across that change.
Where a deployment uses a security profile and a contact migrates, that profile
MUST be able to bind the new channel to the original contact, so that a peer
appearing on the second transport can be shown to be the peer the contact began
with rather than merely a peer that arrived at the right moment.

### 2.10.1 The interaction sequence belongs to the deployment

MCL MUST NOT mandate an interaction sequence.

What a machine discloses, in what order, over which transports, whether it
migrates transports at all, whether it authenticates, whether it encrypts, and
whether it eventually hands off to another protocol are **configuration**, not
protocol. A gatekeeper at a building entrance, a domestic assistant, and a
quadruped in a warehouse can each use MCL as their first interaction layer while
agreeing on none of those choices.

Two MCL implementations configured differently MUST remain interoperable at the
frame and semantic layers. They will refuse each other at different points, and
refusing early is a policy outcome, not an interoperability failure. A profile
MAY constrain a sequence within its own domain; Core MUST NOT.

A configuration that never migrates transports, never authenticates, and never
hands off is a complete and valid use of MCL.

### 2.10.2 MCL is not an authentication protocol

MCL MUST NOT become one. Where a deployment needs authentication, MCL's
obligation is to make a reviewed authenticated key exchange possible without
requiring sensitive material to cross an exposed channel — not to define that
exchange, and not to own the credential ecosystems it depends on.

Authentication is one thing MCL can be configured to carry. It is not what MCL
is for.

### 2.11 Security properties are separate and are never summarised

Contact continuity, channel confidentiality, channel authenticity, peer
identity, attestation, proximity evidence, and local authorization are distinct
properties established by distinct means.

An implementation MUST NOT collapse them into a single trust indicator. No
representation of the form `trusted = true` may appear in a normative MCL
interface, because every such field eventually invites a shortcut from one
property to a stronger one that was never established.

Correspondingly, a mechanism MUST NOT be named for a property it does not
provide. An error-detecting code is not integrity; an encrypted channel is not
an authenticated peer; a verified credential is not an authorization.

### 2.12 Evidence maturity must be visible

Analytical, simulated, replayed-channel, controlled over-air, multi-device, and independent-interoperability results MUST be labeled separately.

A simulated result MUST NOT be promoted as field evidence.

## 3. Layer ownership

- **MCL Core** owns semantic meaning and shared primitives.
- **MCL Wire** owns deterministic representation and canonicalization.
- **MCL Link** owns contact/session behavior, negotiation, freshness hooks, QoS, and handoff semantics.
- **Transport bindings** own medium-specific delivery behavior and physical metrics.
- **MCL SDK** exposes these contracts to builders without becoming a competing specification.

A lower layer MUST NOT redefine a higher-layer semantic meaning.

## 4. Compatibility law

Compatible evolution should prefer:
1. registry additions;
2. new optional extensions;
3. new profile IDs;
4. new transport bindings.

An incompatible reinterpretation of existing canonical bytes requires a new major wire version.

Minor document revisions, new assigned values, errata, and compatible optional behavior do not consume a major wire version.

## 5. Standardization maturity

MCL uses the following research-to-standard path:

1. **Research Note** - equations, experiments, hypotheses, non-normative.
2. **Working Draft** - implementable but expected to change.
3. **Candidate Specification** - feature-complete enough for independent implementation.
4. **Interoperability Candidate** - at least two independent implementations pass cross-implementation tests.
5. **Stable Specification** - architecture and wire meanings considered stable after public review and operational evidence.
6. **Historic** - retained for compatibility/reference but no longer recommended.

No private research draft is an adopted standard.

## 6. Promotion gates

A specification cannot advance merely because the reference implementation works.

Candidate Specification requires:
- normative requirements language;
- machine-readable registries where numeric assignments exist;
- positive and negative conformance vectors;
- explicit security/trust considerations;
- backwards/forwards-compatibility rules;
- documented open issues.

Interoperability Candidate additionally requires:
- at least two independent codebases;
- no shared protocol encoder/decoder implementation between them;
- bidirectional cross-implementation tests;
- malformed/unknown-extension/context-mismatch tests.

Stable Specification additionally requires:
- resolved known wire ambiguities;
- published errata process;
- public review;
- evidence that the specification is useful beyond one demo implementation.

Transport profiles have additional profile-specific physical test requirements.

## 7. Change classes

Every normative change is classified as:

- **Editorial** - no behavioral or wire effect.
- **Clarification** - resolves ambiguity without changing conforming behavior.
- **Compatible extension** - new assigned value/profile/optional field under existing rules.
- **Behavioral revision** - changes required behavior without reinterpreting existing canonical bytes; requires heightened review.
- **Wire-breaking change** - existing bytes could change meaning; requires a new major wire version.

## 8. Governance objective

The project succeeds when independent builders can implement MCL without copying the reference implementation, exchange the same semantic objects, reject incompatible input deterministically, and evolve through published extension/registry processes without fragmenting the ecosystem.

# MCL Core v0

Status: **Research Draft**

This document defines the first working semantic contract for the Machine Contact Layer.

## 1. Objective

MCL Core provides a deterministic vocabulary for first contact and physical-world coordination between machines that may not share a vendor, fleet manager, network, cloud account, or prior relationship.

The core answers a small set of recurring questions:

- Who or what are you?
- What can you do?
- What is happening?
- What do you intend to do?
- What must or must not happen?
- What is your current state?
- How should we continue communicating?

## 2. Core message classes

### 2.1 Presence

`PRESENCE`

Minimal indication that an MCL-capable node is present.

Suggested fields:

- `node_ref`
- `machine_class?`
- `protocol_version`
- `ttl`

### 2.2 Identity and authority

`IDENTITY_CLAIM`

- `subject_ref`
- `credential_ref?`
- `operator_ref?`
- `owner_ref?`
- `validity?`

`AUTHORITY_CLAIM`

- `subject_ref`
- `authority_class`
- `jurisdiction?`
- `credential_ref?`
- `validity`

Claims are not self-authenticating. Verification and policy remain outside the semantic object.

### 2.3 Capability

`CAPABILITY`

- `subject_ref`
- `capability_codes[]`
- `limits?`
- `confidence?`

`TRANSPORT_CAPABILITY`

- `transport_id`
- `profile_ids[]`
- `direction`
- `endpoint_hint?`

### 2.4 Observation and hazard

`OBSERVATION`

- `observer_ref`
- `observation_class`
- `subject_ref?`
- `spatial_scope`
- `temporal_scope?`
- `confidence`
- `evidence_ref?`

`HAZARD`

- `hazard_class`
- `spatial_scope`
- `temporal_scope?`
- `severity`
- `confidence`
- `source_class`
- `evidence_ref?`

### 2.5 Intent and trajectory

`INTENT`

- `actor_ref`
- `action_class`
- `trajectory_ref?`
- `spatial_scope?`
- `temporal_scope?`
- `constraints?`
- `confidence`

`TRAJECTORY`

A compact time-indexed representation of expected motion. Exact encoding belongs to MCL Wire.

### 2.6 Constraint and request

`CONSTRAINT`

- `constraint_class`
- `subject_ref?`
- `spatial_scope?`
- `temporal_scope?`
- `limit_or_rule`
- `source_ref`

`REQUEST`

- `request_class`
- `target_ref?`
- `object_ref?`
- `spatial_scope?`
- `temporal_scope?`
- `priority`

`OFFER`, `ACK`, and `REFUSE` provide deterministic response semantics.

### 2.7 Status

`STATUS`

- `subject_ref`
- `state_class`
- `health?`
- `mission_state?`
- `confidence?`

`DEGRADED_STATE`

- `subject_ref`
- `affected_capability`
- `severity`
- `expected_duration?`

### 2.8 Link and transport state

`CHANNEL_STATE`

- `transport_id`
- `quality_class`
- `direction`
- `metrics?`

`INTERFERENCE`

- `affected_transport_or_band`
- `severity`
- `spatial_scope?`
- `temporal_scope?`
- `confidence`

`TRANSPORT_OFFER`

- `transport_id`
- `profile_id?`
- `endpoint_hint?`
- `credential_ref?`
- `validity?`

`TRANSPORT_ACCEPT`

- `transport_id`
- `profile_id?`
- `session_ref?`

## 3. Shared primitives

The following primitives recur across message classes:

- `TIME`
- `TEMPORAL_SCOPE`
- `SPATIAL_SCOPE`
- `CONFIDENCE`
- `PRIORITY`
- `PROVENANCE_REFERENCE`
- `NODE_REFERENCE`
- `SESSION_REFERENCE`
- `TRANSPORT_ID`

MCL Wire defines their canonical representation.

## 4. Semantic tiers

### Tier 0 — Contact / governing microframes

Fixed or tightly bounded meanings for:

- presence
- identity or authority claim reference
- basic hazard
- basic request
- capability digest
- transport offer
- acknowledgement

Target size is a research hypothesis, not a requirement. Initial experiments should test whether common Tier-0 objects can fit within approximately 16–64 bytes before channel coding.

### Tier 1 — Structured semantics

Compact typed objects for observations, intent, trajectory, constraints, diagnosis, and richer state.

### Tier 2 — Rich extensions

Large evidence objects, maps, embeddings, model-specific payloads, or domain-specific structures. Tier 2 is normally handed off to a richer transport when available.

## 5. Extension model

A domain extension MUST NOT redefine the meaning of a core message or primitive.

Extensions may add:

- domain-specific codes
- additional optional fields
- richer trajectory or geometry representations
- credential formats
- transport-specific metadata

Unknown extensions must be safely ignorable unless explicitly marked mandatory for the current session.

## 6. Non-goals

MCL Core is not:

- a universal robot ontology
- a planning language
- a fleet orchestration system
- a remote-control policy
- an authentication authority
- a physical transport

## 7. Open research questions

- Which fields are genuinely mandatory across machine classes?
- Which primitives can be safely quantized?
- What semantic loss is acceptable for each priority class?
- Which objects belong in Tier 0 versus Tier 1?
- How should heterogeneous models map into the same deterministic object without changing its meaning?

# MCL Core

**Machine Contact Layer (MCL)** is a candidate interoperability layer for first contact and communication between previously unrelated machines.

`mcl-core` defines the transport-independent semantic contract. It is intentionally smaller than a robot language or world ontology. The core standardizes the minimum physical-world meaning that independent machines may need to exchange during contact.

MCL is infrastructure for builders, not a product or autonomy stack. The long-term design goal is a layer whose stable meanings can survive changes in transports, transducers, models, operating systems, and hardware generations.

## Scope

MCL Core defines semantic objects for:

- presence
- identity and authority claims
- capability and transport capability
- observation and hazard
- intent, trajectory, and constraints
- request, offer, acknowledgement, and refusal
- status and degraded state
- channel state and interference
- transport offer and acceptance
- time, spatial scope, confidence, priority, and provenance references

MCL Core does **not** define acoustic modulation, Bluetooth, UWB, IP transport, hardware, fleet control, or an autonomous policy engine.

## Design rules

1. **Deterministic semantic boundary.** A simple controller must be able to produce and consume MCL objects without an AI model.
2. **Transport independence.** The same semantic object may travel over MCL-AP, IP, BLE, UWB, or another binding.
3. **Local decision sovereignty.** A received request or authority claim is information for local policy evaluation, not automatic remote control.
4. **Domain-general core, domain-specific extensions.** The core does not assume roads, warehouses, drones, or any single machine class.
5. **Bounded governing subset.** Safety- and contact-critical meanings must have compact deterministic representations.
6. **Explicit compatibility.** Unknown critical meaning, stale context, and incompatible wire versions are rejected rather than guessed.
7. **Immutable assigned meaning after stabilization.** Stable identifiers are never reused or silently reinterpreted.

## Governing specification machinery

- [`governance/ARCHITECTURE_CHARTER.md`](governance/ARCHITECTURE_CHARTER.md) — long-term invariants
- [`governance/SPECIFICATION_PROCESS.md`](governance/SPECIFICATION_PROCESS.md) — maturity, change and errata process
- [`governance/REGISTRY_POLICY.md`](governance/REGISTRY_POLICY.md) — assigned-number policy
- [`governance/ORGANIZATION_MODEL.md`](governance/ORGANIZATION_MODEL.md) — future multi-party standards model
- [`governance/PUBLICATION_POLICY.md`](governance/PUBLICATION_POLICY.md) — immutable releases and persistence
- [`governance/IPR_PRINCIPLES.md`](governance/IPR_PRINCIPLES.md) — intended royalty-free implementation direction
- [`conformance/CONFORMANCE_MODEL.md`](conformance/CONFORMANCE_MODEL.md) — conformance classes and evidence levels
- [`registries/semantic-codes-v0.2.json`](registries/semantic-codes-v0.2.json) — provisional machine-readable semantic assignments

## Core documents

- [`spec/core-v0.md`](spec/core-v0.md) — working semantic contract
- [`spec/shared-primitives-v0.1.md`](spec/shared-primitives-v0.1.md) — units, time, space, confidence, priority and references
- [`research/scenarios/corpus-v0.1.json`](research/scenarios/corpus-v0.1.json) — encounter-driven semantic corpus

## Repository family

- `mcl-core` — semantics
- `mcl-wire` — canonical encoding, context, delta, priority
- `mcl-link` — discovery, framing, sessions, QoS, adaptation
- `mcl-ap` — acoustic profile
- `mcl-ip` — IP binding
- `mcl-ble` — BLE binding
- `mcl-uwb` — UWB binding
- `mcl-sdk` — developer-facing reference SDK

## Status

Private research repository. Pre-v0.1. This is a **candidate open specification**, not an adopted standard.

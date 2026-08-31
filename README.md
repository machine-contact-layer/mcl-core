# MCL Core

**Machine Contact Layer (MCL)** is a candidate interoperability layer for first contact and communication between previously unrelated machines.

`mcl-core` defines the transport-independent semantic contract. It is intentionally smaller than a robot language or world ontology. The core standardizes the minimum physical-world meaning that independent machines may need to exchange during contact.

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

See [`spec/core-v0.md`](spec/core-v0.md) for the working semantic contract.

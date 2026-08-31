# Scenario Corpus v0.1

Status: **non-normative research corpus**

This corpus forces MCL Core and MCL Wire choices to emerge from concrete machine encounters rather than from an abstract ontology.

## Contents

- 30 encounter scenarios
- 42 example semantic events
- 41 current Tier-0-candidate events and one generic `STATUS` Tier-1 example
- domains: road, warehouse, public safety, construction, service robotics, agriculture, industrial systems, logistics, drones, and transport handoff
- deadlines and nominal contact ranges are research assumptions used for feasibility lower bounds, not safety requirements

Semantic-event counts:

```json
{
  "HAZARD": 11,
  "REQUEST": 14,
  "AUTHORITY_CLAIM": 6,
  "STATUS": 1,
  "PRESENCE": 3,
  "DEGRADED_STATE": 3,
  "TRANSPORT_OFFER": 4
}
```

The corpus already exposed one useful schema boundary: contact-critical degraded capability belongs in `DEGRADED_STATE`; generic operational `STATUS` remains outside the Tier-0 candidate set.

## Method

For each scenario we record the physical encounter, a nominal decision deadline, a nominal contact range, and the minimum semantic events that appear useful.

The corpus intentionally contains ordinary peer coordination, authority claims, hazards, degraded state, and transport handoff so MCL does not collapse into a single road, warehouse, or drone ontology.

## Layer boundary

- semantic meaning and scenarios: `mcl-core`
- exact byte representation: `mcl-wire`
- contact/session timing: `mcl-link`
- acoustic feasibility: `mcl-ap`

## Provenance

SHA-256 of `corpus-v0.1.json`:

`ac1f8ba0474d2def22b736a737305681144d6fae86ce327ce978ec1b24c783d5`

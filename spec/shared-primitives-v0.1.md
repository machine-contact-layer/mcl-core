# MCL Shared Primitives v0.1

Status: **Research Draft**

This document defines semantic meaning for primitives reused across MCL Core objects. MCL Wire owns the compact numeric representation and quantization.

## 1. Units

Normative physical quantities use SI semantics unless a specific MCL extension explicitly defines another representation.

Examples:
- length / position: metre (m)
- duration: second (s)
- speed: metre per second (m/s)
- acceleration: metre per second squared (m/s^2)
- angle: radian (rad)
- angular rate: radian per second (rad/s)

Wire encodings MAY use scaled integers, but the scale is fixed by the Wire specification rather than negotiated through locale-specific unit strings.

An implementation MUST NOT interpret a canonical MCL length as feet, a speed as km/h, or an angle as degrees merely because its internal system uses those units.

## 2. TIME and clock independence

First contact MUST NOT require synchronized wall clocks.

MCL distinguishes three concepts:

### 2.1 Post-receipt semantic lifetime (`ttl`)

`ttl` is the maximum local interval after successful semantic decode during which the receiver may continue treating the object as current, subject to local policy.

TTL does not authenticate freshness and does not prevent replay. MCL Link freshness/replay mechanisms are separate.

### 2.2 Event age

An observation or event MAY carry an `event_age` indicating the sender's estimate of how much time elapsed between the underlying event/observation and transmission.

This allows a receiver to distinguish a newly received message about an old event from a newly observed event without requiring synchronized clocks.

### 2.3 Absolute time

Absolute timestamps are optional and MUST identify their time basis and uncertainty when interpretation depends on them.

A receiver that does not understand or trust the declared time basis MUST NOT invent synchronization.

## 3. TEMPORAL_SCOPE

A temporal scope describes when the asserted state, hazard, intent, request, or constraint applies.

The baseline semantics should be expressible using relative durations. Domain extensions may add richer schedules or synchronized timestamps.

## 4. SPATIAL_SCOPE

Spatial values are meaningless without a reference frame.

MCL Core therefore treats frame identity as semantic state, not an implementation detail.

A session or object may use a declared local frame. The initial research default for a machine body-local Cartesian frame is:

```text
+x = forward
+y = left
+z = up
```

All axes use metres.

Other explicit frames, including earth/local-navigation frames, may be registered. A receiver MUST NOT silently treat an unknown frame as the default frame.

Global maps, complex polygons, and geodetic representations may use richer Tier-1/domain extensions rather than bloating every Tier-0 object.

## 5. CONFIDENCE

`confidence` is the sender's declared confidence in the associated assertion, represented semantically on [0,1].

Unless an applicability profile or extension states a calibration contract, confidence is **not guaranteed to be a statistically calibrated probability**.

Rules:
- absence is different from zero confidence;
- confidence MUST NOT create authority;
- a receiver MAY apply its own calibration/trust model;
- Wire quantization MUST preserve monotonic ordering.

## 6. PRIORITY

Priority describes communication/resource urgency and protection importance.

Working classes:
- P0 / CRITICAL
- P1 / HIGH
- P2 / NORMAL
- P3 / BULK

Priority may influence scheduling, repetition, FEC, retransmission, or discard policy.

Priority MUST NOT mean:
- hazard severity;
- identity strength;
- authority level;
- trust;
- legal obligation.

A malicious sender setting P0 does not become authoritative.

## 7. SEVERITY

Severity describes the consequence/magnitude class of a condition such as a hazard or degraded state.

Severity is independent of transport priority. A high-severity persistent condition may be transmitted efficiently, while a lower-severity time-critical transition may receive higher link priority.

Exact severity taxonomies may be domain-specific while preserving the generic ordering contract.

## 8. NODE_REFERENCE

A node reference identifies an entity within a contact/session scope.

An ephemeral node reference is not proof of identity, ownership, manufacturer, or operator.

Long-lived/authenticated identity is expressed through identity/credential mechanisms, not inferred from the reference number.

## 9. SESSION_REFERENCE

A session reference identifies MCL Link state. It has no meaning outside its defined lifetime/scope unless another specification explicitly establishes one.

## 10. PROVENANCE_REFERENCE

A provenance reference points to supporting source/evidence metadata.

The existence of provenance does not make it trustworthy. Verification is policy/security behavior outside the primitive itself.

## 11. Quantization boundary

Core semantics remain real/typed concepts. Wire chooses bounded encodings.

For example, a 0.25 m Wire grid has a maximum rounding error of 0.125 m per axis. Whether that is acceptable is an applicability/conformance question, not a change in what a metre means.

A future Wire revision may offer another representation without redefining the Core spatial semantic.

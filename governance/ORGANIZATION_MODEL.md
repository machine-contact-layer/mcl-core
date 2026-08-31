# Future MCL Standards Organization Model

Status: **Governance Design Draft**

This is a future operating model for the point at which MCL moves from private research into multi-party standards development. It is not yet an incorporated governance structure.

## 1. Design objective

Technical authority should be separated so that no single vendor, transport technology, or reference implementation can silently redefine the layer.

## 2. Bodies

### Architecture Review Council (ARC)

Owns:
- Architecture Charter;
- cross-layer invariants;
- wire-breaking change review;
- creation of new standards-track categories/layers;
- resolution of disputes about layer ownership.

The ARC should not author every feature.

### Core/Wire/Link Working Groups

Own normative work inside their layer boundaries.

They produce:
- change proposals;
- draft specifications;
- registries;
- conformance tests;
- migration plans.

### Transport/Profile Working Groups

Own MCL-AP, IP, BLE, UWB, and future bindings.

A transport group cannot redefine Core semantics or authority policy.

### Registry Designated Experts

Review Specification-Required assignments and protect scarce namespaces from duplication or product-specific allocations.

Registry experts do not have authority to make wire-breaking changes through assignment decisions.

### Test and Interoperability Committee

Owns:
- implementation conformance statement schema;
- test case reference lists;
- test-suite quality;
- independent interoperability events;
- test-system validation criteria.

This function is intentionally separate from specification authorship.

### Security and Trust Review Group

Reviews:
- credential/freshness hooks;
- downgrade behavior;
- replay/relay implications;
- authority-claim handling;
- privacy and physical-evidence semantics.

It does not become a global credential authority.

### Domain Liaison Groups

Automotive, robotics, industrial, aerospace, agriculture, public safety, accessibility, and other communities may propose applicability requirements and extensions.

Domain groups advise Core; they do not get to redefine domain-general semantics unilaterally.

## 3. Decision flow

A standards-track change normally moves:

```text
research evidence
 -> MCL Change Proposal
 -> working-group review
 -> registry/conformance impact
 -> architecture review if required
 -> Candidate Specification
 -> independent implementation
 -> interoperability testing
 -> Stable review
```

## 4. Consensus and objections

The future process should seek technical consensus rather than simple vendor voting.

Material unresolved objections should be recorded with:
- exact technical concern;
- affected interoperability property;
- evidence;
- disposition/reasoning.

An architecture decision should be appealable through a documented process.

## 5. Conflict and capture resistance

Future governance should require disclosure of relevant organizational affiliations and conflicts for reviewers making registry, architecture, or qualification decisions.

No single equipment vendor, AI vendor, transport provider, or application sector should control the Core specification.

## 6. Separation of powers

Specification authors define required behavior.
Registry experts manage assigned values under published policy.
Conformance groups test implementations against the spec.
Reference-code maintainers implement but do not interpret the standard by fiat.
Trademark/qualification administration, if created, is separate from protocol meaning.

## 7. External standards liaison

MCL should reuse and reference established standards rather than clone them.

Potential liaison domains include:
- IETF for Internet protocol practices and registries;
- IEEE/ISO for robotics, safety, timing, and domain standards;
- Bluetooth SIG / Connectivity Standards Alliance where transport interworking matters;
- automotive, aviation, industrial, and public-safety standards bodies for applicability.

Liaison does not imply that MCL owns those domains.

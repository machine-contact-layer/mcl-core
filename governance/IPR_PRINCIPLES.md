# MCL IPR and Implementation-Rights Principles

Status: **Research Governance Draft - not legal terms**

A public interoperability layer cannot function as durable infrastructure if implementers are uncertain whether implementing the specification exposes them to undisclosed standards-essential patent claims or whether the reference-code license controls the protocol.

This document states the intended policy direction. Formal participation, contribution, patent, copyright, trademark, and licensing terms require dedicated legal drafting before MCL operates as an external standards body.

## 1. Implementation goal

The intended goal for Stable MCL specifications is that the normative interoperability requirements can be implemented on a **royalty-free basis** by any implementer, subject to final legal policy.

The goal applies to claims essential to implementing the Stable specification, not to unrelated patents or product technology.

## 2. Early disclosure

Contributors to future standards-track MCL work should disclose, as early as reasonably possible, patent/IPR constraints they know may be essential to a proposal under discussion.

The purpose is architectural: the community must be able to evaluate alternatives before a dependency becomes embedded in a wire standard.

## 3. Design-around preference

When technically reasonable, MCL should prefer an interoperable design that avoids a blocking or materially restrictive essential claim over one that makes a mandatory baseline depend on it.

A patented technique may still be researched or used in an optional profile, but its IPR status must be explicit before that profile can become Stable and mandatory for any conformance class.

## 4. Specification versus implementation license

The following are separate:

- rights to read/copy/publish the specification;
- patent rights necessary to implement normative requirements;
- license of the reference implementation;
- trademark/brand/qualification rights.

A reference implementation license MUST NOT become the accidental legal definition of who may implement the protocol.

## 5. Reference implementations

Multiple independent implementations are encouraged.

Stable conformance MUST be achievable from the published specification, registries, and tests without copying MCL reference source code.

## 6. Contribution record

Future external standards work should preserve:

- contributor identity;
- proposal/change history;
- IPR disclosures associated with proposals;
- specification revisions affected;
- resolution/design-around decisions.

## 7. No current legal commitment

The MCL research repositories, whether private or publicly readable, do not by
themselves create a formal standards-development membership regime or
patent-license commitment.

Before public standards participation begins, MCL should obtain legal review and adopt explicit contributor, specification copyright, patent, and trademark policies.

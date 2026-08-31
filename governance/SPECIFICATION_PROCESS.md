# MCL Specification Process

Status: **Research Governance Draft**

## Normative language

Normative specifications use the uppercase key words `MUST`, `MUST NOT`, `REQUIRED`, `SHOULD`, `SHOULD NOT`, and `MAY` with the meanings defined by BCP 14 (RFC 2119 and RFC 8174).

Lowercase prose remains explanatory unless a document explicitly states otherwise.

## Specification artifacts

A normative MCL release should consist of more than prose:

- normative specification text;
- assigned-number registries;
- canonical examples;
- positive golden vectors;
- negative/rejection vectors;
- implementation conformance statement (ICS) template;
- test-case reference list;
- errata;
- change log and compatibility statement.

## Proposals

Normative changes should be proposed as an MCL Change Proposal (MCPROP), containing:

1. problem statement;
2. affected layer(s);
3. compatibility class;
4. exact normative change;
5. registry impact;
6. security/trust impact;
7. conformance tests;
8. migration behavior;
9. evidence supporting the change;
10. rejected alternatives.

An idea without interoperability consequences can remain a research note and does not need a change proposal.

## Architecture review

Changes crossing layer boundaries, consuming scarce assigned numbers, changing unknown-field behavior, changing trust semantics, or requiring a new major wire version require architecture review.

## Errata

Errata are classified as:
- editorial;
- technical clarification;
- normative defect;
- security defect.

Errata MUST NOT be used to smuggle an incompatible new feature into an existing Stable wire version.

## Independent implementation rule

A Candidate Specification cannot become an Interoperability Candidate based solely on forks, language ports, or wrappers around the same encoder/decoder.

Independent implementations must be developed from the specification and vectors rather than sharing protocol implementation code.

## Applicability profiles

MCL may define applicability statements for machine classes or operating environments without changing Core meaning.

Examples:
- constrained receive-only hazard listener;
- public-safety authority broadcaster;
- indoor service robot;
- high-mobility acoustic node.

An applicability profile selects required/optional features. It does not redefine them.

# MCL Registry and Assigned-Number Policy

Status: **Research Governance Draft**

MCL uses explicit registries because small numeric fields are shared interoperability resources. Allocation is part of protocol architecture, not repository housekeeping.

The policy is modeled on long-lived registry practices such as IANA's graded registration policies: scarce or semantics-critical values receive stronger review, while experimentation has dedicated ranges.

## 1. General rules

1. An assigned Stable value is never reused.
2. Deprecation does not free a value.
3. Every public interoperable assignment has a permanent specification reference.
4. Experimental and private values MUST NOT be advertised as globally interoperable.
5. Registries are machine-readable and reviewed together with normative text.
6. Registry changes are append-only after Stable publication except for metadata such as status, reference, or deprecation notes.
7. The semantic meaning of an existing Stable assignment cannot be changed by editing a registry row.

## 2. Registration policies

### MCL Standards Action

Used for scarce or architecture-defining values such as Core categories and the main standardized opcode range.

Requires:
- MCL specification change;
- architecture review;
- conformance implications documented;
- collision/redundancy review;
- permanent specification.

### Specification Required

Used for interoperable extensions that need not become part of Core.

Requires:
- permanent public specification;
- designated technical review;
- clear wire semantics;
- compatibility and failure behavior;
- at least one conformance vector.

### Experimental Use

Reserved for research.
No stability or global uniqueness outside the defined experimental range is promised.
Experimental assignments MUST NOT later be silently promoted to Stable meaning; promotion receives a Stable assignment unless governance explicitly reserves the same value before public deployment.

### Private Use

Vendor/site-local values, when a registry defines such a range, are not globally coordinated.
Private values MUST NOT be required for baseline MCL interoperability.

## 3. Provisional semantic code space

The current 16-bit common-header study uses:

- 4 bits major wire version
- 4 bits semantic category
- 5 bits opcode within category
- 2 bits priority
- 1 bit extension-present

Category policy:
- `0x0-0xD`: MCL Standards Action category space
- `0xE`: Experimental
- `0xF`: Extended namespace escape

Within a standardized category:
- `0x00-0x17`: MCL Standards Action
- `0x18-0x1B`: Specification Required
- `0x1C-0x1D`: Experimental Use
- `0x1E-0x1F`: Reserved

This yields 336 Standards-Action semantic slots before using the extended namespace, versus only 16 direct values in the previous v0.1 type field.

These ranges are provisional until a Candidate Specification is published.

## 4. Extended namespaces

Category `0xF` is reserved as an escape mechanism for semantics that should not consume Core opcode space.

The final extension envelope is not frozen yet. It MUST provide:
- globally unambiguous namespace identification for public extensions;
- an explicit critical/non-critical interpretation rule;
- deterministic length/framing;
- collision avoidance;
- a Private/Experimental path.

## 5. Review criteria

A reviewer should reject an assignment when:
- an existing semantic already covers the use case;
- the proposal is product-specific rather than interoperability-relevant;
- the proposal embeds transport-specific details into Core;
- failure behavior is undefined;
- units/reference frames are ambiguous;
- the proposal requires free-form natural language for normative interpretation;
- it creates authority/trust semantics from reception alone;
- a domain extension is being forced into the domain-general Core.

## 6. Registry source of truth

Human-readable specifications explain meaning.
Machine-readable registries define current assigned numeric values.
Conformance tests verify that implementations agree with both.

A generated document or SDK enum is never the authoritative assigned-number source.

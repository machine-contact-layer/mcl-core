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

**The extension envelope is now specified and implemented.** This section
previously said it was not frozen and listed five properties it would have to
provide. All five are provided by `mcl-wire/spec/tier0-extensions-v0.1.md`,
which is normative for the bytes:

| Required property | Where it is met |
|---|---|
| globally unambiguous namespace identification | the `id` field, allocated by the registry below |
| explicit critical/non-critical interpretation rule | the low bit of the TLV key; an unknown **critical** extension rejects the whole object rather than being skipped |
| deterministic length/framing | uvarint `block_length` plus per-TLV `value_length`, so an object stays self-delimiting on the raw-Wire path where no outer envelope exists |
| collision avoidance | the registry, plus strictly increasing ids so a set of extensions has exactly one encoding |
| a Private/Experimental path | the Experimental Use and Private Use ranges in that registry |

### Extension identifier registry

Assignments live in `mcl-wire/registries/extension-ids-v0.1.json`, machine-checked
by `mcl-wire/tools/validate_extension_registry.c`. The tool enforces that the
declared ranges **partition** the identifier space: a gap is a value with no
policy and an overlap is a value with two, and both would otherwise be
discovered by whoever requests that number rather than by whoever wrote the
table. It also refuses to let identifier 0 become assignable, because zero being
reserved is a property of the encoding — a zeroed buffer must never decode as an
extension — and not a policy that governance may revisit.

The space is not uniformly priced. The TLV key is `uvarint((id << 1) | critical)`,
so ids 1..63 cost one byte on the wire and 64..8191 cost two. The cheap range is
therefore allocated under the strictest policy rather than first-come: wanting a
short identifier is not a reason to receive one.

**Zero assigned extensions is the expected state at v1.0 and is not a defect.**
No extension has yet demonstrated cross-vendor necessity, and inventing one to
populate the table would be inventing it wrongly. What a release requires is
that the mechanism and its governance are ready on the day somebody first asks.

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

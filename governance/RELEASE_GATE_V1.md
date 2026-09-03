# MCL v1.0.0 release gate

**No `v1.0.0` tag exists while any mandatory row below is OPEN, PARTIAL,
NOT_RUN, "owner decision required", or supported only by the reference
implementation itself.**

Status: living document. Updated only when the evidence that closes a row
actually exists.

## The rule this ledger enforces

Every row records **the evidence that closes it**, not the intention to close
it. A row says `DONE` only when the artifact named in its evidence column is in
the tree and passing. "Implemented" is not "release-ready", and this ledger
exists to stop the two becoming synonyms.

**All checklist items must close. Not every research feature must become
Stable.** AP-B0, UWB, cryptographic binding, context compression, `HAZARD`,
`REQUEST`, `AUTHORITY_CLAIM` and `DEGRADED_STATE` are deliberately
Experimental / Candidate / Deferred. Their *correct disposition, documentation
and non-overclaiming* is itself the requirement. Turning every research branch
Stable is not.

## Status

| # | Gate | State | Evidence |
|--:|---|---|---|
| 1 | Final v1 scope approval | **OPEN — owner** | `V1_SCOPE.md` exists and is complete. Two owner decisions outstanding: the three-object Stable Tier-0 subset, and `machine_class` (`MACHINE_CLASS_AUDIT.md`). |
| 2 | Stable semantic closure | **PARTIAL** | Closed: `ttl`, `validity` (`duration-v0.1.md`), `capability_tag`, refs, `transport_id`. Open: `profile_id` (blocked on 7/8); `machine_class` pending item 1. |
| 3 | Registry governance closure | **OPEN** | Extension-ID registry + validator done. Semantic codes, transport IDs, profile IDs still need change controllers and promotion/deprecation procedures. |
| 4 | Link class disposition | **DONE** | `mcl-link/spec/link-class-disposition-v1.md`. Nine Stable, one reserved, none excluded. |
| 5 | Minimum capability/version negotiation | **DONE** | `link-negotiation-v1.md`, `src/negotiation.c`, `tests/test_negotiation.c` — 4241 checks, 0 failed. Symmetry exhaustive over 675 ordered pairs, 0 disagreements. |
| 6 | Candidate-vs-Stable major enforcement | **DONE** | `common-header-v0.2.md` §3.1, `mcl_wire_kind_allowed_at_major`, `tests/test_major_rule.c` — 149 checks. Major 1 defined, deliberately not yet cut. |
| 7 | Stable IP-DATAGRAM profile | **PARTIAL — spec done, promotion pending** | `mcl-ip/spec/ip-datagram-profile-v1.md`, normative, at Candidate. Carriage only, no port assigned, discovery deferred. Frame check now required and enforced. Steps 2–5 of the promotion sequence need item 15. |
| 8 | Stable BLE-GATT profile | **PARTIAL — spec done, promotion pending** | `mcl-ble/spec/ble-gatt-profile-v1.md`, normative, at Candidate. Service, characteristics, fragmentation, MTU floor, discard table frozen. Frame check required (reassembly, not radio). Steps 2–5 need item 15. |
| 9 | Multi-contact isolation campaign | **DONE** | `mcl-sdk/tests/test_multi_contact.c` — 50 checks, 9 cases, broadcast bus. Mutation-tested: `MULTI_CONTACT_MUTATIONS.md`, one escape found and closed. Host-side only; several real peers on one radio is not claimed. |
| 10 | Final Wire major 1 | **BLOCKED** on 1, 2, 7, 8 | Rule already in place (item 6). |
| 11 | Final Link major 1 | **BLOCKED** on 10 | |
| 12 | Immutable major-1 vectors | **BLOCKED** on 10, 11 | v0 vectors never rewritten. |
| 13 | SDK release engineering | **OPEN** | Installable package, exported targets, external consumer build. |
| 14 | Public API freeze | **OPEN** | Source/API compatibility, **not** binary ABI (§4.5). Symbol baseline + diff before release. |
| 15 | Clean-room independent implementation | **OPEN** | From specs and vectors, never by translating the reference C. |
| 16 | C4 independent interoperability | **BLOCKED** on 15 | One implementation on two machines does not count. |
| 17 | C5 Stable-profile interoperability | **BLOCKED** on 7, 8, 15 | Re-run on final assigned profile bytes — see §5.6 ordering. |
| 18 | Full robustness gates | **PASSING, re-run at RC** | GCC/Clang/MSVC `-Werror`, ASan/UBSan, ARM-M0, RV32IM, C++ headers, freestanding symbol inspection. Both halves green today. |
| 19 | Specification synchronization audit | **PARTIAL** | Four stale READMEs, two hardcoded counts and three rename artifacts fixed. Full pass not yet run. |
| 20 | Specification index + compatibility matrix | **OPEN** | |
| 21 | Feature traceability ledger | **OPEN** | This document is the gate ledger, not yet the per-feature trace. |
| 22 | ICS / conformance declaration | **OPEN** | Conformance must not be inferred from passing unit tests. |
| 23 | Public security process | **OPEN** | Protocol limits are already conspicuous; the disclosure channel is not. |
| 24 | Legal / IPR / contribution closure | **OPEN — owner** | Apache-2.0 on code alone does not finish this. |
| 25 | Licensing / provenance audit | **OPEN** | |
| 26 | Governance operationalization | **OPEN** | Procedures that work, not research-governance drafts. |
| 27 | Public Candidate release | **BLOCKED** | |
| 28 | Interoperability Candidate gate | **BLOCKED** on 16, 17 | |
| 29 | Public review and errata pass | **BLOCKED** on 27 | |
| 30 | Final release bundle | **BLOCKED** | `releases/v1.0.0/`. Historical alpha manifest stays historical. |
| 31 | Reconstructability check | **BLOCKED** on 30 | Rebuild from the bundle alone. Fixes the cross-repository self-reference problem. |
| 32 | Final clean-room release rehearsal | **BLOCKED** on 30 | |
| 33 | Final go/no-go audit | **BLOCKED** | Sweep for `draft`, `TODO`, `TBD`, `provisional`, stale counts, old signatures, experimental values in Stable examples. |
| 34 | Create `v1.0.0` | **BLOCKED** on all above | |

## Counts

```text
DONE       4   (4, 5, 6, 9)
PARTIAL    5   (2, 7, 8, 18, 19)
OPEN      12
BLOCKED   13
```

`18` is counted PARTIAL rather than DONE on purpose: the gates pass **today**,
and anything added before the release candidate re-runs them. A passing gate is
a measurement, not a property.

## What "not on the critical path" means

These are deliberately excluded from v1.0 Stable and are **not** blockers.
Excluding them is a decision recorded in `V1_SCOPE.md`, not an omission:

```text
HAZARD / REQUEST / AUTHORITY_CLAIM / DEGRADED_STATE vocabularies
spatial-reference extension
AP-B0, UWB hardware
context compression
cryptographic contact binding
IP stream profile, BLE connectionless profile
PANLANG / semantic-grammar research
```

Their requirement is honest disposition, not promotion.

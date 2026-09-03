# MCL v1.0.0 release gate

**No `v1.0.0` tag exists while any row is `ACTIVE`, `WAIT_DEP`, or `EXTERNAL`.**

## States

| State | Meaning |
|---|---|
| `DONE` | Evidence exists in the tree and passes. |
| `DONE + REVERIFY_AT_RC` | Complete, and re-run once more at the release candidate. A passing gate is a measurement, not a property — this is finished work, not unfinished work. |
| `ACTIVE` | Executable now. Work it. |
| `WAIT_DEP` | Names the exact prerequisite row IDs. Not a blocker on the session — the prerequisites are themselves rows. |
| `EXTERNAL` | Literally impossible with this repository and these tools. **Must state the exact external act still required.** A technical or specification question is never `EXTERNAL`: it gets researched, tested and resolved where the evidence gives a dominant answer. |

There is no `OWNER`, `PARTIAL` or `BLOCKED` state. A question that can be
answered from evidence is answered.

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

| # | Gate | State | Evidence / next act |
|--:|---|---|---|
| 1 | v1 scope, technically resolved | `ACTIVE` | Resolve `machine_class` on the evidence in `MACHINE_CLASS_AUDIT.md` rather than deferring it. |
| 2 | Stable semantic closure | `WAIT_DEP` 1, 7, 8 | `ttl`, `validity`, `capability_tag`, refs, `transport_id` closed. |
| 3 | Registry governance closure | `ACTIVE` | Change controllers and promotion/deprecation procedures for every Stable registry. |
| 4 | Link class disposition | `DONE` | `mcl-link/spec/link-class-disposition-v1.md`. Nine Stable, one reserved. |
| 5 | Minimum capability/version negotiation | `DONE` | `link-negotiation-v1.md` + `tests/test_negotiation.c`, 4241 checks. |
| 6 | Candidate-vs-Stable major enforcement | `DONE` | `common-header-v0.2.md` §3.1, `test_major_rule.c`, 149 checks. |
| 7 | IP-DATAGRAM profile | `WAIT_DEP` 15, 16 | Normative spec done at Candidate. Promotion needs independent interop. |
| 8 | BLE-GATT profile | `WAIT_DEP` 15, 16 | Normative spec done at Candidate. Promotion needs independent interop. |
| 9 | Multi-contact isolation campaign | `DONE` | `test_multi_contact.c`, 50 checks, mutation-tested. |
| 10 | Final Wire major 1 | `WAIT_DEP` 1, 2 | Rule already enforced (row 6). |
| 11 | Final Link major 1 | `WAIT_DEP` 10 | |
| 12 | Immutable major-1 vectors | `WAIT_DEP` 10, 11 | v0 vectors never rewritten. |
| 13 | SDK release engineering | `ACTIVE` | Install rules, exported package, external consumer build. |
| 14 | Public API freeze | `ACTIVE` | Symbol baseline + diff tool. |
| 15 | Clean-room independent implementation | `ACTIVE` | From specs and vectors, different language, zero shared code. |
| 16 | C4 independent interoperability | `WAIT_DEP` 15 | |
| 17 | C5 Stable-profile interoperability | `WAIT_DEP` 15, 16 | Re-run on final assigned profile bytes. |
| 18 | Full robustness gates | `DONE + REVERIFY_AT_RC` | Both halves green. GCC/Clang/MSVC `-Werror`, ASan/UBSan, ARM-M0, RV32IM, C++ headers, symbol inspection. |
| 19 | Specification synchronization audit | `ACTIVE` | Full mechanical pass. |
| 20 | Specification index + compatibility matrix | `ACTIVE` | |
| 21 | Feature traceability ledger | `ACTIVE` | Per-feature trace, machine-checked. |
| 22 | ICS / conformance declaration | `ACTIVE` | |
| 23 | Public security process | `ACTIVE` | `SECURITY.md` with commitments the project can meet. |
| 24 | Legal / IPR / contribution closure | `ACTIVE` | Draft everything; only the licence *selection* is a product choice. |
| 25 | Licensing / provenance audit | `ACTIVE` | Every releasable artifact, machine-checked. |
| 26 | Governance operationalization | `ACTIVE` | Procedures, not drafts. |
| 27 | Public Candidate release | `WAIT_DEP` 19, 20, 22, 23, 26 | |
| 28 | Interoperability Candidate gate | `WAIT_DEP` 16, 17 | |
| 29 | Public review and errata pass | `EXTERNAL` | **Exact external act:** third parties outside this project must read the published Candidate and report. No tool here can supply an independent reviewer. Errata handling itself is row 26. |
| 30 | Final release bundle | `WAIT_DEP` 10, 11, 12, 21 | |
| 31 | Reconstructability check | `WAIT_DEP` 30 | |
| 32 | Final clean-room release rehearsal | `WAIT_DEP` 30 | |
| 33 | Final go/no-go audit | `ACTIVE` | Mechanical sweep, runnable now and again at RC. |
| 34 | Create `v1.0.0` | `WAIT_DEP` all | |

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

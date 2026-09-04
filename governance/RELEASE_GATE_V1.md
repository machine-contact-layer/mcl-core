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

| # | Gate | State | Evidence |
|--:|---|---|---|
| 1 | v1 scope, technically resolved | `DONE` | `V1_SCOPE.md` §4.8 — `machine_class` removed from major-1 `PRESENCE` on the audit evidence, not escalated. |
| 2 | Stable semantic closure | `DONE` | Every field in the three Stable objects has one meaning. `profile_id` is transport-scoped, zero-reserved, registry-governed; no Stable value is assigned and that is recorded, not hidden. |
| 3 | Registry governance closure | `DONE` | All 9 registries name a change controller and 4 procedures; `check-registry-governance.sh` in the gates. |
| 4 | Link class disposition | `DONE` | `link-class-disposition-v1.md`. Nine Stable, one reserved. |
| 5 | Minimum capability/version negotiation | `DONE` | `link-negotiation-v1.md`, 4241 checks. |
| 6 | Candidate-vs-Stable major enforcement | `DONE` | `common-header-v0.2.md` §3.1, enforced at both ends. |
| 7 | IP-DATAGRAM profile | `DONE at Candidate` | Normative spec; C5 interoperability on Experimental value 192. Standards Action assignment is row 28's business. |
| 8 | BLE-GATT profile | `DONE at Candidate` | Same. |
| 9 | Multi-contact isolation campaign | `DONE` | `test_multi_contact.c`, 50 checks, mutation-tested. |
| 10 | Wire major 1 | `DONE` | Cut. Encoder and decoder both enforce the Stable set. |
| 11 | Link major 1 | `DONE` | Cut. Layout byte-identical; class dispositions frozen. |
| 12 | Immutable major-1 vectors | `DONE` | `tier0-major1-v1.0.json` — 3 positive with **field values**, 6 negative; `validate_major1_vectors.c` in the gates. |
| 13 | SDK release engineering | `DONE` | `install-and-verify.sh` — install, external consumer, negative control. |
| 14 | Public API freeze | `DONE` | `api-baseline.sh`, 131 symbols, in the gates. |
| 15 | Clean-room independent implementation | `DONE` | `conformance/independent/`, Python, zero shared code. |
| 16 | C4 independent interoperability | `DONE` | 787 checks, both directions, matching refusals. |
| 17 | C5 Stable-profile interoperability | `DONE at Candidate` | 60 checks on Experimental profile 192. Re-run on final bytes when a Stable value is assigned. |
| 18 | Full robustness gates | `DONE + REVERIFY_AT_RC` | Both halves green; MSVC 36 targets. |
| 19 | Specification synchronization audit | `DONE` | `build-spec-index.sh --check` in the gates; drift fails the build. |
| 20 | Specification index + compatibility matrix | `DONE` | `SPECIFICATION_INDEX.md`, generated. |
| 21 | Feature traceability ledger | `DONE` | `check-traceability.sh`, 21 features, in the gates. |
| 22 | ICS / conformance declaration | `DONE` | `conformance/ICS.md`. |
| 23 | Public security process | `DONE` | `SECURITY.md` with meetable commitments. |
| 24 | Legal / IPR / contribution closure | `DONE` | `LICENSING.md`, `CONTRIBUTING.md`, `NOTICE` in all eight. |
| 25 | Licensing / provenance audit | `DONE` | `check-provenance.sh`, 79 binaries accounted for, in the gates. |
| 26 | Governance operationalization | `DONE` | `governance/GOVERNANCE.md`. |
| 27 | Public Candidate release | `EXTERNAL` | **Exact external act:** publish the eight repositories where third parties can read them. Nothing in this tree can make a repository public. |
| 28 | Interoperability Candidate gate | `EXTERNAL` | **Exact external act:** an implementation built by someone outside this project must interoperate. The clean-room implementation here is independent *of the reference code* but not of its author, and rows 16/17 say so. This is also what unblocks the Standards Action profile assignment. |
| 29 | Public review and errata pass | `EXTERNAL` | **Exact external act:** third parties read the published Candidate and report. No tool here can supply a reviewer. |
| 30 | Final release bundle | `DONE` | `releases/v1.0.0/` — 8 commits, 32 artifacts, 32 checksums. |
| 31 | Reconstructability check | `DONE` | `build-release-bundle.sh --verify` → RECONSTRUCTION VERIFIED. |
| 32 | Final clean-room release rehearsal | `DONE + REVERIFY_AT_RC` | Fresh-prefix install, external consumer, C4, C5, all checks. Re-run on the exact release commits before the tag. |
| 33 | Final go/no-go audit | `DONE + REVERIFY_AT_RC` | `go-no-go-audit.sh` — 0 fatal. |
| 34 | Create `v1.0.0` | `WAIT_DEP` 27, 28, 29 | Everything internally achievable is DONE. |

## What remains, precisely

**Three rows, all `EXTERNAL`, all the same underlying fact: this project
cannot review itself.**

```text
27  publish the repositories publicly
28  a second implementation, by someone else, interoperates
29  third parties review and report
```

Row 28 is the one that matters most, and the reason is stated in `ICS.md` and
`GOVERNANCE.md` §8 rather than glossed: the clean-room implementation in
`conformance/independent/` shares no code, no language and no build system with
the reference C, and it found three real specification-reading errors — but it
was written by the same author. That makes it strong evidence about whether the
specifications are *readable*, and no evidence at all about whether two
*organisations* can interoperate.

Row 28 is also what unblocks the Standards Action profile assignments, which is
why rows 7, 8 and 17 read `DONE at Candidate` rather than `DONE`: the
specifications are complete and interoperability is demonstrated, on the
Experimental Use value 192, which is exactly what the promotion sequence in
`V1_SCOPE.md` §5.6 prescribes at this stage.

**No `v1.0.0` tag exists while rows 27, 28 and 29 are open.** Tagging now would
claim an interoperability the project has not earned.

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

# MCL v1.0.0 release gate

**No `v1.0.0` tag exists while any row is `ACTIVE`, `WAIT_DEP` or `EXTERNAL`.**

## States

| State | Meaning |
|---|---|
| `DONE` | Evidence exists in the tree and passes. Fully satisfied for the final Stable v1 release — not "at Candidate", not "pending promotion", not "needs a final rerun". |
| `ACTIVE` | Executable now. Work it. |
| `WAIT_DEP` | Names the exact prerequisite row IDs. Not a blocker on the session — the prerequisites are themselves rows. |
| `EXTERNAL` | Literally impossible with this repository and these tools. **Must state the exact external act still required.** A technical or specification question is never `EXTERNAL`: it gets researched, tested and resolved where the evidence gives a dominant answer. |

There is no `OWNER`, `PARTIAL` or `BLOCKED` state, and there is no
`DONE at Candidate`. A question that can be answered from evidence is answered;
a row that is not finished is not marked finished under a softer word.

## The rule this ledger enforces

Every row records **the evidence that closes it**, not the intention to close
it. A row says `DONE` only when the artifact named in its evidence column is in
the tree and passing. "Implemented" is not "release-ready", and this ledger
exists to stop the two becoming synonyms.

**All checklist items must close. Not every research feature must become
Stable.** AP-B0, UWB, cryptographic binding, context compression, `HAZARD`,
`REQUEST`, `AUTHORITY_CLAIM` and `DEGRADED_STATE` are deliberately
Experimental / Candidate / Deferred. Their *correct disposition, documentation
and non-overclaiming* is itself the requirement.

## Status

| # | Gate | State | Evidence |
|--:|---|---|---|
| 1 | v1 scope, technically resolved | `DONE` | `V1_SCOPE.md` §4.8 — `machine_class` removed from major-1 `PRESENCE` on the audit evidence, not escalated. |
| 2 | Stable semantic closure | `DONE` | Every field in the three Stable objects has one meaning. `profile_id` is transport-scoped, zero-reserved, registry-governed, and now assigned. |
| 3 | Registry governance closure | `DONE` | All 9 registries name a change controller and 4 procedures; `check-registry-governance.sh` in the gates. |
| 4 | Link class disposition | `DONE` | `link-class-disposition-v1.md`. Nine Stable, one reserved. |
| 5 | Minimum capability/version negotiation | `DONE` | `link-negotiation-v1.md`, 4241 checks. |
| 6 | Candidate-vs-Stable major enforcement | `DONE` | `common-header-v0.2.md` §3.1, enforced at both ends. |
| 7 | IP-DATAGRAM profile | `DONE` | **Stable.** `IP-DATAGRAM = 1`, MCL Standards Action, 2026-09-04. The registry row answers each of the five `REGISTRY_POLICY.md` §2 requirements individually. Specification promoted to Stable. |
| 8 | BLE-GATT profile | `DONE` | **Stable.** `BLE-GATT = 1`, same date, same treatment. |
| 9 | Multi-contact isolation campaign | `DONE` | `test_multi_contact.c`, 50 checks, mutation-tested, on the assigned profile value. |
| 10 | Wire major 1 | `DONE` | Cut. Encoder and decoder both enforce the Stable set. |
| 11 | Link major 1 | `DONE` | Cut. Layout byte-identical; class dispositions frozen. |
| 12 | Immutable major-1 vectors | `DONE` | `tier0-major1-v1.0.json` — 3 positive with **field values**, 6 negative, regenerated on the assigned profile bytes before first publication and recording that revision. `validate_major1_vectors.c` in the gates, 39 checks. |
| 13 | SDK release engineering | `DONE` | `install-and-verify.sh` — install, external consumer, negative control. |
| 14 | Public API freeze | `DONE` | `api-baseline.sh`, 131 symbols, in the gates. |
| 15 | Clean-room independent implementation | `DONE` | `conformance/independent/`, Python, zero shared code. |
| 16 | C4 independent interoperability | `DONE` | 803 checks, both directions, matching refusals, every profile range carried. |
| 17 | C5 Stable-profile interoperability | `DONE` | 108 checks **on the assigned value 1**, both profiles. Includes checks read from the registry files, so relabelling 192 fails the suite — verified by doing it. |
| 18 | Full robustness gates | `DONE` | Both halves green; MSVC 36 targets. Re-run at the release candidate per `GOVERNANCE.md` §7. |
| 19 | Specification synchronization audit | `DONE` | `build-spec-index.sh --check` in the gates; drift fails the build. |
| 20 | Specification index + compatibility matrix | `DONE` | `SPECIFICATION_INDEX.md`, generated, 32 rows. |
| 21 | Feature traceability ledger | `DONE` | `check-traceability.sh`, 21 features, in the gates. |
| 22 | ICS / conformance declaration | `DONE` | `conformance/ICS.md`, including what is **not** claimed. |
| 23 | Public security process | `DONE` | `SECURITY.md` with meetable commitments. |
| 24 | Legal / IPR / contribution closure | `DONE` | `LICENSING.md`, `CONTRIBUTING.md`, `NOTICE` in all eight. |
| 25 | Licensing / provenance audit | `DONE` | `check-provenance.sh`, 101 binaries accounted for, in the gates. |
| 26 | Governance operationalization | `DONE` | `governance/GOVERNANCE.md`. |
| 27 | Public Candidate release | `WAIT_DEP` 34a | Everything a repository can carry is present and checked: `check-publication-readiness.sh` (front doors, absolute paths, secrets, claim boundary, no hosted CI) and `governance/PUBLISHING.md` (the order, and the evidence-disclosure decisions the owner takes). **The remaining act is one step and is not in this tree: making the eight repositories readable by other people.** |
| 28 | Interoperability gate | `DONE` | `V1_SCOPE.md` §5.9 defines what v1.0 requires, in three mandatory parts, and all three are met: (a) two implementations independent of each other's code cross-decoding, C4 803 + C5 108; (b) over-air between distinct devices on IP, BLE and acoustic; (c) the stack compiled by a different toolchain for a different architecture, running on an ESP32-S3 and interoperating over air — `mcl-ap/experiments/008-embedded-node/`. **See the note below: this row was narrowed by an explicit scope decision, and what it no longer covers is stated in the release.** |
| 29 | Errata and defect-report process | `DONE` | `REPORTING.md` (what a useful report is, and what happens to it) and `errata/README.md` (the list, empty at v1.0.0 by design, with the format and the never-silently-rewrite rule). `GOVERNANCE.md` §6 defines the process; these make it usable by someone who has just found a defect. |
| 30 | Final release bundle | `DONE` | `releases/v1.0.0/` — 8 commits, artifacts, checksums. |
| 31 | Reconstructability check | `DONE` | `build-release-bundle.sh --verify` → RECONSTRUCTION VERIFIED. |
| 32 | Final clean-room release rehearsal | `DONE` | `release-rehearsal.sh`, 12 checks in one pass. Re-run on the exact release commits before the tag. |
| 33 | Final go/no-go audit | `DONE` | `go-no-go-audit.sh` — 0 fatal. |
| 34 | Create `v1.0.0` | `WAIT_DEP` 27, 34a | Every internally achievable row is DONE. |
| 34a | Android peer verification | `EXTERNAL` | **Exact external act:** connect an Android device over USB. The owner's stated release order is: qualify the DFR1154, then verify against an Android peer, then publish. The board is qualified (row 28). `adb` is present and reports no device attached, so this cannot proceed from here. |

## Row 28: what was narrowed, and what was not

This row originally read *"an implementation built by someone outside this
project must interoperate"*. That is how a standards body validates a
specification, and this project is one maintainer with two laptops, a
development board, two speakers and two microphones. A bar that can only be
cleared by people who do not yet know the project exists cannot be cleared
before publication.

**The scope decision, recorded in `V1_SCOPE.md` §5.9:** v1.0.0 ships as a
functional first release with its claim boundary stated *in the release*, and
outside review happens after publication through the errata process.

That **narrows what the release claims**. It lowers no check:

```text
NOT claimed: two ORGANISATIONS have interoperated
NOT claimed: anyone outside this project has implemented these specifications
NOT claimed: anyone outside this project has reviewed them
NOT claimed: the specifications are free of defects a fresh reader would find
```

Those four lines appear in `README.md`, `ICS.md`, `V1_SCOPE.md` §5.9 and the
release manifest, in the same words, so a reader cannot find a weaker version by
looking somewhere else. `check-publication-readiness.sh` fails if any of them
loses the statement.

The clean-room implementation is independent *of the reference code* — no shared
source, language or build system — and it found three real
specification-reading defects. It was written by the same author. E6 remains
**not reached**, and the first external implementation report is a v1.1 event.

## What remains

```text
27    make the eight repositories readable by other people
34a   connect an Android device over USB
34    tag v1.0.0, after both
```

Row 34a is the owner's stated order, not an invented obstacle: the board is
qualified, Android is next, publication follows. Row 27 is one action in a
settings page. Neither is a technical question and neither can be answered from
inside this tree.

## What "not on the critical path" means

Deliberately excluded from v1.0 Stable and **not** blockers. Excluding them is a
decision recorded in `V1_SCOPE.md`, not an omission:

```text
HAZARD / REQUEST / AUTHORITY_CLAIM / DEGRADED_STATE vocabularies
spatial-reference extension
AP-B0 selection, UWB hardware
context compression
cryptographic contact binding
IP stream profile, BLE connectionless profile
PANLANG / semantic-grammar research
```

Their requirement is honest disposition, not promotion.

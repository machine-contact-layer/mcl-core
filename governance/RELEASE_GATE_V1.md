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
| 7 | IP-DATAGRAM profile | `DONE` | **Stable.** `IP-DATAGRAM = 1`, MCL Standards Action, 2026-09-04. The registry row answers each of the five `REGISTRY_POLICY.md` §2 requirements individually. Specification promoted to Stable. `transport_id = 2` promoted with it — a Stable profile scoped to a provisional identifier is incoherent (`V1_SCOPE.md` §5.6). |
| 8 | BLE-GATT profile | `DONE` | **Stable.** `BLE-GATT = 1`, same date, same treatment, and `transport_id = 3` with it. |
| 9 | Multi-contact isolation campaign | `DONE` | `test_multi_contact.c`, 50 checks, mutation-tested, on the assigned profile value. |
| 10 | Wire major 1 | `DONE` | Cut. Encoder and decoder both enforce the Stable set. |
| 11 | Link major 1 | `DONE` | Cut. Layout byte-identical; class dispositions frozen. |
| 12 | Immutable major-1 vectors | `DONE` | `tier0-major1-v1.0.json` — 3 positive with **field values**, 6 negative, regenerated on the assigned profile bytes before first publication and recording that revision. `validate_major1_vectors.c` in the gates, 39 checks. |
| 13 | SDK release engineering | `DONE` | `install-and-verify.sh` — install, external consumer, negative control. |
| 14 | Public API freeze | `DONE` | `api-baseline.sh`, in the gates. Baseline regenerated deliberately on the release candidate: **143 symbols**, the 11 additions being the `mcl_ap_modem_*` and `mcl_ap_listen_*` functions, each verified declared in a public header. The gate permits additions within a major, so a stale baseline passes while promising less than the release ships — the baseline is therefore refreshed at the candidate, not left to drift. Also fixed here: the gate read the committed baseline without stripping carriage returns, so a Windows checkout with `core.autocrlf=true` reported **every** symbol as renamed — 143 false source breaks in the exact shape of a real one. Reproduced, then fixed at the read. |
| 15 | Clean-room independent implementation | `DONE` | `conformance/independent/`, Python, zero shared code. |
| 16 | C4 independent interoperability | `DONE` | 803 checks, both directions, matching refusals, every profile range carried. |
| 17 | C5 Stable-profile interoperability | `DONE` | 108 checks **on the assigned value 1**, both profiles. Includes checks read from the registry files, so relabelling 192 fails the suite — verified by doing it. |
| 18 | Full robustness gates | `DONE` | Both halves green on the release candidate: POSIX `release-rehearsal.sh` 12/12 (GCC, Clang, ASan/UBSan, the freestanding cross-compiles, C4, C5, the external consumer install and the API gate), and MSVC **40 test targets**. Both scripts count what actually ran; take the number from the run, not from this row. Re-run at the release candidate per `GOVERNANCE.md` §7. |
| 19 | Specification synchronization audit | `DONE` | `build-spec-index.sh --check` in the gates; drift fails the build. |
| 20 | Specification index + compatibility matrix | `DONE` | `SPECIFICATION_INDEX.md`, generated. Take the row count from the generator, not from this cell: it read "32 rows" while the index carried 33, which is the same hand-maintained-number drift that made the generator itself claim "the 34 rows" of this ledger after a 35th was added. Both now count. |
| 21 | Feature traceability ledger | `DONE` | `check-traceability.sh`, 21 features, in the gates. |
| 22 | ICS / conformance declaration | `DONE` | `conformance/ICS.md`, including what is **not** claimed. |
| 23 | Public security process | `DONE` | `SECURITY.md` with meetable commitments. |
| 24 | Legal / IPR / contribution closure | `DONE` | `LICENSING.md`, `CONTRIBUTING.md`, `NOTICE` in all eight. |
| 25 | Licensing / provenance audit | `DONE` | `check-provenance.sh`, 101 binaries accounted for, in the gates. |
| 26 | Governance operationalization | `DONE` | `governance/GOVERNANCE.md`. |
| 27 | Public Candidate release | `EXTERNAL` | Everything a repository can carry is present and checked: `check-publication-readiness.sh` (front doors, absolute paths, secrets, claim boundary, no hosted CI) and `governance/PUBLISHING.md` (the order, and the evidence-disclosure decisions the owner takes). **The remaining act is one step and is not in this tree: making the eight repositories readable by other people.** |
| 28 | Interoperability gate | `DONE` | `V1_SCOPE.md` §5.9 defines what v1.0 requires, in three mandatory parts, and all three are met: (a) two implementations independent of each other's code cross-decoding, C4 803 + C5 108; (b) over-air between distinct devices on IP, BLE and acoustic; (c) the stack compiled by a different toolchain for a different architecture, running on an ESP32-S3 and interoperating over air — `mcl-ap/experiments/008-embedded-node/`. **See the note below: this row was narrowed by an explicit scope decision, and what it no longer covers is stated in the release.** |
| 29 | Errata and defect-report process | `DONE` | `REPORTING.md` (what a useful report is, and what happens to it) and `errata/README.md` (the list, empty at v1.0.0 by design, with the format and the never-silently-rewrite rule). `GOVERNANCE.md` §6 defines the process; these make it usable by someone who has just found a defect. |
| 30 | Final release bundle | `WAIT_DEP` 35 | `releases/v1.0.0/` exists and was rebuilt at the 2026-09-05 closeout, but row 35 reopened the scope and has been changing specifications, tools, fixtures and the API surface since. The bundle in the tree is therefore **stale by design**, and the rehearsal reports it: `release bundle reconstruction` is the single failing check in the current 12/13 run, on exactly the artifacts row 35 edited. A stale bundle is the expected state during active scope work; calling it `DONE` while the reconstruction check fails is exactly the fake-finished state this ledger's `States` section forbids. Rebuilt **once**, after row 35 closes. |
| 31 | Reconstructability check | `WAIT_DEP` 30 | `build-release-bundle.sh --verify` → RECONSTRUCTION VERIFIED, **from a fresh clone rather than from the tree that built it**. The digests are taken over the working tree, so before the line-ending policy landed a clone made by Git for Windows with `core.autocrlf=true` failed all 35 of them on a tree where nothing had changed — reproduced deliberately, then fixed at the cause. All eight repositories re-cloned with that setting verified at the 2026-09-05 closeout. The mechanism is proven; the check is meaningless until row 30 rebuilds the bundle it verifies, so it is re-run then. |
| 32 | Final clean-room release rehearsal | `WAIT_DEP` 30, 31 | `release-rehearsal.sh` ran green twice at the closeout — once in the working tree and once inside fresh clones of all eight repositories, which is what "clean-room" was supposed to mean — with the MSVC half alongside, 40 targets. It is currently **12 passed / 1 failed**, the failure being row 30's stale bundle. The word in this row is *final*: it means the rehearsal that ran on the exact commits that get tagged. That run has not happened, so this row is not `DONE`. |
| 33 | Final go/no-go audit | `WAIT_DEP` 32 | `go-no-go-audit.sh` reported 0 fatal at the 2026-09-05 closeout, and the script is in the gates. Same reason as row 32: the row says *final*, meaning the audit that runs on the commits that get tagged. Row 35 has changed the tree since. Re-run last, after the bundle is rebuilt and the rehearsal is green. |
| 34 | Create `v1.0.0` | `WAIT_DEP` 35, 30, 31, 32, 33, 27 | Row 34a closed 2026-09-04 and the closeout pass (API baseline, ledger repair, both gate halves, rebuilt bundle) closed 2026-09-05, but that pass is no longer the release state: row 35 reopened the scope, and rows 30-33 were returned to `WAIT_DEP` on 2026-09-06 because the artifacts they close over are stale while row 35 runs. The tag waits on the scope work, then on one rebuild-and-reverify pass, then on publication. |
| 34a | Android peer verification | `DONE` | `mcl-ip/evidence/e4-android-udp-20260904/` — an iQOO 9 on Android 14 (arm64-v8a) as a third IP peer over its own 2.4 GHz SoftAP. Four cells (both directions × both majors), 142 checks, 0 failed, 400 sustained frames, 0 lost, 0 retries. The Stable path — major-1 Link frames carrying major-1 `PRESENCE` and `TRANSPORT_OFFER` on profile 1 — was exercised in both directions, including refusal of reserved `profile_id` 0, reserved `transport_id` 0, and a Candidate object at the Stable major. Harness in `mcl-ip/hardware/android-udp-peer/`. |
| 35 | Builder-interoperability floor | `ACTIVE` | `V1_SCOPE.md` §5.10, on the evidence in `research/TWO_BUILDER_AUDIT.md`. Row 28 established that *these specifications* can be implemented from their text. It never asked whether two builders who never coordinate are **guaranteed** a common first-contact path, and today they are not: every transport binding is individually optional, BLE rendezvous advertising is conformant to omit, IP defers discovery and assigns no port, and the one bearer needing no prior arrangement is Experimental. The guaranteed intersection of two conformant implementations is empty. **Conformance layers specified 2026-09-05** in `spec/conformance-profiles-v1.md` — `MCL Base 1` complete and claimable, `MCL Stranger-Contact 1` normatively complete but unclaimable until `AP-BOOTSTRAP-1` exists, `MCL Secure-Stranger 1` a reserved name. **AP bootstrap requirements** stated in `mcl-ap/spec/ap-bootstrap-requirements-v0.1.md`, and Experiment 010 measured the error structure the coding decision depends on. **Deployment-profile schema landed 2026-09-06** — `spec/deployment-profile-v1.md`, `tools/validate_deployment_profile.c`, a reference deployment, nine negative fixtures and `check-deployment-profiles.sh` in the rehearsal; it derives each guarantee from the profile's content rather than letting a deployment declare one, and refuses peer-specific rendezvous data so the §5.10 criterion cannot be passed by prearrangement. Closes when the §5.10 acceptance criterion — two implementations given only the release, a deployment profile and its trust anchors, with no peer address, token, secret or pairing step — reaches migration and policy under a named conformance profile, plus the three-or-more machine contention variant. |

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
34    tag v1.0.0, after that
```

Row 27 is one action in a settings page. It is not a technical question and it
cannot be answered from inside this tree.

**Row 34a closed on 2026-09-04.** The owner's stated release order was: qualify
the DFR1154, then verify against an Android peer, then publish. The board was
qualified in row 28 and the Android verification is now recorded in
`mcl-ip/evidence/e4-android-udp-20260904/`. It found no protocol defect. It did
find a stale harness case — `udp_over_air_peer.c` was still sending a frame with
no frame check, which the IP-DATAGRAM profile forbids — and that refusal is now
a permanent negative case rather than a passing test that was never re-run.

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

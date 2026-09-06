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
| 14 | Public API freeze | `DONE` | `api-baseline.sh`, in the gates. The baseline is regenerated deliberately at each release candidate. **The symbol count is not repeated here**: it is derivable from `conformance/api-baseline-v1.txt`, this row said 143 while the file held 155, and a hand-maintained copy of a derivable number is a defect waiting to happen. Take it from the file. The gate permits additions within a major, so a stale baseline passes while promising less than the release ships — the baseline is therefore refreshed at the candidate, not left to drift. Also fixed here: the gate read the committed baseline without stripping carriage returns, so a Windows checkout with `core.autocrlf=true` reported **every** symbol as renamed — 143 false source breaks in the exact shape of a real one. Reproduced, then fixed at the read. |
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
| 30 | Final release bundle | `WAIT_DEP` 35 | `releases/v1.0.0/` — the artifact and checksum counts are in `artifacts.txt` and `SHA256SUMS` and are **not** copied here; this row said 35 after the bundle grew to 48. **This row was marked `DONE` on 2026-09-06 on the strength of a rebuild taken *before* row 35 finished, and that was wrong: row 35 is still `ACTIVE` and the tree has moved since.** The rehearsal has reported `release bundle reconstruction` as its single failing check throughout, naming exactly the files the scope work changed — the gate was right and this cell was not. It is stale **by design** until the engineering surface stops changing; it is rebuilt **once**, after row 35 closes, and never to turn this cell green. |
| 31 | Reconstructability check | `WAIT_DEP` 30 | `build-release-bundle.sh --verify`. It cannot pass while row 30 is stale, and a pass recorded against a superseded bundle would mean nothing. The digests are taken over the working tree, so before the line-ending policy landed a clone made by Git for Windows with `core.autocrlf=true` failed all of them on a tree where nothing had changed — reproduced deliberately, then fixed at the cause. The same defect was caught again on 2026-09-06 in Experiment 011's evidence, where run logs were hashed as CRLF while git stores LF; caught before it reached the bundle. |
| 32 | Final clean-room release rehearsal | `WAIT_DEP` 30, 31 | `release-rehearsal.sh`. The current run is **15 of 16**, and the one failure is row 30's stale bundle. The rehearsal is only *final* when it runs green on the artifacts the release actually ships, so this row closes after the single rebuild. Two gates added during row 35 are part of the run: `check-maturity.sh`, which found eight places where a Stable claim rested on a document calling itself Research Draft, and `mcl-ap/conformance/check-vectors.sh`, which cross-tests the reference and an independent receiver on one corpus against one set of expectations. |
| 33 | Final go/no-go audit | `WAIT_DEP` 30, 31, 32 | `go-no-go-audit.sh` — 0 fatal when last run, but on commits that row 35 has since moved past. A go/no-go decision is about the artifacts being released, so it is retaken after the rebuild rather than inherited. |
| 34 | Create `v1.0.0` | `WAIT_DEP` 35, 30, 31, 32, 33, 27, 36 | Row 34a closed 2026-09-04 and the closeout pass (API baseline, ledger repair, both gate halves, rebuilt bundle) closed 2026-09-05, but that pass is no longer the release state: row 35 reopened the scope. **Rows 30-33 were returned to `WAIT_DEP` on 2026-09-07.** They had been left reading `DONE` while this row's own text said they had been returned and while the rehearsal reported the bundle failing — a ledger disagreeing with itself and with its own gate, which is the exact failure this file exists to prevent. The tag waits on the scope work, then on one rebuild-and-reverify pass, then on publication, **then on row 36**: `ARCHITECTURE_CHARTER.md` §6 requires public review for Stable, and making a repository readable is not review. |
| 34a | Android peer verification | `DONE` | `mcl-ip/evidence/e4-android-udp-20260904/` — an iQOO 9 on Android 14 (arm64-v8a) as a third IP peer over its own 2.4 GHz SoftAP. Four cells (both directions × both majors), 142 checks, 0 failed, 400 sustained frames, 0 lost, 0 retries. The Stable path — major-1 Link frames carrying major-1 `PRESENCE` and `TRANSPORT_OFFER` on profile 1 — was exercised in both directions, including refusal of reserved `profile_id` 0, reserved `transport_id` 0, and a Candidate object at the Stable major. Harness in `mcl-ip/hardware/android-udp-peer/`. |
| 35 | Builder-interoperability floor | `ACTIVE` | `V1_SCOPE.md` §5.10, on the evidence in `research/TWO_BUILDER_AUDIT.md`. Row 28 established that *these specifications* can be implemented from their text. It never asked whether two builders who never coordinate are **guaranteed** a common first-contact path, and today they are not: every transport binding is individually optional, BLE rendezvous advertising is conformant to omit, IP defers discovery and assigns no port, and the one bearer needing no prior arrangement is Experimental. The guaranteed intersection of two conformant implementations is empty. **Conformance layers specified 2026-09-05** in `spec/conformance-profiles-v1.md` — `MCL Base 1` complete and claimable, `MCL Stranger-Contact 1` normatively complete, `MCL Secure-Stranger 1` a reserved name. **`AP-BOOTSTRAP-1` landed 2026-09-06** (`mcl-ap/spec/ap-bootstrap-1.md`), so Stranger-Contact 1 is now claimable **with a caveat**: the profile is Candidate, because every measurement of its waveform comes from one transmitter class, and the caveat travels in code (`MCL_CONFORMANCE_CAVEAT_BOOTSTRAP_CANDIDATE`) rather than only in prose. **Experiment 011 measured the bootstrap objects over air** and made the receiver work at those sizes — 21/45 to 44/45, with FEC rejected on the measured error structure. **The rendezvous coordinator landed** in `mcl-sdk` (`mcl/rendezvous.h`), which is the layer that actually drives detection → PRESENCE → ordered bearer trial → OFFER/ACCEPT → candidate validation → migration, and without which every builder would have written that loop differently. **Corrected 2026-09-07:** the first version had no notion of *whose* round a round was, so every machine could be announcer, responder, offerer and acceptor at once. Two machines converged; three did not — 600 s of simulation gave 36 bearer agreements, 0 validations and 0 migrations, in a stable cycle that never broke on its own. `AP-BOOTSTRAP-1` §8.1 now fixes one solicitor per round with `TRANSPORT_ACCEPT`'s `migration_ref` echo as the selection, §8.2 requires that reference to be random on a shared medium (a value derived from the non-unique `source_ref` can name two contenders at once), and §7.2 freezes the timing as profile constants with the response timeout **derived** rather than guessed — it had been 3000 ms against a legal maximum backoff of 3750 ms, so a peer behaving perfectly could be declared silent before it was allowed to answer. Glare resolution is not gone but is now unreachable under §8.1 and is documented as §8.3. Each rule is proved by a mutation that makes the suite fail. **The BLE half of the same gap is now written down too.** `AP-BOOTSTRAP-1` gets two strangers to an agreed candidate bearer; if that bearer is BLE, `BLE-GATT-1` specifies carriage over an *established* connection and makes advertising explicitly optional, so two conformant builders can each wait for the other to connect. `mcl-ble/spec/ble-activate-1.md` (**BLE-ACTIVATE-1**, Candidate, 2026-09-07) closes it *without touching Stable `BLE-GATT-1`*: it derives the advertiser/scanner roles from the wire rather than choosing them (only `TRANSPORT_OFFER` carries an `endpoint_token`, so only the offerer can be found), fixes the beacon match on UUID **and** token, forbids a zero token for a BLE candidate, and derives the 30 s activation window from the controller's own retransmission schedule. It is Candidate because **no two independent implementations have activated a BLE candidate against each other** — so until it or an equivalent is Stable, `MCL Stranger-Contact 1` over a BLE candidate bearer is **not** guaranteed between builders who never coordinate. That is the same §5.10 finding one layer down, and it is stated in the profile rather than left for an integrator to hit. **Specification maturity is now gated** by `check-maturity.sh`, which found and closed eight places where a Stable claim rested on a document calling itself Research Draft. **AP bootstrap requirements** stated in `mcl-ap/spec/ap-bootstrap-requirements-v0.1.md`, and Experiment 010 measured the error structure the coding decision depends on. **Deployment-profile schema landed 2026-09-06** — `spec/deployment-profile-v1.md`, `tools/validate_deployment_profile.c`, a reference deployment, nine negative fixtures and `check-deployment-profiles.sh` in the rehearsal; it derives each guarantee from the profile's content rather than letting a deployment declare one, and refuses peer-specific rendezvous data so the §5.10 criterion cannot be passed by prearrangement. Closes when the §5.10 acceptance criterion — two implementations given only the release, a deployment profile and its trust anchors, with no peer address, token, secret or pairing step — reaches migration and policy under a named conformance profile, plus the three-or-more machine contention variant. |
| 36 | Charter-required public review | `EXTERNAL` | `ARCHITECTURE_CHARTER.md` §6 requires **public review** for a Stable Specification, in addition to interoperability and operational evidence. This row exists because that requirement was being satisfied nowhere: row 27 makes the repositories readable, and readability is not review. **The external act is people outside this project reading the specifications and reporting on them**, after row 27. No fixed waiting period is recorded, because the charter names review, not a timer — the evidence is the reports and what was done about them, tracked as errata. Two consequences while this row is open: no profile is promoted to Stable on private evidence alone, and **AP's Standards Action profile identifier is not assigned** — `AP-BOOTSTRAP-1` and `BLE-ACTIVATE-1` stop at Interoperability Candidate, and profile 192 stays Experimental forever. |

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
35    the builder-interoperability floor          ACTIVE
27    make the eight repositories readable        EXTERNAL
34    tag v1.0.0, after both                      WAIT_DEP
```

**Row 35 is listed first because it is the one still being worked.** This
section named only 27 and 34 while row 35 sat above it marked `ACTIVE`, which is
the same defect the row states forbid under a softer word -- a summary that
disagrees with the table it summarises. Take the open set from the table's
states, not from this list.

Row 35 closes on evidence that is not yet in the tree: a zero-prior-knowledge
two-builder run through migration, and a three-or-more machine contention
campaign. Both need machines in a room. What has closed inside the tree is
recorded in the row.

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

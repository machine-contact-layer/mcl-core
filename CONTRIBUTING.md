# Contributing to MCL

## Before anything else

**Run both gate halves and say the result in your pull request.**

```sh
mcl-core/tools/local-gates.sh        # GCC, Clang, ASan/UBSan, ARM-M0, RV32IM,
                                     # C++ headers, API surface, registries,
                                     # spec index, traceability
mcl-core/tools/local-gates-msvc.ps1  # MSVC /W4 /WX
```

**Neither run alone is "the gates".** A change that passes one and breaks the
other has broken the build.

**There is no CI.** This project deliberately uses no GitHub Actions; gates are
run locally by whoever proposes the change. That places the obligation on you
rather than on a machine, which is the point.

## What contributions are licensed under

Apache-2.0, the same as the project. Submitting a contribution asserts that you
wrote it or have the right to submit it, that it may be released under
Apache-2.0, that you are not knowingly contributing third-party code under
incompatible terms, and that you have disclosed any patent claim you know to be
essential to it. No CLA is required. See [`LICENSING.md`](LICENSING.md) §6.

## What a change costs

Set by what it can break, not by its size. Full table in
[`governance/GOVERNANCE.md`](governance/GOVERNANCE.md) §2.

| Change | What it needs |
|---|---|
| Comments, non-normative prose | Both gate halves. |
| New test | Both gate halves. |
| Behaviour change in a Candidate area | Gates, a reason in the commit message, and the affected specification updated **in the same commit**. |
| Anything touching a Stable surface | `GOVERNANCE.md` §5. Expect a new major version. |
| A registry assignment | `GOVERNANCE.md` §4. |

## House rules that are not obvious

These are conventions the existing code follows and that a reviewer will ask
about if a change does not.

**Protocol code is freestanding C99.** No heap, no libc at runtime, no OS calls,
caller-owned memory. The ARM-M0 and RV32IM gate steps inspect undefined symbols,
so a `memcpy` the compiler inserted on your behalf will fail the build — which
is why byte-copy destinations are `volatile` throughout. This has already caught
a real defect; see `governance/IMPLEMENTATION_CONTRACT.md` §2.2.

**Python appears in exactly two places** and is not permitted elsewhere: the
clean-room implementation under `mcl-core/conformance/independent/`, and
research tooling under `research/`. Neither is protocol-facing and nothing links
against them.

**Never hardcode a count.** Test counts, field counts, "sixteen of the
twenty-one" — these have gone stale four separate times in this project. Derive
the number, or do not state it.

**Never edit historical evidence or published vectors.** An evidence file
records what was measured on a date; a vector records what an implementation
emitted. Changing either to match newer code destroys the only property that
makes it worth having. Add a new versioned artifact instead.

**A refusal test is worth more than an acceptance test.** What decides whether
two independent implementations agree is what gets rejected. Most of the
existing test files are refusals, deliberately.

**Say what a result does not establish.** Every gate script, evidence README and
conformance document in this project ends by stating its own limits. A result
presented without them will be asked to add them.

## Commit messages

State what changed and **why**, and name the evidence for any claim.

A commit that says a gate item is closed must name the artifact that closes it.
"Implemented" is not "release-ready" — see
[`governance/RELEASE_GATE_V1.md`](governance/RELEASE_GATE_V1.md).

If a change is a correction, say what was wrong. The commit history is where the
reasoning lives, and a future reader needs the mistake more than the fix.

## Reporting a vulnerability

**Not through a pull request or a public issue.** See
[`SECURITY.md`](SECURITY.md), which also lists what is *not* a vulnerability —
MCL v1.0 has no confidentiality, no peer authentication and no replay
protection, and those are recorded scope decisions rather than defects.

## Where to start

- `governance/V1_SCOPE.md` — what v1.0 claims, and what it deliberately does not.
- `governance/ARCHITECTURE_CHARTER.md` — the invariants no layer may violate.
- `SPECIFICATION_INDEX.md` — every specification and its status.
- `conformance/independent/SPEC_GAPS.md` — what a clean-room implementer got
  wrong reading the specifications, which is the best available list of where
  they are unclear.

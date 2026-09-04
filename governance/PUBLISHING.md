# Publishing MCL

Release gate item 27. This document exists so that the act of publishing is a
decision someone takes in one step, with everything else already true.

**Nothing in this tree can make a repository readable by other people.** That
is the whole of what remains external, and it belongs to the maintainer.

## What must be true first

All of it is checked, not remembered:

```sh
mcl-core/tools/check-publication-readiness.sh   # front doors, paths, secrets, claims
mcl-core/tools/release-rehearsal.sh             # everything runnable, one pass
mcl-core/tools/local-gates-msvc.ps1             # the other compiler
mcl-core/tools/go-no-go-audit.sh                # unfinished-work markers
```

The readiness check enforces, per repository: a `README.md`, a `LICENSE` and a
`NOTICE`; in `mcl-core` also `SECURITY.md`, `LICENSING.md`, `CONTRIBUTING.md`,
`CODE_OF_CONDUCT.md`, `REPORTING.md`, `SPECIFICATION_INDEX.md` and
`errata/README.md`. It fails on an absolute user path in any tracked script, on
anything credential-shaped, on a missing claim boundary in the three documents a
reader actually opens, and on any hosted-CI configuration.

## The one thing it cannot decide for you

Evidence files sometimes contain the local path a tool printed. The check lists
them and calls them **decisions**, not failures, because the alternative is
worse:

> **Evidence is never edited.** A record of what a machine printed on a date
> stops being that the moment it is tidied. Rewriting one to look cleaner is
> the single thing this project's rules forbid outright.

So for each listed file, choose deliberately:

```text
publish it as it stands        the path discloses a username and nothing else
withhold that directory        the evidence stays private; the README says it
                               exists and is available on request
redact the whole record        replace the directory with a note saying what
                               was measured and that the raw record was
                               withheld -- never a partially edited record
```

Whichever is chosen, say which in the evidence directory's README. A reader who
finds a gap should find the reason for the gap in the same place.

## The order

1. Run all four scripts above. Every one green.
2. Decide the evidence files the readiness check listed.
3. Confirm the release bundle reconstructs:
   `mcl-core/tools/build-release-bundle.sh --verify v1.0.0`.
4. **Make the eight repositories readable.** This step, and only this step, is
   outside the tree.
5. Confirm from a logged-out session that each front door renders and that the
   links between repositories resolve. Cross-repository links are relative and
   are the first thing to break when eight repositories become eight URLs.
6. Only then tag. `GOVERNANCE.md` §7: no tag while any gate row is open, and
   both gate halves re-run on the exact commits being released.

Publishing before tagging is deliberate. A tag is a promise that a specific
tree is what people fetched; making the tree fetchable first means the promise
is made about something that exists.

## What publishing starts

The errata process, and it is the point rather than a side effect.
`V1_SCOPE.md` §5.9 records that these specifications have not been read by
anyone outside this project. `REPORTING.md` is where the first outside reader
goes, `errata/` is where the result is recorded, and the first external
implementation report is a v1.1 event — not a defect in v1.0 and not a reason
to have withheld it.

## What publishing does not change

It does not make the release independently reviewed, and no README may imply
that it does. Until an implementation built by someone else interoperates, the
claim boundary in `V1_SCOPE.md` §5.9 stands exactly as written, in the same
words, in `README.md`, `ICS.md` and the release manifest.

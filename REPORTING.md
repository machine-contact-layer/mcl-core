# Reporting a defect in MCL

This project ships a v1.0 that has **not been reviewed by anyone outside it**.
`governance/V1_SCOPE.md` §5.9 says so in the release rather than leaving a
reader to assume otherwise, and this document is the other half of that
admission: the process for the defects a first external reader will find.

A report is welcome even if it is wrong. A specification that is easy to
misread has a defect whether or not the misreading was reasonable.

## What kind of thing is it

| Kind | Example | Where it goes |
|---|---|---|
| **Erratum** | the specification says something it did not mean, and no conforming implementation's bytes or behaviour change | `errata/` in the owning repository — `GOVERNANCE.md` §6 |
| **Breaking defect** | a Stable meaning or a Stable byte layout is wrong | a new major version — `GOVERNANCE.md` §5. There is no third option, and "a clarification that happens to change behaviour" is a breaking change |
| **Implementation bug** | the reference C disagrees with the specification | fix the code; the specification is the authority |
| **Interoperability failure** | your implementation and the reference disagree about bytes | the most valuable report this project can receive — see below |
| **Vulnerability** | a security defect | `SECURITY.md`, not here |

## What a useful report contains

For anything about bytes, this is the whole report:

```text
1. the exact input bytes, in hex
2. what your implementation did with them
3. what you expected, and the section of which document says so
4. the version: wire major, link major, and the commit or tag
```

Nothing else is required. A hex string and a specification reference are enough
to settle almost any disagreement about this protocol, because the whole
protocol is bytes and the meanings of bytes.

For an interoperability failure, add: which side produced the bytes, and whether
the other side **refused** them or **accepted them and read them differently**.
Those are very different defects. A refusal is a disagreement about validity; a
silent difference in interpretation is a disagreement about meaning, and it is
the one that stays hidden.

> This project has a worked example of the second kind. The clean-room
> implementation decoded `AUTHORITY_CLAIM` with an 8-bit `authority_class` and a
> 16-bit jurisdiction instead of 6 and 12. Because that object carries 6 bits of
> padding, **both layouts consume exactly 14 bytes** — the published vector
> passed, the length check passed, and round-tripping passed, while every field
> after `source_ref` was misread. It was found only by comparing decoded
> *values*. `conformance/independent/SPEC_GAPS.md` §2.

## What happens next

```text
report -> classify -> erratum:  correction published AND recorded in errata/
                   -> breaking: new major, new immutable vectors, evidence re-run
                   -> neither:  answered, with the reasoning
```

An erratum never silently rewrites the specification text without leaving the
record. The correction is applied *and* listed, because a reader working from a
printed or cached copy needs to know it changed.

**What is not promised:** a response time. This project is one maintainer.
`SECURITY.md` states the one commitment that is time-bound, and it is
deliberately the only one — a service level nobody can meet is worse than an
absent one.

## The errata list

[`errata/`](errata/) in this repository, and in each repository for its own
documents. It is empty at v1.0.0. That is the expected state of a first release
and not a claim that none will be needed.

## What is most useful

In rough order:

1. **An implementation written from the specifications by someone who is not
   this project**, interoperating or failing to. That is the E6 evidence v1.0.0
   explicitly does not claim, and one report of it is worth more than any
   number of internal checks.
2. **A passage you had to read twice.** Ambiguity found by a reader is cheaper
   than ambiguity found by two deployed implementations.
3. **A conformance vector that disagrees with your reading.** The vectors carry
   expected field values for exactly this purpose.

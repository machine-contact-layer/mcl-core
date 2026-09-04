# MCL governance — how this project actually operates

Release gate item 26.

## 0. Why this exists alongside the other governance documents

`ORGANIZATION_MODEL.md` describes a future multi-party standards body with an
Architecture Review Council and per-layer working groups. `IPR_PRINCIPLES.md`
states intended policy direction. Both are **design drafts for an organization
that does not exist yet**, and a release cannot be governed by an organization
that does not exist.

This document describes the procedures **in force today**, for the project as it
actually is: one maintainer, eight repositories, no external contributors yet,
and no incorporated body. It is deliberately smaller than the future model and
says so, because a governance document describing bodies nobody sits on is
worse than none — it lets a reader believe review happened that did not.

When the multi-party model is stood up, this document is superseded by it. Until
then, this is the process.

## 1. Roles

| Role | Held by | Authority |
|---|---|---|
| **Maintainer** | The repository owner | Every decision below. Sole release authority. |
| **Change controller** | The maintainer, for every MCL registry | Registry assignments and promotions (§4). |
| **Security contact** | The maintainer | Vulnerability reports (`SECURITY.md`). |
| **Contributor** | Anyone submitting a change | No decision authority; see §3. |

**One person holds every role.** That is a real limitation and it is stated
rather than disguised by inventing committee names. Its practical consequence:
**MCL cannot self-certify interoperability.** No amount of internal review
substitutes for a second implementation, which is why release gate items 15–17
exist and why `V1_SCOPE.md`'s go/no-go rule refuses to call anything Stable that
is supported only by the reference implementation.

**Contact:** the repository owner, via the GitHub account that owns the eight
MCL repositories. For security reports use a private channel — a GitHub security
advisory on the affected repository — not a public issue.

## 2. What may change, and what it costs

The cost of a change is set by what it can break, not by its size.

| Change | Requires |
|---|---|
| Typo, comment, non-normative prose | Maintainer commit. |
| New test, new negative case | Maintainer commit; must pass both gate halves. |
| New **Experimental** registry assignment | Maintainer commit; recorded in the registry with its status. |
| Behaviour change in a **Candidate** area | Maintainer commit, plus a recorded reason in the commit message and any affected specification updated in the same commit. |
| Any change to a **Stable** specification or registry | §5, and a new major version if bytes or meanings change. |
| A new **Stable** registry assignment | Standards Action, §4. |
| Promotion of anything to **Stable** | The go/no-go rule in `V1_SCOPE.md` §6, in full. |

**The rule that governs all of them:** a change to a Stable surface that alters
what two independent implementations would do requires a new major version. It
is never made in place, and never made because the alternative is inconvenient.

## 3. Contributions

Until a contribution agreement exists (release gate item 24), contributions are
accepted on these terms and no others:

1. Submitted as a pull request against the affected repository.
2. The contributor asserts they have the right to submit the work and that it
   may be released under the repository's licence.
3. The maintainer reviews and merges, or declines with a reason.
4. Both gate halves must pass before merge. No exceptions, including for the
   maintainer's own changes.
5. **No GitHub Actions.** Gates are run locally by the person proposing the
   change, and the result is stated in the pull request. This is a deliberate
   standing constraint of the project.

A contribution touching a Stable surface will be declined unless it comes with
the evidence §5 requires. That is not a judgement about the contributor.

## 4. Registry procedures

Every MCL registry follows the same four procedures. They are stated once here
and referenced by each registry rather than restated in each.

**Registries in force:**

| Registry | Location |
|---|---|
| Semantic codes | `mcl-core/registries/semantic-codes-v0.2.json` |
| Tier-0 fields | `mcl-core/registries/tier0-fields-v0.1.json` |
| Transport IDs | `mcl-link/registries/transport-ids-v0.1.json` |
| Handoff operations | `mcl-link/registries/handoff-ops-v0.1.json` |
| Extension IDs | `mcl-wire/registries/extension-ids-v0.1.json` |
| IP profiles | `mcl-ip/registries/ip-profiles-v0.1.json` |
| BLE profiles | `mcl-ble/registries/ble-profiles-v0.1.json` |
| AP profiles | `mcl-ap/registries/ap-profiles-v0.1.json` |
| UWB profiles | `mcl-uwb/registries/uwb-profiles-v0.1.json` |

**Change controller for all of them: the maintainer.**

### 4.1 Application

Open an issue on the owning repository naming: the registry, the requested
range, the intended meaning, a permanent specification reference, and the
criticality/failure behaviour a receiver that does not implement it must
exhibit. An application without a specification reference is not an application.

### 4.2 Review

The change controller checks:

- the requested value is in a range whose policy permits the request
  (Standards Action, Specification Required, Experimental Use, Private Use);
- the meaning is domain-general, not a domain concept pushed into domain-general
  Core (`REGISTRY_POLICY.md`);
- unknown-value behaviour is defined;
- for a Stable assignment, the specification reference is permanent and public.

### 4.3 Promotion

**Experimental Use values are never relabelled.** A value cannot become Stable
by having its `status` edited. Promotion means:

```text
1. A normative specification, complete, published at Candidate.
2. An independent implementation interoperates against that specification,
   using the EXPERIMENTAL value.
3. That interoperability satisfies the registry's promotion gate.
4. A NEW value is assigned in the Standards Action range.
5. Conformance evidence is re-run on the final assigned bytes.
```

Step 5 is not ceremony where the identifier travels on the wire — `profile_id`
does, inside `TRANSPORT_OFFER` and `TRANSPORT_ACCEPT`, so changing it changes
what was tested.

### 4.4 Deprecation

A retired assignment becomes a **permanent tombstone**. Its value is never
reused, and a decoder must refuse it rather than treat it as unassigned. A peer
that once meant something by value *N* would otherwise be misread rather than
refused, which is worse than an error.

## 5. Changing a Stable specification

1. Open an issue stating what is wrong and what breaks if it is not fixed.
2. Classify it:
   - **Erratum** — the specification says something it did not mean, and no
     conforming implementation's bytes or behaviour change. §6.
   - **Breaking** — bytes or meanings change. Requires a new major version.
     There is no third option, and "clarification that happens to change
     behaviour" is a breaking change.
3. For a breaking change: a new major, new immutable vectors, and the
   conformance evidence re-run. The old major's vectors and evidence are never
   edited.

## 6. Errata

An erratum corrects a specification without changing what a conforming
implementation does.

```text
report -> classify -> if erratum: publish correction + record in the errata list
                   -> if breaking: escalate to section 5
```

Errata are recorded in `errata/` in the owning repository, each naming the
document, the affected text, the correction, and the date. **An erratum never
silently rewrites the specification text without leaving the record**: the
correction is applied *and* listed, because a reader working from a printed or
cached copy needs to know it changed.

**Security errata** may be published before any normal review period elapses.
That is the only place this process is deliberately shortened, and the reason is
that a known-exploitable defect left unfixed for procedural reasons is worse
than a fast correction.

## 7. Releases

Release authority: the maintainer.

A release happens when **every mandatory row of `RELEASE_GATE_V1.md` is DONE**.
No tag is created while any row is ACTIVE, WAIT_DEP or EXTERNAL. A row is DONE
only when the evidence named in its evidence column exists in the tree and
passes — an intention to do the work does not close a row.

Both gate halves — `mcl-core/tools/local-gates.sh` and
`local-gates-msvc.ps1` — are re-run immediately before the tag, on the exact
commits being released.

## 8. What this governance cannot do

Stated plainly, because governance that overstates its own reach is the failure
mode this document is trying to avoid:

- **It cannot substitute for independent review.** One maintainer reviewing
  their own work is not review. External review is release gate item 29 and is
  the one row that no amount of work inside this repository can close.
- **It cannot make MCL a standards body.** MCL is not incorporated, holds no
  trademark, and cannot certify conformance. `ORGANIZATION_MODEL.md` describes
  what would be required.
- **It cannot bind future participants.** Everything here is the maintainer's
  own commitment, revocable by the maintainer, until an actual organization
  exists with actual members.

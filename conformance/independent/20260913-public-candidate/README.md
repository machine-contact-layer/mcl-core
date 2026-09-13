# Public Candidate operations receipt

Receipts for release gate rows 27 and 37, taken on 2026-09-13 after all nine
repositories were made public.

| file | what it records |
| --- | --- |
| `PUBLIC_AUDIT.txt` | the logged-out audit, run with no token and no credential helper |
| `PUBLIC_CI.json` | the qualifying public `ci` and `release-gates` runs, by run id |
| `HEADS.json` | the heads those runs qualified, and `.github` separately |
| `releases/v1.0.0/GOVERNANCE_RECEIPT.json` | the live read-back of every ruleset |

## What the audit found

All eight release repositories and `.github` are anonymously readable. The
organization profile renders. Every release repository serves its LICENSE, a
security policy and a contributing guide: `mcl-core` its own, the other seven
through the default community-health files in `.github`, verified from the
community profile and security-policy pages rather than assumed. The 14 unique
cross-repository links in the READMEs and the 7 evidence-index claim paths all
resolve. No credential-shaped string exists in any tracked file. Absolute user
paths appear only in retained evidence records, which
`check-publication-readiness.sh` lists as disclosure decisions rather than
defects. There are zero tags and zero GitHub Releases.

## What public qualification found first

The first public `release-gates` run failed, and it was right to. Two digests
under `mcl-ap/experiments/011-bootstrap-over-air` had been recorded over a
Windows working tree still holding CRLF bytes, while Git stores LF; a Windows
sweep reported them passing because it read the wrong bytes. `mcl-ap` #1
corrected the two records without touching the measurements, and `mcl-core` #1
made the digest gate compare the working tree against the committed blob. Both
were merged before the qualifying runs recorded in `PUBLIC_CI.json`.

## Review, stated accurately

`@0j0bit` and `@sed-boi` are two GitHub accounts controlled by the same project
owner. The code-owner requirement is satisfied by the owner reviewing changes
proposed by the `mcl-release-governor` App. That is account redundancy, not
independent two-person review.

## What this does not establish

These receipts record operations. They are not review: row 36, public external
review, remains open, and no Stable tag or GitHub Release exists or is implied.

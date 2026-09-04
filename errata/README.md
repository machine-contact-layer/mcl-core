# MCL errata

**Empty at v1.0.0.** That is the expected state of a first release, not a claim
that no errata will be needed. `governance/V1_SCOPE.md` §5.9 records that these
specifications have not been read by anyone outside this project, and the
clean-room implementation — written by the same author — still found three real
specification-reading defects. A reader who is not the author will find more.

## What goes here

An erratum corrects a specification **without changing what a conforming
implementation does**. If bytes or meanings change, it is not an erratum: it is
a breaking change and needs a new major version. `GOVERNANCE.md` §5 and §6.

Each erratum is one file, `E<nnnn>-<slug>.md`, containing:

```text
document      the exact path, with the version in its name
affected      the section, and the text as published
correction    the text as it should read
why           what a reader could reasonably have concluded from the old text
class         erratum -- and why it does not change conforming behaviour
date          when it was published
reported by   who found it, if they wish to be named
```

The correction is applied to the document **and** listed here. An erratum never
silently rewrites the specification text without leaving the record: a reader
working from a printed or cached copy has to be able to find out that it
changed.

## Index

| ID | Document | Summary | Date |
|---|---|---|---|
| — | — | none published | — |

## Errata in the other repositories

Each repository holds errata for its own documents, under the same rules:

```text
mcl-wire/errata/    the byte layouts and the common header
mcl-link/errata/    contact, framing, negotiation, handoff
mcl-ip/errata/      the IP-DATAGRAM profile
mcl-ble/errata/     the BLE-GATT profile
```

They are created when the first erratum for that repository is published.
Creating eight empty directories in advance would say a process exists; keeping
this one, which the release front door links to, says where the process starts.

## Security errata

Published before any normal review period elapses. That is the only place this
process is deliberately shortened, and the reason is that a known-exploitable
defect left unfixed for procedural reasons is worse than a fast correction.
`SECURITY.md`.

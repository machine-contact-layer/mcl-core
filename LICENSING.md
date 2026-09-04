# MCL licensing and IPR

Release gate items 24 and 25.

`governance/IPR_PRINCIPLES.md` states the intended *direction* for a future
standards organization. This document states what is **actually in force
today**, which is what a release needs.

## 1. What is licensed, and how

**All eight repositories are Apache License 2.0.** The `LICENSE` file is
byte-identical in every one, and `tools/check-provenance.sh` verifies that on
every gate run rather than trusting it.

```text
mcl-core   mcl-wire   mcl-link   mcl-sdk
mcl-ap     mcl-ip     mcl-ble    mcl-uwb
```

The licence covers everything in each repository: reference source,
specifications, registries, conformance vectors, tooling, and recorded evidence.

## 2. Why Apache-2.0 for the specifications too

A code licence applied to specification text is a choice that needs a reason,
because it is not the usual one — standards bodies typically publish
specifications under separate terms.

**The reason is §3, the patent grant.** Apache-2.0 grants a perpetual,
worldwide, royalty-free patent licence covering claims necessarily infringed by
the contribution, from every contributor. For an interoperability layer, that is
the property that matters most: an implementer needs to know that implementing
the specification does not expose them to a patent claim from the people who
wrote it. `IPR_PRINCIPLES.md` §1 names royalty-free implementation as the goal,
and Apache-2.0 §3 is the shortest route to it that does not require an
incorporated body to administer a separate patent policy.

It also has a defensive termination clause: a party that initiates patent
litigation alleging the work infringes loses its patent licence. That is a
deliberate property, not an accident of the choice.

**What Apache-2.0 does not do for a specification.** It does not prevent
someone publishing a modified specification and calling it MCL. Preventing that
requires a trademark, and MCL holds none — see §5.

## 3. Attribution

Copyright is held by the MCL project maintainer. Apache-2.0 requires derivative
works to retain attribution notices; the `NOTICE` file in each repository is the
canonical attribution text.

## 4. Third-party content: there is none

The protocol repositories take **no dependencies**. There is no package
manifest, no vendored source tree, no copied third-party file, and nothing to
attribute beyond the project's own work. `check-provenance.sh` verifies this
mechanically — it fails on any dependency manifest, any `vendor`/`third_party`
directory, and any binary artifact that sits outside an evidence directory with
a README explaining what produced it.

The binaries that exist are recorded evidence: WAV captures from the acoustic
experiments and serial logs from the hardware runs. Each is under an evidence
directory whose README states the rig that produced it.

**Toolchain note.** Building MCL uses GCC, Clang, MSVC, CMake and the ARM and
RISC-V cross toolchains. None of them is redistributed here, and none imposes
terms on the output — a compiler's licence does not reach the code it compiles.

## 5. What MCL does not have, and what follows

| | Status | Consequence |
|---|---|---|
| **Trademark** | none | Anyone may call anything "MCL". The project cannot object, cannot certify, and cannot operate a conformance mark. |
| **Incorporation** | none | No legal entity holds the copyright or can enter agreements. |
| **Patent search** | not performed | No search has been done for third-party claims reading on the specification. The Apache-2.0 grant binds *contributors*; it says nothing about parties who never contributed. |
| **Contributor agreement** | none beyond §6 | Contributions are accepted on the inbound=outbound terms below, not under a signed CLA. |

**These are stated rather than implied.** A reader who assumed MCL had a
conformance mark or a cleared patent position would be wrong, and the assumption
is easy to make about anything calling itself a standard.

## 6. Contribution terms

Inbound = outbound: **a contribution is licensed under Apache-2.0**, the same
terms as the project, per Apache-2.0 §5, which makes that the default for any
contribution submitted for inclusion unless the contributor states otherwise
explicitly.

By submitting, a contributor asserts:

1. they wrote the contribution or have the right to submit it;
2. it may be released under Apache-2.0;
3. they are not knowingly contributing third-party code under incompatible
   terms;
4. they have disclosed any patent claim they know to be essential to it, per
   `IPR_PRINCIPLES.md` §2.

No CLA is required and none is administered, because there is no entity to
administer one. If MCL is later incorporated, contributors may be asked to
re-license under whatever terms that entity adopts; this document does not
pre-commit anyone to that.

See `CONTRIBUTING.md` for the process.

## 7. Evidence and media

Recorded evidence — WAV captures, serial logs, host output — is licensed under
the same Apache-2.0 terms and was produced by the project on its own hardware.
No third-party recording, dataset or media is included.

**Historical evidence is never re-licensed or edited.** An evidence file records
what was measured on a date. Changing it, including to change its terms, would
destroy the property that makes it evidence.

## 8. The one question this document does not answer

Everything above describes terms already in force. One choice remains open and
it is genuinely a product decision rather than a technical one:

> **Should the specifications be re-published under a separate specification
> licence when MCL moves to multi-party governance?**

Arguments both ways are real. Apache-2.0 carries the patent grant that matters
and is already in force, so changing nothing is defensible. A dedicated
specification licence would separate the right to *implement* from the right to
*copy and modify the text*, which is what a standards body usually wants once
there is a trademark to protect.

**Nothing in v1.0 depends on the answer.** The current terms are complete,
consistent and verified. This is recorded as an open question for the
organization stage, not as a gap in the release.

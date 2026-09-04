# Security policy

Release gate item 23.

This document says two different things, and conflating them would be the most
dangerous thing it could do:

1. **What MCL v1.0 does not protect against.** These are design properties, not
   defects, and reporting them is not a vulnerability report.
2. **How to report an actual vulnerability**, and what this project commits to
   doing about it.

## 1. What MCL v1.0 does not protect against

**MCL v1.0 provides no confidentiality, no peer authentication, no message
integrity in the security sense, and no replay protection.**

This is stated first, prominently, because a protocol that quietly lacks these
is more dangerous than one that says so.

| Property | v1.0 |
|---|---|
| Confidentiality | **none.** Every byte is in the clear on every binding. |
| Peer authentication | **none.** Nothing establishes who sent a frame. |
| Message integrity | **none in the security sense.** `frame_check` is a CRC-32: it detects accidental corruption. Anyone who can write to the medium can recompute it. |
| Replay protection | **none.** A recorded frame replayed later is a valid frame. |
| Denial-of-service resistance | **none.** Anyone who can reach a binding can send to it. |
| Downgrade protection | **none.** Capability negotiation is unauthenticated, so an active attacker can present a minimal capability set and both peers will honestly negotiate down to it. |
| Contact continuity | **correlation, not authentication.** `session_ref` says two frames belong to one conversation. It does not say the peer is the machine the contact began with. |

The constitutional rule holds everywhere in MCL and is the shortest summary of
this section:

```text
reception != identity != authenticity != authority != trust != obligation
```

An `AUTHORITY_CLAIM` is a claim. Receiving one establishes that someone
transmitted it. It confers nothing.

**None of the above is a vulnerability in v1.0.** They are recorded scope
decisions — see `governance/V1_SCOPE.md` §4.4, which defers cryptography
conspicuously rather than quietly. A report saying "MCL traffic can be read by
anyone in range" describes the specification working as written.

**What to do instead.** A deployment needing any of those properties places MCL
inside a transport that provides them — a DTLS-wrapped IP path, LE Secure
Connections beneath the BLE profile, or a physically controlled medium — and
treats every MCL-carried claim as input to local policy rather than as
authorization. `MCL_IP_SEC_TLS_CLAIMED` and the BLE bonding state let an
endpoint *claim* such a wrapper. A claim is not verification.

## 2. What IS a vulnerability here

Something that makes an implementation behave in a way the specification does
not describe, or makes the specification's own guarantees false:

- A decoder that reads or writes outside its buffer on any input — the fuzz and
  sanitizer gates exist to prevent exactly this.
- An input that causes unbounded memory or CPU use in a bounded-work path.
- A frame that is accepted when the specification says it must be refused, or
  refused when it must be accepted, in a way that lets one peer make another
  act incorrectly.
- A migration that can be driven to an inconsistent state — for example a peer
  induced to believe a transport change committed when its peer believes
  otherwise.
- Cross-contact contamination: one contact's frames affecting another's state.
- Any way to make an implementation treat reception as identity, authenticity,
  authority or trust.

## 3. How to report

**Do not open a public issue for a suspected vulnerability.**

Report privately to the maintainer contact listed in
`governance/GOVERNANCE.md`. Include:

- affected repository and commit,
- what an attacker can cause,
- a reproducer — an input, a test, or a sequence of frames,
- your assessment of severity, and why.

A reproducer matters more than a severity rating. The project can assess
severity; it cannot reproduce an effect it cannot see.

## 4. What this project commits to

Commitments this project can actually meet, given that it is a small
specification effort and not a staffed vendor security team. Overstating them
would be its own failure.

| Stage | Commitment |
|---|---|
| Acknowledgement | Within **7 days** of a report reaching the maintainer contact. |
| Initial assessment | Within **30 days**: confirmed, not-a-vulnerability with reasoning, or needs-more-information. |
| Fix or documented decision | Within **90 days** of confirmation, or a public statement explaining why longer is needed. |
| Disclosure | Coordinated. The project publishes after a fix is available, or at **90 days** from confirmation, whichever is sooner, unless the reporter asks for longer. |
| Credit | Given by default, and withheld on request. |

**No bounty is offered**, and none should be inferred.

If a report receives no acknowledgement within 7 days, the reporter is free to
disclose publicly. A process that can silently stall is not a process.

## 5. Supported versions

| Version | Supported |
|---|---|
| `v1.0.x` | Yes, once released. |
| `v0.x` pre-release | **No.** Experimental, superseded, and never to be deployed. |

MCL's version policy is source compatibility within a major
(`V1_SCOPE.md` §4.5). A security fix that requires a wire-format change requires
a new major version, and the project will say so plainly rather than breaking a
compatibility promise quietly.

## 6. Security errata

A confirmed vulnerability in a **Stable** specification produces a security
erratum, handled under the errata process in `governance/GOVERNANCE.md`. A
security erratum may be published before its normal review period elapses; that
is the one place the governance process is deliberately shortened, and the
reason is recorded there.

## 7. What a scan of this repository will and will not find

Stated so that automated reports are useful rather than noise:

- **No dependencies.** The protocol repositories take none — no package manifest,
  no vendored third-party source. A dependency-scanning report finding nothing
  is correct.
- **No cryptography.** There is no key material, no random number generation
  used for security, and no cryptographic primitive to get wrong. The CRC-32 is
  not one.
- **No network listener in the libraries.** Bindings hand bytes to a
  caller-supplied transport callback. The reference harnesses in `tools/` and
  `hardware/` do open sockets and radios; those are test instruments, not
  shipped code, and are not covered by the commitments in §4.

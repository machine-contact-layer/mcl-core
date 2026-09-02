# Security

## Scope: security in MCL is optional, and currently absent

MCL is a contact and communication layer. Whether a deployment authenticates
anything is a configuration choice it makes for itself — Architecture Charter
§2.10.1. Plenty of legitimate deployments never authenticate at all: presence,
hazard broadcast and capability discovery among unknown listeners, or machines
that already know each other through means entirely outside MCL.

This document is therefore not a description of what MCL *is*. It is a
description of what MCL does and does not give you if you need it to.

## Read this before building on MCL

**MCL currently provides no confidentiality, no cryptographic authenticity, and
no peer authentication.** Not weak versions of them — none.

That is a statement of implementation status, not of intent: MCL is designed to
be able to carry a reviewed security profile, and that profile has not been
built. It is stated first because the alternative is that somebody assumes
otherwise and ships it.

**If your deployment does not need those properties, MCL is usable today.** If
it does, it is not yet.

| Property | Status today |
|---|---|
| Contact continuity | **not provided** |
| Channel confidentiality | **not provided** |
| Channel authenticity | **not provided** |
| Peer authentication | **not provided** |
| Attestation | **not provided** |
| Proximity evidence | AP and UWB expose measurements as *evidence*, never as proof |
| Local authorization | yours — MCL never decides it for you |

If you deploy MCL today, assume every frame you receive may have been written by
anyone within range, and treat it accordingly. That is a legitimate way to use
it — presence, hazard broadcast and capability discovery are useful without
authentication, and designing for exactly those conditions is a first-class use
of MCL rather than a compromise. But it must be a decision, not a surprise.

### The frame check is not integrity

`MCL_LINK_FLAG_FRAME_CHECK` selects a CRC-32. A CRC detects **accidental
corruption**. It provides no protection whatsoever against deliberate
modification: an attacker who alters a frame simply recomputes the CRC over the
altered bytes.

This flag was originally named `MCL_LINK_FLAG_INTEGRITY`. It was renamed
precisely because that name invited implementers to assume a guarantee that was
never there. The wire bit is unchanged; only the name is.

**A mechanism is never named for a property it does not provide** — Architecture
Charter §2.11. An error-detecting code is not integrity, an encrypted channel is
not an authenticated peer, and a verified credential is not an authorization.

### Transport security is not MCL security

A BLE connection, a completed pairing, a joined Wi-Fi network, or a TLS session
establishes something about the *channel*. None of them establishes anything
about the *peer*.

The published BLE evidence used Bluetooth "Just Works" pairing: encrypted
against a passive listener, unauthenticated against an active one. The evidence
record says so. `BLE connected` must never be read as `peer authenticated`.

### Never summarise security state

Charter §2.11 forbids collapsing the properties above into a single indicator.
No `trusted = true` may appear in any normative MCL interface, in any
implementation. Every such field eventually invites a shortcut from one property
to a stronger one that was never established.

Record and reason about the properties separately. They fail independently.

## What is being worked on

The security track designs an **optional profile**. It is not MCL's roadmap, and
MCL is not blocked on it — the deployments that do not need it are usable now.

It is deliberately specification-first. No cryptographic code exists in any
repository, and none will be written before the design is settled.

- [`mcl-link/research/secure-contact-threat-model.md`](https://github.com/machine-contact-layer/mcl-link) — adversaries, and what cannot be achieved without a trust anchor
- [`mcl-link/research/secure-contact-candidate.md`](https://github.com/machine-contact-layer/mcl-link) — prior art to adopt rather than reinvent
- [`mcl-link/research/contact-continuity-experiment.md`](https://github.com/machine-contact-layer/mcl-link) — the next experiment and the attacks it must survive

The governing principle: **MCL adopts reviewed cryptographic constructions and
invents none.** Cryptography is the worst possible place to be original.

## Reporting a vulnerability

This is a private pre-v0.1 research project with no deployed users, so there is
no embargo process yet. If you find a flaw:

- **In the specification or the security model** — open an issue in the relevant
  repository. Design flaws in a pre-adoption specification are the most valuable
  thing you can contribute, and they are not sensitive.
- **In reference implementation code** — open an issue. There are no production
  deployments to protect.

When MCL reaches public adoption this section will be replaced by a coordinated
disclosure process with a contact address and response commitments. It has not
been, because pretending to operate a process that does not exist would itself
be a security failure.

## What we most want reviewed

Specific, and roughly in order of how much damage a mistake would do:

1. **The contact continuity design.** An earlier revision proposed proving
   knowledge of a hash over the first-contact exchange. That is worthless: first
   contact is observable, so any listener computes the same hash. The corrected
   requirement is that a continuity proof depend on secret state both peers
   committed *during* the contact. If there is a flaw in the corrected model, it
   is the most valuable flaw to find.

2. **Anything that lets a security property be inferred from a weaker one.** A
   place where receiving implies identity, where a channel implies a peer, where
   a credential implies authorization, or where a measurement implies proximity.

3. **Decoder behaviour on hostile input.** Truncation, reserved bits, unknown
   classes, oversized declared lengths, fragment sequence manipulation. These are
   the paths an attacker reaches first, and they run before any policy does.

4. **Anything a name promises that the mechanism does not deliver.** The
   `INTEGRITY` rename was the first instance found. It will not be the last.

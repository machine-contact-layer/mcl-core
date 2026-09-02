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

**Transport establishment alone does not imply an authenticated MCL peer.** A
transport security mechanism may establish confidentiality, channel
authenticity, or even credential-based peer authentication, depending entirely
on how it is configured — and MCL must surface only the properties actually
established, never the ones the mechanism is capable of.

An earlier revision of this section said no transport mechanism "establishes
anything about the peer." That was too absolute: a properly configured TLS
session authenticates a peer under its own credential and trust model, and
Bluetooth's authenticated association methods — Passkey Entry, Numeric
Comparison, OOB — are meaningfully different from Just Works. The warning was
right; the wording overstated it, and an overstated security claim is a defect
in the same way an understated one is.

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

The architectural consequence, now charter §2.10.2: **MCL defines the interface,
not the cryptography.** A builder supplies the mechanism — their own stack, a
secure element, a platform crypto API, or a reviewed key exchange — and MCL
defines only what must be bound, and how the resulting properties are surfaced
separately. MCL is implementable without ever holding a private key.

What MCL contributes there is not cryptographic. It is the precise definition of
*what must be bound* so that a contact migrating from one medium to another
cannot be stolen. That definition is algorithm-independent, and no existing
standard supplies it, because none spans an acoustic first contact and a later
radio channel.

Because two strangers with no mechanism in common cannot negotiate at all, at
least one fully specified named profile will eventually be needed as well — as a
profile, never as a precondition for using MCL.

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

2. **Multi-peer cross-binding.** A machine hears several peers at once, each
   advertising an endpoint, and an attacker swaps which contact is associated
   with which endpoint. No key is broken and no peer is impersonated — only the
   pairing is wrong. Every diagram in this project so far assumes a clean
   two-party encounter; a factory floor, warehouse aisle or road junction is not
   one. This is the least-examined problem here.

3. **Anything that lets a security property be inferred from a weaker one.** A
   place where receiving implies identity, where a channel implies a peer, where
   a credential implies authorization, or where a measurement implies proximity.
   Including the self-inflicted case: treating "the peer appears not to support
   security" as grounds to proceed without it (charter §2.11.2).

4. **Decoder behaviour on hostile input.** Truncation, reserved bits, unknown
   classes, oversized declared lengths, fragment sequence manipulation. These are
   the paths an attacker reaches first, and they run before any policy does.

5. **Anything a name promises that the mechanism does not deliver.** The
   `INTEGRITY` rename was the first instance found. It will not be the last.

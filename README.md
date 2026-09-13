<p align="center">
  <img src="https://raw.githubusercontent.com/machine-contact-layer/.github/main/profile/banner.png" alt="Machine Contact Layer (MCL) banner: black and white checkerboard with the OJOBIT wordmark" width="100%">
</p>

<h1 align="center">Machine Contact Layer (MCL)</h1>

<p align="center"><strong>A transport-independent layer for machines to meet, and to keep talking.</strong></p>

<p align="center">
  Open machine-to-machine protocol and portable C99 stack for device discovery,
  contact, transport negotiation and communication continuity across BLE, IP
  and acoustic links.
</p>

<p align="center">
  <a href="https://github.com/machine-contact-layer/mcl-core/actions/workflows/ci.yml"><img alt="CI status" src="https://github.com/machine-contact-layer/mcl-core/actions/workflows/ci.yml/badge.svg"></a>
  <a href="https://github.com/machine-contact-layer/mcl-core/blob/main/LICENSE"><img alt="License: Apache-2.0" src="https://img.shields.io/badge/license-Apache--2.0-blue"></a>
  <img alt="Release status: Public Candidate" src="https://img.shields.io/badge/status-Public%20Candidate-orange">
  <img alt="Language: freestanding C99" src="https://img.shields.io/badge/C99-freestanding-informational">
</p>

<p align="center">
  <a href="https://github.com/machine-contact-layer/mcl-sdk/blob/main/QUICKSTART.md"><b>Quickstart</b></a> ·
  <a href="https://github.com/machine-contact-layer/mcl-sdk"><b>SDK</b></a> ·
  <a href="https://github.com/machine-contact-layer/mcl-sdk/tree/main/examples"><b>Examples</b></a> ·
  <a href="SPECIFICATION_INDEX.md"><b>Specifications</b></a> ·
  <a href="#supported-transports"><b>Transports</b></a> ·
  <a href="SECURITY.md"><b>Security</b></a>
</p>

---

MCL lets machines establish contact even when they were built independently, do
not start on the same network, or need to move an existing contact from one
transport to another. It runs on a microcontroller as readily as on a server —
freestanding C99, no heap, no libc — and it leaves your application protocol,
your admission policy and your security stack to you.

> **Building something?** Start with [**mcl-sdk**](https://github.com/machine-contact-layer/mcl-sdk).
> The release ships a self-contained developer SDK: one CMake project, two
> machines in contact in a few commands. This repository holds the protocol
> specifications, registries and conformance model the SDK implements.

## What MCL solves

Machine-to-machine communication usually assumes the hard part is already done:
both devices are on the same network, speak the same protocol, and were
configured to find each other. MCL is for when that is not true, or stops being
true.

- **First contact.** Two devices from different vendors, robots from different
  fleets, or an embedded node and a phone need a common way to announce
  themselves and describe what they can do.
- **Transport negotiation.** Once they hear each other, they need to agree on a
  better bearer — BLE, Wi-Fi/IP — and prove it actually reaches the peer.
- **Transport migration.** A contact that starts on one link needs to continue
  on another without resetting the session.
- **Deterministic refusal.** Machines that act in the physical world must reject
  unknown, stale or incompatible input rather than guess at it.

## Where MCL fits

```text
  your application or domain protocol        MQTT · ROS 2 · DDS · HTTP · your own
                 ▲
                 │  hand off — or keep the contact on MCL
                 │
  MACHINE CONTACT LAYER                      contact · negotiation · migration · refusal
                 │
       ┌─────────┼──────────┬───────────┐
      BLE        IP      acoustic      UWB (experimental)
```

MCL does not replace MQTT, ROS 2, DDS, HTTP, CAN or your own protocol. It
solves the layer before or alongside them: establishing contact, describing
compatible transport choices, refusing incompatible input, and preserving the
contact while the underlying bearer changes. When the machines are ready, your
protocol takes over — or they stay on MCL, which carries contact and control
objects, not your application payloads.

## Common use cases

**Robotics.** Two robots or autonomous machines discover each other, establish
contact, exchange presence and transport offers, and migrate onto a shared
network or hand off to a fleet or robot protocol.

**Embedded and IoT devices.** Devices built by different vendors use the same
contact layer without a common operating system, runtime or cloud service. The
reference stack needs no OS and no dynamic allocation; a Stable `PRESENCE` is
10 bytes on the wire.

**Provisioned fleets.** Machines that already know each other and already share
a bearer use `MCL Base 1` directly — no discovery, no pairing step, no
microphone.

**Offline and degraded networking.** Machines establish contact where normal
infrastructure is absent — over BLE, or acoustically through the speaker and
microphone they already have — and migrate when a better bearer becomes
available.

**Cross-transport systems.** A contact begins on one supported transport and
continues on another, with the same session and the same meaning for every
object, because transports are bindings and never redefine semantics.

## How it works

```text
announce          PRESENCE                            over whatever medium exists
agree a bearer    TRANSPORT_OFFER / TRANSPORT_ACCEPT
prove it reaches  PATH_CHALLENGE / PATH_RESPONSE      on the candidate bearer
apply policy      admit or refuse                     decided locally, never by MCL
move              COMMIT / CONFIRM                    the contact continues there
```

Your application sees a small event stream: a peer was detected, a policy
decision is needed, a contact is established, a contact was lost.

- **Meaning does not depend on the medium.** An object means the same thing
  whether it arrived through a loudspeaker, a BLE characteristic or a UDP
  datagram.
- **Unknown critical input fails loudly.** An unknown opcode, an incompatible
  version or a reserved bit set is rejected, never guessed.
- **Reception is not permission.** Receiving a claim establishes that someone
  sent it. Your policy decides what it is worth.
- **Deterministic, no AI required.** Every normative object can be produced and
  consumed by plain software on a microcontroller.

MCL has two conformance layers:

| | What it covers | Maturity |
|---|---|---|
| **MCL Base 1** | Machines that already share a bearer: establish, maintain, validate, refuse and migrate a contact. Wire major 1 inside Link major 1. | Stable |
| **MCL Stranger-Contact 1** | Extends Base 1 with a zero-prior rendezvous path for machines that share no bearer yet. | Candidate |

## Supported transports

| Transport | Repository | Profile | Maturity | Run on hardware |
|---|---|---|---|---|
| **IP** (UDP over Wi-Fi/Ethernet) | [mcl-ip](https://github.com/machine-contact-layer/mcl-ip) | IP-DATAGRAM profile 1 | Stable | Windows laptop, ESP32-S3, Android 14 |
| **Bluetooth Low Energy** | [mcl-ble](https://github.com/machine-contact-layer/mcl-ble) | BLE-GATT profile 1 · BLE-ACTIVATE-1 | Stable · Candidate | Windows laptop, ESP32-S3 |
| **Acoustic** (speaker and microphone) | [mcl-ap](https://github.com/machine-contact-layer/mcl-ap) | AP-BOOTSTRAP-1 | Candidate | laptop, ESP32-S3 |
| **Ultra-Wideband** | [mcl-uwb](https://github.com/machine-contact-layer/mcl-uwb) | binding draft | Research Draft | not yet |

Each binding is freestanding C99 and contains no network, Bluetooth or audio
stack of its own: you connect it to the one your platform already has.

## Get started

From the release's developer SDK — one CMake project, no sibling checkout:

```sh
curl -LO https://github.com/machine-contact-layer/mcl-core/raw/main/releases/v1.0.0/mcl-developer-sdk.tar.gz
tar -xzf mcl-developer-sdk.tar.gz
cmake -S mcl-developer-sdk -B build
cmake --build build
./build/mcl_base_arranged_bearer
```

That runs two machines on a bearer they already share: they detect each other,
admit each other by local policy, establish contact, exchange a Stable
`PRESENCE`, and refuse an object the Stable major does not carry.

To use it from your own CMake project:

```cmake
find_package(mcl_sdk REQUIRED)
target_link_libraries(my_machine PRIVATE mcl::mcl_sdk)
```

## Example

The integration surface is [`mcl/machine.h`](https://github.com/machine-contact-layer/mcl-sdk/blob/main/include/mcl/machine.h):
you supply a clock and a way to send bytes, feed in what arrives, and poll for
events. MCL keeps the protocol choreography.

```c
#include "mcl/machine.h"

/* Your platform: a monotonic clock and a way to put bytes on your bearer. */
static uint32_t my_clock_ms(void *user);
static int32_t  my_send(void *user, uint8_t transport_id,
                        const uint8_t *data, size_t size);

void run_contact(void)
{
    mcl_machine_t        machine;
    mcl_machine_config_t cfg;
    mcl_platform_t       platform = {0};
    mcl_machine_event_t  ev;

    platform.clock_ms       = my_clock_ms;
    platform.transport_send = my_send;   /* 0 sent, <0 not sent, >0 unknown */

    /* MCL Base 1: two machines that already share a bearer. No discovery. */
    mcl_machine_config_deployment(&cfg, MCL_DEPLOYMENT_BASE_ARRANGED_1,
                                  0xA1A1A1A1u, MCL_CONTACT_ROLE_INITIATOR);
    mcl_machine_init(&machine, &cfg, &platform);
    mcl_machine_start(&machine);

    for (;;) {   /* call from your main loop or a ~10 ms timer */
        /* Bytes that arrive on your socket, UART or BLE characteristic:
           mcl_machine_receive(&machine, transport_id, data, size);      */

        if (mcl_machine_poll(&machine, &ev) != MCL_MACHINE_OK) {
            break;
        }
        if (ev.kind == MCL_MACHINE_EVENT_POLICY_REQUIRED) {
            mcl_machine_admit(&machine);   /* your policy decides, never MCL */
        } else if (ev.kind == MCL_MACHINE_EVENT_CONTACT_ESTABLISHED) {
            /* ev.peer_ref is reachable: stay on MCL, or hand off */
        }
    }
}
```

- **Full quickstart** → [`mcl-sdk/QUICKSTART.md`](https://github.com/machine-contact-layer/mcl-sdk/blob/main/QUICKSTART.md)
- **Builder guide** → [`mcl-sdk/BUILDER_GUIDE.md`](https://github.com/machine-contact-layer/mcl-sdk/blob/main/BUILDER_GUIDE.md) — transports, migration, capabilities, conformance, what changes under you
- **Examples** → [`mcl-sdk/examples/`](https://github.com/machine-contact-layer/mcl-sdk/tree/main/examples) — Base 1 on a shared bearer, stranger first contact, resource report
- **Porting** → [`mcl-sdk/PORTING.md`](https://github.com/machine-contact-layer/mcl-sdk/blob/main/PORTING.md)

## Architecture

```text
┌──────────────── YOUR MACHINE ────────────────┐
│  autonomy · control · filesystem · fleet     │
│                    ▲                         │
│                    │  scoped handoff only    │
│              ┌─────┴─────┐                   │
│              │  policy   │                   │
│              └─────▲─────┘                   │
│         ┌──────────┴──────────┐              │
│         │    MCL boundary     │              │
│         │ contact · transport │              │
│         └───┬──────┬──────┬───┘              │
│            AP     BLE    IP                  │
└─────────────┼──────┼──────┼──────────────────┘
              └──────┴──────┘
               other machines
```

A peer talks to MCL. It does not talk to your actuators, your CAN bus, your
filesystem or your fleet credentials. Everything a deployment chooses is
configuration, not protocol:

- which transports it speaks, and whether it migrates at all
- what it discloses at each stage, and over which medium
- whether it admits a peer, and on what local policy
- whether it hands off to its own protocol or keeps the contact on MCL

Differently configured machines stay interoperable at the frame and semantic
layers; they simply refuse each other at different points.

Dependencies run one way: `core → wire → link → bindings → sdk`. A lower layer
never redefines a higher layer's meaning.

## Repository map

| Repository | What it contains |
|---|---|
| **[mcl-core](https://github.com/machine-contact-layer/mcl-core)** | Machine semantics, protocol specifications, registries, conformance model, governance |
| **[mcl-wire](https://github.com/machine-contact-layer/mcl-wire)** | Canonical binary encoding and deterministic decoding for every MCL object |
| **[mcl-link](https://github.com/machine-contact-layer/mcl-link)** | Machine contact lifecycle, framing, sessions and transport migration |
| **[mcl-sdk](https://github.com/machine-contact-layer/mcl-sdk)** | Portable C99 SDK, examples, porting guide and the developer SDK package |
| **[mcl-ip](https://github.com/machine-contact-layer/mcl-ip)** | IP transport binding: MCL over UDP and other datagram carriers |
| **[mcl-ble](https://github.com/machine-contact-layer/mcl-ble)** | Bluetooth Low Energy transport binding: GATT carriage and role derivation |
| **[mcl-ap](https://github.com/machine-contact-layer/mcl-ap)** | Acoustic transport binding: first contact through a speaker and microphone |
| **[mcl-uwb](https://github.com/machine-contact-layer/mcl-uwb)** | Experimental Ultra-Wideband transport binding |

## Compatibility and maturity

**Public Candidate.** The Stable surface is frozen; the `v1.0.0` tag has not
been cut yet.

| Maturity | What it covers |
|---|---|
| **Stable** | Wire major 1 · Link major 1 and its nine frame classes · `PRESENCE`, `TRANSPORT_OFFER`, `TRANSPORT_ACCEPT` · IP-DATAGRAM profile 1 (transport 2) · BLE-GATT profile 1 (transport 3) · `MCL Base 1` · SDK API at source compatibility |
| **Candidate** | `MCL Stranger-Contact 1` · AP-BOOTSTRAP-1 · BLE-ACTIVATE-1 · `HAZARD`, `REQUEST`, `AUTHORITY_CLAIM`, `DEGRADED_STATE` (Wire major 0 only) |
| **Research Draft / Experimental** | UWB binding · the wider IP and BLE binding drafts · profile identifier 192 |

Two things worth knowing before you integrate:

- The pre-existing encode calls still emit major 0 for source compatibility.
  Use the `_at_major` calls, or the `MCL_DEPLOYMENT_BASE_ARRANGED_1` deployment,
  to emit the Stable pair.
- Source compatibility is promised within v1; binary ABI stability is not.

The per-document status and the full compatibility matrix are in
[`SPECIFICATION_INDEX.md`](SPECIFICATION_INDEX.md).

## Security model

**MCL v1.0 provides no confidentiality, no peer authentication, no
cryptographic integrity and no replay protection.** Every byte is in the clear
on every binding, and a completed contact establishes reachability and
correlation — not identity.

- `frame_check` is a CRC-32. It detects accidental corruption, not tampering.
- A BLE connection or an IP socket says nothing about who the peer is.
- `source_ref` and `session_ref` are correlation references, never identities.

MCL is cryptography-agnostic: you bring your own security stack, and MCL never
holds a private key. If you need to know who you are talking to, run MCL inside
something that authenticates — DTLS on IP, LE Secure Connections beneath BLE,
a controlled network — or hand off to a protocol that does. v1.0 ships no
security profile of its own. [`SECURITY.md`](SECURITY.md) is specific about
each property and how to report a vulnerability.

## Specifications and conformance

- [`SPECIFICATION_INDEX.md`](SPECIFICATION_INDEX.md) — every specification and its maturity
- [`spec/conformance-profiles-v1.md`](spec/conformance-profiles-v1.md) — what `MCL Base 1` and `MCL Stranger-Contact 1` require
- [`deployments/`](deployments/) — the named deployment profiles the SDK implements
- [`conformance/CONFORMANCE_MODEL.md`](conformance/CONFORMANCE_MODEL.md) — test classes C0–C6
- [`conformance/ICS.md`](conformance/ICS.md) — the implementation conformance statement
- [`registries/`](registries/) — machine-readable assigned values
- [`governance/IMPLEMENTATION_CONTRACT.md`](governance/IMPLEMENTATION_CONTRACT.md) — the runtime constraints on reference code

You do not need our code to implement MCL: the specifications, registries and
conformance vectors are the contract, and the reference implementation is
subordinate to them.

**Verification resources.** Conformance (C0–C6) and physical evidence (E0–E6)
are tracked separately. The hardware runs behind the transport table above keep
their raw captures, logs and digests:

- IP over 2.4 GHz UDP between a laptop and an ESP32-S3, and with an Android 14 handset at Wire and Link major 1 — [`mcl-ip/evidence/`](https://github.com/machine-contact-layer/mcl-ip/tree/main/evidence)
- BLE GATT with fragmentation at the minimum MTU of 23 — [`mcl-ble/evidence/`](https://github.com/machine-contact-layer/mcl-ble/tree/main/evidence)
- One contact carried across 104 BLE/IP changes of medium with both radios live — [`mcl-sdk/evidence/`](https://github.com/machine-contact-layer/mcl-sdk/tree/main/evidence)
- The Wire, Link and acoustic stack decoding over the air on an ESP32-S3 — [`mcl-ap/experiments/`](https://github.com/machine-contact-layer/mcl-ap/tree/main/experiments)
- A second implementation, in a different language, cross-checking the reference C — [`conformance/independent/`](conformance/independent/)
- Every empirical record bound to a path and digest — [`releases/v1.0.0/EVIDENCE_INDEX.json`](releases/v1.0.0/EVIDENCE_INDEX.json)

## Contributing

- [`CONTRIBUTING.md`](CONTRIBUTING.md) — how changes are made, and the rules reference code follows
- [`REPORTING.md`](REPORTING.md) — report a defect or a specification error; published corrections are in [`errata/`](errata/)
- [`SECURITY.md`](SECURITY.md) — report a vulnerability
- [`CODE_OF_CONDUCT.md`](CODE_OF_CONDUCT.md)
- [`governance/`](governance/) — the architecture charter, specification process and registry policy

## License

Apache-2.0. See [`LICENSE`](LICENSE), [`NOTICE`](NOTICE) and
[`LICENSING.md`](LICENSING.md).

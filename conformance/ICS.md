# Implementation Conformance Statement — MCL reference implementation

Release gate item 22.

**Conformance is not established by passing this project's unit tests.** A test
suite written by the same person as the implementation measures agreement with
itself. What this document states is what the reference implementation
implements, what it does not, and what evidence exists for each claim.

Read with `governance/V1_SCOPE.md`, which says what v1.0 *claims*, and
`SPECIFICATION_INDEX.md`, which says which documents are in force.

## 0. Identification

| | |
|---|---|
| Implementation | MCL reference implementation |
| Repositories | `mcl-core`, `mcl-wire`, `mcl-link`, `mcl-sdk`, `mcl-ap`, `mcl-ip`, `mcl-ble`, `mcl-uwb` |
| Language | C99, freestanding for all protocol-facing code |
| Dependencies | none |
| Wire major implemented | 0 (experimental). Major 1 is defined and **refused**; it is not cut. |
| Link major implemented | 0 |

## 1. Conformance levels reached

MCL uses two ladders that are never blurred: **C0–C6** for conformance and
**E0–E6** for physical evidence. A high C level says nothing about E, and the
reverse.

| Level | Reached | Evidence |
|---|---|---|
| **C0–C3** | yes | Repository test suites; both gate halves. |
| **C4** cross-implementation | **yes, at Wire majors 0 and 1** | `conformance/independent/test_independent.py` — 803 checks against a clean-room Python implementation, both directions, including matching refusals. |
| **C5** profile interoperability | **yes, on the assigned profile value 1** | `conformance/independent/test_profiles_c5.py` — 108 checks against both Stable profiles, on the final assigned bytes. |
| **C6** | **no** | Requires field deployment beyond anything this project has run. |

**The C4/C5 caveat that mattered has been discharged.** Both were first run
against Wire major 0 and transport profile 192 — the experimental values, and
therefore evidence about those values. Major 1 is now cut and the Standards
Action assignments are made, so both were re-run on the final bytes, because
`profile_id` travels inside `TRANSPORT_OFFER` and `TRANSPORT_ACCEPT`. The
earlier runs are retained as what they were: evidence about profile 192, which
remains Experimental Use permanently.

**The caveat that has NOT been discharged, and will not be by v1.0.0:** the
clean-room implementation is independent *of the reference code* — different
language, no shared source, no shared build — and it found three real
specification-reading defects. It was written by the same author. C4 and C5 are
therefore strong evidence that these specifications can be implemented **from
the text alone**, and no evidence at all that two *organisations* can
interoperate. v1.0.0 does not claim that. See `V1_SCOPE.md` §5.9.

| Level | Reached | Evidence |
|---|---|---|
| **E4** over-air, IP | yes | `mcl-ip/evidence/e4-udp-2g4-20260902/` |
| **E4** over-air, BLE | yes | `mcl-ble/evidence/e4-ble-gatt-20260902/` |
| **E4** dual-transport migration | yes | `mcl-sdk/evidence/e4-dual-transport-migration-20260903/` — 104 migrations, 100 consecutive alternating BLE↔IP, 2989 checks, 0 failures |
| **E3** acoustic | yes | `mcl-ap/experiments/001-known-waveform/evidence/` |
| **E5, E6** | **no** | Not attempted. |

## 2. Mandatory features

| Feature | Implemented | Notes |
|---|---|---|
| Wire common header | yes | |
| Canonical encoding, zero padding checked | yes | |
| Unknown category/opcode refused | yes | |
| Unsupported major refused | yes | Including major 1, which is defined but not cut. |
| `PRESENCE` | yes | 11 bytes at major 0; 10 at major 1 (no `machine_class`). |
| `TRANSPORT_OFFER` / `TRANSPORT_ACCEPT` | yes | |
| Extension envelope | yes | Mechanism only; **zero Stable extension IDs assigned**, by design. |
| Unknown critical extension refused | yes | |
| Link frame encode/decode | yes | |
| Link frame classes | 9 of 10 | `ADAPT` reserved and refused at both encode and decode. |
| ACK / NACK / KEEPALIVE / CLOSE | yes | |
| `CAPABILITY` / `NEGOTIATION` | yes | |
| Contact lifecycle | yes | |
| Transport migration | yes | Offer → accept → challenge → response → commit → confirm. |
| Irrevocable COMMIT | yes | No rollback path exists, deliberately. |
| Retransmission and idempotence | yes | |
| Multi-contact isolation | yes | One contact per node; several nodes for several contacts. |
| IP datagram carriage | yes | Frame check **required** by the profile. |
| BLE GATT carriage | yes | Frame check required; fragmentation exercised at the 23-byte minimum MTU. |

## 3. Optional features

| Feature | Implemented | Notes |
|---|---|---|
| `KEEPALIVE` emission | **no** | Accepted, never sent. Permitted: Stable-but-optional-to-emit. |
| IP stream carriage | partially | Unit-tested only; **never exercised over a real TCP connection**. Experimental. |
| BLE connectionless carriage | no | Not a v1 profile. |
| AP acoustic carriage | experimental | E3 reached. Not a v1 Stable transport. |
| UWB carriage | experimental | **No hardware evidence at all.** |
| Rendezvous beacons | yes | Experimental; not required by either Stable profile. |
| Context compression | **no** | Deferred. No codec exists. |
| Cryptographic contact binding | **no** | Deferred. See `SECURITY.md`. |

## 4. Limits

| Limit | Value |
|---|---|
| Maximum Link frame | 1048 bytes (8 header + 16 optional + 1024 payload) |
| Maximum Link payload | 1024 bytes |
| Maximum Tier-0 object | 17 bytes |
| Negotiated frame floor | 42 bytes |
| Duration range | 0 – 507904 s; worst relative loss above 60 s **5.882%** |
| BLE minimum ATT MTU assumed | 23 (19 usable per PDU) |
| BLE maximum fragments per frame | 56, within a 64-value sequence |
| Contacts per node | **1** |
| Heap allocation | **none** |
| libc at runtime in protocol code | **none** |

## 5. Registries: what is assigned

| Registry | Stable assignments |
|---|---|
| Semantic codes | provisional; none Stable |
| Tier-0 field meanings | 8 of 21 settled |
| Transport IDs | 4 provisional (AP, IP, BLE, UWB) |
| Handoff operations | provisional |
| **Extension IDs** | **zero — and that is the intended v1 state** |
| **IP profiles** | **1 Stable** — `IP-DATAGRAM = 1`, Standards Action, 2026-09-04. 192 stays Experimental Use |
| **BLE profiles** | **1 Stable** — `BLE-GATT = 1`, Standards Action, 2026-09-04. 192 stays Experimental Use |
| Negotiated feature bits | **zero assigned** |

An empty Stable table is a correct outcome where the mechanism is ready and
nothing has earned an assignment.

## 6. Platforms verified

| Toolchain | Verified |
|---|---|
| GCC, `-Wall -Wextra -Werror` | yes |
| Clang, same | yes |
| MSVC 19.51, `/W4 /WX` | yes |
| ASan + UBSan | yes |
| ARM Cortex-M0, freestanding | compiles; no undefined symbols beyond named toolchain helpers |
| RV32IM, freestanding | same |
| C++17 header inclusion | g++ and clang++ |

Hardware exercised: ESP32-S3 (UDP peer, GATT peer, dual-radio peer); Windows
host with a Realtek RTL8188EU USB adapter and WinRT Bluetooth.

## 7. What this implementation does NOT claim

- **Not a security implementation.** No confidentiality, authentication,
  integrity in the security sense, or replay protection. See `SECURITY.md`.
- **Not certified.** MCL is not an incorporated body and cannot certify anyone,
  including itself (`governance/GOVERNANCE.md` §8).
- **Not a Stable implementation yet.** No MCL specification is Stable. Every
  claim above is against Candidate or Research Draft documents.
- **Not evidence for UWB or for the IP stream profile.** Both are implemented
  and neither has over-air evidence.
- **Not proof that the tests are good.** The traceability check
  (`tools/check-traceability.sh`) shows every Stable feature has a positive and
  a negative test. It does not show those tests are strong. The one measurement
  of test strength in this project is the mutation campaign in
  `mcl-sdk/tests/MULTI_CONTACT_MUTATIONS.md`, which found a real gap.

## 8. Reproducing every claim

```sh
mcl-core/tools/local-gates.sh                        # GCC/Clang/sanitizers/cross
mcl-core/tools/local-gates-msvc.ps1                  # MSVC
mcl-core/conformance/independent/test_independent.py # C4
mcl-core/conformance/independent/test_profiles_c5.py # C5
mcl-core/tools/check-traceability.sh                 # feature traceability
mcl-core/tools/api-baseline.sh                       # API surface
mcl-core/tools/check-registry-governance.sh          # registry governance
mcl-sdk/packaging/install-and-verify.sh              # external consumability
```

Physical evidence is not reproducible from this repository: it requires the
hardware named in each evidence README, and each records the rig it used.

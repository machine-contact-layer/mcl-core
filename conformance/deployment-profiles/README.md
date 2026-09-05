# Deployment profile fixtures

`spec/deployment-profile-v1.md` is the prose, `tools/validate_deployment_profile.c`
is the executable form, and these fixtures keep the two honest.

`tools/check-deployment-profiles.sh` runs them and is wired into
`release-rehearsal.sh`.

## Valid

| Fixture | What it exercises |
|---|---|
| `base-arranged-bearer.json` | `MCL Base 1` with a mandatory continuation bearer and no bootstrap profile. A deployment that guarantees continuation without guaranteeing that strangers can meet — the arranged-bearer case, which is legitimate and common. |

The reference deployment itself lives at
`deployments/MCL-REFERENCE-DEPLOYMENT-1.json` and is validated by the same gate.

## Invalid — each of these MUST be refused

This is the half that matters. A validator that accepts everything passes a
suite made only of valid inputs, so the gate fails if any of these is accepted.

| Fixture | What it proves the validator catches |
|---|---|
| `01-experimental-mandatory.json` | A mandatory bearer on profile 192. A deployment cannot require of its members a value the registry marks Experimental Use — `GOVERNANCE.md` §4.3 says such a value is never relabelled Stable, so requiring it requires something committed to replacement. Checked against the real registry file, not a compiled-in copy. |
| `02-peer-address-smuggled.json` | An IP address in the legitimately-named `transport` field. Refusing unknown *keys* does not stop an address arriving through a known one, and if a deployment profile could carry a peer address the two-builder test could be passed by prearrangement — the exact failure it exists to detect. |
| `03-base-names-bootstrap.json` | `MCL Base 1` naming a bootstrap profile. A foundation deployment has an arranged bearer and no rendezvous requirement; naming one imposes a requirement no Base implementation must meet. |
| `04-stranger-without-bootstrap.json` | The inverse: a stranger-contact layer with no bootstrap profile, which claims that strangers can meet while selecting nothing they can meet over. |
| `05-security-profile-named.json` | `security.profile` set to `MCL-S1`. No named security profile exists; accepting the name would let a deployment claim a guarantee nothing can supply. |
| `06-unknown-key.json` | A `trust_anchors` key. Trust material is deliberately out of scope for v1 (§2), and silently ignoring an unknown key is how a profile comes to mean less than its author thought. |
| `07-wire-major-0.json` | `wire_major: 0`. Major 0 is experimental and permanent; a deployment does not select it. |
| `08-mandatory-and-optional.json` | The same transport and profile in both lists, which makes "optional" a lie about a bearer that is in fact required. |
| `09-unknown-layer.json` | A conformance layer that `spec/conformance-profiles-v1.md` does not define. |

## What is not covered yet

No fixture exercises trust anchors, credential formats or security suites,
because none of those is in the schema. When `MCL-S1` exists, `05` changes from
a negative fixture to a positive one and this table records that it did.

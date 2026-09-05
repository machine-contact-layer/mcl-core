# MCL Deployment Profile v1

Status: **Candidate**

A deployment profile is how a city, operator or site selects the optional pieces
of MCL that are **mandatory there**, so that two builders who never coordinate
can both implement *the same profile* instead of coordinating with each other.

It changes no MCL code and adds no wire format. It is a profile of profiles.

## 1. The problem it solves, and the one it does not

`spec/conformance-profiles-v1.md` §5.3 draws the line this document sits on:

> `MCL Stranger-Contact 1` guarantees **meeting**. It does not guarantee
> **continuing.**

No conformance layer can mandate a common richer bearer without excluding honest
implementations — a roadside unit may reasonably have Ethernet and no radio. So
the layer guarantees that two strangers can meet, and a deployment profile
guarantees that the machines *in one deployment* can also continue.

That produces a legible ladder of claims:

```text
MCL Stranger-Contact 1                      strangers can MEET
  + a deployment profile with a
    mandatory continuation bearer            they also share a CONTINUATION bearer
  + a deployment profile with a
    mandatory security profile               they also share a SECURITY mechanism
```

**The guarantees are derived from the content, never declared.** A profile does
not assert what it guarantees; the validator computes it from what the profile
requires. One source of truth.

## 2. Deliberately small

This version defines identity, required layers, and continuation bearers. It
does **not** define trust anchors, credential formats, cryptographic suites,
authorisation policy, endpoints, or a generic extension bag.

Those are omitted because the decisions they encode have not been made. A
placeholder that later has to change meaning is worse than an absent field, and
a generic extension bag is how a small schema becomes a policy language nobody
can validate. The security block exists as a forward-compatible hole and nothing
more; `MCL-S1` does not exist, so v1 requires `security.profile` to be `null`.

## 3. Format

```json
{
  "schema": "mcl-deployment-profile/v1",
  "profile_id": "MCL-REFERENCE-DEPLOYMENT-1",
  "revision": 1,

  "requires": {
    "wire_major": 1,
    "link_major": 1,
    "conformance_layer": "MCL Stranger-Contact 1",
    "bootstrap_profile": "AP-BOOTSTRAP-1"
  },

  "continuation": {
    "mandatory": [
      { "transport": "MCL_BLE", "transport_id": 3,
        "profile": "BLE-GATT", "profile_id": 1 }
    ],
    "optional": [
      { "transport": "MCL_IP", "transport_id": 2,
        "profile": "IP-DATAGRAM", "profile_id": 1 }
    ]
  },

  "security": { "profile": null }
}
```

### 3.1 Fields

| Field | Rule |
|---|---|
| `schema` | Exactly `mcl-deployment-profile/v1`. |
| `profile_id` | `A-Z`, `0-9` and `-`, 3–64 characters. Names the deployment, not a wire value. |
| `revision` | Integer ≥ 1. Increments on any change. |
| `requires.wire_major` | Must be `1`. Major 0 is experimental and permanent; a deployment does not select it. |
| `requires.link_major` | Must be `1`. |
| `requires.conformance_layer` | One of the layers named in `spec/conformance-profiles-v1.md`. |
| `requires.bootstrap_profile` | Required when the layer is `MCL Stranger-Contact 1` or above. **Must be absent for `MCL Base 1`** — a foundation-layer deployment has an arranged bearer and no rendezvous requirement, and naming one there would be a requirement no Base implementation must meet. |
| `continuation.mandatory` | Array. Every member must implement **all** of these. May be empty, in which case continuation is simply not guaranteed and the validator says so. |
| `continuation.optional` | Array. May be implemented. Never contributes to a guarantee. |
| `security.profile` | `null` in v1. Any other value is refused, because no named security profile exists yet. |

Each continuation entry carries `transport`, `transport_id`, `profile` and
`profile_id`. The names are redundant with the numbers **on purpose**: a
deployment profile is read by people, and a mismatch between the two is a
validation error rather than a silent reinterpretation.

### 3.2 There is no `oneOf`

`continuation.mandatory` is a conjunction — every entry is required of every
member. There is deliberately **no** way to write "BLE *or* IP".

An alternation is exactly the empty-intersection bug this whole layer exists to
remove: if each builder may independently satisfy the requirement a different
way, two conformant members can again share nothing. A deployment that genuinely
accepts either must pick one as mandatory and list the other as optional.

## 4. What a deployment profile must never contain

**No peer-specific rendezvous information.** No IP address, no port, no BLE
address, no `source_ref`, no `endpoint_token`, no pre-shared secret, no pairing
material, no per-device configuration of any kind.

This is not tidiness. The acceptance criterion in `governance/V1_SCOPE.md` §5.10
gives both implementations the release, this profile, and the deployment's trust
material — and nothing else. **If a deployment profile could carry a peer
address, the two-builder test could be passed by prearrangement**, which is
precisely the failure it was written to detect.

The validator enforces this two ways: unknown keys are refused outright, and
every string value is scanned for IPv4, IPv6 and MAC-shaped content wherever it
appears. A profile that smuggles an address through a legitimately-named field
fails.

## 5. Validation

`tools/validate_deployment_profile.c` is the executable form of this document.

There is deliberately **no JSON Schema file**. Nothing in this toolchain
enforces JSON Schema, so shipping one would create a second description of the
same rules that drifts from the first the moment either changes. The prose here
and the validator are the two forms, and the fixtures in
`conformance/deployment-profiles/` keep them honest.

The validator reports two independent things:

**Validity** — the profile obeys this document. Failure exits non-zero.

**Satisfiability** — whether everything the profile requires exists *today*.
A profile naming `AP-BOOTSTRAP-1` is valid and **not yet satisfiable**, because
that profile has not been specified. This is reported as `PENDING`, not as an
error: the deployment is correctly written and is waiting on MCL, and conflating
"you wrote this wrong" with "we have not built that yet" would hide both.

Profile identifiers in `continuation` are cross-checked against the actual
transport registries in `mcl-ip/` and `mcl-ble/`. A mandatory entry naming an
Experimental Use value fails, because a deployment cannot require of its members
something the project has committed to replacing.

## 6. Change control

A deployment profile is owned by its deployment, not by MCL. MCL owns this
schema and the registries a profile references.

Weakening a published deployment profile — removing a mandatory bearer, lowering
a required layer — breaks members built against it. Such a change takes a new
`profile_id`, not a new `revision`. `revision` is for additions and corrections
that no conforming member can fail.

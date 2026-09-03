# `machine_class` — necessity audit for Stable v1 PRESENCE

Status: **RESOLVED — Option A adopted**, recorded as `V1_SCOPE.md` §4.8
Date: 2026-09-04
Applies to: `V1_SCOPE.md` §5.1, which lists the `machine_class` vocabulary as a
blocker for a Stable `PRESENCE`.

## Why this document exists instead of a vocabulary

`V1_SCOPE.md` §5.1 says a Stable `PRESENCE` requires a `machine_class`
vocabulary. The obvious next action was to write one. This audit was run first,
and it changes the recommendation.

The question an audit answers and a vocabulary does not:

> **What Stable-v1 decision becomes impossible if `machine_class` is absent
> until capability metadata is exchanged?**

A taxonomy written before that question is answered is a taxonomy justified by
the field's existence rather than by a requirement. `REGISTRY_POLICY.md` already
directs reviewers to reject domain-specific concepts pushed into domain-general
Core; an 8-bit universal machine taxonomy is the largest such concept in Tier-0.

## Method

Every reference to the field in all eight repositories was enumerated and
classified by what it *does*, not by whether it appears. Sources: the eight
repository working trees at the heads listed below, the research scenario
corpus, the Tier-0 layout specification, and Core/Link specification prose.

## Finding 1 — no code anywhere consumes the value

21 references exist across the eight repositories. Every one falls into one of
four categories, none of which is a behavioural consumer:

| Category | Count | What it does |
|---|---:|---|
| Writes a hardcoded constant | 14 | `= 1u`, `= 2u`, `= 3u`, `= 5u`, `= 7u` |
| Codec plumbing | 2 | `mcl_write_u` / assignment in `wire.c` |
| Layout-validator / benchmark plumbing | 4 | field-name dispatch by string |
| Round-trip preservation assert | 2 | "the value that went in came out" |

**Nothing dispatches on it. Nothing filters on it. Nothing negotiates with it.
No contact, session, migration, transport-selection or acceptance decision
anywhere in Link or SDK reads it.**

The single reference that appears to branch on the value,
`mcl-ap/experiments/001-known-waveform/decode_wav.c:164`, is a fixed-vector
regression assert: it checks that a decoded object equals the recorded E3
over-air vector field for field. It would assert equally on any field in that
vector. It is not a behavioural consumer, and it is verifying historical
evidence rather than exercising protocol logic.

The constants themselves are the tell. Five different values are in use across
the reference paths — `1`, `2`, `3`, `5`, `7` — with no shared meaning between
them, because no meaning exists to share. The dual-radio migration harness that
produced the E4 evidence fills it with a constant while the migration machinery
operates entirely on contact, transport and session state.

## Finding 2 — the corpus cannot support an 8-bit taxonomy

The research corpus (`mcl-core/research/scenarios/corpus-v0.1.json`, explicitly
non-normative) contains 30 scenarios and 42 semantic messages. Of those:

```text
REQUEST           14
HAZARD            11
AUTHORITY_CLAIM    6
TRANSPORT_OFFER    4
PRESENCE           3      <-- the only object carrying machine_class
DEGRADED_STATE     3
STATUS             1
```

Three PRESENCE messages, carrying two distinct classes: `ground_robot` and
`service_robot`.

Two observed values is not evidence for a 256-value cross-vendor taxonomy. It is
not evidence for a 4-value one. Designing the vocabulary from this corpus would
be designing it from the two examples someone happened to write down.

## Finding 3 — the specifications already mark it optional

Neither specification that describes the field treats it as required:

- `mcl-core/spec/core-v0.md` §2.1 lists it among suggested contact fields as
  `machine_class?`
- `mcl-link/spec/machine-card.md` lists it in the MachineCard structure as
  `machine_class?`

The optionality was written before this audit and independently of it. The
project's own specification prose has never claimed a first-contact decision
depends on the field.

## Finding 4 — it is probably not one dimension

"Machine class" collapses several orthogonal properties into one flat 8-bit
code:

```text
mobile / stationary
ground / aerial / surface / underwater
manipulator / sensing / infrastructure / transport
autonomous / remotely operated / human-worn
```

A flat taxonomy over orthogonal axes encodes their cross-product, and the
cross-product grows every time a new axis is recognised. That is the failure
mode a first-contact field can least afford: a taxonomy that must be updated to
meet a new kind of machine defeats the purpose of first contact, which the
registry entry for this field already says in its own `before_stable` note.

Mature interoperability standards resolve this by layering rather than
enumerating — OPC UA puts domain identity in Companion Specifications over
common infrastructure; oneM2M keeps a minimal Base Ontology that external
ontologies map into; W3C WoT keeps a small core interaction vocabulary and
attaches richer semantic types separately. Each keeps domain identity *out* of
the base.

## Outcome

**Option A was adopted.** `machine_class` is removed from the Wire major-1
`PRESENCE` body; major 0 keeps it permanently along with its vectors and its
over-air evidence. No replacement taxonomy was defined.

The decision follows from the findings above rather than from preference: the
audit asked what Stable-v1 decision becomes impossible without the field, the
answer was none, and §4.1 of the scope had already settled what to do with a
Stable field nobody may act on. Option B required producing a concrete
first-contact requirement that coarse machine typing satisfies before capability
exchange; none exists anywhere in the tree.

Propagated to `mcl-wire/spec/tier0-layout-v0.2.md` §4.1 (which now carries both
layouts), `mcl_wire_tier0_encoded_size_at_major`,
`mcl-wire/tests/test_major_rule.c`, the field registry's `v1_disposition`, and
the independent implementation.

## Recommendation, as it stood before the decision

Two options were open.

### Option A — remove from major-1 PRESENCE — **ADOPTED**

```text
Wire major 0 PRESENCE       unchanged, permanently
    source_ref
    machine_class
    capability_tag
    ttl

Wire major 1 PRESENCE
    source_ref
    capability_tag
    ttl                     10 bytes, from 11
```

Machine typing moves to capability/domain metadata exchanged after contact,
where a vocabulary can be domain-scoped and versioned instead of universal and
frozen.

**This is the same decision the owner already made about coordinates**, applied
consistently. `V1_SCOPE.md` §4.1 rejected keeping a Stable field with a
permanent "MUST NOT act on this" rule, on the grounds that *a Stable field
nobody may act on is an invitation to act on it*. A `machine_class` with no
assigned values is exactly that field: a receiver learns the sender considers
itself class 7 and has no way to look 7 up. The argument does not become weaker
because this field sits in a Stable object rather than a Candidate one — it
becomes more urgent, because a Candidate object can still change.

Cost: 1 byte of 11, a 9.1% reduction in the most frequently transmitted object.
On the 300 bit/s acoustic binding that is ~26.7 ms of serialisation per
announcement before PHY overhead. The saving is real but it is not the argument;
removing an unearned universal taxonomy from a frozen surface is.

### Option B — keep it, and earn it first

Legitimate only if a concrete first-contact requirement is produced that a
receiver must satisfy *before* any capability exchange, and that coarse machine
typing genuinely satisfies. If such a requirement exists, define the minimum
vocabulary that requirement justifies and no more.

The audit found no such requirement in the current tree. That is not proof none
exists — it is proof none is currently implemented, specified or exercised.

## What this audit does not decide

- **v0 is untouched either way.** The experimental major keeps its layout, its
  vectors and its evidence exactly as recorded. No historical vector or evidence
  file is modified by either option.
- **Nothing is removed today.** Major-1 layouts are not being cut yet
  (`V1_SCOPE.md` §5.8). This is the cheapest possible moment to answer the
  question and the last one at which it is free.
- **This does not settle machine typing.** It says the concept has not earned a
  place in a frozen first-contact object, not that machines never need to know
  what they are talking to.

## Reproducing this audit

```sh
# Finding 1 — every reference, classified by hand from this output
grep -rn "machine_class" --include=*.c --include=*.h --include=*.cs --include=*.ino .

# Finding 2 — corpus composition
python -c "import json,collections; d=json.load(open('mcl-core/research/scenarios/corpus-v0.1.json')); \
m=[x for s in d['scenarios'] for x in s['messages']]; \
print(collections.Counter(x['semantic_type'] for x in m)); \
print([x['machine_class'] for x in m if x['semantic_type']=='PRESENCE'])"

# Finding 3
grep -rn "machine_class" --include=*.md mcl-core/spec mcl-link/spec
```

Repository heads at the time of the audit:

```text
mcl-core  eac13c4    mcl-wire  1be0612    mcl-link  0e87e8e    mcl-sdk  25af416
mcl-ap    aa30067    mcl-ip    d00ae49    mcl-ble   8e1746a    mcl-uwb  2abb9b9
```

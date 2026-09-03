# What the clean-room implementation had to work out

Release gate item 15. A second implementation's most valuable output is not that
it works — it is the list of places where a competent implementer, reading only
the normative specifications, went wrong or had to guess.

Three errors were made writing `mcl_independent.py`. All three were caught, and
**how** each was caught is the useful part.

## 1. `DEGRADED_STATE` — transposed the 3-bit and 7-bit fields

**What was written:** `affected_capability` 8, `health` 8, `validity` 8.
**What the specification says:** `affected_capability` 8, `health` 7,
`severity` 3, `ttl` 8, then 6 bits of zero padding.

**Caught by:** the published vector. The wrong layout consumed 9 bytes where the
vector is 10, so the byte count alone exposed it.

**The specification predicted this exact mistake.** `tier0-layout-v0.2.md` §4.5
carries a note saying `health` precedes `severity` here while in `HAZARD` the
3-bit `severity` precedes the 7-bit `confidence`, and that an implementer
working from the C structs alone could easily transpose them. The note is
correct and it is not sufficient — this implementer read the note's object,
skimmed the table, and transposed them anyway. **Recommendation for v1: keep
the note, and consider making the two objects order the pair identically. A
warning that has to be read is weaker than a layout that cannot be got wrong.**

## 2. `AUTHORITY_CLAIM` — wrong widths that summed correctly

**What was written:** `authority_class` 8, `jurisdiction` 16.
**What the specification says:** `authority_class` 6, `jurisdiction` 12.

`8 + 16 = 24` and `6 + 12 = 18`, but the object also carries 6 bits of padding,
so **both layouts consume exactly 14 bytes.**

**Not caught by:** the published vector, the byte count, "every byte consumed",
or round-tripping. Every one of those passed while every field after
`source_ref` was being misread.

**Caught by:** comparing decoded field *values* against the reference decoder,
which required adding a `fields_tier0` verb to `cross_check.c`.

This is the most important finding in this file. **A conformance test that
compares lengths is not comparing anything.** Two implementations can agree on
every byte count of every object and disagree about what every field means. The
vectors as published cannot catch it either, because a vector is a length and a
hex string — it does not say what the fields decode to.

**Recommendation for v1: the major-1 vector family (row 12) must carry expected
FIELD VALUES, not only `name`, `length` and `hex`.** Otherwise an independent
implementer can pass the entire vector suite with a wrong layout, exactly as
this one did.

## 3. `REQUEST` — a field named `validity` that is called `ttl`

**What was written:** `validity` 8. **Specification:** `ttl` 8.

Width correct, name wrong, so nothing byte-level could catch it. Caught by the
field-name comparison against the reference, which requires the two
implementations to agree that the *same* field is present.

Minor by itself, and it matters because `ttl` and `validity` are different
concepts elsewhere in Tier-0 that share one encoding — a reader who confuses
them in one object will confuse them in others.

## What the specification got right

Recorded because a gap list that only lists gaps is misleading.

- **The common header** was implementable from §2 alone, first try.
- **The duration codec** was implementable from `duration-v0.1.md` alone, and
  the band-gap rule was stated clearly enough that this implementation rounds
  down across gaps correctly without seeing the reference code. Both
  implementations independently produce a worst-case relative loss above 60 s of
  **5.882%**.
- **The Link frame** was implementable from the layout comment in `link.h` plus
  `link-v0.md`. The optional-field order and the "frame check covers everything
  before it" rule were unambiguous.
- **CRC-32/IEEE** was implemented from the polynomial rather than by calling
  `zlib.crc32`, deliberately, so that agreement between the two implementations
  means both derived the same function from the specification rather than both
  delegating to one library. They agree.
- **The negotiation controls** were implementable from `link-negotiation-v1.md`
  alone, including the symmetric selection rule, and both implementations
  compute identical selections.
- **The Stable-major rule** was unambiguous: `common-header-v0.2.md` §3.1 states
  which objects are carried at major 1 and what a decoder does with the rest.

## Structural divergences, chosen on purpose

An implementation that mirrored the reference's structure would not expose
assumptions that only appear when two different designs meet. So:

| Reference C | Independent |
|---|---|
| Status-code returns | Exceptions |
| Bit-writer accumulating across field boundaries | Whole-byte assembly for byte-aligned objects, an explicit bit reader for the rest |
| One size function keyed on kind | Layout tables keyed on `(major, kind)` |
| `zlib`-equivalent CRC table | CRC computed from the polynomial |
| Caller-owned structs, no allocation | Dictionaries |
| C99, freestanding | Python, hosted |

The `(major, kind)` divergence turned out to matter: major-1 `PRESENCE` drops
`machine_class`, so a layout keyed on kind alone is wrong at exactly one major.
The reference C needed a second function (`mcl_wire_tier0_encoded_size_at_major`)
for the same reason.

## Reproducing

```sh
cd mcl-core/conformance/independent
python3 test_independent.py
```

Builds `cross_check.c` against the reference sources and runs 718 checks. The
two implementations exchange hex on a command line and share no memory, no
header and no language.

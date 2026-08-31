# MCL Publication, Persistence, and Errata Policy

Status: **Governance Design Draft**

A Stable interoperability specification must remain reconstructable years after publication.

## 1. Immutable Stable snapshots

A Stable specification release is an immutable snapshot.

After publication, normative bytes/text in that snapshot are not edited in place.

Corrections occur through:
- published errata;
- an amended revision;
- or a new major wire version when bytes would change meaning.

## 2. Release bundle

A future Stable release should include:

- normative specification documents;
- machine-readable assigned-number registry snapshots;
- positive/negative conformance vectors;
- implementation conformance statement schema;
- test case reference list;
- release manifest containing hashes;
- known errata at publication time;
- change log from previous Stable release.

## 3. Content integrity

Every release artifact should be cryptographically hashed in a release manifest.

The organization should later add signed release manifests using an operational key-management process independent of individual developer Git credentials.

## 4. Persistent references

Normative specifications and registered-extension references should have durable public locations.

A registered value must not depend solely on a temporary repository branch, issue comment, vendor website, or mutable wiki page.

## 5. Errata classes

- Editorial
- Technical clarification
- Normative defect
- Security defect

An erratum can constrain or clarify valid behavior but cannot assign an incompatible new meaning to bytes from a Stable release.

## 6. Historic specifications

Historic versions remain publicly retrievable with their registries and errata.

Assigned identifiers from Historic specifications remain reserved and are never recycled.

## 7. Generated artifacts

Rendered PDFs, SDK enums, documentation sites, tables, and language bindings are generated views.

They MUST identify the normative source revision from which they were produced.

The source specification/registry remains authoritative.

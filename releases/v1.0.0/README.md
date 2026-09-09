# Generated release-candidate bundle

This directory is a reconstruction artifact, not release approval. The open
criteria in `../../governance/RELEASE_GATE_V1.md` still govern publication.

`mcl-developer-sdk.tar.gz` is generated from the canonical sibling repositories
by `../../tools/build-release-bundle.sh`, which invokes the SDK packaging tools.
It contains the self-contained developer source package and documentation;
it is not a downloaded dependency or a prebuilt runtime. `commits.txt` records
the source commits; `artifacts.txt` inventories the archive and `SHA256SUMS.txt`
records its exact digest. `../../tools/build-release-bundle.sh --verify v1.0.0` checks the
reconstruction, including building and running the extracted SDK contract test.

The existing bundle predates subsequent physical-test fixes and must be rebuilt
and rechecked against the final qualified sources before any release decision.

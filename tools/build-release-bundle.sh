#!/bin/sh
#
# Release gate items 30 and 31: build the release bundle, and verify that the
# bundle alone is enough to reconstruct what it claims.
#
# THE CROSS-REPOSITORY SELF-REFERENCE PROBLEM
#
# MCL is eight repositories. A manifest that lives in one of them cannot record
# its own commit -- writing the commit changes the tree, which changes the
# commit. The v0.1.0-alpha.1 manifest hit exactly this and recorded a stale
# mcl-core hash.
#
# The fix is not cleverness, it is honesty about what a manifest can know:
#
#   - the seven OTHER repositories are recorded by exact commit;
#   - mcl-core is recorded by the commit the bundle was BUILT FROM, which is
#     the parent of the commit that adds the manifest;
#   - the verifier checks the seven exactly, and checks mcl-core by content
#     rather than by hash.
#
# A manifest that claimed to know its own hash would be lying, and this one
# says which of its entries is which.
#
#   ./build-release-bundle.sh <version>       write releases/<version>/
#   ./build-release-bundle.sh --verify <ver>  reconstruct and check
#
set -e

ROOT=$(cd "$(dirname "$0")/../.." && pwd)
REPOS="mcl-core mcl-wire mcl-link mcl-sdk mcl-ap mcl-ip mcl-ble mcl-uwb"

VERIFY=0
if [ "$1" = "--verify" ]; then
    VERIFY=1
    shift
fi
VERSION=${1:-v1.0.0}
BUNDLE="$ROOT/mcl-core/releases/$VERSION"

# --------------------------------------------------------------- verify mode
if [ "$VERIFY" -eq 1 ]; then
    echo "=== reconstructing $VERSION from its bundle alone ==="
    echo
    if [ ! -f "$BUNDLE/manifest.txt" ]; then
        echo "no manifest at $BUNDLE/manifest.txt"
        exit 1
    fi

    failures=0

    echo "-- every named commit exists and is what the manifest says"
    while read -r repo commit; do
        case "$repo" in ''|'#'*) continue ;; esac
        if [ ! -d "$ROOT/$repo/.git" ]; then
            echo "  FAIL $repo is not a repository here"
            failures=$((failures + 1))
            continue
        fi
        if ! git -C "$ROOT/$repo" cat-file -e "$commit^{commit}" 2>/dev/null; then
            echo "  FAIL $repo has no commit $commit"
            failures=$((failures + 1))
            continue
        fi
        echo "  ok   $repo $(echo "$commit" | cut -c1-12)"
    done < "$BUNDLE/commits.txt"

    echo
    echo "-- checksums match the artifacts they name"
    if [ -f "$BUNDLE/SHA256SUMS.txt" ]; then
        # Verified from the REPOSITORY ROOT, because the paths in
        # SHA256SUMS.txt are relative to it -- the artifacts live in the eight
        # repositories and are referenced in place rather than copied into the
        # bundle. Copying them would create a second version that can drift
        # from the one the commits name.
        if (cd "$ROOT" && sha256sum -c "$BUNDLE/SHA256SUMS.txt" > /dev/null 2>&1); then
            n=$(grep -c . "$BUNDLE/SHA256SUMS.txt")
            echo "  ok   $n artifact(s) verified against the working tree"
        else
            echo "  FAIL checksums do not match:"
            (cd "$ROOT" && sha256sum -c "$BUNDLE/SHA256SUMS.txt" 2>&1                 | grep -v ': OK' | head)
            failures=$((failures + 1))
        fi
    else
        echo "  FAIL no SHA256SUMS.txt"
        failures=$((failures + 1))
    fi

    echo
    echo "-- every artifact the manifest names is present"
    while read -r path; do
        case "$path" in ''|'#'*) continue ;; esac
        if [ -f "$BUNDLE/$path" ] || [ -f "$ROOT/$path" ]; then
            echo "  ok   $path"
        else
            echo "  FAIL $path is named by the manifest and is missing"
            failures=$((failures + 1))
        fi
    done < "$BUNDLE/artifacts.txt"

    echo
    echo "-- bundled developer SDK builds and runs its contract test"
    sdk_archive="$BUNDLE/mcl-developer-sdk.tar.gz"
    if [ ! -f "$sdk_archive" ]; then
        echo "  FAIL developer SDK archive is missing"
        failures=$((failures + 1))
    else
        sdk_work=$(mktemp -d)
        if tar -xzf "$sdk_archive" -C "$sdk_work" &&
           (cd "$sdk_work/mcl-developer-sdk" && sha256sum -c SHA256SUMS.txt >/dev/null) &&
           cmake -S "$sdk_work/mcl-developer-sdk" -B "$sdk_work/build" \
               -DCMAKE_BUILD_TYPE=Release >/dev/null &&
           cmake --build "$sdk_work/build" --config Release -j 4 >/dev/null &&
           ctest --test-dir "$sdk_work/build" --build-config Release \
               --output-on-failure; then
            echo "  ok   self-contained SDK checksum, build and contract test"
        else
            echo "  FAIL self-contained SDK did not reconstruct"
            failures=$((failures + 1))
        fi
        rm -rf "$sdk_work"
    fi

    echo
    if [ "$failures" -ne 0 ]; then
        echo "$failures reconstruction failure(s)."
        echo "RECONSTRUCTION FAILED"
        exit 1
    fi
    echo "RECONSTRUCTION VERIFIED"
    echo
    echo "What this does NOT establish: that the release is correct, or that a"
    echo "clean checkout on another machine builds. It establishes that the"
    echo "bundle names real commits, real artifacts, and correct checksums."
    exit 0
fi

# ---------------------------------------------------------------- build mode
echo "=== building the $VERSION release bundle ==="
mkdir -p "$BUNDLE"

# Refuse to bundle a dirty tree. A bundle built from uncommitted work names
# commits that do not contain what was measured.
#
# Line endings are ignored deliberately. These repositories are worked on from
# Windows, where git checks files out with CRLF, and this script also runs from
# WSL, where git reports every one of those files as modified. A plain
# `status --porcelain` therefore calls a perfectly clean tree dirty on one of
# the two shells that has to be able to run it -- so the check compares content
# with --ignore-cr-at-eol, and looks for untracked files separately.
#
# What is NOT ignored: a real content change, a staged change, or an untracked
# file. Any of those means the bundle would name commits that do not contain
# what was measured.
dirty=0
for repo in $REPOS; do
    reason=""
    if ! git -C "$ROOT/$repo" diff --quiet --ignore-cr-at-eol HEAD 2>/dev/null; then
        reason="modified tracked files"
    fi
    untracked=$(git -C "$ROOT/$repo" ls-files --others --exclude-standard)
    if [ -n "$untracked" ]; then
        if [ -n "$reason" ]; then
            reason="$reason and untracked files"
        else
            reason="untracked files"
        fi
    fi
    if [ -n "$reason" ]; then
        echo "  $repo has $reason"
        [ -n "$untracked" ] && echo "$untracked" | sed 's/^/      ?? /'
        dirty=1
    fi
done
if [ "$dirty" -ne 0 ]; then
    echo
    echo "REFUSING to bundle: a bundle built from uncommitted work names"
    echo "commits that do not contain what was measured."
    exit 1
fi

# The adoption artifact, not merely the repositories that maintain it. A
# builder receives one include tree, one CMake project, the named deployment
# profile, its required specifications, and an executable machine contract.
sdk_work=$(mktemp -d)
"$ROOT/mcl-sdk/packaging/make-developer-sdk.sh" \
    "$sdk_work/mcl-developer-sdk" >/dev/null
tar --sort=name --mtime='@0' --owner=0 --group=0 --numeric-owner \
    -C "$sdk_work" -cf - mcl-developer-sdk | gzip -n \
    > "$BUNDLE/mcl-developer-sdk.tar.gz"
rm -rf "$sdk_work"

: > "$BUNDLE/commits.txt"
for repo in $REPOS; do
    printf '%s %s\n' "$repo" "$(git -C "$ROOT/$repo" rev-parse HEAD)" \
        >> "$BUNDLE/commits.txt"
done

# ------------------------------------------------- EVIDENCE_INDEX.json
#
# GENERATED, never hand-maintained. The manuscript says an evidence index binds
# every empirical claim to a revision, a path and a digest; a copy of that
# binding typed by hand is a copy that goes stale silently, which is the exact
# failure this project has already had four times on derivable numbers.
#
# WHY EACH CLAIM CARRIES A WIRE MAJOR. The 104-migration continuity campaign
# ran its ordinary Tier-0 traffic at Wire major 0: tools/dual_host_shim.c
# configures mask 0 and populates machine_class, a field major 1 removed. That
# does not weaken what the campaign establishes -- one contact surviving 104
# physical-medium changes, with path validation, COMMIT/CONFIRM, retransmission
# recovery and wrong-transport refusal -- but it is NOT evidence that Wire
# major 1 survived 104 migrations, and the two claims must not be merged by a
# reader. Experiment 008 is what carries Wire 1 inside Link 1 across a physical
# medium. The combination, Wire1+Link1 under migration, has not been run, and
# proves_wire1_migration says so on the record rather than in a footnote.

sha_of() {
    if [ -f "$ROOT/$1" ]; then
        sha256sum "$ROOT/$1" | cut -d" " -f1
    else
        echo "MISSING"
    fi
}

commit_of() {
    git -C "$ROOT/$1" rev-parse HEAD
}

claim() {
    # claim <name> <path> <repo> <trailing-comma-or-empty>
    {
        printf '    {\n'
        printf '      "claim": "%s",\n' "$1"
        printf '      "path": "%s",\n' "$2"
        printf '      "sha256": "%s",\n' "$(sha_of "$2")"
        printf '      "repository_commit": "%s"\n' "$(commit_of "$3")"
        printf '    }%s\n' "$4"
    } >> "$BUNDLE/EVIDENCE_INDEX.json"
}

{
    printf '{\n'
    printf '  "generated_by": "mcl-core/tools/build-release-bundle.sh",\n'
    printf '  "version": "%s",\n' "$VERSION"
    printf '  "source_commits": {\n'
} > "$BUNDLE/EVIDENCE_INDEX.json"

ev_first=1
for repo in $REPOS; do
    if [ "$ev_first" -eq 1 ]; then
        ev_first=0
    else
        printf ',\n' >> "$BUNDLE/EVIDENCE_INDEX.json"
    fi
    printf '    "%s": "%s"' "$repo" "$(commit_of "$repo")" \
        >> "$BUNDLE/EVIDENCE_INDEX.json"
done
printf '\n  },\n  "claims": [\n' >> "$BUNDLE/EVIDENCE_INDEX.json"

claim continuity_104_migrations \
      mcl-sdk/evidence/e4-dual-transport-migration-20260903/README.md mcl-sdk ,
claim continuity_raw \
      mcl-sdk/evidence/e4-dual-transport-migration-20260903/host-output.txt mcl-sdk ,
claim embedded_wire1_link1_physical \
      mcl-ap/experiments/008-embedded-node/README.md mcl-ap ,
claim embedded_wire1_link1_digests \
      mcl-ap/experiments/008-embedded-node/evidence/e4-node-board-to-host-frame-20260904/SHA256SUMS.txt mcl-ap ,
claim physical_campaign_digests \
      mcl-sdk/hardware/dfr1154-autonomous-node/runs/20260909-contention-closure/SHA256SUMS.txt mcl-sdk ,
claim row35 \
      mcl-core/conformance/independent/20260910-private-rc/ROW35.json mcl-core ,
claim row35_verifier \
      mcl-core/conformance/independent/20260910-private-rc/verify_row35.py mcl-core ""

cat >> "$BUNDLE/EVIDENCE_INDEX.json" <<'EVJSON'
  ],
  "wire_major_qualification": {
    "e4-dual-transport-migration-20260903": {
      "establishes": "Link migration and contact continuity across 104 physical-medium changes",
      "ordinary_tier0_wire_major": 0,
      "proves_wire1_migration": false,
      "note": "Ordinary traffic was major-0 PRESENCE emitted by tools/dual_host_shim.c. The migration controls are the claim; the Wire major of the carried object is not."
    },
    "008-embedded-node": {
      "establishes": "Wire major 1 inside Link major 1, modulated and decoded across a physical acoustic channel on an ESP32-S3-class target",
      "ordinary_tier0_wire_major": 1,
      "proves_wire1_migration": false,
      "note": "Different toolchain and architecture from the host gates. It does not exercise migration."
    },
    "combination_not_run": {
      "description": "Wire 1 + Link 1 under repeated bearer migration",
      "status": "not run",
      "disposition": "post-v1 evidence backlog; the constituent layers are evidenced separately above"
    }
  },
  "conformance": {
    "C4_independent_cross_implementation_checks": 803,
    "C5_stable_profile_interoperability_checks": 108,
    "note": "Separate campaigns. They are not summed, and no combined figure is authoritative."
  },
  "limitations": [
    "No external independent organization implementation or review",
    "AP bootstrap and BLE activation remain Candidate",
    "Failed 120-second three-machine stress run preserved rather than discarded",
    "No physical UWB qualification",
    "No cryptographic profile exists in any repository",
    "Two board-serial.log files (mcl-ble/evidence/e4-ble-gatt-20260902, mcl-ip/evidence/e4-udp-2g4-20260902) have an unresolved integrity chain: the originally recorded digest matches neither the committed bytes nor any line-ending variant. Owner disposition is to publish as-is and disclose. Neither file is cited by any claim above. See DISPOSITION.md in each directory."
  ]
}
EVJSON

# --------------------------------------------------- REPRODUCIBILITY.md

cat > "$BUNDLE/REPRODUCIBILITY.md" <<REPRO
# Reproducing the MCL $VERSION research artifacts

Generated by \`mcl-core/tools/build-release-bundle.sh\`. Do not edit by hand:
the next bundle build overwrites it.

The paper version is distinct from a Stable specification or a Git tag.
\`commits.txt\` records the eight source revisions that constitute this
release, and \`EVIDENCE_INDEX.json\` maps each reported result to an immutable
receipt with its SHA-256.

## What a rebuild does and does not repeat

Rebuilding the software repeats the software. It does **not** repeat the
physical experiments: the acoustic, BLE and dual-radio campaigns ran on
specific hardware in a specific room, and their firmware and APK identities
belong to those retained receipts. A green gate run today says nothing about
them.

## Checking out this release

Clone the eight repositories from https://github.com/machine-contact-layer into
sibling directories, then check out each revision in \`commits.txt\`.
mcl-core records the commit the bundle was BUILT FROM; it cannot record the
commit that contains it, because writing the hash changes the hash.

## Rebuilding

From the sibling-repository root, under a POSIX toolchain:

\`\`\`sh
sh mcl-core/tools/build-release-bundle.sh --verify $VERSION
sh mcl-core/tools/release-rehearsal.sh
\`\`\`

On Windows, also run:

\`\`\`powershell
powershell -NoProfile -File mcl-core/tools/local-gates-msvc.ps1
\`\`\`

Both halves are the gates. A change passing one and breaking the other has
broken the build.

## The standalone developer SDK

Extract \`mcl-developer-sdk.tar.gz\`, verify its internal \`SHA256SUMS.txt\`,
then follow its README and CMake instructions. It requires no sibling checkout.
\`examples/base_arranged_bearer.c\` is MCL Base 1 end to end: Wire major 1
inside Link major 1 on a bearer that is already there, with no rendezvous.

## What is not settled by any of this

Public visibility, external review and errata, and Stable promotion are
separate steps governed by \`governance/RELEASE_GATE_V1.md\` and
\`governance/PUBLISHING.md\`. No DOI and no public tag is invented by this pack.
REPRO


cat > "$BUNDLE/artifacts.txt" <<'ARTIFACTS'
# Normative specifications and conformance artifacts that constitute this
# release. Paths are relative to the eight-repository root.
#
# THE ACOUSTIC VECTORS ARE HERE ON PURPOSE, BINARY AND ALL.
#
# A conformance corpus whose bytes are not pinned is not a corpus: two
# implementations can only be compared against samples that cannot drift, and
# "regenerate the vectors" is exactly how a failing cross-test quietly becomes
# a passing one. The developer SDK archive is also binary: it is the actual
# one-package adoption surface, not another claim that the source repos suffice.
#
# The two conformance/deployment profile documents are here because a builder
# cannot determine what they may claim without them, and AP-BOOTSTRAP-1 is here
# because the guaranteed interoperability floor rests on it.
mcl-core/SPECIFICATION_INDEX.md
mcl-core/SECURITY.md
mcl-core/REPORTING.md
mcl-core/errata/README.md
mcl-core/governance/PUBLISHING.md
mcl-core/LICENSING.md
mcl-core/CONTRIBUTING.md
mcl-core/governance/V1_SCOPE.md
mcl-core/governance/RELEASE_GATE_V1.md
mcl-core/governance/GOVERNANCE.md
mcl-core/governance/ARCHITECTURE_CHARTER.md
mcl-core/governance/REGISTRY_POLICY.md
mcl-core/governance/MACHINE_CLASS_AUDIT.md
mcl-core/conformance/ICS.md
mcl-core/conformance/api-baseline-v1.txt
mcl-core/conformance/independent/SPEC_GAPS.md
mcl-core/registries/semantic-codes-v0.2.json
mcl-core/registries/tier0-fields-v0.1.json
mcl-wire/spec/common-header-v0.2.md
mcl-wire/spec/tier0-layout-v0.2.md
mcl-wire/spec/duration-v0.1.md
mcl-wire/spec/tier0-extensions-v0.1.md
mcl-wire/registries/extension-ids-v0.1.json
mcl-wire/conformance/vectors/tier0-major1-v1.0.json
mcl-link/spec/link-v0.md
mcl-link/spec/link-class-disposition-v1.md
mcl-link/spec/link-negotiation-v1.md
mcl-link/spec/link-handoff-control-v0.1.md
mcl-link/spec/link-contact-ownership-v0.1.md
mcl-link/registries/transport-ids-v0.1.json
mcl-link/registries/handoff-ops-v0.1.json
mcl-ip/spec/ip-datagram-profile-v1.md
mcl-ip/registries/ip-profiles-v0.1.json
mcl-ble/spec/ble-gatt-profile-v1.md
mcl-ble/registries/ble-profiles-v0.1.json
mcl-core/spec/conformance-profiles-v1.md
mcl-core/spec/deployment-profile-v1.md
mcl-ap/spec/ap-bootstrap-1.md
mcl-ap/conformance/vectors/VECTORS.md
mcl-ap/conformance/vectors/01-presence-10b.wav
mcl-ap/conformance/vectors/02-transport-accept-16b.wav
mcl-ap/conformance/vectors/03-transport-offer-17b.wav
mcl-ap/conformance/vectors/04-refuse-bad-crc.wav
mcl-ap/conformance/vectors/05-refuse-zero-length.wav
mcl-ap/conformance/vectors/06-refuse-length-over-cap.wav
mcl-ap/conformance/vectors/07-refuse-truncated.wav
mcl-ap/conformance/vectors/08-refuse-no-preamble.wav
mcl-ap/conformance/vectors/09-refuse-silence.wav
ARTIFACTS
printf 'mcl-core/releases/%s/mcl-developer-sdk.tar.gz\n' "$VERSION" \
    >> "$BUNDLE/artifacts.txt"
printf 'mcl-core/releases/%s/EVIDENCE_INDEX.json
' "$VERSION" \
    >> "$BUNDLE/artifacts.txt"
printf 'mcl-core/releases/%s/REPRODUCIBILITY.md
' "$VERSION" \
    >> "$BUNDLE/artifacts.txt"

{
    echo "MCL $VERSION release manifest"
    echo "built: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo
    echo "COMMITS"
    echo
    echo "  The seven repositories other than mcl-core are recorded by exact"
    echo "  commit and can be checked out directly."
    echo
    echo "  mcl-core is recorded as the commit the bundle was BUILT FROM. It"
    echo "  cannot record the commit that contains it: writing the hash changes"
    echo "  the tree, which changes the hash. The v0.1.0-alpha.1 manifest hit"
    echo "  exactly this and recorded a stale mcl-core hash. Stating which"
    echo "  entry is which is the honest fix; claiming to know it is not."
    echo
    sed 's/^/  /' "$BUNDLE/commits.txt"
    echo
    echo "WHAT THIS RELEASE CONTAINS"
    echo
    echo "  Wire major        1 (Stable), 0 retained permanently"
    echo "  Link major        1 (Stable), 0 retained permanently"
    echo "  Stable objects    PRESENCE, TRANSPORT_OFFER, TRANSPORT_ACCEPT"
    echo "  Candidate objects HAZARD, REQUEST, AUTHORITY_CLAIM, DEGRADED_STATE"
    echo "                    -- carried at major 0 only"
    echo "  Link classes      9 Stable, ADAPT reserved"
    echo "  Transports        IP (2) and BLE (3) Stable; AP (1) and UWB (4)"
    echo "                    experimental"
    echo "  Profiles          IP-DATAGRAM = 1 under transport 2"
    echo "                    BLE-GATT    = 1 under transport 3"
    echo "                    MCL Standards Action, assigned 2026-09-04. Both"
    echo "                    profile specifications are Stable. C4/C5 were"
    echo "                    re-run on these assigned bytes. Value 192 remains"
    echo "                    Experimental Use in each registry and was never"
    echo "                    relabelled."
    echo "  Extension IDs     none assigned; the mechanism ships, the table is"
    echo "                    empty by design"
    echo "  Feature bits      none assigned; same disposition"
    echo "  Cryptography      none. See mcl-core/SECURITY.md"
    echo "  Developer SDK     mcl-developer-sdk.tar.gz; one CMake build, named"
    echo "                    deployment profile and executable machine contract"
    echo
    echo "WHAT THIS RELEASE DOES NOT CLAIM"
    echo
    echo "  Stated here in the same words as mcl-core/README.md,"
    echo "  conformance/ICS.md and governance/V1_SCOPE.md section 5.9, so that"
    echo "  a reader cannot find a weaker version by looking somewhere else."
    echo
    echo "  NOT claimed: two ORGANISATIONS have interoperated"
    echo "  NOT claimed: anyone outside this project has implemented these"
    echo "               specifications"
    echo "  NOT claimed: anyone outside this project has reviewed them"
    echo "  NOT claimed: the specifications are free of defects a fresh reader"
    echo "               would find"
    echo
    echo "  The clean-room implementation in mcl-core/conformance/independent/"
    echo "  shares no code, no language and no build system with the reference"
    echo "  C, and it found three real specification-reading defects. It was"
    echo "  written by the same author. E6 is NOT reached."
    echo
    echo "  Report a defect: mcl-core/REPORTING.md. Errata: mcl-core/errata/."
    echo
    echo "ARTIFACTS"
    echo
    grep -v '^#' "$BUNDLE/artifacts.txt" | sed 's/^/  /'
    echo
    echo "REPRODUCING"
    echo
    echo "  mcl-core/tools/local-gates.sh"
    echo "  mcl-core/tools/local-gates-msvc.ps1"
    echo "  mcl-core/conformance/independent/test_independent.py"
    echo "  mcl-core/conformance/independent/test_profiles_c5.py"
    echo "  mcl-sdk/packaging/install-and-verify.sh"
    echo "  mcl-core/tools/go-no-go-audit.sh"
    echo
    echo "  Physical evidence is NOT reproducible from this bundle. It requires"
    echo "  the hardware each evidence README names, and those directories are"
    echo "  referenced in place rather than copied: historical evidence is never"
    echo "  duplicated into a release, because a copy can drift from what was"
    echo "  measured."
} > "$BUNDLE/manifest.txt"

# Checksums over the artifacts, computed from the working tree.
#
# -b is not decoration. Coreutils prints " *" before the path in binary mode
# and two spaces in text mode, and it picks the default from the platform: a
# bundle built under Git for Windows and one built under Linux produced
# byte-different SHA256SUMS.txt files carrying identical digests. Both verify,
# so nothing was ever wrong -- but every line changed on a rebuild, which
# hides the one line that mattered. Forcing binary mode makes the bundle a
# function of the tree rather than of the host that built it.
: > "$BUNDLE/SHA256SUMS.txt"
grep -v '^#' "$BUNDLE/artifacts.txt" | while read -r path; do
    [ -n "$path" ] || continue
    if [ -f "$ROOT/$path" ]; then
        (cd "$ROOT" && sha256sum -b "$path") >> "$BUNDLE/SHA256SUMS.txt"
    else
        echo "WARNING: artifact missing: $path" >&2
    fi
done

# The checksum file lists paths relative to ROOT, so verification runs there.
sed -i "s|^|# verify from the repository root: sha256sum -c |" /dev/null 2>/dev/null || true

echo "  commits.txt   $(grep -c . "$BUNDLE/commits.txt") repositories"
echo "  artifacts.txt $(grep -vc '^#' "$BUNDLE/artifacts.txt") artifacts"
echo "  SHA256SUMS    $(grep -c . "$BUNDLE/SHA256SUMS.txt") checksums"
echo "  manifest.txt  written"
echo
echo "Bundle at $BUNDLE"

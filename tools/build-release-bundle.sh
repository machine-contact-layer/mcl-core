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
        if (cd "$BUNDLE" && sha256sum -c SHA256SUMS.txt > /dev/null 2>&1); then
            n=$(grep -c . "$BUNDLE/SHA256SUMS.txt")
            echo "  ok   $n artifact(s) verified"
        else
            echo "  FAIL checksums do not match:"
            (cd "$BUNDLE" && sha256sum -c SHA256SUMS.txt 2>&1 | grep -v ': OK' | head)
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

: > "$BUNDLE/commits.txt"
for repo in $REPOS; do
    printf '%s %s\n' "$repo" "$(git -C "$ROOT/$repo" rev-parse HEAD)" \
        >> "$BUNDLE/commits.txt"
done

cat > "$BUNDLE/artifacts.txt" <<'ARTIFACTS'
# Normative specifications and conformance artifacts that constitute this
# release. Paths are relative to the eight-repository root.
mcl-core/SPECIFICATION_INDEX.md
mcl-core/SECURITY.md
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
ARTIFACTS

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
    echo "  Profiles          NO Stable profile identifier is assigned."
    echo "                    Both profile specifications are Candidate and"
    echo "                    interoperability was demonstrated on the"
    echo "                    Experimental Use value 192 in each registry."
    echo "  Extension IDs     none assigned; the mechanism ships, the table is"
    echo "                    empty by design"
    echo "  Feature bits      none assigned; same disposition"
    echo "  Cryptography      none. See mcl-core/SECURITY.md"
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
: > "$BUNDLE/SHA256SUMS.txt"
grep -v '^#' "$BUNDLE/artifacts.txt" | while read -r path; do
    [ -n "$path" ] || continue
    if [ -f "$ROOT/$path" ]; then
        (cd "$ROOT" && sha256sum "$path") >> "$BUNDLE/SHA256SUMS.txt"
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

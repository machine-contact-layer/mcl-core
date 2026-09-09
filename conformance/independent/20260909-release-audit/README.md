# Release audit: HOLD

MCL v1.0.0 is **not approved for release or paper compilation on the basis of
release approval**. Passing software tests or rebuilding the archive does not
close the physical or governance criteria.

The detailed private campaign is in
`../../../../mcl-sdk/hardware/dfr1154-autonomous-node/runs/20260909-central-lifecycle/README.md`
relative to the sibling-repository workspace (see the SDK record directly if
reading this document outside that layout).

## Established results

- Independent Windows-to-Android exact-token GATT discovery and 40-byte,
  three-fragment exact return.
- DFR transmission failure discriminated to a failed 27-byte internal-DMA
  allocation; moving a cold staging buffer restored carriage. This does not
  retroactively explain the earlier first-connection failure.
- Retained zero-prior DFR/Android lifecycle runs with explicit policy and
  matching migrated session references in both BLE orientations.
- Deterministic regressions for lost ACCEPT preserving a pending candidate,
  uncertain transmit preserving validation, and a blocking emitter retaining
  the full frozen response window. Undelivered controls do not establish a
  contact and candidate resources are released after bounded failure.
- Current board application readback matches its built image; two cancelled
  attempts reuse one client with identical settled resource figures and live
  acoustic recovery. STOP cancels activation and restores the control plane.
- Final board image `0DF1D23A7F710840EB1DD5A85D122C4D1A9DA2E89A15D24E57A540C296E5702C`
  and APK `02C0EA5B0E30502DE1C5BFF25BA03330877AE0CDD3C0991C9E31BE2B0BDFA7FC`
  passed both BLE orientations: board-central sessions `E54DB407` / `DB6E5978`
  and board-peripheral session `4FF8E555`. The last run exercised the previously
  failing notification-before-readiness-service ordering.

## Open release blockers

1. The 3+ physical contention criterion has not passed. Both retained
   three-machine attempts failed to migrate. The Windows adapter cannot
   advertise the required complete beacon and is not a qualified substitute
   for a third BLE-ACTIVATE-1 peer.
2. The existing bundle was built before later fixes. It must be rebuilt only
   after physical closure, then all final gates must run on those exact sources.
3. Charter-required public review and disclosure decisions are separate and
   have not been replaced by this private audit.

The source-archive packaging defect was repaired by retaining exact revision
metadata in exports. The tracked generated SDK archive now has explicit
provenance accounting: the audit requires its README, artifact inventory and
matching digest; arbitrary release binaries remain refused.

No protocol constants, role/token rules, or conformance criteria were relaxed.
No publication or release tag is authorized by this record.

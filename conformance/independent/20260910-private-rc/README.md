# Private v1 candidate closure

Row 35's original physical invariant is satisfied. The owner review dated
2026-09-10 restores the original V1_SCOPE section 5.10 criterion; the later
three-cell stress matrix is informative. This scope decision is explicit and
does not change the outcome or contents of any retained experiment.

`verify_row35.py` verifies all 75 committed campaign artifact digests and the
E0585224 transaction. All three physical machines transmit and decode AP;
Windows is heard by both qualified devices. The later Windows ACCEPT does not
replace Android's first selected session. Both endpoints admit policy and
migrate on the same BLE session, with no observed three-edge acceptance cycle.
`ROW35.json` is the machine-readable receipt. This verifies a bounded run,
not guaranteed convergence under every interference pattern.

The board image is EEA8DA8D63078D29ECD836967D9C422CAA55BA98007CF9287F3D030C5EF881F4
and APK is E997AEA073AEA516F9C79B0CBAC23E171638D46887A49DBAE1779B7B4203B0B8.
The same campaign retains both BLE roles, explicit early-frame deferral,
exact firmware readback, two equal-resource cancelled retries with live audio,
and STOP cancellation. No new physical experiment is authorized by this record.

The full historical campaign remains under the sibling SDK's
`hardware/dfr1154-autonomous-node/runs/20260909-contention-closure/`.
Its failed 120-second collision recheck and stricter historical HOLD verdict
remain unchanged. Windows is qualified here only as an AP contention participant,
not as a transmitter-diversity endpoint or a complete BLE implementation.

Release engineering receipts will be sealed here after execution. The bundle
is a private candidate; public visibility, external review and Stable tags
remain separate. AP-BOOTSTRAP-1 and BLE-ACTIVATE-1 retain their Candidate caveats.

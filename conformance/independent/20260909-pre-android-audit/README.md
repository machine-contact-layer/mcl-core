# Pre-Android audit checkpoint, 2026-09-09

**Release not approved.** COM3 component/recovery work and repository checks
are complete for this checkpoint. Android physical lifecycle work remains.
The paper, tags, repository visibility and release bundle were not changed.

## Verified results

| Gate | Result | Receipt |
|---|---|---|
| MSVC /W4 /WX, all eight repositories | 43 test targets passed | `msvc.log` |
| POSIX rehearsal | 18/19 passed; bundle reconstruction failed | `posix-rehearsal.log` |
| Standalone developer SDK | External one-header consumer passed; 131 checks; 281 local Markdown links; seven negative documentation-checker cases | `package-final.log` |
| Windows BLE probe verdict | Six mocked cases passed, including silence, wrong bytes, duplicate and rejected fragments; physical exact echo passed on the board | rehearsal and board receipts |
| Provenance/licensing | Passed | `provenance-final.log` |
| Disclosure audit | Zero fatal findings; 42 evidence-file decisions after the checkpoint evidence was staged | `disclosure-sealed.log` |
| Android bench build | Built from canonical protocol sources; not installed or physically tested in this checkpoint | `android-build.log` |

The POSIX rehearsal includes GCC/Clang, sanitizers, freestanding cross-compiles,
conformance, adoption, API/registry/specification checks and deployment checks.
Its remaining failure is an old bundle checksum snapshot and missing developer
SDK archive. A generated working package passing does not repair that bundle.
Final gates must run again after physical closure and the final bundle rebuild.

## Board image and claim boundary

Final application SHA-256:
`F4F1C89BB837E9CAE0696A441138C45BD6FE8D13872AB15C833E8857D02CE8FD`
(1,274,400 bytes). Full readback at `0x20000` matched. The image fixes blocking
activation, repeated client allocation, unbounded scan continuation and native
NimBLE address reversal. Final review also fixed cross-task mailbox publication
and completion before worker-receipt consumption.

The final image passed address/beacon controls, two cancelled connection
attempts with one client and equal settled heap, two live acoustic PRESENCE
recoveries without capture loss, stop during activation, and a Windows-central
40-byte / three-fragment exact echo from the board peripheral. These configured
diagnostics correctly report `zero_prior=false`. Prior image receipts and failed
readback/Windows-peripheral attempts remain preserved.

Detailed evidence and source/build hashes are in
`mcl-sdk/hardware/dfr1154-autonomous-node/runs/20260909-activation-worker/`.
The old 16 KB versus 5.4 KB observation does not establish the cause of the
earlier Android connection failure. No first-failure causal claim is approved.

Android APK SHA-256:
`44A3B42899C26FF6B09D3B33E52F977137461969F5C30D1BC29EFEB7E43E8DC9`.

## Exact continuation

1. Switch USB from COM3 to Android, preserving board power and Wi-Fi 2 control.
2. Install the freshly built bench. Independently require Windows to scan the
   exact diagnostic UUID/token, connect, discover GATT and receive the exact
   40-byte / three-fragment return from Android.
3. Use board scenario 7 against that same Android diagnostic advertiser to
   test the corrected production central worker. Scenario 5 proves scan only.
4. Run the full zero-prior facade lifecycle, reverse-role regression and 3+
   physical contention under the existing contracts and admission policy.
5. Only after physical closure, rebuild the final bundle and rerun all final
   gates on its exact sources. Public review and disclosure remain separate.

`source-sha256.txt` records the implementation/tool snapshot. Logs were decoded
to UTF-8/LF without deleting transcript lines; trailing spaces in raw tool
output are retained. These are private lab evidence, not a public release.

# Final private-closure receipts

These are the current receipts for release gate rows 31, 32 and 33. They
supersede `20260910-private-rc/` as the evidence those rows cite.

The earlier receipts are not withdrawn and not edited. They record what was
true on 2026-09-10. They stopped being the *final* evidence when executable
source changed after them: the Base 1 send path
(`mcl_node_send_framed_tier0_at_major`), the arranged-bearer deployment, and
the two gates added to check them. A ledger that still pointed at 20 POSIX
checks and 43 MSVC targets was pointing at a rehearsal that predated the code
it was supposed to qualify. That is the defect this directory closes, and it
is bookkeeping, not a new engineering campaign.

## What ran

| receipt | result |
| --- | --- |
| `posix-rehearsal.log` | 22 checks, 22 passed, 0 failed, exit 0 |
| `msvc-gates.log` | 44 test targets, all passed, exit 0 |
| `go-no-go.log` | no fatal findings, exit 0 |
| `reconstruction.log` | RECONSTRUCTION VERIFIED, exit 0 |
| `HEADS.json` | the eight revisions all four ran against |

All eight working trees were clean at the frozen heads before the run and
unchanged after it, so these receipts describe committed bytes and not a
working copy.

The two checks that take the count from 20 to 22 are
`check-base-deployment.sh` and `check-evidence-digests.sh`. The extra MSVC
target is `test_base1`.

## The rig fault this run found

The first attempt failed seven checks. None of it was the tree.

The 2026-09-10 rehearsal had been run as **root**, and it left root-owned
working directories in `/tmp` — `mclgates`, `mcl-packaging`,
`mcl-api-baseline`, `mcl-spec-index`, `mcl-ap-vectors-build`,
`mcl-deployment-profiles`, `mcl-trace.txt`. Re-running as an ordinary user
could not overwrite them, so the gates reported `Permission denied` and the
go/no-go audit inherited two FATALs from the two it could not rebuild.

Read quickly, that looks like an API baseline break and a stale specification
index. It was neither. The failures are one-to-one with the leftover
directories, which is the signature of a stale working directory and not of a
broken tree.

The receipts here were taken after clearing those leftovers, as an
unprivileged user with a private empty `TMPDIR`. That is a stronger
configuration than the run it replaces: root could write over anything it
found, so a root run cannot distinguish a gate that rebuilt from a gate that
reused. Prefer this configuration for future rehearsals.

## What these receipts do not establish

Every check here was written by this project, including the ones that check
the others. Passing them says the tree is self-consistent. It does not say it
is correct, and it is not review.

No hardware ran. The E3/E4 acoustic, BLE, IP and dual-radio campaigns stand on
the rigs their own READMEs name; a software pass does not re-measure them and
a green result here says nothing about them.

Public visibility, the governance receipt and charter-required public external
review are rows 27, 37 and 36. All three remain open, and none of them is
satisfied by anything in this directory.

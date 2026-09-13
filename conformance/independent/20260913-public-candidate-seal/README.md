# Public Candidate seal receipts

The exact-head software closure on the final Public Candidate heads, taken on
2026-09-13 after the release-integrity fixes, the rows 27/37 closure and the
adoption READMEs merged. These are the receipts release gate rows 31, 32 and
33 now cite. The 2026-09-10 and 2026-09-12 receipts are retained unedited; each
stopped being final when the tree it qualified moved.

| receipt | result |
| --- | --- |
| `posix-rehearsal.log` | 22 checks, 22 passed, exit 0 |
| `msvc-gates.log` | 44 test targets, all passed, exit 0 |
| `go-no-go.log` | no fatal findings, exit 0 |
| `reconstruction.log` | RECONSTRUCTION VERIFIED, exit 0 |
| `HEADS.json` | the eight release revisions, and `.github` separately |

No hardware ran. Every check here was written by this project, so passing them
says the tree is self-consistent, not that it is correct. That is what row 36,
public external review, is for.

## Order, and why

The POSIX rehearsal, go/no-go and reconstruction ran on `mcl-core` with the
bundle rebuilt onto the final heads. MSVC ran on the same final heads just
before that bundle commit, which changes no C source. The transcripts were then
scrubbed and digested, and rows 31 to 33 were updated from them. Because the
ledger is an inventoried release artifact, the bundle was rebuilt once more
after that update and the rehearsal was re-run to confirm it still passes. The
transcripts here are the first run; the confirmation is recorded in the pull
request that merges this directory.

## One edit to the captured logs

Local identity was replaced before digesting: the repository root, home
directories, the account name and the workstation name became `<repo-root>`,
`<user-home>`, `<builder>` and `<workstation>`. No gate name, result, count or
exit status was touched.

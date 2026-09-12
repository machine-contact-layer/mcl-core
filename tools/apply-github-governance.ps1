<#
.SYNOPSIS
    Apply and verify per-repository governance across the eight MCL repositories.

.DESCRIPTION
    Release gate row 37. Run this IMMEDIATELY AFTER the eight repositories are
    made public, and not before: on GitHub Free both branch protection and
    repository rulesets answer

        403 Upgrade to GitHub Pro or make this repository public

    while a repository is private. That was measured, not assumed, which is why
    protections cannot be pre-staged and why the interval between the
    visibility flip and this script is real. The interval is small in severity
    -- becoming public grants no outsider write access -- and this script exists
    so it is measured in seconds rather than in a manual settings session.

    Organisation-wide rulesets are deliberately NOT applied. They require
    GitHub Team; visibility does not unlock them, and eight repositories are
    manageable per-repository.

    Every setting is written and then READ BACK through the API, and the
    receipt is the read-back, not the write. A governance setting nobody
    re-read is a governance setting nobody has.

.PARAMETER WhatIf
    Show what would be applied and verify current state without writing.

.PARAMETER Receipt
    Path for the machine-readable receipt. Default:
    mcl-core/releases/v1.0.0/GOVERNANCE_RECEIPT.json
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$Org = 'machine-contact-layer',
    [string]$Receipt
)

$ErrorActionPreference = 'Stop'

$repos = @('mcl-core','mcl-wire','mcl-link','mcl-sdk','mcl-ap','mcl-ip','mcl-ble','mcl-uwb')

if (-not $Receipt) {
    $root = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    $Receipt = Join-Path $root 'mcl-core\releases\v1.0.0\GOVERNANCE_RECEIPT.json'
}

if (-not $env:GH_TOKEN) {
    throw "GH_TOKEN is not set. Run: `$env:GH_TOKEN = mcl-gh-token"
}

function Invoke-GH {
    param([string[]]$GhArgs, [switch]$AllowFail)
    $out = & gh @GhArgs 2>&1
    if ($LASTEXITCODE -ne 0 -and -not $AllowFail) {
        throw "gh $($GhArgs -join ' ') failed: $out"
    }
    return $out
}

# The branch ruleset applied to every repository. PR-only merges, one approving
# review, required conversation resolution, code-owner review, required CI, and
# no force push or deletion of the default branch.
function New-BranchRuleset {
    @{
        name        = 'mcl-main-protection'
        target      = 'branch'
        enforcement = 'active'
        conditions  = @{
            ref_name = @{ include = @('~DEFAULT_BRANCH'); exclude = @() }
        }
        rules = @(
            @{ type = 'deletion' },
            @{ type = 'non_fast_forward' },       # no force push
            @{
                type = 'pull_request'
                parameters = @{
                    required_approving_review_count   = 1
                    require_code_owner_review         = $true
                    required_review_thread_resolution = $true
                    dismiss_stale_reviews_on_push     = $true
                    require_last_push_approval        = $false
                }
            },
            @{
                type = 'required_status_checks'
                parameters = @{
                    strict_required_status_checks_policy = $true
                    required_status_checks = @(
                        @{ context = 'build (gcc)' },
                        @{ context = 'build (clang)' }
                    )
                }
            }
        )
    }
}

# Tag protection. A release tag that can be moved is not a release tag: the
# whole point of tagging all eight repositories at v1.0.0 is that the manifest
# names one immutable revision per component.
function New-TagRuleset {
    @{
        name        = 'mcl-release-tags'
        target      = 'tag'
        enforcement = 'active'
        conditions  = @{
            ref_name = @{ include = @('refs/tags/v*'); exclude = @() }
        }
        rules = @(
            @{ type = 'deletion' },
            @{ type = 'non_fast_forward' },
            @{ type = 'update' }
        )
    }
}

$results = @()

foreach ($repo in $repos) {
    Write-Host "== $repo" -ForegroundColor Cyan

    $info = Invoke-GH @('api', "repos/$Org/$repo") | ConvertFrom-Json
    if ($info.private) {
        Write-Warning "  $repo is still PRIVATE. Rulesets are unavailable on GitHub Free until it is public. Skipping."
        $results += [pscustomobject]@{ repository = $repo; skipped = 'still private' }
        continue
    }

    foreach ($rs in @((New-BranchRuleset), (New-TagRuleset))) {
        $body = $rs | ConvertTo-Json -Depth 12 -Compress
        $tmp  = [IO.Path]::GetTempFileName()
        try {
            [IO.File]::WriteAllText($tmp, $body)

            # Replace an existing ruleset of the same name rather than stacking
            # duplicates, so re-running is idempotent.
            $existing = Invoke-GH @('api', "repos/$Org/$repo/rulesets") -AllowFail | ConvertFrom-Json
            $match = $existing | Where-Object { $_.name -eq $rs.name }

            if ($PSCmdlet.ShouldProcess("$repo/$($rs.name)", 'apply ruleset')) {
                if ($match) {
                    Invoke-GH @('api','-X','PUT',"repos/$Org/$repo/rulesets/$($match.id)",'--input',$tmp) | Out-Null
                } else {
                    Invoke-GH @('api','-X','POST',"repos/$Org/$repo/rulesets",'--input',$tmp) | Out-Null
                }
                Write-Host "   applied $($rs.name)"
            }
        } finally {
            Remove-Item $tmp -Force -ErrorAction SilentlyContinue
        }
    }

    # --- read back. This, not the write, is the receipt. ---
    $live = Invoke-GH @('api', "repos/$Org/$repo/rulesets") | ConvertFrom-Json
    $detail = @()
    foreach ($r in $live) {
        $detail += (Invoke-GH @('api', "repos/$Org/$repo/rulesets/$($r.id)") | ConvertFrom-Json)
    }

    $branch = $detail | Where-Object { $_.name -eq 'mcl-main-protection' }
    $tag    = $detail | Where-Object { $_.name -eq 'mcl-release-tags' }

    $results += [pscustomobject]@{
        repository        = $repo
        private           = $info.private
        default_branch    = $info.default_branch
        branch_ruleset    = if ($branch) { $branch.enforcement } else { 'MISSING' }
        tag_ruleset       = if ($tag) { $tag.enforcement } else { 'MISSING' }
        branch_rule_types = @($branch.rules.type | Sort-Object)
        tag_rule_types    = @($tag.rules.type | Sort-Object)
        codeowners        = (Invoke-GH @('api',"repos/$Org/$repo/contents/.github/CODEOWNERS",'--jq','.sha') -AllowFail)
        verified_utc      = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }
}

$out = [pscustomobject]@{
    generated_by = 'mcl-core/tools/apply-github-governance.ps1'
    organization = $Org
    note         = 'Organisation-wide rulesets are intentionally absent: they require GitHub Team, and visibility does not unlock them. Per-repository rulesets are the v1 mechanism.'
    repositories = $results
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Receipt) | Out-Null
$out | ConvertTo-Json -Depth 12 | Out-File -FilePath $Receipt -Encoding utf8

Write-Host ""
Write-Host "Receipt written to $Receipt"
$results | Format-Table repository, private, branch_ruleset, tag_ruleset -AutoSize

$missing = $results | Where-Object { $_.branch_ruleset -ne 'active' -or $_.tag_ruleset -ne 'active' }
if ($missing) {
    Write-Host ""
    Write-Warning "Row 37 is NOT satisfied. These repositories lack an active ruleset:"
    $missing | ForEach-Object { Write-Warning "  $($_.repository)" }
    exit 1
}

Write-Host ""
Write-Host "Row 37 satisfied: every repository carries an active branch and tag ruleset." -ForegroundColor Green

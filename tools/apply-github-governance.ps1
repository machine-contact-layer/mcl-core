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

    TWO GOVERNANCE CLASSES. The eight MCL repositories are release components
    and get the full ruleset. The .github repository is organization
    infrastructure -- the public profile, and the default SECURITY.md and
    CONTRIBUTING.md for the seven repositories that define neither -- so it is
    protected, but with no required status checks and no tag rule. It is NOT
    the ninth component: it is absent from the v1.0.0 manifest, the
    synchronized tags and the canonical Release, and row 37 is satisfied by
    the eight alone.

    Every setting is written and then READ BACK through the API, and the
    receipt is the read-back, not the write. A governance setting nobody
    re-read is a governance setting nobody has.

    The read-back records VALUES, not rule types. Recording that a
    pull_request rule exists says nothing: a rule requiring zero approvals
    and no code-owner review has the same type as a correct one. So each
    parameter is pulled out of the live response, serialized into the receipt
    as its observed value, and asserted. Any mismatch names the setting, the
    expected value and the value GitHub actually returned, and fails row 37.

    Verified offline against a stand-in gh CLI: a correct ruleset verifies,
    and eleven deliberately malformed ones -- zero approvals, code-owner
    review off, conversation resolution off, stale-review dismissal off,
    non-strict checks, a missing required check, the wrong branch ref,
    enforcement left on 'evaluate', a mutable tag ruleset, an over-broad tag
    ref, and a missing CODEOWNERS file -- are each refused by name. Every one
    of those eleven would have satisfied a receipt that recorded only rule
    types.

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

# ORGANIZATION INFRASTRUCTURE, governed but NOT a release component.
#
# The .github repository carries the public organization profile and, because
# GitHub serves default community-health files from it, the SECURITY.md and
# CONTRIBUTING.md of every MCL repository that does not define its own. Seven
# of the eight do not. A change there alters the published security policy of
# seven repositories without a commit appearing in any of them, which is why
# it is protected at all.
#
# It is deliberately absent from the v1.0.0 manifest, the synchronized tags and
# the canonical Release: its lifecycle is configuration, not protocol release.
# The MCL v1 release is exactly eight repositories. Row 37 is about those eight
# and is unchanged by anything in this list.
#
# It gets a LIGHTER ruleset. Forcing 'build (gcc)' and 'build (clang)' onto a
# repository that has no such workflow would make every pull request
# permanently unmergeable, and there is no release tag namespace to protect.
$infraRepos = @('.github')

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

# The lighter ruleset for organization infrastructure: review is required, the
# branch cannot be force-pushed or deleted, and that is all. No required status
# checks -- see the note on $infraRepos -- and no tag rule, because nothing here
# is released under a v* tag.
function New-InfraBranchRuleset {
    @{
        name        = 'mcl-main-protection'
        target      = 'branch'
        enforcement = 'active'
        conditions  = @{
            ref_name = @{ include = @('~DEFAULT_BRANCH'); exclude = @() }
        }
        rules = @(
            @{ type = 'deletion' },
            @{ type = 'non_fast_forward' },
            @{
                type = 'pull_request'
                parameters = @{
                    required_approving_review_count   = 1
                    require_code_owner_review         = $true
                    required_review_thread_resolution = $true
                    dismiss_stale_reviews_on_push     = $true
                    require_last_push_approval        = $false
                }
            }
        )
    }
}

$results = @()

$allRepos = @()
foreach ($r in $repos)      { $allRepos += [pscustomobject]@{ Name = $r; Class = 'release' } }
foreach ($r in $infraRepos) { $allRepos += [pscustomobject]@{ Name = $r; Class = 'infrastructure' } }

foreach ($entry in $allRepos) {
    $repo  = $entry.Name
    $class = $entry.Class
    Write-Host "== $repo ($class)" -ForegroundColor Cyan

    $info = Invoke-GH @('api', "repos/$Org/$repo") | ConvertFrom-Json
    if ($info.private) {
        Write-Warning "  $repo is still PRIVATE. Rulesets are unavailable on GitHub Free until it is public. Skipping."
        $results += [pscustomobject]@{ repository = $repo; repository_class = $class; skipped = 'still private' }
        continue
    }

    $rulesets = if ($class -eq 'infrastructure') {
        @((New-InfraBranchRuleset))
    } else {
        @((New-BranchRuleset), (New-TagRuleset))
    }

    foreach ($rs in $rulesets) {
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
    #
    # Row 37 says every setting is read back through the API and recorded.
    # Recording that a rule of the right TYPE exists is not that: a
    # pull_request rule requiring zero approvals and no code-owner review has
    # exactly the same type as a correct one. So each parameter is pulled out
    # of the live response, written into the receipt as its actual value, and
    # asserted against what this script set. The receipt is the values, and a
    # value that disagrees fails the row.
    $live = Invoke-GH @('api', "repos/$Org/$repo/rulesets") | ConvertFrom-Json
    $detail = @()
    foreach ($r in $live) {
        $detail += (Invoke-GH @('api', "repos/$Org/$repo/rulesets/$($r.id)") | ConvertFrom-Json)
    }

    $branch = $detail | Where-Object { $_.name -eq 'mcl-main-protection' }
    $tag    = $detail | Where-Object { $_.name -eq 'mcl-release-tags' }

    function Get-RuleParameters {
        param($Ruleset, [string]$Type)
        if (-not $Ruleset) { return $null }
        $rule = $Ruleset.rules | Where-Object { $_.type -eq $Type } | Select-Object -First 1
        if ($rule) { return $rule.parameters }
        return $null
    }

    $pr     = Get-RuleParameters -Ruleset $branch -Type 'pull_request'
    $checks = Get-RuleParameters -Ruleset $branch -Type 'required_status_checks'

    $branchTypes  = @($branch.rules.type | Sort-Object)
    $tagTypes     = @($tag.rules.type | Sort-Object)
    $branchRefs   = @($branch.conditions.ref_name.include)
    $tagRefs      = @($tag.conditions.ref_name.include)
    $contexts     = @($checks.required_status_checks.context | Sort-Object)

    # Observed values, serialized into the receipt exactly as the API
    # returned them. A reader compares these against the ledger; they are not
    # re-derived from what the script intended to write.
    $observed = [ordered]@{
        branch_ruleset_enforcement           = if ($branch) { $branch.enforcement } else { 'MISSING' }
        branch_ref_include                   = $branchRefs
        branch_rule_types                    = $branchTypes
        required_approving_review_count      = $pr.required_approving_review_count
        require_code_owner_review            = $pr.require_code_owner_review
        required_review_thread_resolution    = $pr.required_review_thread_resolution
        dismiss_stale_reviews_on_push        = $pr.dismiss_stale_reviews_on_push
        require_last_push_approval           = $pr.require_last_push_approval
        strict_required_status_checks_policy = $checks.strict_required_status_checks_policy
        required_status_check_contexts       = $contexts
        tag_ruleset_enforcement              = if ($tag) { $tag.enforcement } else { 'MISSING' }
        tag_ref_include                      = $tagRefs
        tag_rule_types                       = $tagTypes
    }

    # Each assertion names the row-37 promise it enforces. A failure lists the
    # setting, not merely "not satisfied", so the operator knows what to fix.
    function Assert-Setting {
        param([string]$Name, [bool]$Ok, $Expected, $Actual)
        if (-not $Ok) {
            $script:failures += [pscustomobject]@{
                setting  = $Name
                expected = "$Expected"
                actual   = "$Actual"
            }
        }
    }

    $script:failures = @()

    Assert-Setting 'branch_ruleset_enforcement' ($branch -and $branch.enforcement -eq 'active') 'active' $observed.branch_ruleset_enforcement
    Assert-Setting 'branch_ref_include' (($branchRefs.Count -eq 1) -and ($branchRefs[0] -eq '~DEFAULT_BRANCH')) '~DEFAULT_BRANCH' ($branchRefs -join ',')
    Assert-Setting 'branch_rule.deletion' ($branchTypes -contains 'deletion') 'present' ($branchTypes -join ',')
    Assert-Setting 'branch_rule.non_fast_forward' ($branchTypes -contains 'non_fast_forward') 'present' ($branchTypes -join ',')
    Assert-Setting 'branch_rule.pull_request' ($null -ne $pr) 'present' ($branchTypes -join ',')
    Assert-Setting 'required_approving_review_count' ($pr.required_approving_review_count -ge 1) '>= 1' $pr.required_approving_review_count
    Assert-Setting 'require_code_owner_review' ($pr.require_code_owner_review -eq $true) 'true' $pr.require_code_owner_review
    Assert-Setting 'required_review_thread_resolution' ($pr.required_review_thread_resolution -eq $true) 'true' $pr.required_review_thread_resolution
    Assert-Setting 'dismiss_stale_reviews_on_push' ($pr.dismiss_stale_reviews_on_push -eq $true) 'true' $pr.dismiss_stale_reviews_on_push
    if ($class -eq 'release') {
        Assert-Setting 'branch_rule.required_status_checks' ($null -ne $checks) 'present' ($branchTypes -join ',')
        Assert-Setting 'strict_required_status_checks_policy' ($checks.strict_required_status_checks_policy -eq $true) 'true' $checks.strict_required_status_checks_policy
        Assert-Setting 'required_status_check:build (gcc)' ($contexts -contains 'build (gcc)') 'present' ($contexts -join ',')
        Assert-Setting 'required_status_check:build (clang)' ($contexts -contains 'build (clang)') 'present' ($contexts -join ',')

        Assert-Setting 'tag_ruleset_enforcement' ($tag -and $tag.enforcement -eq 'active') 'active' $observed.tag_ruleset_enforcement
        Assert-Setting 'tag_ref_include' (($tagRefs.Count -eq 1) -and ($tagRefs[0] -eq 'refs/tags/v*')) 'refs/tags/v*' ($tagRefs -join ',')
        Assert-Setting 'tag_rule.deletion' ($tagTypes -contains 'deletion') 'present' ($tagTypes -join ',')
        Assert-Setting 'tag_rule.non_fast_forward' ($tagTypes -contains 'non_fast_forward') 'present' ($tagTypes -join ',')
        Assert-Setting 'tag_rule.update' ($tagTypes -contains 'update') 'present' ($tagTypes -join ',')
    } else {
        # Infrastructure. Required status checks must be ABSENT, not merely
        # unchecked: a required context that no workflow ever reports would
        # make every pull request permanently unmergeable, so asserting its
        # absence is a real check rather than a skipped one.
        Assert-Setting 'branch_rule.required_status_checks_absent' ($null -eq $checks) 'absent' ($branchTypes -join ',')
        Assert-Setting 'tag_ruleset_absent' ($null -eq $tag) 'absent' $observed.tag_ruleset_enforcement
    }

    # CODEOWNERS must exist, because require_code_owner_review with no
    # CODEOWNERS file protects nothing at all.
    # GitHub honours CODEOWNERS in .github/, the repository root, or docs/.
    # The eight use .github/CODEOWNERS; inside a repository that is itself
    # named .github that path reads as .github/.github/, so the root is the
    # natural place there. Accept either rather than force one convention.
    $codeownersSha = Invoke-GH @('api',"repos/$Org/$repo/contents/.github/CODEOWNERS",'--jq','.sha') -AllowFail
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($codeownersSha)) {
        $codeownersSha = Invoke-GH @('api',"repos/$Org/$repo/contents/CODEOWNERS",'--jq','.sha') -AllowFail
        if ($LASTEXITCODE -ne 0) { $codeownersSha = $null }
    }
    Assert-Setting 'codeowners_present' (-not [string]::IsNullOrWhiteSpace($codeownersSha)) 'present' $codeownersSha

    $repoFailures = @($script:failures)

    $results += [pscustomobject]@{
        repository       = $repo
        repository_class = $class
        private        = $info.private
        default_branch = $info.default_branch
        observed       = [pscustomobject]$observed
        codeowners_sha = $codeownersSha
        verified       = ($repoFailures.Count -eq 0)
        failures       = $repoFailures
        verified_utc   = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
    }

    if ($repoFailures.Count -eq 0) {
        Write-Host "   verified: every asserted setting matches" -ForegroundColor Green
    } else {
        Write-Warning "   $($repoFailures.Count) setting(s) do not match:"
        $repoFailures | ForEach-Object { Write-Warning "     $($_.setting): expected $($_.expected), got $($_.actual)" }
    }
}

$out = [pscustomobject]@{
    generated_by = 'mcl-core/tools/apply-github-governance.ps1'
    organization = $Org
    note         = 'Organisation-wide rulesets are intentionally absent: they require GitHub Team, and visibility does not unlock them. Per-repository rulesets are the v1 mechanism.'
    receipt_kind = 'read-back of live API state, with every asserted setting recorded as its observed value'
    release_repositories = $repos
    infrastructure_repositories = $infraRepos
    scope_note   = 'The MCL v1 release is exactly the eight release repositories. Infrastructure repositories are governed here but are NOT release components: they are absent from the v1.0.0 manifest, the synchronized tags and the canonical Release. Row 37 is satisfied by the eight.'
    asserted_release = @(
        'branch ruleset active on ~DEFAULT_BRANCH',
        'deletion and non_fast_forward blocked on the default branch',
        'pull request required, >= 1 approving review',
        'code-owner review required, and a CODEOWNERS file exists',
        'conversation resolution required',
        'stale reviews dismissed on push',
        'strict required status checks, including build (gcc) and build (clang)',
        'tag ruleset active on refs/tags/v*, blocking deletion, force-update and mutation'
    )
    asserted_infrastructure = @(
        'branch ruleset active on ~DEFAULT_BRANCH',
        'deletion and non_fast_forward blocked on the default branch',
        'pull request required, >= 1 approving review',
        'code-owner review required, and a CODEOWNERS file exists',
        'conversation resolution required',
        'stale reviews dismissed on push',
        'required status checks ABSENT -- a required context no workflow reports would make every pull request unmergeable',
        'tag ruleset ABSENT -- nothing here is released under a v* tag'
    )
    repositories = $results
}

New-Item -ItemType Directory -Force -Path (Split-Path -Parent $Receipt) | Out-Null
$out | ConvertTo-Json -Depth 12 | Out-File -FilePath $Receipt -Encoding utf8

Write-Host ""
Write-Host "Receipt written to $Receipt"
$results | Format-Table repository, repository_class, private, verified -AutoSize

$skipped = $results | Where-Object { $_.PSObject.Properties.Name -contains 'skipped' }
$bad     = $results | Where-Object { $_.PSObject.Properties.Name -notcontains 'skipped' -and -not $_.verified }

# Row 37 is a statement about the eight RELEASE repositories. Infrastructure is
# governed and reported, but it is not what the row promises, and a healthy
# .github must never be able to make the row look satisfied.
$releaseResults = $results | Where-Object { $_.repository_class -eq 'release' }
$releaseOk = @($releaseResults | Where-Object {
    $_.PSObject.Properties.Name -notcontains 'skipped' -and $_.verified
}).Count

if ($skipped) {
    Write-Host ""
    Write-Warning "These repositories were skipped:"
    $skipped | ForEach-Object { Write-Warning "  $($_.repository) ($($_.repository_class)): $($_.skipped)" }
}
if ($bad) {
    Write-Host ""
    Write-Warning "These repositories have settings that do not match:"
    $bad | ForEach-Object {
        Write-Warning "  $($_.repository) ($($_.repository_class))"
        $_.failures | ForEach-Object { Write-Warning "    $($_.setting): expected $($_.expected), got $($_.actual)" }
    }
}

if ($releaseOk -ne $repos.Count) {
    Write-Host ""
    Write-Warning "Row 37 is NOT satisfied: $releaseOk of $($repos.Count) release repositories verified."
}
if ($skipped -or $bad) { exit 1 }

Write-Host ""
Write-Host "Row 37 satisfied: all $($repos.Count) release repositories, every asserted setting read back and matching." -ForegroundColor Green
Write-Host "Infrastructure governed and verified: $($infraRepos -join ', ') -- not a release component, not tagged, not in the manifest." -ForegroundColor Green

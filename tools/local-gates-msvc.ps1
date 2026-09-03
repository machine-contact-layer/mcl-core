# MSVC half of the local quality gates.
#
# local-gates.sh runs GCC, Clang, the sanitizers, the freestanding
# cross-compiles and the C++ header compiles. It needs a POSIX shell and the
# GNU/LLVM toolchain, so it does NOT run MSVC -- and the manifest used to claim
# it ran "every gate in one pass", which was wrong in the direction that
# overstates coverage.
#
# This is the other half. Two runs, both by hand, and a claim of "all compilers"
# needs both.
#
# MSVC is not redundant with GCC and Clang. Each sees things the others do not:
# Clang's -Wunneeded-internal-declaration found a test constant used only for
# its length while reading as though it carried real protocol bytes; GCC's
# -Werror=unused-function found a static function left behind by a refactor that
# MSVC accepted silently. MSVC's /W4 has its own set, and an integrator on
# Windows will hit them first.
#
# This project has no hosted CI and will not gain any: a governing
# interoperability layer whose verification depends on one vendor's build
# service has a dependency it did not declare.
#
#   powershell -File mcl-core\tools\local-gates-msvc.ps1
#   powershell -File mcl-core\tools\local-gates-msvc.ps1 -Root C:\path\to\mcl

param(
    [string]$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [string]$Work = (Join-Path $env:TEMP 'mclgates-msvc')
)

$ErrorActionPreference = 'Continue'
$repos = @('mcl-core', 'mcl-wire', 'mcl-link', 'mcl-sdk',
           'mcl-ap', 'mcl-ip', 'mcl-ble', 'mcl-uwb')
$failures = 0
$targets = 0

function Note($text) {
    Write-Host ''
    Write-Host "=== $text ===" -ForegroundColor Cyan
}

function Fail($text) {
    $script:failures++
    Write-Host "  FAIL: $text" -ForegroundColor Red
}

Note "MSVC /W4 /WX, all eight repositories"
Write-Host "root: $Root"

if (-not (Get-Command cmake -ErrorAction SilentlyContinue)) {
    Write-Host 'cmake is not on PATH.' -ForegroundColor Red
    exit 2
}

foreach ($repo in $repos) {
    $src = Join-Path $Root $repo
    if (-not (Test-Path $src)) {
        Fail "$repo is not present at $src"
        continue
    }

    $build = Join-Path $Work $repo
    Write-Host ''
    Write-Host "-- $repo"

    # /W4 /WX: warnings are errors. A warning an integrator has to read past is
    # a warning nobody reads.
    $cfg = & cmake -S $src -B $build -DCMAKE_C_FLAGS='/W4 /WX' 2>&1
    if ($LASTEXITCODE -ne 0) {
        Fail "$repo configure"
        $cfg | Select-Object -Last 15 | ForEach-Object { Write-Host "     $_" }
        continue
    }

    $bld = & cmake --build $build --config Debug 2>&1
    if ($LASTEXITCODE -ne 0) {
        Fail "$repo build"
        $bld | Select-String -Pattern 'error|warning' |
            Select-Object -Last 15 | ForEach-Object { Write-Host "     $_" }
        continue
    }

    Push-Location $build
    $tst = & ctest -C Debug --output-on-failure 2>&1
    $code = $LASTEXITCODE
    Pop-Location

    # Count what actually ran rather than trusting a remembered number. A test
    # count written from memory was wrong twice in this project's history, in
    # both directions.
    #
    # The pattern matches both shapes ctest emits -- "100% tests passed out of
    # N" when nothing failed, and "... N tests failed out of M" when something
    # did. An earlier version matched only the second and silently reported
    # zero, which is the same class of quietly-wrong number this exists to
    # prevent.
    $line = ($tst | Out-String) -split "`n" | Select-String -Pattern 'out of (\d+)'
    if ($line) {
        $targets += [int]$line[0].Matches[0].Groups[1].Value
    } else {
        Fail "$repo produced no ctest summary line to count"
    }

    if ($code -ne 0) {
        Fail "$repo tests"
        $tst | Select-Object -Last 20 | ForEach-Object { Write-Host "     $_" }
    } else {
        Write-Host "   OK" -ForegroundColor Green
    }
}

Note 'SUMMARY'
Write-Host "test targets run: $targets"
if ($failures -eq 0) {
    Write-Host 'MSVC GATES PASSED' -ForegroundColor Green
    Write-Host ''
    Write-Host 'This is one half. Run local-gates.sh for GCC, Clang, ASan/UBSan,'
    Write-Host 'the ARM and RISC-V freestanding cross-compiles and the C++ header'
    Write-Host 'compiles. Neither run alone is "the gates".'
} else {
    Write-Host "$failures MSVC GATE(S) FAILED" -ForegroundColor Red
}

exit $failures

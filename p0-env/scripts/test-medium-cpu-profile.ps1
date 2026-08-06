[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$profilePath = Join-Path $repositoryRoot 'p0-env\config\faults\cpu-recommendation-medium-v1.json'
$testRoot = Join-Path $repositoryRoot 'p0-env\state\tests\medium-profile'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

$positive = @(& powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'invoke-cpu-stress.ps1') `
    -ProfilePath $profilePath -RunId 'ob-cpu-medium-test-001' `
    -EvidencePath (Join-Path $testRoot 'positive-evidence.json') -WhatIf 2>&1)
if ($LASTEXITCODE -ne 0 -or ($positive -join "`n") -notmatch 'cpu_stress_injection=not-executed') {
    throw "Medium profile positive fixture failed: $($positive -join ' | ')"
}

$invalidProfilePath = Join-Path $testRoot 'invalid-minimum-increase.json'
$invalidProfile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
$invalidProfile.physical_effect_verification.minimum_steady_minus_baseline_mean_millicores = 49
[System.IO.File]::WriteAllText(
    $invalidProfilePath,
    ($invalidProfile | ConvertTo-Json -Depth 20),
    (New-Object System.Text.UTF8Encoding($false))
)
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $negative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'invoke-cpu-stress.ps1') `
        -ProfilePath $invalidProfilePath -RunId 'ob-cpu-medium-test-002' `
        -EvidencePath (Join-Path $testRoot 'negative-evidence.json') -WhatIf 2>&1)
}
finally { $ErrorActionPreference = $previousErrorActionPreference }
if ($LASTEXITCODE -eq 0 -or ($negative -join "`n") -notmatch 'does not match its preregistered CPU-stress contract') {
    throw 'Medium profile verifier accepted a 49 mCPU minimum-increase gate.'
}

Write-Output 'medium_cpu_profile_positive_whatif_fixture=passed'
Write-Output 'medium_cpu_profile_minimum_increase_negative_fixture=passed'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$testRoot = Join-Path $repositoryRoot 'p0-env\state\tests\second-workload-injector-profiles'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

$profiles = @(
    'cpu-recommendation-low-15u-v1.json',
    'cpu-recommendation-medium-15u-v1.json',
    'cpu-recommendation-high-15u-v1.json'
)

foreach ($name in $profiles) {
    $profilePath = Join-Path $repositoryRoot "p0-env\config\faults\$name"
    $profileId = [IO.Path]::GetFileNameWithoutExtension($name)
    $output = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'invoke-cpu-stress.ps1') `
        -ProfilePath $profilePath `
        -RunId "ob-$profileId-test" `
        -EvidencePath (Join-Path $testRoot "$profileId-evidence.json") `
        -WhatIf 2>&1)
    if ($LASTEXITCODE -ne 0 -or ($output -join "`n") -notmatch 'cpu_stress_injection=not-executed') {
        throw "Second-workload injector profile fixture failed for ${profileId}: $($output -join ' | ')"
    }
    Write-Output "second_workload_injector_profile=passed profile=$profileId"
}

$mediumPath = Join-Path $repositoryRoot 'p0-env\config\faults\cpu-recommendation-medium-15u-v1.json'
$invalidPath = Join-Path $testRoot 'invalid-medium-minimum-increase.json'
$invalid = Get-Content -LiteralPath $mediumPath -Raw | ConvertFrom-Json
$invalid.physical_effect_verification.minimum_steady_minus_baseline_mean_millicores = 49
[IO.File]::WriteAllText(
    $invalidPath,
    ($invalid | ConvertTo-Json -Depth 20),
    (New-Object Text.UTF8Encoding($false))
)
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $negative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'invoke-cpu-stress.ps1') `
        -ProfilePath $invalidPath `
        -RunId 'ob-cpu-15u-medium-invalid-test' `
        -EvidencePath (Join-Path $testRoot 'negative-evidence.json') `
        -WhatIf 2>&1)
}
finally { $ErrorActionPreference = $previousErrorActionPreference }
if ($LASTEXITCODE -eq 0 -or ($negative -join "`n") -notmatch 'does not match its preregistered CPU-stress contract') {
    throw 'Second-workload injector accepted a modified medium minimum-effect gate.'
}
Write-Output 'second_workload_injector_modified_contract_negative=passed'
$global:LASTEXITCODE = 0

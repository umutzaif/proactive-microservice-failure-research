[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$positive = @(& powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') `
    -ExpectedProfileRelative 'p0-env/config/workloads/ob-capacity-20u-1r-v1.json' `
    -StaticOnly 2>&1)
if ($LASTEXITCODE -ne 0 -or ($positive -join "`n") -notmatch 'static_workload_profile_binding=passed') {
    throw "Static workload positive fixture failed: $($positive -join ' | ')"
}

$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $negative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') `
        -ExpectedProfileRelative 'p0-env/config/workloads/ob-second-15u-1r-v1.json' `
        -StaticOnly 2>&1)
}
finally { $ErrorActionPreference = $previous }
if ($LASTEXITCODE -eq 0 -or ($negative -join "`n") -notmatch 'static_workload_binding_missing') {
    throw 'Static workload verifier accepted a mismatched profile.'
}

Write-Output 'active_workload_static_positive_fixture=passed'
Write-Output 'active_workload_static_mismatch_negative_fixture=passed'
exit 0

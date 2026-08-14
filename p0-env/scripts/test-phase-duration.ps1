[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'phase-duration.ps1')

$minimumSeconds = 0.05
$startUtc = [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
$endUtc = Wait-UntilMinimumUtcDuration -StartUtc $startUtc -MinimumSeconds $minimumSeconds
$elapsed = ([datetimeoffset]::Parse($endUtc) - [datetimeoffset]::Parse($startUtc)).TotalSeconds
if ($elapsed -lt $minimumSeconds) {
    throw "phase_duration_guard_returned_early:$elapsed"
}

$runnerSource = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'run-low-cpu-calibration.ps1')
if ($runnerSource -notmatch [regex]::Escape(". (Join-Path `$PSScriptRoot 'phase-duration.ps1')")) {
    throw 'phase_duration_guard_not_loaded'
}
if ([regex]::Matches($runnerSource, 'Wait-UntilMinimumUtcDuration').Count -ne 3) {
    throw 'phase_duration_guard_phase_count_mismatch'
}
if ($runnerSource -match 'Start-Sleep\s+-Seconds\s+300') {
    throw 'unguarded_300_second_sleep_remains'
}

Write-Output "phase_duration_elapsed_seconds=$elapsed"
Write-Output 'phase_duration_guard=passed'

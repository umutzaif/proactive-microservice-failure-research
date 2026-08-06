[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'worker-lifecycle.ps1')

function Event([string]$Name, [string]$Utc, [double]$Elapsed = 0) {
    [pscustomobject]@{ event=$Name; event_utc=$Utc; elapsed_seconds=$Elapsed }
}

$positive = Resolve-WorkerLifecycle -Events @(
    (Event 'started' '2026-08-06T12:00:00.000000Z'),
    (Event 'completed' '2026-08-06T12:07:00.250000Z' 420.0002)
) -RampSeconds 120 -SteadySeconds 300
if ($positive.injection_start_utc -ne '2026-08-06T12:00:00.000000Z') { throw 'positive_start_mismatch' }

$negativeCases = @(
    @{ name='missing_utc'; events=@((Event 'started' ''),(Event 'completed' '2026-08-06T12:07:00Z' 420)); expected='worker_started_utc_not_canonical' },
    @{ name='offset_utc'; events=@((Event 'started' '2026-08-06T12:00:00+00:00'),(Event 'completed' '2026-08-06T12:07:00Z' 420)); expected='worker_started_utc_not_canonical' },
    @{ name='wall_duration'; events=@((Event 'started' '2026-08-06T12:00:00Z'),(Event 'completed' '2026-08-06T12:07:06Z' 420)); expected='worker_wall_duration_mismatch' },
    @{ name='monotonic_duration'; events=@((Event 'started' '2026-08-06T12:00:00Z'),(Event 'completed' '2026-08-06T12:07:00Z' 426)); expected='worker_monotonic_duration_mismatch' }
)
foreach ($case in $negativeCases) {
    try {
        [void](Resolve-WorkerLifecycle -Events $case.events -RampSeconds 120 -SteadySeconds 300)
        throw "negative_case_accepted:$($case.name)"
    }
    catch {
        if ($_.Exception.Message -notmatch [regex]::Escape([string]$case.expected)) { throw }
    }
}

Write-Output 'worker_lifecycle_positive_fixture=passed'
$negativeCases | ForEach-Object { Write-Output "worker_lifecycle_$($_.name)_negative_fixture=passed" }

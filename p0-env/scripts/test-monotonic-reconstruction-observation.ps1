[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')

$plan = New-MonotonicReconstructionObservationPlan `
    -DurationSeconds 180 -CadenceSeconds 5 -CompletionTimeoutSeconds 210 `
    -MaximumLatenessMilliseconds 5000
if ($plan.mode -ne 'monotonic_target_time' -or $plan.target_count -ne 36 -or
    $plan.target_elapsed_ms[0] -ne 0 -or
    $plan.target_elapsed_ms[$plan.target_elapsed_ms.Count - 1] -ne 175000) {
    throw 'monotonic_schedule_plan_invalid'
}
if ((Get-MonotonicReconstructionDelayMilliseconds `
        -TargetElapsedMilliseconds 5000 -CurrentElapsedMilliseconds 1350) -ne 3650) {
    throw 'monotonic_schedule_remaining_delay_invalid'
}
if ((Get-MonotonicReconstructionDelayMilliseconds `
        -TargetElapsedMilliseconds 5000 -CurrentElapsedMilliseconds 6200) -ne 0) {
    throw 'monotonic_schedule_late_delay_not_zero'
}
foreach ($current in @(4999.01,4999.1,4999.49,4999.5,4999.6,4999.9,4999.99)) {
    $delay = Get-MonotonicReconstructionDelayMilliseconds `
        -TargetElapsedMilliseconds 5000 -CurrentElapsedMilliseconds $current
    if ($delay -ne 1) { throw "monotonic_fractional_positive_delay_invalid:$current`:$delay" }
}
foreach ($current in @(5000.0,5000.01,5001.0)) {
    $delay = Get-MonotonicReconstructionDelayMilliseconds `
        -TargetElapsedMilliseconds 5000 -CurrentElapsedMilliseconds $current
    if ($delay -ne 0) { throw "monotonic_nonpositive_remaining_delay_invalid:$current`:$delay" }
}

$earlyWakeSequence = [Collections.Generic.Queue[double]]::new()
foreach ($value in @(4900.0,4997.0,5000.25)) { $earlyWakeSequence.Enqueue($value) }
$sleepRequests = [Collections.Generic.List[int]]::new()
$guard = Wait-MonotonicReconstructionTarget -TargetElapsedMilliseconds 5000 `
    -GetElapsedMilliseconds { $earlyWakeSequence.Dequeue() } `
    -SleepMilliseconds { param($Milliseconds) $sleepRequests.Add([int]$Milliseconds) }
if (-not $guard.target_reached -or $guard.reached_elapsed_ms -lt 5000 -or
    $guard.recheck_count -ne 2 -or $sleepRequests.Count -ne 2 -or
    $sleepRequests[0] -ne 100 -or $sleepRequests[1] -ne 3) {
    throw 'monotonic_guarded_recheck_early_wake_invalid'
}
$zeroGuard = Wait-MonotonicReconstructionTarget -TargetElapsedMilliseconds 0 `
    -GetElapsedMilliseconds { 0.0 } `
    -SleepMilliseconds { param($Milliseconds) throw 'zero_target_must_not_sleep' }
if (-not $zeroGuard.target_reached -or $zeroGuard.recheck_count -ne 0) {
    throw 'monotonic_guarded_recheck_zero_target_invalid'
}
$fractionalWakeSequence = [Collections.Generic.Queue[double]]::new()
foreach ($value in @(4999.6,5000.1)) { $fractionalWakeSequence.Enqueue($value) }
$fractionalSleepRequests = [Collections.Generic.List[int]]::new()
$fractionalGuard = Wait-MonotonicReconstructionTarget -TargetElapsedMilliseconds 5000 `
    -GetElapsedMilliseconds { $fractionalWakeSequence.Dequeue() } `
    -SleepMilliseconds { param($Milliseconds) $fractionalSleepRequests.Add([int]$Milliseconds) }
if (-not $fractionalGuard.target_reached -or $fractionalGuard.recheck_count -ne 1 -or
    $fractionalSleepRequests.Count -ne 1 -or $fractionalSleepRequests[0] -ne 1) {
    throw 'monotonic_guarded_fractional_recheck_invalid'
}

$valid = @()
for ($index = 0; $index -lt $plan.target_count; $index++) {
    $target = [long]$plan.target_elapsed_ms[$index]
    $valid += ,[pscustomobject]@{
        target_index=$index;target_elapsed_ms=$target
        sample_started_elapsed_ms=[double]($target + 100)
        sample_completed_elapsed_ms=[double]($target + 900)
        lateness_ms=100;exit_code=0;host='Running';kubelet='Running'
        apiserver='Running';kubeconfig='Configured'
    }
}
$summary = Assert-MonotonicReconstructionObservations -Plan $plan -Observations $valid
if ($summary.completed_count -ne 36 -or $summary.stable_count -ne 36 -or
    $summary.maximum_lateness_ms -ne 100) { throw 'monotonic_schedule_summary_invalid' }

function Expect-Failure([object[]]$Observations, [string]$Expected) {
    try {
        Assert-MonotonicReconstructionObservations -Plan $plan -Observations $Observations | Out-Null
        throw "expected_monotonic_failure_missing:$Expected"
    }
    catch {
        if ($_.Exception.Message -notlike "*$Expected*") { throw }
    }
}

Expect-Failure @($valid | Select-Object -First 35) 'monotonic_schedule_target_count_not_completed'
$unstable = @($valid | ForEach-Object { $_ | Select-Object * })
$unstable[12].apiserver = 'Stopped'
Expect-Failure $unstable 'monotonic_schedule_unstable_observation'
$wrongTarget = @($valid | ForEach-Object { $_ | Select-Object * })
$wrongTarget[20].target_elapsed_ms = 99999
Expect-Failure $wrongTarget 'monotonic_schedule_target_identity_mismatch'
$wrongLateness = @($valid | ForEach-Object { $_ | Select-Object * })
$wrongLateness[8].lateness_ms = 999
Expect-Failure $wrongLateness 'monotonic_schedule_lateness_mismatch'
$lateTarget = @($valid | ForEach-Object { $_ | Select-Object * })
$lateTarget[15].sample_started_elapsed_ms = $lateTarget[15].target_elapsed_ms + 5000
$lateTarget[15].sample_completed_elapsed_ms = $lateTarget[15].target_elapsed_ms + 5900
$lateTarget[15].lateness_ms = 5000
Expect-Failure $lateTarget 'monotonic_schedule_lateness_limit_exceeded'
$tooLate = @($valid | ForEach-Object { $_ | Select-Object * })
$lastIndex = $tooLate.Count - 1
$tooLate[$lastIndex].sample_started_elapsed_ms = 210100
$tooLate[$lastIndex].sample_completed_elapsed_ms = 210900
$tooLate[$lastIndex].lateness_ms = 35100
Expect-Failure $tooLate 'monotonic_schedule_completion_timeout_exceeded'

Write-Output 'monotonic_reconstruction_observation_tests=passed targets=36 window=180 cadence=5 lateness_lt_ms=5000 timeout=210 guarded_early_wake=passed fractional_boundaries=10 branch_then_ceiling=passed positive=6 negative=6 runtime=none'

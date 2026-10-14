Set-StrictMode -Version Latest

function New-MonotonicReconstructionObservationPlan {
    [CmdletBinding()]
    param(
        [int]$DurationSeconds = 180,
        [int]$CadenceSeconds = 5,
        [int]$CompletionTimeoutSeconds = 210,
        [int]$MaximumLatenessMilliseconds = 5000,
        [ValidateSet('single_delay','guarded_recheck')]
        [string]$WaitStrategy = 'single_delay'
    )
    if ($DurationSeconds -le 0 -or $CadenceSeconds -le 0 -or
        $DurationSeconds % $CadenceSeconds -ne 0) {
        throw 'monotonic_schedule_invalid_duration_or_cadence'
    }
    if ($CompletionTimeoutSeconds -le $DurationSeconds) {
        throw 'monotonic_schedule_completion_timeout_not_greater_than_window'
    }
    if ($MaximumLatenessMilliseconds -le 0 -or
        $MaximumLatenessMilliseconds -gt ($CadenceSeconds * 1000)) {
        throw 'monotonic_schedule_lateness_limit_invalid'
    }
    $count = [int]($DurationSeconds / $CadenceSeconds)
    [pscustomobject]@{
        schema_version = 1
        mode = 'monotonic_target_time'
        clock = 'System.Diagnostics.Stopwatch'
        window_semantics = 'half_open_[0,duration)'
        duration_seconds = $DurationSeconds
        cadence_seconds = $CadenceSeconds
        completion_timeout_seconds = $CompletionTimeoutSeconds
        maximum_lateness_ms_exclusive = $MaximumLatenessMilliseconds
        wait_strategy = $WaitStrategy
        target_count = $count
        target_elapsed_ms = @(0..($count - 1) | ForEach-Object { [long]($_ * $CadenceSeconds * 1000) })
    }
}

function Wait-MonotonicReconstructionTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$TargetElapsedMilliseconds,
        [Parameter(Mandatory)][scriptblock]$GetElapsedMilliseconds,
        [Parameter(Mandatory)][scriptblock]$SleepMilliseconds,
        [int]$MaximumRechecks = 1000
    )
    if ($TargetElapsedMilliseconds -lt 0) { throw 'monotonic_wait_negative_target' }
    if ($MaximumRechecks -le 0) { throw 'monotonic_wait_invalid_recheck_limit' }
    $rechecks = 0
    while ($true) {
        $elapsed = [double](& $GetElapsedMilliseconds)
        if ($elapsed -ge $TargetElapsedMilliseconds) {
            return [pscustomobject]@{
                target_elapsed_ms = $TargetElapsedMilliseconds
                reached_elapsed_ms = $elapsed
                recheck_count = $rechecks
                target_reached = $true
            }
        }
        if ($rechecks -ge $MaximumRechecks) { throw 'monotonic_wait_recheck_limit_exceeded' }
        $delayMs = Get-MonotonicReconstructionDelayMilliseconds `
            -TargetElapsedMilliseconds $TargetElapsedMilliseconds `
            -CurrentElapsedMilliseconds $elapsed
        if ($delayMs -le 0) { throw 'monotonic_wait_nonpositive_delay_before_target' }
        & $SleepMilliseconds $delayMs
        $rechecks++
    }
}

function Get-MonotonicReconstructionDelayMilliseconds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$TargetElapsedMilliseconds,
        [Parameter(Mandatory)][double]$CurrentElapsedMilliseconds
    )
    [int][Math]::Ceiling([Math]::Max(0, $TargetElapsedMilliseconds - $CurrentElapsedMilliseconds))
}

function Assert-MonotonicReconstructionObservations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Plan,
        [Parameter(Mandatory)][object[]]$Observations
    )
    if (@($Plan.target_elapsed_ms).Count -ne [int]$Plan.target_count) {
        throw 'monotonic_schedule_plan_target_count_mismatch'
    }
    for ($index = 0; $index -lt [int]$Plan.target_count; $index++) {
        if ([long]$Plan.target_elapsed_ms[$index] -ne [long]($index * [int]$Plan.cadence_seconds * 1000)) {
            throw 'monotonic_schedule_plan_target_sequence_mismatch'
        }
    }
    foreach ($observation in $Observations) {
        if ([double]$observation.sample_completed_elapsed_ms -gt
            ([int]$Plan.completion_timeout_seconds * 1000)) {
            throw 'monotonic_schedule_completion_timeout_exceeded'
        }
    }
    if ($Observations.Count -ne [int]$Plan.target_count) {
        throw 'monotonic_schedule_target_count_not_completed'
    }
    for ($index = 0; $index -lt $Observations.Count; $index++) {
        $observation = $Observations[$index]
        if ([int]$observation.target_index -ne $index -or
            [long]$observation.target_elapsed_ms -ne [long]$Plan.target_elapsed_ms[$index]) {
            throw 'monotonic_schedule_target_identity_mismatch'
        }
        if ([double]$observation.sample_started_elapsed_ms -lt [long]$observation.target_elapsed_ms) {
            throw 'monotonic_schedule_sample_started_before_target'
        }
        if ([double]$observation.sample_completed_elapsed_ms -lt [double]$observation.sample_started_elapsed_ms) {
            throw 'monotonic_schedule_sample_completion_invalid'
        }
        $expectedLateness = [Math]::Max(
            0,
            [double]$observation.sample_started_elapsed_ms - [long]$observation.target_elapsed_ms
        )
        if ([Math]::Abs([double]$observation.lateness_ms - $expectedLateness) -gt 0.01) {
            throw 'monotonic_schedule_lateness_mismatch'
        }
        if ($expectedLateness -ge [int]$Plan.maximum_lateness_ms_exclusive) {
            throw 'monotonic_schedule_lateness_limit_exceeded'
        }
        if ([int]$observation.exit_code -ne 0 -or $observation.host -ne 'Running' -or
            $observation.kubelet -ne 'Running' -or $observation.apiserver -ne 'Running' -or
            $observation.kubeconfig -ne 'Configured') {
            throw 'monotonic_schedule_unstable_observation'
        }
    }
    $last = $Observations[$Observations.Count - 1]
    [pscustomobject]@{
        target_count = [int]$Plan.target_count
        completed_count = $Observations.Count
        stable_count = $Observations.Count
        maximum_lateness_ms = [double](($Observations | Measure-Object lateness_ms -Maximum).Maximum)
        completed_elapsed_ms = [double]$last.sample_completed_elapsed_ms
    }
}

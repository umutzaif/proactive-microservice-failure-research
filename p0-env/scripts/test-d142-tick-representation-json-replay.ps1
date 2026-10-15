[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')

function Expect-Failure([object]$Fixture, [string]$Expected) {
    try {
        Assert-MonotonicReconstructionTickObservations `
            -Plan $Fixture.schedule -Observations @($Fixture.observations) | Out-Null
        throw "expected_d142_failure_missing:$Expected"
    }
    catch {
        if ($_.Exception.Message -notlike "*$Expected*") { throw }
    }
}

function Copy-Fixture([object]$Value) {
    $Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json
}

$frequency = [long]10000000
$plan = New-MonotonicReconstructionTickPlan -StopwatchFrequency $frequency
$observations = @()
for ($index = 0; $index -lt [int]$plan.target_count; $index++) {
    $targetMilliseconds = [long]$plan.target_elapsed_ms[$index]
    $targetTicks = [long]($targetMilliseconds * 10000)
    $latenessTicks = if ($index -eq ([int]$plan.target_count - 1)) {
        [long]49999999
    }
    else {
        [long]1001250
    }
    $startedTicks = [long]($targetTicks + $latenessTicks)
    $completedTicks = [long]($startedTicks + 625)
    $observations += ,[ordered]@{
        target_index = $index
        target_elapsed_ms = $targetMilliseconds
        stopwatch_frequency_hz = $frequency
        sample_started_ticks = $startedTicks
        sample_completed_ticks = $completedTicks
        sample_started_elapsed_ms_display = Convert-StopwatchTicksToDisplayMilliseconds `
            -ElapsedTicks $startedTicks -StopwatchFrequency $frequency
        sample_completed_elapsed_ms_display = Convert-StopwatchTicksToDisplayMilliseconds `
            -ElapsedTicks $completedTicks -StopwatchFrequency $frequency
        wait_strategy = 'guarded_tick_rational_ceiling'
        wait_guard_satisfied = $true
        wait_recheck_count = 1
        exit_code = 0
        host = 'Running'
        kubelet = 'Running'
        apiserver = 'Running'
        kubeconfig = 'Configured'
    }
}

$fixture = [ordered]@{
    schema_version = 3
    schedule = $plan
    observations = $observations
}
$replayed = Copy-Fixture $fixture
$summary = Assert-MonotonicReconstructionTickObservations `
    -Plan $replayed.schedule -Observations @($replayed.observations)
if ([long]$summary.maximum_lateness_numerator -ne [long]49999999000 -or
    [long]$summary.stopwatch_frequency_hz -ne $frequency -or
    [string]$summary.maximum_lateness_ms_display -ne '4999.9999' -or
    [bool]$summary.display_values_authoritative) {
    throw 'd142_json_replay_summary_invalid'
}

$early = Copy-Fixture $fixture
$early.observations[7].sample_started_ticks = [long]($early.observations[7].target_elapsed_ms * 10000 - 1)
Expect-Failure $early 'monotonic_tick_sample_started_before_target'

$atLimit = Copy-Fixture $fixture
$atLimit.observations[8].sample_started_ticks = [long]($atLimit.observations[8].target_elapsed_ms * 10000 + 50000000)
$atLimit.observations[8].sample_completed_ticks = [long]($atLimit.observations[8].sample_started_ticks + 625)
Expect-Failure $atLimit 'monotonic_tick_lateness_limit_exceeded'

$lateCompletion = Copy-Fixture $fixture
$lateCompletion.observations[-1].sample_completed_ticks = [long](210 * $frequency + 1)
Expect-Failure $lateCompletion 'monotonic_tick_completion_timeout_exceeded'

$frequencyMismatch = Copy-Fixture $fixture
$frequencyMismatch.observations[9].stopwatch_frequency_hz = [long]9999999
Expect-Failure $frequencyMismatch 'monotonic_tick_frequency_mismatch'

$unsafeInteger = Copy-Fixture $fixture
$unsafeInteger.observations[10].sample_started_ticks = [uint64]9007199254740992
Expect-Failure $unsafeInteger 'monotonic_tick_json_safe_integer_exceeded'

$floatingInteger = Copy-Fixture $fixture
$floatingInteger.observations[11].sample_started_ticks = [double]$floatingInteger.observations[11].sample_started_ticks
Expect-Failure $floatingInteger 'monotonic_tick_json_integer_required'

$floatingExitCode = Copy-Fixture $fixture
$floatingExitCode.observations[12].exit_code = [double]0.0
Expect-Failure $floatingExitCode 'monotonic_tick_json_integer_required'

$changedFrozenPlan = Copy-Fixture $fixture
$changedFrozenPlan.schedule.completion_timeout_seconds = [long]211
Expect-Failure $changedFrozenPlan 'monotonic_tick_frozen_plan_mismatch'

$overflowPlan = Copy-Fixture $fixture
$overflowPlan.schedule.stopwatch_frequency_hz = [long]9007199254740991
Expect-Failure $overflowPlan 'monotonic_tick_int64_overflow'

Write-Output (
    'd142_tick_representation_json_replay=passed targets=36 no_early=true ' +
    'lateness_lt_5000=true completion_lte_210=true frequency_bound=true ' +
    'json_safe_integer=true int64_overflow=fail_closed display_authoritative=false ' +
    "runtime=$($PSVersionTable.PSEdition) successor=none d067=3/6"
)

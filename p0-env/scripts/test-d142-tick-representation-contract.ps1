[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

function Expect-Failure([scriptblock]$Action, [string]$Expected) {
    try {
        & $Action
        throw "expected_d142_failure_missing:$Expected"
    }
    catch {
        if ($_.Exception.Message -notlike "*$Expected*") { throw }
    }
}

$seal = 'f02c370c2a4582b995c47871ac42f8ce696f05cab6ca15ec1bdd1f794f4abaf7'
foreach ($relative in @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-142','ElapsedTicks','Stopwatch.Frequency',$seal,'3/6','replacement slot')) {
        if ($text -notlike "*$term*") { throw "d142_canonical_term_missing:$relative`:$term" }
    }
}

$helperText = Get-Content -LiteralPath (
    Join-Path $repo 'p0-env/scripts/monotonic-reconstruction-observation.ps1'
) -Raw
foreach ($term in @(
    'New-MonotonicReconstructionTickPlan',
    'Wait-MonotonicReconstructionTargetTicks',
    'Assert-MonotonicReconstructionTickObservations',
    '[Math]::DivRem',
    'elapsed_ticks_with_recorded_frequency',
    'json_safe_int64'
)) {
    if (-not $helperText.Contains($term)) { throw "d142_helper_term_missing:$term" }
}
$runnerText = Get-Content -LiteralPath (
    Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1'
) -Raw
if ($runnerText.Contains('Wait-MonotonicReconstructionTargetTicks') -or
    $runnerText.Contains("timing_representation='elapsed_ticks_with_recorded_frequency'")) {
    throw 'd142_tick_contract_wired_to_consumed_runner'
}

$frequency = [long]10000000
$plan = New-MonotonicReconstructionTickPlan -StopwatchFrequency $frequency
if ([int]$plan.schema_version -ne 2 -or
    $plan.timing_representation -ne 'elapsed_ticks_with_recorded_frequency' -or
    $plan.authoritative_numeric_type -ne 'json_safe_int64' -or
    [bool]$plan.display_milliseconds_authoritative -or
    [long]$plan.stopwatch_frequency_hz -ne $frequency -or
    [int]$plan.target_count -ne 36) {
    throw 'd142_tick_plan_contract_invalid'
}

$oneAndHalfMillisecondRemainder = Get-MonotonicReconstructionDelayMillisecondsFromTicks `
    -TargetElapsedMilliseconds 2 -CurrentElapsedTicks 5000 -StopwatchFrequency $frequency
if ($oneAndHalfMillisecondRemainder -ne 2) {
    throw 'd142_exact_ceiling_failed_for_half_boundary'
}
$exactMillisecondRemainder = Get-MonotonicReconstructionDelayMillisecondsFromTicks `
    -TargetElapsedMilliseconds 1 -CurrentElapsedTicks 0 -StopwatchFrequency $frequency
if ($exactMillisecondRemainder -ne 1) {
    throw 'd142_exact_ceiling_failed_for_exact_boundary'
}
$subMillisecondRemainder = Get-MonotonicReconstructionDelayMillisecondsFromTicks `
    -TargetElapsedMilliseconds 1 -CurrentElapsedTicks 9999 -StopwatchFrequency $frequency
if ($subMillisecondRemainder -ne 1) {
    throw 'd142_exact_ceiling_failed_for_submillisecond_boundary'
}
$reached = Get-MonotonicReconstructionDelayMillisecondsFromTicks `
    -TargetElapsedMilliseconds 1 -CurrentElapsedTicks 10000 -StopwatchFrequency $frequency
if ($reached -ne 0) { throw 'd142_reached_target_delay_not_zero' }

$script:tickReads = @([long]5000, [long]20000)
$script:sleeps = @()
$wait = Wait-MonotonicReconstructionTargetTicks `
    -TargetElapsedMilliseconds 2 -StopwatchFrequency $frequency `
    -GetElapsedTicks {
        $next = $script:tickReads[0]
        $script:tickReads = @($script:tickReads | Select-Object -Skip 1)
        $next
    } `
    -SleepMilliseconds { param($Milliseconds) $script:sleeps += [int]$Milliseconds }
if (-not [bool]$wait.target_reached -or [int]$wait.recheck_count -ne 1 -or
    @($script:sleeps).Count -ne 1 -or [int]$script:sleeps[0] -ne 2) {
    throw 'd142_tick_wait_recheck_invalid'
}

$safeMaximum = ConvertTo-JsonSafeInt64 `
    -Value ([uint64]9007199254740991) -FieldName 'safe_maximum'
if ($safeMaximum -ne [long]9007199254740991) { throw 'd142_json_safe_maximum_rejected' }
Expect-Failure {
    ConvertTo-JsonSafeInt64 -Value ([uint64]9007199254740992) -FieldName 'unsafe'
} 'monotonic_tick_json_safe_integer_exceeded:unsafe'
Expect-Failure {
    ConvertTo-JsonSafeInt64 -Value ([double]1.0) -FieldName 'floating'
} 'monotonic_tick_json_integer_required:floating'
Expect-Failure {
    Get-CheckedInt64Product -Left ([long]::MaxValue) -Right 2 -FieldName 'overflow'
} 'monotonic_tick_int64_overflow:overflow'
Expect-Failure {
    New-MonotonicReconstructionTickPlan -StopwatchFrequency 0
} 'monotonic_tick_frequency_invalid'

if ((Convert-StopwatchTicksToDisplayMilliseconds `
        -ElapsedTicks 49999999 -StopwatchFrequency $frequency) -ne '4999.9999') {
    throw 'd142_non_authoritative_tick_display_invalid'
}
if ((Convert-LatenessNumeratorToDisplayMilliseconds `
        -LatenessNumerator 49999999000 -StopwatchFrequency $frequency) -ne '4999.9999') {
    throw 'd142_non_authoritative_lateness_display_invalid'
}

Write-Output (
    'd142_tick_representation_contract=passed representation=elapsed_ticks_with_recorded_frequency ' +
    'integer_type=json_safe_int64 exact_ceiling=Math.DivRem overflow=fail_closed ' +
    'display_authoritative=false runtime=none successor=none d067=3/6'
)

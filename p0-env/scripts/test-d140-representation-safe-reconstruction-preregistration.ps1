[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')

$id = 'ob-k8s-clean-reconstruction-005'
$gate = 'P2-KUBERNETES-CLEAN-RECONSTRUCTION-005'
$seal = 'a81c23f18d0478908592c902c488ef73f0f5868cad3439f32e8c69adad2628f6'

foreach ($relative in @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-140',$id,$gate,$seal,'3/6','replacement slot remains null')) {
        if ($text -notlike "*$term*") { throw "d140_canonical_term_missing:$relative`:$term" }
    }
}

$runner = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1') -Raw
foreach ($term in @(
    "ReconstructionId = '$id'","`$gate = '$gate'","preregistration_decision='D-140'",
    "predecessor_decision='D-139'",$seal,
    'lateness_ms=[double]($sampleStartedMs - [double]$targetElapsedMs)',
    "sampling_contract='representation_safe_fractional_monotonic_target_time'"
)) {
    if (-not $runner.Contains($term)) { throw "d140_runner_term_missing:$term" }
}
if ($runner.Contains('lateness_ms=[double]([Math]::Max(')) {
    throw 'd140_runner_ambiguous_lateness_math_max_retained'
}

$helper = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/monotonic-reconstruction-observation.ps1') -Raw
foreach ($term in @(
    '$expectedLateness = [double]$observation.sample_started_elapsed_ms -',
    '$latenessValues = @($Observations | ForEach-Object { [double]$_.lateness_ms })',
    '($latenessValues | Measure-Object -Maximum).Maximum'
)) {
    if (-not $helper.Contains($term)) { throw "d140_helper_term_missing:$term" }
}
if ($helper.Contains('$Observations | Measure-Object lateness_ms -Maximum') -or
    $helper.Contains('$expectedLateness = [Math]::Max(')) {
    throw 'd140_representation_sensitive_summary_or_math_max_retained'
}

$plan = New-MonotonicReconstructionObservationPlan `
    -DurationSeconds 180 -CadenceSeconds 5 -CompletionTimeoutSeconds 210 `
    -MaximumLatenessMilliseconds 5000 -WaitStrategy 'guarded_branch_then_ceiling'
$ordered = @()
for ($index = 0; $index -lt $plan.target_count; $index++) {
    $target = [long]$plan.target_elapsed_ms[$index]
    $lateness = if ($index -eq ($plan.target_count - 1)) { [double]4999.875 } else { [double]100.125 }
    $ordered += ,[ordered]@{
        target_index=$index;target_elapsed_ms=$target
        sample_started_elapsed_ms=[double]($target + $lateness)
        sample_completed_elapsed_ms=[double]($target + $lateness + 0.0625)
        lateness_ms=$lateness;exit_code=0;host='Running';kubelet='Running'
        apiserver='Running';kubeconfig='Configured'
    }
}
$summary = Assert-MonotonicReconstructionObservations -Plan $plan -Observations $ordered
if ([double]$summary.maximum_lateness_ms -ne [double]4999.875 -or
    [double]$ordered[0].lateness_ms -ne [double]100.125) {
    throw 'd140_fractional_lateness_not_preserved_exactly'
}

function Expect-Failure([object[]]$Observations, [string]$Expected) {
    try {
        Assert-MonotonicReconstructionObservations -Plan $plan -Observations $Observations | Out-Null
        throw "expected_d140_failure_missing:$Expected"
    }
    catch {
        if ($_.Exception.Message -notlike "*$Expected*") { throw }
    }
}
$rounded = @($ordered | ForEach-Object { [ordered]@{} + $_ })
$rounded[7].lateness_ms = [double]100
Expect-Failure $rounded 'monotonic_schedule_lateness_mismatch'
$limit = @($ordered | ForEach-Object { [ordered]@{} + $_ })
$limit[8].sample_started_elapsed_ms = [double]($limit[8].target_elapsed_ms + 5000)
$limit[8].sample_completed_elapsed_ms = [double]($limit[8].target_elapsed_ms + 5000.0625)
$limit[8].lateness_ms = [double]5000
Expect-Failure $limit 'monotonic_schedule_lateness_limit_exceeded'

Write-Output 'd140_representation_safe_reconstruction_preregistration=passed targets=36 ordered_dictionary=true fractional_exact=true max_lateness_boundary=4999.875 limit_5000_rejected=true runtime=none d067=3/6 replacement=null'

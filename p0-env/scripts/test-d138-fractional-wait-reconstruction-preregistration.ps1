[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-004'
$documents = @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)
foreach ($relative in $documents) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-138',$id,'branch-then-ceiling','36','3/6')) {
        if ($text -notlike "*$term*") { throw "d138_preregistration_term_missing:$relative`:$term" }
    }
}

$decisionText = Get-Content -LiteralPath (Join-Path $repo 'research_decisions.md') -Raw
$match = [regex]::Match($decisionText,'(?ms)^## D-138\b.*?(?=^## D-|\z)')
if (-not $match.Success) { throw 'd138_decision_missing' }
$decision = $match.Value -replace '\s+',' '
foreach ($term in @(
    'branch-then-ceiling','ob-k8s-clean-reconstruction-004',
    'P2-KUBERNETES-CLEAN-RECONSTRUCTION-004','0, 5, 10, ..., 175',
    '36/36 stable','5,000 ms','210-second',
    'runtime, backup creation and profile deletion remain unauthorized',
    'fresh separate execution and destructive reset approval','replacement slot remains null'
)) {
    if ($decision -notlike "*$term*") { throw "d138_decision_term_missing:$term" }
}

$runner = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1') -Raw
foreach ($term in @(
    "ReconstructionId = 'ob-k8s-clean-reconstruction-004'",
    "if (`$ReconstructionId -ne 'ob-k8s-clean-reconstruction-004')",
    "preregistration_decision='D-138'","predecessor_decision='D-137'",
    '37016adf3d435362ea34484666a074c1634811c474fed49030ab91bad6169e1a',
    "-WaitStrategy 'guarded_branch_then_ceiling'",'Wait-MonotonicReconstructionTarget',
    "sampling_contract='guarded_fractional_monotonic_target_time'"
)) {
    if (-not $runner.Contains($term)) { throw "d138_runner_term_missing:$term" }
}
if ($runner -match "ReconstructionId = 'ob-k8s-clean-reconstruction-003'") {
    throw 'd138_runner_reuses_consumed_003'
}

$helper = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/monotonic-reconstruction-observation.ps1') -Raw
foreach ($term in @(
    '$remainingMilliseconds = [double]$TargetElapsedMilliseconds - $CurrentElapsedMilliseconds',
    'if ($remainingMilliseconds -le 0) { return 0 }',
    '[int][Math]::Ceiling($remainingMilliseconds)'
)) {
    if (-not $helper.Contains($term)) { throw "d138_helper_term_missing:$term" }
}
if ($helper.Contains('[Math]::Max(0, $TargetElapsedMilliseconds - $CurrentElapsedMilliseconds)')) {
    throw 'd138_ambiguous_math_max_overload_retained'
}

$registry = Get-Content -LiteralPath (Join-Path $repo 'results_registry.md') -Raw
$row = [regex]::Match($registry,'(?m)^\|[^\r\n]*' + [regex]::Escape($id) + '[^\r\n]*$')
if (-not $row.Success) { throw 'd138_registry_row_missing' }
foreach ($term in @(
    'invalid/incomplete operational reconstruction','D-139 closure',
    'ordered-record','ID consumed/closed'
)) {
    if ($row.Value -notlike "*$term*") { throw "d138_registry_term_missing:$term" }
}

Write-Output 'd138_fractional_wait_reconstruction_preregistration=passed targets=36 fractional_boundaries=10 branch_then_ceiling=true closure=invalid_incomplete id_consumed=true d067=3/6'

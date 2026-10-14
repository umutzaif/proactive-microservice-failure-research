[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-002'
$documents = @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)
foreach ($relative in $documents) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-134',$id,'36','180','3/6')) {
        if ($text -notlike "*$term*") { throw "d134_preregistration_term_missing:$relative`:$term" }
    }
}

$decisionText = Get-Content -LiteralPath (Join-Path $repo 'research_decisions.md') -Raw
$match = [regex]::Match($decisionText,'(?ms)^## D-134\b.*?(?=^## D-|\z)')
if (-not $match.Success) { throw 'd134_decision_missing' }
$decision = $match.Value -replace '\s+',' '
foreach ($term in @(
    'monotonic target-time','0, 5, 10, ..., 175','36/36 stable','5,000 ms','210-second',
    'runtime, backup creation and profile deletion remain unauthorized','new identity',
    'fresh separate execution and destructive reset approval','replacement slot remains null'
)) {
    if ($decision -notlike "*$term*") { throw "d134_decision_term_missing:$term" }
}

$verifier = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/verify-kubernetes-clean-reconstruction.ps1') -Raw
foreach ($term in @(
    "'ob-k8s-clean-reconstruction-002' = [ordered]@{",
    "gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-002'",
    "preregistration_decision='D-134'","predecessor_decision='D-133'",
    'bc97ddb3ee38077de9cb2ec3f031ac78b9fb07f0a3265151de28b883b11417d9',
    "sampling_contract='monotonic_target_time'"
)) {
    if (-not $verifier.Contains($term)) { throw "d134_historical_verifier_term_missing:$term" }
}
$registry = Get-Content -LiteralPath (Join-Path $repo 'results_registry.md') -Raw
$registryMatch = [regex]::Match(
    $registry,
    '(?m)^\|[^\r\n]*' + [regex]::Escape($id) + '[^\r\n]*$'
)
if (-not $registryMatch.Success) { throw 'd134_registry_row_missing' }
$registryRow = $registryMatch.Value
foreach ($term in @(
    'invalid/incomplete operational reconstruction','D-135 closure',
    'monotonic_schedule_sample_started_before_target','ID consumed/closed',
    'no retry/restore/application/workload/successor/fault authority'
)) {
    if ($registryRow -notlike "*$term*") { throw "d135_registry_closure_term_missing:$term" }
}
$normalRunner = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/run-network-delay-headroom-normal.ps1') -Raw
if ($normalRunner -match [regex]::Escape($id)) { throw 'd134_identity_leaked_into_normal_runner' }

Write-Output 'd134_monotonic_reconstruction_preregistration=passed targets=36 window=180 cadence=5 lateness_lt_ms=5000 timeout=210 closure=invalid_incomplete id_consumed=true retry=false successor=none d067=3/6'

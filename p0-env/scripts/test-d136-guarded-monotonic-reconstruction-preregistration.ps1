[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-003'
$documents = @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)
foreach ($relative in $documents) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-136',$id,'guarded','36','3/6')) {
        if ($text -notlike "*$term*") { throw "d136_preregistration_term_missing:$relative`:$term" }
    }
}

$decisionText = Get-Content -LiteralPath (Join-Path $repo 'research_decisions.md') -Raw
$match = [regex]::Match($decisionText,'(?ms)^## D-136\b.*?(?=^## D-|\z)')
if (-not $match.Success) { throw 'd136_decision_missing' }
$decision = $match.Value -replace '\s+',' '
foreach ($term in @(
    'guarded monotonic','ob-k8s-clean-reconstruction-003','P2-KUBERNETES-CLEAN-RECONSTRUCTION-003',
    '0, 5, 10, ..., 175','36/36 stable','5,000 ms','210-second',
    'runtime, backup creation and profile deletion remain unauthorized',
    'fresh separate execution and destructive reset approval','replacement slot remains null'
)) {
    if ($decision -notlike "*$term*") { throw "d136_decision_term_missing:$term" }
}

$runner = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1') -Raw
foreach ($term in @(
    "ReconstructionId = 'ob-k8s-clean-reconstruction-003'",
    "if (`$ReconstructionId -ne 'ob-k8s-clean-reconstruction-003')",
    "preregistration_decision='D-136'","predecessor_decision='D-135'",
    '9a4b1cf5f854051656bef5e101137982a2ddc06862223d8a6010d5657d75c67e',
    "-WaitStrategy 'guarded_recheck'",'Wait-MonotonicReconstructionTarget',
    "sampling_contract='guarded_monotonic_target_time'"
)) {
    if (-not $runner.Contains($term)) { throw "d136_runner_term_missing:$term" }
}
if ($runner -match "ReconstructionId = 'ob-k8s-clean-reconstruction-002'") {
    throw 'd136_runner_reuses_consumed_002'
}
$attributes = Get-Content -LiteralPath (Join-Path $repo '.gitattributes') -Raw
foreach ($gate in @(
    'P2-KUBERNETES-CLEAN-RECONSTRUCTION-001',
    'P2-KUBERNETES-CLEAN-RECONSTRUCTION-002',
    'P2-KUBERNETES-CLEAN-RECONSTRUCTION-003'
)) {
    if ($attributes -notmatch ([regex]::Escape($gate) + '/\*\* text eol=crlf')) {
        throw "d136_byte_preservation_attribute_missing:$gate"
    }
}
foreach ($stream in @('minikube-start.stdout.txt','minikube-start.stderr.txt','offline-verification.txt')) {
    if ($attributes -notmatch ([regex]::Escape($stream) + ' text eol=lf')) {
        throw "d136_lf_stream_attribute_missing:$stream"
    }
}
$sealVerifier = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/seal-diagnostic-artifacts.ps1') -Raw
if (-not $sealVerifier.Contains('throw "sealed_hash_mismatch:')) {
    throw 'd136_explicit_seal_hash_error_missing'
}

$registry = Get-Content -LiteralPath (Join-Path $repo 'results_registry.md') -Raw
$row = [regex]::Match($registry,'(?m)^\|[^\r\n]*' + [regex]::Escape($id) + '[^\r\n]*$')
if (-not $row.Success) { throw 'd136_registry_row_missing' }
foreach ($term in @(
    'invalid/incomplete operational reconstruction','D-137 closure',
    'monotonic_wait_nonpositive_delay_before_target','ID consumed/closed'
)) {
    if ($row.Value -notlike "*$term*") { throw "d136_registry_term_missing:$term" }
}

Write-Output 'd136_guarded_monotonic_reconstruction_preregistration=passed targets=36 window=180 cadence=5 lateness_lt_ms=5000 timeout=210 closure=invalid_incomplete id_consumed=true d067=3/6'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-006'
$gate = 'P2-KUBERNETES-CLEAN-RECONSTRUCTION-006'
$seal = 'f02c370c2a4582b995c47871ac42f8ce696f05cab6ca15ec1bdd1f794f4abaf7'

foreach ($relative in @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-143',$id,$gate,'D-141','D-142',$seal,'3/6')) {
        if ($text -notlike "*$term*") { throw "d143_canonical_term_missing:$relative`:$term" }
    }
}

$runner = Get-Content -LiteralPath (
    Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1'
) -Raw
foreach ($term in @(
    "ReconstructionId = '$id'", "`$gate = '$gate'", 'closed_reconstruction_id',
    "preregistration_decision='D-143'", "representation_decision='D-142'",
    "predecessor_decision='D-141'", $seal,
    'New-MonotonicReconstructionTickPlan', 'Wait-MonotonicReconstructionTargetTicks',
    'Assert-MonotonicReconstructionTickObservations',
    "sampling_contract='portable_integer_tick_monotonic_target_time'",
    'schema_version=3', 'maximum_lateness_numerator', 'display_values_authoritative=$false'
)) {
    if (-not $runner.Contains($term)) { throw "d143_runner_term_missing:$term" }
}
foreach ($consumed in 1..5 | ForEach-Object { 'ob-k8s-clean-reconstruction-{0:d3}' -f $_ }) {
    if (-not $runner.Contains("'$consumed'")) { throw "d143_closed_identity_missing:$consumed" }
    if ($runner.Contains("ReconstructionId = '$consumed'")) {
        throw "d143_runner_reuses_consumed_identity:$consumed"
    }
}
$closedGate = $runner.IndexOf("throw 'closed_reconstruction_id'")
$activeGate = $runner.IndexOf("throw 'unexpected_reconstruction_id'")
$revisionGate = $runner.IndexOf("throw 'expected_code_revision_mismatch'")
if ($closedGate -lt 0 -or $activeGate -le $closedGate -or $revisionGate -le $activeGate) {
    throw 'd143_identity_gate_order_invalid'
}

$verifier = Get-Content -LiteralPath (
    Join-Path $repo 'p0-env/scripts/verify-kubernetes-clean-reconstruction.ps1'
) -Raw
foreach ($term in @(
    "'$id' = [ordered]@{", "gate_id='$gate'", "preregistration_decision='D-143'",
    "predecessor_decision='D-141'", "representation_decision='D-142'", $seal,
    "sampling_contract='portable_integer_tick_monotonic_target_time'",
    'observation_schema_version=3', 'Assert-MonotonicReconstructionTickObservations',
    'monotonic_tick_reconstruction_assessment_mismatch'
)) {
    if (-not $verifier.Contains($term)) { throw "d143_verifier_term_missing:$term" }
}

foreach ($forbidden in @('apply -k','rollout restart','toxic add','run-loadgenerator')) {
    if ($runner.Contains($forbidden)) { throw "d143_forbidden_path:$forbidden" }
}

Write-Output (
    'd143_tick_reconstruction_preregistration=passed identity=006 predecessor=D-141 ' +
    'representation=D-142 targets=36 thresholds=frozen closed_ids=001-005 ' +
    'runtime_authorized=false delete_authorized=false d067=3/6'
)

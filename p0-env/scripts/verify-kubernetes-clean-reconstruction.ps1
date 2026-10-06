[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArtifactRoot,
    [string]$ExpectedReconstructionId = 'ob-k8s-clean-reconstruction-001'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
function Read-Json([string]$Name) {
    Get-Content -LiteralPath (Join-Path $ArtifactRoot $Name) -Raw | ConvertFrom-Json
}

$resolved = (Resolve-Path -LiteralPath $ArtifactRoot).Path
if ((Split-Path -Leaf $resolved) -ne $ExpectedReconstructionId) {
    throw 'artifact_root_reconstruction_id_mismatch'
}
$manifest = Read-Json 'reconstruction-manifest.json'
$assessment = Read-Json 'assessment.json'
$hostAfter = Read-Json 'host-after.json'
$finalStatus = Read-Json 'final-profile-status-capture.json'

if ($manifest.gate_id -ne 'P2-KUBERNETES-CLEAN-RECONSTRUCTION-001' -or
    $manifest.reconstruction_id -ne $ExpectedReconstructionId -or
    $manifest.preregistration_decision -ne 'D-131' -or
    $manifest.predecessor_decision -ne 'D-130' -or
    $manifest.predecessor_manifest_sha256 -ne '85118c5235cfb3f14d4b52fa90bc17f068c3e258be259ff496e286fa911b0db7' -or
    -not $manifest.runtime_state_root -or -not $manifest.backup_root) {
    throw 'reconstruction_identity_mismatch'
}
if (-not [bool]$manifest.backup_contains_sensitive_runtime_credentials -or
    -not [bool]$manifest.backup_must_remain_outside_repository) {
    throw 'backup_sensitivity_boundary_missing'
}
foreach ($field in @(
    'application_manifest_applied','workload_started','toxic_created','scientific_fault_started',
    'scientific_window_started','dataset_inclusion','headroom_decision_inclusion',
    'successor_authorized'
)) {
    if ([bool]$manifest.$field) { throw "reconstruction_scope_mismatch:$field" }
}
if ([bool]$assessment.causal_conclusion -or [bool]$assessment.repair_cause_proven -or
    [bool]$assessment.successor_authorized -or [bool]$assessment.dataset_inclusion -or
    [bool]$assessment.headroom_decision_inclusion) { throw 'assessment_authority_leak' }
if (-not [bool]$hostAfter.passed -or [int]$hostAfter.counts.whea_event_17 -ne 0 -or
    [int]$hostAfter.counts.kernel_power_41 -ne 0 -or [int]$hostAfter.counts.bugcheck -ne 0) {
    throw 'reconstruction_host_closure_failed'
}

$statusPayload = $finalStatus.stdout | ConvertFrom-Json
foreach ($property in @('Host','Kubelet','APIServer','Kubeconfig')) {
    if ([string]$statusPayload.$property -ne 'Stopped') { throw "final_profile_not_stopped:$property" }
}

if ($assessment.classification -eq 'fresh_kubernetes_reconstruction_supported') {
    $backup = Read-Json 'backup-verification.json'
    $delete = Read-Json 'delete-verification.json'
    $observations = Read-Json 'bootstrap-observations.json'
    if (-not [bool]$backup.passed -or -not [bool]$delete.passed -or
        [bool]$delete.container_exists -or [bool]$delete.volume_exists) {
        throw 'reconstruction_backup_or_delete_gate_failed'
    }
    if ([int]$observations.duration_seconds -ne 180 -or [int]$observations.poll_seconds -ne 5 -or
        @($observations.observations).Count -lt 30 -or
        [int]$assessment.sample_count -ne [int]$assessment.stable_sample_count) {
        throw 'reconstruction_stability_contract_failed'
    }
}
elseif ($assessment.classification -ne 'reconstruction_incomplete') {
    throw 'unexpected_reconstruction_classification'
}

Write-Output (
    "kubernetes_clean_reconstruction_verification=passed id=$ExpectedReconstructionId " +
    "classification=$($assessment.classification)"
)

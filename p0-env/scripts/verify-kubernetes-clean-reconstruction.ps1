[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArtifactRoot,
    [string]$ExpectedReconstructionId = 'ob-k8s-clean-reconstruction-001'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')
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

$contracts = @{
    'ob-k8s-clean-reconstruction-001' = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-001'
        preregistration_decision='D-131';predecessor_decision='D-130'
        predecessor_manifest_sha256='85118c5235cfb3f14d4b52fa90bc17f068c3e258be259ff496e286fa911b0db7'
        sampling_contract='legacy_180_5_minimum_30'
    }
    'ob-k8s-clean-reconstruction-002' = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-002'
        preregistration_decision='D-134';predecessor_decision='D-133'
        predecessor_manifest_sha256='bc97ddb3ee38077de9cb2ec3f031ac78b9fb07f0a3265151de28b883b11417d9'
        sampling_contract='monotonic_target_time'
    }
    'ob-k8s-clean-reconstruction-003' = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-003'
        preregistration_decision='D-136';predecessor_decision='D-135'
        predecessor_manifest_sha256='9a4b1cf5f854051656bef5e101137982a2ddc06862223d8a6010d5657d75c67e'
        sampling_contract='guarded_monotonic_target_time'
        wait_strategy='guarded_recheck'
    }
    'ob-k8s-clean-reconstruction-004' = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-004'
        preregistration_decision='D-138';predecessor_decision='D-137'
        predecessor_manifest_sha256='37016adf3d435362ea34484666a074c1634811c474fed49030ab91bad6169e1a'
        sampling_contract='guarded_fractional_monotonic_target_time'
        wait_strategy='guarded_branch_then_ceiling'
    }
}
if (-not $contracts.ContainsKey($ExpectedReconstructionId)) {
    throw 'unsupported_reconstruction_identity'
}
$contract = $contracts[$ExpectedReconstructionId]

if ($manifest.gate_id -ne $contract.gate_id -or
    $manifest.reconstruction_id -ne $ExpectedReconstructionId -or
    $manifest.preregistration_decision -ne $contract.preregistration_decision -or
    $manifest.predecessor_decision -ne $contract.predecessor_decision -or
    $manifest.predecessor_manifest_sha256 -ne $contract.predecessor_manifest_sha256 -or
    -not $manifest.runtime_state_root -or -not $manifest.backup_root) {
    throw 'reconstruction_identity_mismatch'
}
if (-not [bool]$manifest.backup_contains_sensitive_runtime_credentials -or
    -not [bool]$manifest.backup_must_remain_outside_repository) {
    throw 'backup_sensitivity_boundary_missing'
}
if (-not [bool]$manifest.backup_acl_verified -or
    -not [bool]$manifest.backup_acl_inheritance_protected -or
    [int]$manifest.backup_acl_rule_count -ne 3 -or
    ((@($manifest.backup_acl_allowed_principals) | Sort-Object) -join ',') -ne
        ((@('current_user','SYSTEM','Administrators') | Sort-Object) -join ',')) {
    throw 'backup_acl_evidence_boundary_missing'
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
    if ($contract.sampling_contract -eq 'legacy_180_5_minimum_30') {
        if ([int]$observations.duration_seconds -ne 180 -or [int]$observations.poll_seconds -ne 5 -or
            @($observations.observations).Count -lt 30 -or
            [int]$assessment.sample_count -ne [int]$assessment.stable_sample_count) {
            throw 'reconstruction_stability_contract_failed'
        }
    }
    else {
        if ([int]$observations.schema_version -ne 2 -or
            $observations.schedule.mode -ne 'monotonic_target_time' -or
            $observations.schedule.clock -ne 'System.Diagnostics.Stopwatch' -or
            $observations.schedule.window_semantics -ne 'half_open_[0,duration)' -or
            [int]$observations.schedule.duration_seconds -ne 180 -or
            [int]$observations.schedule.cadence_seconds -ne 5 -or
            [int]$observations.schedule.completion_timeout_seconds -ne 210 -or
            [int]$observations.schedule.maximum_lateness_ms_exclusive -ne 5000 -or
            [int]$observations.schedule.target_count -ne 36 -or
            $assessment.sampling_contract -ne $contract.sampling_contract) {
            throw 'monotonic_reconstruction_contract_mismatch'
        }
        if ($contract.Contains('wait_strategy')) {
            if ($observations.schedule.wait_strategy -ne $contract.wait_strategy) {
                throw 'guarded_monotonic_wait_strategy_missing'
            }
            foreach ($observation in @($observations.observations)) {
                if ($observation.wait_strategy -ne $contract.wait_strategy -or
                    -not [bool]$observation.wait_guard_satisfied -or
                    [int]$observation.wait_recheck_count -lt 0) {
                    throw 'guarded_monotonic_observation_evidence_missing'
                }
            }
        }
        $scheduleAssessment = Assert-MonotonicReconstructionObservations `
            -Plan $observations.schedule -Observations @($observations.observations)
        if ([int]$assessment.target_count -ne [int]$scheduleAssessment.target_count -or
            [int]$assessment.sample_count -ne [int]$scheduleAssessment.completed_count -or
            [int]$assessment.stable_sample_count -ne [int]$scheduleAssessment.stable_count) {
            throw 'monotonic_reconstruction_assessment_mismatch'
        }
    }
}
elseif ($assessment.classification -ne 'reconstruction_incomplete') {
    throw 'unexpected_reconstruction_classification'
}

Write-Output (
    "kubernetes_clean_reconstruction_verification=passed id=$ExpectedReconstructionId " +
    "classification=$($assessment.classification)"
)

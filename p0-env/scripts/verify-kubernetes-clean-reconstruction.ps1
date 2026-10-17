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
    'ob-k8s-clean-reconstruction-005' = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-005'
        preregistration_decision='D-140';predecessor_decision='D-139'
        predecessor_manifest_sha256='a81c23f18d0478908592c902c488ef73f0f5868cad3439f32e8c69adad2628f6'
        sampling_contract='representation_safe_fractional_monotonic_target_time'
        wait_strategy='guarded_branch_then_ceiling'
        representation_safe_lateness=$true
    }
    'ob-k8s-clean-reconstruction-006' = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-006'
        preregistration_decision='D-143';predecessor_decision='D-141'
        predecessor_manifest_sha256='f02c370c2a4582b995c47871ac42f8ce696f05cab6ca15ec1bdd1f794f4abaf7'
        representation_decision='D-142'
        manifest_schema_version=2;observation_schema_version=3;assessment_schema_version=2
        sampling_contract='portable_integer_tick_monotonic_target_time'
        wait_strategy='guarded_tick_rational_ceiling'
        tick_representation=$true
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
if ($contract.Contains('manifest_schema_version')) {
    $manifestSchema = ConvertTo-JsonSafeInt64 `
        -Value $manifest.schema_version -FieldName 'manifest.schema_version'
    if ($manifestSchema -ne [long]$contract.manifest_schema_version -or
        $manifest.representation_decision -ne $contract.representation_decision) {
        throw 'reconstruction_representation_identity_mismatch'
    }
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
        $expectedObservationSchema = if ($contract.Contains('observation_schema_version')) {
            [int]$contract.observation_schema_version
        }
        else { 2 }
        $observationSchema = if ($contract.Contains('tick_representation') -and
            [bool]$contract.tick_representation) {
            ConvertTo-JsonSafeInt64 `
                -Value $observations.schema_version -FieldName 'observations.schema_version'
        }
        else { [int]$observations.schema_version }
        if ($observationSchema -ne $expectedObservationSchema -or
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
        if ($contract.Contains('tick_representation') -and [bool]$contract.tick_representation) {
            $assessmentSchema = ConvertTo-JsonSafeInt64 `
                -Value $assessment.schema_version -FieldName 'assessment.schema_version'
            if ($assessmentSchema -ne [long]$contract.assessment_schema_version -or
                $observations.schedule.timing_representation -ne 'elapsed_ticks_with_recorded_frequency' -or
                $observations.schedule.authoritative_numeric_type -ne 'json_safe_int64' -or
                [bool]$observations.schedule.display_milliseconds_authoritative) {
                throw 'monotonic_tick_reconstruction_contract_mismatch'
            }
            $scheduleAssessment = Assert-MonotonicReconstructionTickObservations `
                -Plan $observations.schedule -Observations @($observations.observations)
        }
        else {
            $scheduleAssessment = Assert-MonotonicReconstructionObservations `
                -Plan $observations.schedule -Observations @($observations.observations)
        }
        if ($contract.Contains('tick_representation') -and [bool]$contract.tick_representation) {
            $assessmentTargetCount = ConvertTo-JsonSafeInt64 `
                -Value $assessment.target_count -FieldName 'assessment.target_count'
            $assessmentSampleCount = ConvertTo-JsonSafeInt64 `
                -Value $assessment.sample_count -FieldName 'assessment.sample_count'
            $assessmentStableCount = ConvertTo-JsonSafeInt64 `
                -Value $assessment.stable_sample_count -FieldName 'assessment.stable_sample_count'
        }
        else {
            $assessmentTargetCount = [int]$assessment.target_count
            $assessmentSampleCount = [int]$assessment.sample_count
            $assessmentStableCount = [int]$assessment.stable_sample_count
        }
        if ($assessmentTargetCount -ne [int]$scheduleAssessment.target_count -or
            $assessmentSampleCount -ne [int]$scheduleAssessment.completed_count -or
            $assessmentStableCount -ne [int]$scheduleAssessment.stable_count) {
            throw 'monotonic_reconstruction_assessment_mismatch'
        }
        if ($contract.Contains('tick_representation') -and [bool]$contract.tick_representation) {
            $assessmentFrequency = ConvertTo-JsonSafeInt64 `
                -Value $assessment.stopwatch_frequency_hz -FieldName 'assessment.stopwatch_frequency_hz'
            $assessmentMaximumNumerator = ConvertTo-JsonSafeInt64 `
                -Value $assessment.maximum_lateness_numerator `
                -FieldName 'assessment.maximum_lateness_numerator'
            $assessmentCompletedTicks = ConvertTo-JsonSafeInt64 `
                -Value $assessment.completed_elapsed_ticks -FieldName 'assessment.completed_elapsed_ticks'
            if ($assessmentFrequency -ne [long]$scheduleAssessment.stopwatch_frequency_hz -or
                $assessmentMaximumNumerator -ne [long]$scheduleAssessment.maximum_lateness_numerator -or
                $assessmentCompletedTicks -ne [long]$scheduleAssessment.completed_elapsed_ticks) {
                throw 'monotonic_tick_reconstruction_assessment_mismatch'
            }
            if ([bool]$assessment.display_values_authoritative -or
                [string]$assessment.maximum_lateness_ms_display -ne
                    [string]$scheduleAssessment.maximum_lateness_ms_display -or
                [string]$assessment.completed_elapsed_ms_display -ne
                    [string]$scheduleAssessment.completed_elapsed_ms_display) {
                throw 'monotonic_tick_reconstruction_display_mismatch'
            }
        }
        if ($contract.Contains('representation_safe_lateness') -and
            [bool]$contract.representation_safe_lateness -and
            [double]$assessment.maximum_lateness_ms -ne [double]$scheduleAssessment.maximum_lateness_ms) {
            throw 'monotonic_reconstruction_lateness_assessment_mismatch'
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

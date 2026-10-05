[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArtifactRoot,
    [string]$ExpectedDiagnosticId = 'ob-k8s-lifecycle-state-diagnostic-001'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'lifecycle-state-diagnostic-contract.ps1')

function Read-EvidenceJson([string]$Name) {
    Get-Content -LiteralPath (Join-Path $ArtifactRoot $Name) -Raw | ConvertFrom-Json
}
function Require-Evidence([string]$Name) {
    if (-not (Test-Path -LiteralPath (Join-Path $ArtifactRoot $Name) -PathType Leaf)) {
        throw "lifecycle_evidence_missing:$Name"
    }
}

$resolved = (Resolve-Path -LiteralPath $ArtifactRoot).Path
$leaf = Split-Path -Leaf $resolved.TrimEnd(
    [IO.Path]::DirectorySeparatorChar,
    [IO.Path]::AltDirectorySeparatorChar
)
if ($leaf -ne $ExpectedDiagnosticId) { throw 'artifact_root_diagnostic_id_mismatch' }

foreach ($name in @(
    'diagnostic-manifest.json',
    'prestart-container-inspect.json',
    'start-process.json',
    'assessment.json',
    'stop-capture.json',
    'final-profile-status-capture.json',
    'final-container-inspect-capture.json',
    'host-after.json'
)) { Require-Evidence $name }

$manifest = Read-EvidenceJson 'diagnostic-manifest.json'
if ($manifest.diagnostic_id -ne $ExpectedDiagnosticId -or
    $manifest.gate_id -ne 'P2-KUBERNETES-LIFECYCLE-STATE-DIAG-001' -or
    $manifest.preregistration_decision -ne 'D-129' -or
    -not $manifest.runtime_state_root -or
    -not $manifest.reuses_preserved_profile -or
    $manifest.application_manifest_applied -or
    $manifest.rollout_restarted -or
    $manifest.object_mutated -or
    $manifest.finalizer_removed -or
    $manifest.profile_deleted_or_reset -or
    $manifest.docker_restarted -or
    $manifest.workload_started -or
    $manifest.scientific_fault_started -or
    $manifest.dataset_inclusion -or
    $manifest.headroom_decision_inclusion) {
    throw 'lifecycle_manifest_scope_mismatch'
}

$assessment = Read-EvidenceJson 'assessment.json'
if ($assessment.diagnostic_id -ne $ExpectedDiagnosticId -or
    $assessment.classification -notin @(
        'stale_lifecycle_state_observed',
        'lifecycle_state_not_reproduced',
        'diagnostic_incomplete'
    ) -or $assessment.causal_conclusion -or $assessment.repair_authorized -or
    $assessment.successor_authorized -or $assessment.dataset_inclusion -or
    $assessment.headroom_decision_inclusion) {
    throw 'lifecycle_assessment_scope_mismatch'
}

if ($assessment.classification -ne 'diagnostic_incomplete') {
    foreach ($name in @(
        'nodes.json',
        'deployments.json',
        'replicasets.json',
        'pods.json',
        'events.json',
        'recommendation-deployment.json',
        'controller-manager-log-capture.json'
    )) { Require-Evidence $name }
    $deploymentCapture = Read-EvidenceJson 'recommendation-deployment.json'
    $podsCapture = Read-EvidenceJson 'pods.json'
    if ([int]$deploymentCapture.exit_code -ne 0 -or [int]$podsCapture.exit_code -ne 0) {
        throw 'lifecycle_primary_capture_failed'
    }
    $deployment = $deploymentCapture.stdout | ConvertFrom-Json
    $podList = $podsCapture.stdout | ConvertFrom-Json
    $computed = Get-LifecycleStateAssessment -Deployment $deployment -Pods @($podList.items)
    if ($computed.classification -ne $assessment.classification -or
        [long]$computed.deployment_generation -ne [long]$assessment.deployment_generation -or
        [long]$computed.observed_generation -ne [long]$assessment.observed_generation -or
        [int]$computed.terminating_pod_count -ne [int]$assessment.terminating_pod_count) {
        throw 'lifecycle_assessment_replay_mismatch'
    }
}

$stop = Read-EvidenceJson 'stop-capture.json'
if ([int]$stop.exit_code -ne 0) { throw 'profile_stop_failed' }
$finalProfile = Read-EvidenceJson 'final-profile-status-capture.json'
if ([string]::IsNullOrWhiteSpace([string]$finalProfile.stdout)) {
    throw 'final_profile_status_missing'
}
$finalProfileObject = $finalProfile.stdout | ConvertFrom-Json
foreach ($property in @('Host', 'Kubelet', 'APIServer', 'Kubeconfig')) {
    if ([string]$finalProfileObject.$property -ne 'Stopped') {
        throw "final_profile_component_not_stopped:$property"
    }
}
$finalInspect = Read-EvidenceJson 'final-container-inspect-capture.json'
if ([int]$finalInspect.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace([string]$finalInspect.stdout)) {
    throw 'final_container_inspect_failed'
}
$inspectItems = @($finalInspect.stdout | ConvertFrom-Json)
if ($inspectItems.Count -ne 1 -or [bool]$inspectItems[0].State.Running) {
    throw 'profile_container_not_stopped_after_diagnostic'
}
$hostEvidence = Read-EvidenceJson 'host-after.json'
if (-not $hostEvidence.passed -or [int]$hostEvidence.counts.whea_event_17 -ne 0 -or
    [int]$hostEvidence.counts.kernel_power_41 -ne 0 -or [int]$hostEvidence.counts.bugcheck -ne 0) {
    throw 'host_health_gate_failed'
}

Write-Output (
    "kubernetes_lifecycle_state_diagnostic_verification=passed " +
    "id=$ExpectedDiagnosticId classification=$($assessment.classification)"
)

[CmdletBinding()]
param([Parameter(Mandatory)][string]$ArtifactRoot,[string]$ExpectedDiagnosticId='ob-k8s-bootstrap-001')
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function ReadJson([string]$Name){Get-Content -LiteralPath(Join-Path $ArtifactRoot $Name)-Raw|ConvertFrom-Json}
$leaf=Split-Path -Leaf $ArtifactRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
if($leaf-ne$ExpectedDiagnosticId){throw 'artifact_root_diagnostic_id_mismatch'}
$m=ReadJson 'diagnostic-manifest.json'
if($m.diagnostic_id-ne$ExpectedDiagnosticId-or$m.gate_id-ne'P2-KUBERNETES-BOOTSTRAP-DIAG-001'){throw 'diagnostic_identity_mismatch'}
if($m.driver-ne'docker'-or$m.kubernetes_version-ne'v1.34.0'-or[int]$m.cpus-ne4-or[int]$m.memory_mib-ne6144-or[int]$m.disk_gib-ne32-or$m.container_runtime-ne'containerd'){throw 'bootstrap_contract_mismatch'}
if($m.application_manifest_applied-ne$false-or$m.workload_started-ne$false-or$m.toxic_created-ne$false-or$m.scientific_fault_started-ne$false-or$m.scientific_window_started-ne$false-or$m.dataset_inclusion-ne$false-or$m.headroom_decision_inclusion-ne$false){throw 'diagnostic_scope_mismatch'}
$delete=ReadJson 'delete-verification.json';if(-not$delete.passed-or$delete.container_exists-or$delete.volume_exists){throw 'stale_profile_delete_not_verified'}
$obs=ReadJson 'bootstrap-observations.json';if([int]$obs.duration_seconds-ne180-or[int]$obs.poll_seconds-ne5-or@($obs.observations).Count-lt30){throw 'bootstrap_observation_contract_mismatch'}
$a=ReadJson 'assessment.json';if($a.classification-ne'fresh_kubernetes_bootstrap_supported'-or-not$a.stale_profile_deleted-or$a.application_manifest_applied-or$a.workload_started-or$a.scientific_fault_started-or$a.dataset_inclusion-or$a.headroom_decision_inclusion-or$a.causal_conclusion){throw 'assessment_contract_mismatch'}
if([int]$a.sample_count-ne[int]$a.stable_sample_count){throw 'bootstrap_stability_mismatch'}
$h=ReadJson 'host-after.json';if(-not$h.passed-or[int]$h.counts.whea_event_17-ne0-or[int]$h.counts.kernel_power_41-ne0-or[int]$h.counts.bugcheck-ne0){throw 'host_health_gate_failed'}
Write-Output "kubernetes_bootstrap_verification=passed id=$ExpectedDiagnosticId classification=$($a.classification)"

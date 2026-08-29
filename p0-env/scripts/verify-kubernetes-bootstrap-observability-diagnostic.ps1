[CmdletBinding()]
param([Parameter(Mandatory)][string]$ArtifactRoot,[string]$ExpectedDiagnosticId='ob-k8s-bootstrap-observe-001')
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function ReadJson([string]$Name){Get-Content -LiteralPath(Join-Path $ArtifactRoot $Name)-Raw|ConvertFrom-Json}
$leaf=Split-Path -Leaf $ArtifactRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar);if($leaf-ne$ExpectedDiagnosticId){throw 'artifact_root_diagnostic_id_mismatch'}
foreach($name in @('diagnostic-manifest.json','prestart-container-inspect.json','bootstrap-process-observations.json','final-container-inspect-capture.json','minikube-last-start-capture.json','assessment.json','host-after.json')){if(-not(Test-Path -LiteralPath(Join-Path $ArtifactRoot $name))){throw "bootstrap_observability_evidence_missing:$name"}}
$m=ReadJson 'diagnostic-manifest.json';if($m.diagnostic_id-ne$ExpectedDiagnosticId-or$m.gate_id-ne'P2-KUBERNETES-BOOTSTRAP-OBS-DIAG-001'){throw 'diagnostic_identity_mismatch'}
if($m.driver-ne'docker'-or$m.kubernetes_version-ne'v1.34.0'-or[int]$m.cpus-ne4-or[int]$m.memory_mib-ne6144-or[int]$m.disk_gib-ne32-or$m.container_runtime-ne'containerd'){throw 'bootstrap_contract_mismatch'}
if(-not$m.reuses_preserved_profile-or$m.profile_deleted-or$m.application_manifest_applied-or$m.workload_started-or$m.toxic_created-or$m.scientific_fault_started-or$m.scientific_window_started-or$m.dataset_inclusion-or$m.headroom_decision_inclusion){throw 'diagnostic_scope_mismatch'}
$o=ReadJson 'bootstrap-process-observations.json';if([int]$o.timeout_seconds-ne420-or[int]$o.poll_seconds-ne5-or@($o.observations).Count-lt1){throw 'bootstrap_observation_contract_mismatch'}
$a=ReadJson 'assessment.json';$allowed=@('bootstrap_client_timeout_observed','bootstrap_start_succeeded_observed','bootstrap_start_failed_with_live_evidence','bootstrap_start_failed_without_live_container');if($a.classification-notin$allowed-or$a.profile_deleted-or-not$a.profile_stopped_after_capture-or$a.application_manifest_applied-or$a.workload_started-or$a.scientific_fault_started-or$a.dataset_inclusion-or$a.headroom_decision_inclusion-or$a.causal_conclusion){throw 'assessment_contract_mismatch'}
if($a.live_container_seen){foreach($name in @('kubelet-journal-capture.json','containerd-journal-capture.json','cri-control-plane-capture.json')){if(-not(Test-Path -LiteralPath(Join-Path $ArtifactRoot $name))){throw "live_bootstrap_evidence_missing:$name"}}}
$h=ReadJson 'host-after.json';if(-not$h.passed-or[int]$h.counts.whea_event_17-ne0-or[int]$h.counts.kernel_power_41-ne0-or[int]$h.counts.bugcheck-ne0){throw 'host_health_gate_failed'}
Write-Output "kubernetes_bootstrap_observability_verification=passed id=$ExpectedDiagnosticId classification=$($a.classification)"

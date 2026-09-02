[CmdletBinding()]
param([Parameter(Mandatory)][string]$ArtifactRoot,[string]$ExpectedDiagnosticId='ob-network-base-readiness-008')
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function ReadJson([string]$Name){Get-Content -LiteralPath(Join-Path $ArtifactRoot $Name)-Raw|ConvertFrom-Json}
$leaf=Split-Path -Leaf $ArtifactRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
if($leaf-ne$ExpectedDiagnosticId){throw 'artifact_root_diagnostic_id_mismatch'}
$manifest=ReadJson 'diagnostic-manifest.json'
if($manifest.diagnostic_id-ne$ExpectedDiagnosticId-or$manifest.gate_id-ne'P2-NETWORK-DELAY-BASE-READINESS-DIAG-001'){throw 'diagnostic_identity_mismatch'}
if($manifest.predecessor_decision-ne'D-094'-or$manifest.predecessor_diagnostic_id-ne'ob-docker-disk-recovery-001'-or$manifest.predecessor_merge_revision-ne'09bf0e077f291318df561f16e48d38cc805ebcd7'){throw 'predecessor_provenance_mismatch'}
if(-not[IO.Path]::IsPathRooted([string]$manifest.runtime_state_root_resolved)-or-not[IO.Path]::IsPathRooted([string]$manifest.source_root_resolved)){throw 'runtime_path_provenance_mismatch'}
if($manifest.dataset_inclusion-ne$false-or$manifest.headroom_decision_inclusion-ne$false-or$manifest.scientific_fault_started-ne$false-or$manifest.scientific_window_started-ne$false){throw 'diagnostic_scope_mismatch'}
if($manifest.base_config-ne'p0-env/config/online-boutique'-or$manifest.workload_profile_id-ne'ob-default-10u-1r-v1'-or$manifest.proxy_overlay_applied-ne$false-or$manifest.toxic_created-ne$false){throw 'diagnostic_topology_mismatch'}
if($manifest.online_boutique_source_revision_expected-ne'5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb'){throw 'source_revision_contract_mismatch'}
$preflight=ReadJson 'preflight-provenance.json'
if(-not$preflight.passed-or$preflight.predecessor_decision-ne'D-094'-or$preflight.predecessor_diagnostic_id-ne'ob-docker-disk-recovery-001'-or$preflight.predecessor_merge_revision-ne'09bf0e077f291318df561f16e48d38cc805ebcd7'){throw 'preflight_predecessor_mismatch'}
if($preflight.runtime_state_root_resolved-ne$manifest.runtime_state_root_resolved-or$preflight.source_root_resolved-ne$manifest.source_root_resolved-or$preflight.profile-ne'p0-online-boutique'-or$preflight.driver-ne'docker'-or$preflight.kubernetes_version-ne'v1.34.0'-or[int]$preflight.cpus-ne4-or[int]$preflight.memory_mib-ne6144-or[int]$preflight.disk_mib-ne32768-or$preflight.container_runtime-ne'containerd'-or$preflight.container_status-ne'exited'-or[int]$preflight.container_exit_code-ne130-or$preflight.container_oom_killed-ne$false-or$preflight.volume_present-ne$true){throw 'preflight_runtime_contract_mismatch'}
$obs=ReadJson 'readiness-observations.json'
if([int]$obs.convergence_timeout_seconds-ne900-or[int]$obs.stability_duration_seconds-ne180-or[int]$obs.poll_seconds-ne5){throw 'observation_contract_mismatch'}
$assessment=ReadJson 'assessment.json'
if($assessment.diagnostic_id-ne$ExpectedDiagnosticId-or$assessment.classification-notin@('fresh_base_stability_supported','fresh_base_stability_not_supported')){throw 'assessment_contract_mismatch'}
if($assessment.dataset_inclusion-ne$false-or$assessment.headroom_decision_inclusion-ne$false-or$assessment.causal_conclusion-ne$false){throw 'assessment_scope_mismatch'}
$hostEvidence=ReadJson 'host-after.json'
if(-not$hostEvidence.passed-or[int]$hostEvidence.counts.whea_event_17-ne0-or[int]$hostEvidence.counts.kernel_power_41-ne0-or[int]$hostEvidence.counts.bugcheck-ne0){throw 'host_health_gate_failed'}
Write-Output "network_base_readiness_verification=passed id=$ExpectedDiagnosticId classification=$($assessment.classification)"

[CmdletBinding()]
param([Parameter(Mandatory)][string]$ArtifactRoot,[string]$ExpectedDiagnosticId='ob-network-base-readiness-011')
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function ReadJson([string]$Name){Get-Content -LiteralPath(Join-Path $ArtifactRoot $Name)-Raw|ConvertFrom-Json}
$leaf=Split-Path -Leaf $ArtifactRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
if($leaf-ne$ExpectedDiagnosticId){throw 'artifact_root_diagnostic_id_mismatch'}
$manifest=ReadJson 'diagnostic-manifest.json'
if($manifest.diagnostic_id-ne$ExpectedDiagnosticId-or$manifest.gate_id-ne'P2-NETWORK-DELAY-BASE-READINESS-DIAG-001'){throw 'diagnostic_identity_mismatch'}
if($manifest.preregistration_decision-ne'D-100'-or$manifest.predecessor_decision-ne'D-099'-or$manifest.predecessor_diagnostic_id-ne'ob-network-base-readiness-010'-or$manifest.predecessor_merge_revision-ne'8e15ef1a11034b62110d90822521c6f21263dcc5'){throw 'predecessor_provenance_mismatch'}
if(-not[IO.Path]::IsPathRooted([string]$manifest.runtime_state_root_resolved)-or-not[IO.Path]::IsPathRooted([string]$manifest.source_root_resolved)){throw 'runtime_path_provenance_mismatch'}
if($manifest.dataset_inclusion-ne$false-or$manifest.headroom_decision_inclusion-ne$false-or$manifest.scientific_fault_started-ne$false-or$manifest.scientific_window_started-ne$false){throw 'diagnostic_scope_mismatch'}
if($manifest.base_config-ne'source-bound temporary deployment bundle'-or$manifest.workload_profile_id-ne'ob-default-10u-1r-v1'-or$manifest.proxy_overlay_applied-ne$false-or$manifest.toxic_created-ne$false){throw 'diagnostic_topology_mismatch'}
if($manifest.online_boutique_source_revision_expected-ne'5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb'){throw 'source_revision_contract_mismatch'}
$preflight=ReadJson 'preflight-provenance.json'
if(-not$preflight.passed-or$preflight.predecessor_decision-ne'D-099'-or$preflight.predecessor_diagnostic_id-ne'ob-network-base-readiness-010'-or$preflight.predecessor_merge_revision-ne'8e15ef1a11034b62110d90822521c6f21263dcc5'){throw 'preflight_predecessor_mismatch'}
if($preflight.runtime_state_root_resolved-ne$manifest.runtime_state_root_resolved-or$preflight.source_root_resolved-ne$manifest.source_root_resolved-or$preflight.profile-ne'p0-online-boutique'-or$preflight.driver-ne'docker'-or$preflight.kubernetes_version-ne'v1.34.0'-or[int]$preflight.cpus-ne4-or[int]$preflight.memory_mib-ne6144-or[int]$preflight.disk_mib-ne32768-or$preflight.container_runtime-ne'containerd'-or$preflight.container_status-ne'exited'-or[int]$preflight.container_exit_code-ne137-or$preflight.container_oom_killed-ne$false-or$preflight.volume_present-ne$true){throw 'preflight_runtime_contract_mismatch'}
$ssh=$preflight.ssh_key_provenance
if(-not$ssh.passed-or-not$ssh.exact_host_public_key_present-or$ssh.host_public_key_sha256-ne'86bf057eb0bf9488079879a62c297157bd9e0b2a835b9097dc9d61b79d7e02b1'-or$ssh.host_public_key_fingerprint-ne'SHA256:E8X6DYnpxGPJpp3lUOnbtLCow0oNNLC9HomdrrWBEOs'-or$manifest.ssh_public_key_sha256_expected-ne$ssh.host_public_key_sha256-or$manifest.ssh_public_key_fingerprint_expected-ne$ssh.host_public_key_fingerprint){throw 'ssh_key_provenance_mismatch'}
$bundle=ReadJson 'deployment-bundle-provenance.json'
if(-not$bundle.passed-or$bundle.source_root_resolved-ne$manifest.source_root_resolved-or$bundle.source_revision-ne$manifest.online_boutique_source_revision_expected-or[int]$bundle.upstream_file_count-ne12-or$bundle.relative_checkout_source_reference_used-ne$false-or[string]::IsNullOrWhiteSpace([string]$bundle.kustomization_sha256)){throw 'deployment_bundle_provenance_mismatch'}
$obs=ReadJson 'readiness-observations.json'
if([int]$obs.convergence_timeout_seconds-ne900-or[int]$obs.stability_duration_seconds-ne180-or[int]$obs.poll_seconds-ne5){throw 'observation_contract_mismatch'}
$assessment=ReadJson 'assessment.json'
if($assessment.diagnostic_id-ne$ExpectedDiagnosticId-or$assessment.classification-notin@('fresh_base_stability_supported','fresh_base_stability_not_supported')){throw 'assessment_contract_mismatch'}
if($assessment.dataset_inclusion-ne$false-or$assessment.headroom_decision_inclusion-ne$false-or$assessment.causal_conclusion-ne$false){throw 'assessment_scope_mismatch'}
$hostEvidence=ReadJson 'host-after.json'
if(-not$hostEvidence.passed-or[int]$hostEvidence.counts.whea_event_17-ne0-or[int]$hostEvidence.counts.kernel_power_41-ne0-or[int]$hostEvidence.counts.bugcheck-ne0){throw 'host_health_gate_failed'}
Write-Output "network_base_readiness_verification=passed id=$ExpectedDiagnosticId classification=$($assessment.classification)"

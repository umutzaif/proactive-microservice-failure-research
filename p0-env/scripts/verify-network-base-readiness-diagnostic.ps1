[CmdletBinding()]
param([Parameter(Mandatory)][string]$ArtifactRoot,[string]$ExpectedDiagnosticId='ob-network-base-readiness-003')
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function ReadJson([string]$Name){Get-Content -LiteralPath(Join-Path $ArtifactRoot $Name)-Raw|ConvertFrom-Json}
$leaf=Split-Path -Leaf $ArtifactRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
if($leaf-ne$ExpectedDiagnosticId){throw 'artifact_root_diagnostic_id_mismatch'}
$manifest=ReadJson 'diagnostic-manifest.json'
if($manifest.diagnostic_id-ne$ExpectedDiagnosticId-or$manifest.gate_id-ne'P2-NETWORK-DELAY-BASE-READINESS-DIAG-001'){throw 'diagnostic_identity_mismatch'}
if($manifest.dataset_inclusion-ne$false-or$manifest.headroom_decision_inclusion-ne$false-or$manifest.scientific_fault_started-ne$false-or$manifest.scientific_window_started-ne$false){throw 'diagnostic_scope_mismatch'}
if($manifest.base_config-ne'p0-env/config/online-boutique'-or$manifest.workload_profile_id-ne'ob-default-10u-1r-v1'-or$manifest.proxy_overlay_applied-ne$false-or$manifest.toxic_created-ne$false){throw 'diagnostic_topology_mismatch'}
$obs=ReadJson 'readiness-observations.json'
if([int]$obs.convergence_timeout_seconds-ne900-or[int]$obs.stability_duration_seconds-ne180-or[int]$obs.poll_seconds-ne5){throw 'observation_contract_mismatch'}
$assessment=ReadJson 'assessment.json'
if($assessment.diagnostic_id-ne$ExpectedDiagnosticId-or$assessment.classification-notin@('fresh_base_stability_supported','fresh_base_stability_not_supported')){throw 'assessment_contract_mismatch'}
if($assessment.dataset_inclusion-ne$false-or$assessment.headroom_decision_inclusion-ne$false-or$assessment.causal_conclusion-ne$false){throw 'assessment_scope_mismatch'}
$host=ReadJson 'host-after.json'
if(-not$host.passed-or[int]$host.counts.whea_event_17-ne0-or[int]$host.counts.kernel_power_41-ne0-or[int]$host.counts.bugcheck-ne0){throw 'host_health_gate_failed'}
Write-Output "network_base_readiness_verification=passed id=$ExpectedDiagnosticId classification=$($assessment.classification)"

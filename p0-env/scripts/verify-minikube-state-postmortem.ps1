[CmdletBinding()]
param([Parameter(Mandatory)][string]$ArtifactRoot,[string]$ExpectedDiagnosticId='ob-minikube-state-postmortem-001',[Parameter(Mandatory)][string]$ExpectedMinikubeHome)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
function ReadJson([string]$Name){Get-Content -LiteralPath(Join-Path $ArtifactRoot $Name)-Raw|ConvertFrom-Json}
$leaf=Split-Path -Leaf $ArtifactRoot.TrimEnd([IO.Path]::DirectorySeparatorChar,[IO.Path]::AltDirectorySeparatorChar)
if($leaf-ne$ExpectedDiagnosticId){throw 'artifact_root_diagnostic_id_mismatch'}
foreach($required in @('diagnostic-manifest.json','container-inspect.json','volume-inspect.json','docker-logs.json','minikube-last-start-logs.json','source-presence.json','assessment.json')){if(-not(Test-Path -LiteralPath(Join-Path $ArtifactRoot $required))){throw "postmortem_evidence_missing:$required"}}
$m=ReadJson 'diagnostic-manifest.json'
if($m.diagnostic_id-ne$ExpectedDiagnosticId-or$m.gate_id-ne'P2-MINIKUBE-STATE-POSTMORTEM-001'){throw 'diagnostic_identity_mismatch'}
$expected=[IO.Path]::GetFullPath($ExpectedMinikubeHome);$resolved=[IO.Path]::GetFullPath([string]$m.resolved_minikube_home)
if(-not[string]::Equals($resolved,$expected,[StringComparison]::OrdinalIgnoreCase)-or-not[string]::Equals([IO.Path]::GetFullPath([string]$m.expected_minikube_home),$expected,[StringComparison]::OrdinalIgnoreCase)){throw 'state_root_provenance_mismatch'}
if($m.profile_deleted-or$m.container_started-or$m.cluster_started-or$m.application_manifest_applied-or$m.workload_started-or$m.toxic_created-or$m.scientific_fault_started-or$m.scientific_window_started-or$m.dataset_inclusion-or$m.headroom_decision_inclusion){throw 'postmortem_scope_mismatch'}
if([string]$m.container_state-eq'running'){throw 'postmortem_container_was_running'}
$source=ReadJson 'source-presence.json';if(-not$source.profile_root_present){throw 'profile_source_missing'}
$a=ReadJson 'assessment.json';if($a.diagnostic_id-ne$ExpectedDiagnosticId-or$a.classification-ne'stopped_state_postmortem_captured'-or-not$a.resolved_state_root_matches_expected-or$a.profile_mutated-or$a.cluster_started-or$a.application_manifest_applied-or$a.workload_started-or$a.scientific_fault_started-or$a.dataset_inclusion-or$a.headroom_decision_inclusion-or$a.causal_conclusion){throw 'assessment_contract_mismatch'}
Write-Output "minikube_state_postmortem_verification=passed id=$ExpectedDiagnosticId state=$($a.container_state)"

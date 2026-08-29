[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]
param([string]$DiagnosticId='ob-minikube-state-postmortem-001',[string]$Profile='p0-online-boutique',[switch]$ExecutionApproved)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$externalMinikubeHome=if(Test-Path Env:MINIKUBE_HOME){[string]$env:MINIKUBE_HOME}else{$null}
. (Join-Path $PSScriptRoot 'env.ps1')
$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path
$expectedMinikubeHome=[IO.Path]::GetFullPath((Join-Path $repo 'p0-env\state\minikube'))
$resolvedMinikubeHome=[IO.Path]::GetFullPath([string]$env:MINIKUBE_HOME)
$profileRoot=Join-Path $resolvedMinikubeHome ".minikube\profiles\$Profile"
$lastStart=Join-Path $resolvedMinikubeHome '.minikube\logs\lastStart.txt'
$root=Join-Path $repo "p0-env\artifacts\P2-MINIKUBE-STATE-POSTMORTEM-001\$DiagnosticId"
function NowUtc{[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')}
function WriteJson([string]$Path,[object]$Value){New-Item -ItemType Directory -Path(Split-Path -Parent $Path)-Force|Out-Null;[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 80),[Text.UTF8Encoding]::new($false))}
function CaptureNative([string]$Name,[scriptblock]$Command){$lines=@(& $Command 2>&1)|ForEach-Object{[string]$_};$exit=$LASTEXITCODE;WriteJson(Join-Path $root $Name)([ordered]@{captured_utc=NowUtc;exit_code=$exit;lines=$lines})}
if(-not$ExecutionApproved){throw 'explicit_state_postmortem_approval_required'}
if($DiagnosticId-ne'ob-minikube-state-postmortem-001'){throw 'unexpected_diagnostic_id'}
if(@(& git -C $repo status --porcelain).Count){throw 'working_tree_not_clean'}
if(Test-Path -LiteralPath $root){throw 'immutable_diagnostic_output_exists'}
if(-not[string]::Equals($resolvedMinikubeHome,$expectedMinikubeHome,[StringComparison]::OrdinalIgnoreCase)){throw 'resolved_minikube_home_mismatch'}
if(-not(Test-Path -LiteralPath $profileRoot)){throw 'exact_profile_state_missing'}
if(-not$PSCmdlet.ShouldProcess($Profile,'capture read-only Minikube state-root provenance and stopped-profile postmortem evidence')){return}
$dockerVersion=@(& docker info --format '{{.ServerVersion}}' 2>$null);if($LASTEXITCODE-ne0-or$dockerVersion.Count-ne1-or-not$dockerVersion[0]){throw 'docker_engine_not_ready'}
$inspectRaw=@(& docker inspect $Profile 2>$null);if($LASTEXITCODE-ne0-or$inspectRaw.Count-eq0){throw 'exact_profile_container_missing'}
$inspect=($inspectRaw-join"`n")|ConvertFrom-Json;if(@($inspect).Count-ne1){throw 'exact_profile_container_ambiguous'}
$containerState=[string]$inspect[0].State.Status;if($containerState-eq'running'){throw 'profile_container_not_stopped'}
New-Item -ItemType Directory -Path $root|Out-Null
$failure=$null
try{
 WriteJson(Join-Path $root 'diagnostic-manifest.json')([ordered]@{schema_version=1;gate_id='P2-MINIKUBE-STATE-POSTMORTEM-001';diagnostic_id=$DiagnosticId;code_revision=(& git -C $repo rev-parse HEAD).Trim();profile=$Profile;external_minikube_home=$externalMinikubeHome;resolved_minikube_home=$resolvedMinikubeHome;expected_minikube_home=$expectedMinikubeHome;profile_root=$profileRoot;docker_version=[string]$dockerVersion[0];container_state=$containerState;profile_deleted=$false;container_started=$false;cluster_started=$false;application_manifest_applied=$false;workload_started=$false;toxic_created=$false;scientific_fault_started=$false;scientific_window_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false})
 WriteJson(Join-Path $root 'container-inspect.json')$inspect[0]
 CaptureNative 'volume-inspect.json' {& docker volume inspect $Profile}
 CaptureNative 'docker-logs.json' {& docker logs --timestamps $Profile}
 CaptureNative 'minikube-last-start-logs.json' {& minikube logs --profile $Profile --last-start-only}
 $profileConfig=Join-Path $profileRoot 'config.json';if(Test-Path -LiteralPath $profileConfig){Copy-Item -LiteralPath $profileConfig -Destination(Join-Path $root 'profile-config.json')}
 if(Test-Path -LiteralPath $lastStart){Copy-Item -LiteralPath $lastStart -Destination(Join-Path $root 'lastStart.txt')}
 WriteJson(Join-Path $root 'source-presence.json')([ordered]@{profile_config_present=(Test-Path -LiteralPath $profileConfig);last_start_present=(Test-Path -LiteralPath $lastStart);profile_root_present=(Test-Path -LiteralPath $profileRoot)})
 WriteJson(Join-Path $root 'assessment.json')([ordered]@{schema_version=1;diagnostic_id=$DiagnosticId;classification='stopped_state_postmortem_captured';resolved_state_root_matches_expected=$true;container_state=$containerState;profile_mutated=$false;cluster_started=$false;application_manifest_applied=$false;workload_started=$false;scientific_fault_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false;causal_conclusion=$false;limitations=@('A stopped-container postmortem cannot collect live kubelet or containerd journal state without starting the container.','Captured logs and metadata may narrow hypotheses but do not establish a unique Kubernetes bootstrap root cause.','This diagnostic does not authorize profile deletion, bootstrap retry, application deployment, a replacement normal run, or fault injection.')})
}
catch{$failure=$_.Exception.Message;WriteJson(Join-Path $root 'run-error.json')([ordered]@{failed_utc=NowUtc;error=$failure;profile_mutated=$false;cluster_started=$false;scientific_fault_started=$false})}
if($failure){& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create;throw "state_postmortem_failed:$failure"}
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'verify-minikube-state-postmortem.ps1')-ArtifactRoot $root -ExpectedDiagnosticId $DiagnosticId -ExpectedMinikubeHome $expectedMinikubeHome
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create
Write-Output "minikube_state_postmortem=completed id=$DiagnosticId"

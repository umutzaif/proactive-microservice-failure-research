[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param([string]$DiagnosticId='ob-k8s-bootstrap-001',[string]$Profile='p0-online-boutique',[switch]$ExecutionApproved)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'host-event-recordid.ps1')
$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path
$root=Join-Path $repo "p0-env\artifacts\P2-KUBERNETES-BOOTSTRAP-DIAG-001\$DiagnosticId"
$stateRoot=Join-Path $repo 'p0-env\state\minikube\.minikube'
function NowUtc{[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')}
function WriteJson([string]$Path,[object]$Value){New-Item -ItemType Directory -Path(Split-Path -Parent $Path)-Force|Out-Null;[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 80),[Text.UTF8Encoding]::new($false))}
function CaptureText([string]$Name,[scriptblock]$Command){$lines=@(& $Command 2>&1)|ForEach-Object{[string]$_};[IO.File]::WriteAllLines((Join-Path $root $Name),$lines,[Text.UTF8Encoding]::new($false))}
if(-not$ExecutionApproved){throw 'explicit_bootstrap_diagnostic_approval_required'}
$allowedDiagnosticIds=@('ob-k8s-bootstrap-001','ob-k8s-bootstrap-recovery-001','ob-docker-disk-recovery-001')
if($DiagnosticId-notin$allowedDiagnosticIds){throw 'unexpected_diagnostic_id'}
if(@(& git -C $repo status --porcelain).Count){throw 'working_tree_not_clean'}
if(Test-Path -LiteralPath $root){throw 'immutable_diagnostic_output_exists'}
if(-not$PSCmdlet.ShouldProcess($Profile,'capture evidence, delete exact stale Minikube profile, and test clean no-workload bootstrap')){return}
$dockerVersion=(& docker info --format '{{.ServerVersion}}' 2>$null)
if(-not$dockerVersion){throw 'docker_engine_not_ready'}
$minimumHostFreeBytes=[long](15GB)
$hostFreeBytes=[long](Get-PSDrive -Name C).Free
if($hostFreeBytes-lt$minimumHostFreeBytes){throw 'host_free_space_below_15_gib'}
New-Item -ItemType Directory -Path $root|Out-Null
$boundary=New-HostEventRecordIdBoundary;$failure=$null;$stopped=$false;$deleted=$false;$observations=@()
WriteJson (Join-Path $root 'host-before.json') $boundary
WriteJson (Join-Path $root 'diagnostic-manifest.json') ([ordered]@{schema_version=1;gate_id='P2-KUBERNETES-BOOTSTRAP-DIAG-001';diagnostic_id=$DiagnosticId;code_revision=(& git -C $repo rev-parse HEAD).Trim();profile=$Profile;driver='docker';kubernetes_version='v1.34.0';cpus=4;memory_mib=6144;disk_gib=32;container_runtime='containerd';host_free_space_minimum_gib=15;host_free_space_observed_bytes=$hostFreeBytes;host_free_space_gate_passed=$true;application_manifest_applied=$false;workload_started=$false;toxic_created=$false;scientific_fault_started=$false;scientific_window_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false})
try{
 CaptureText 'predelete-container-inspect.json' {& docker inspect $Profile}
 CaptureText 'predelete-volume-inspect.json' {& docker volume inspect $Profile}
 $lastStart=Join-Path $stateRoot 'logs\lastStart.txt';if(Test-Path -LiteralPath $lastStart){Copy-Item -LiteralPath $lastStart -Destination(Join-Path $root 'predelete-lastStart.txt')}
 & minikube delete --profile $Profile;if($LASTEXITCODE){throw 'minikube_delete_failed'};$deleted=$true
 $containerExists=@(& docker ps -a --filter "name=^/$Profile$" --format '{{.ID}}').Count-gt0
 $volumeExists=@(& docker volume ls --filter "name=^$Profile$" --format '{{.Name}}').Count-gt0
 WriteJson (Join-Path $root 'delete-verification.json') ([ordered]@{deleted_utc=NowUtc;profile=$Profile;container_exists=$containerExists;volume_exists=$volumeExists;passed=(-not$containerExists-and-not$volumeExists)})
 if($containerExists-or$volumeExists){throw 'profile_delete_verification_failed'}
 & minikube start --profile $Profile --driver docker --kubernetes-version v1.34.0 --cpus 4 --memory 6144mb --disk-size 32g --container-runtime containerd;if($LASTEXITCODE){throw 'clean_minikube_start_failed'}
 $deadline=[datetimeoffset]::UtcNow.AddSeconds(180)
 do{$raw=@(& minikube status --profile $Profile --output json 2>&1);$exit=$LASTEXITCODE;$parsed=$null;if($exit-eq0){$parsed=($raw-join"`n")|ConvertFrom-Json};$observations+=,[ordered]@{observed_utc=NowUtc;exit_code=$exit;host=$(if($parsed){[string]$parsed.Host}else{$null});kubelet=$(if($parsed){[string]$parsed.Kubelet}else{$null});apiserver=$(if($parsed){[string]$parsed.APIServer}else{$null});kubeconfig=$(if($parsed){[string]$parsed.Kubeconfig}else{$null})};Start-Sleep -Seconds 5}while([datetimeoffset]::UtcNow-lt$deadline)
 WriteJson (Join-Path $root 'bootstrap-observations.json') ([ordered]@{duration_seconds=180;poll_seconds=5;observations=$observations})
 CaptureText 'nodes.json' {& minikube kubectl --profile $Profile -- get nodes -o json}
 CaptureText 'kube-system-pods.json' {& minikube kubectl --profile $Profile -- -n kube-system get pods -o json}
 CaptureText 'kube-system-events.txt' {& minikube kubectl --profile $Profile -- -n kube-system get events --sort-by=.lastTimestamp}
 $stable=@($observations|Where-Object{$_.exit_code-eq0-and$_.host-eq'Running'-and$_.kubelet-eq'Running'-and$_.apiserver-eq'Running'-and$_.kubeconfig-eq'Configured'})
 $supported=$observations.Count-ge30-and$stable.Count-eq$observations.Count
 WriteJson (Join-Path $root 'assessment.json') ([ordered]@{schema_version=1;diagnostic_id=$DiagnosticId;classification=$(if($supported){'fresh_kubernetes_bootstrap_supported'}else{'fresh_kubernetes_bootstrap_not_supported'});sample_count=$observations.Count;stable_sample_count=$stable.Count;stale_profile_deleted=$deleted;application_manifest_applied=$false;workload_started=$false;scientific_fault_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false;causal_conclusion=$false;limitations=@('A successful clean bootstrap supports but does not by itself prove stale persistent state as the unique cause.','This diagnostic does not authorize recommendationservice deployment, a replacement normal run, or fault injection.')})
 if(-not$supported){throw 'bootstrap_stability_not_supported'}
}
catch{$failure=$_.Exception.Message;WriteJson (Join-Path $root 'run-error.json') ([ordered]@{failed_utc=NowUtc;error=$failure;scientific_fault_started=$false})}
finally{if(-not$stopped){& minikube stop --profile $Profile|Out-Null;$stopped=$true};try{WriteJson (Join-Path $root 'host-after.json') (Measure-HostEventsAfterRecordIdBoundary -Boundary $boundary)}catch{WriteJson (Join-Path $root 'host-after-error.json') ([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}}
if($failure){& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1') -ArtifactRoot $root -Mode Create;throw "bootstrap_diagnostic_failed:$failure"}
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'verify-kubernetes-bootstrap-diagnostic.ps1') -ArtifactRoot $root -ExpectedDiagnosticId $DiagnosticId
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1') -ArtifactRoot $root -Mode Create
Write-Output "kubernetes_bootstrap_diagnostic=completed id=$DiagnosticId"

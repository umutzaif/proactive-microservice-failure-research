[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]
param([string]$DiagnosticId='ob-k8s-bootstrap-observe-001',[string]$Profile='p0-online-boutique',[switch]$ExecutionApproved)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'host-event-recordid.ps1')
. (Join-Path $PSScriptRoot 'native-command-capture.ps1')
$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path
$root=Join-Path $repo "p0-env\artifacts\P2-KUBERNETES-BOOTSTRAP-OBS-DIAG-001\$DiagnosticId"
function NowUtc{[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')}
function WriteJson([string]$Path,[object]$Value){New-Item -ItemType Directory -Path(Split-Path -Parent $Path)-Force|Out-Null;[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 80),[Text.UTF8Encoding]::new($false))}
function Capture([string]$FilePath,[string[]]$Arguments){$savedWhatIf=$WhatIfPreference;$WhatIfPreference=$false;try{Invoke-NativeCommandCapture -FilePath $FilePath -ArgumentList $Arguments}finally{$WhatIfPreference=$savedWhatIf}}
if(-not$ExecutionApproved){throw 'explicit_bootstrap_observability_approval_required'}
if($DiagnosticId-ne'ob-k8s-bootstrap-observe-001'){throw 'unexpected_diagnostic_id'}
if(@(& git -C $repo status --porcelain).Count){throw 'working_tree_not_clean'}
if(Test-Path -LiteralPath $root){throw 'immutable_diagnostic_output_exists'}
$dockerExe=(Get-Command docker -CommandType Application|Select-Object -First 1).Source
$minikubeExe=(Get-Command minikube -CommandType Application|Select-Object -First 1).Source
$dockerInfo=Capture $dockerExe @('info','--format','{{.ServerVersion}}');if($dockerInfo.exit_code-ne0-or-not$dockerInfo.stdout.Trim()){throw 'docker_engine_not_ready'}
$before=Capture $dockerExe @('inspect',$Profile);if($before.exit_code-ne0-or-not$before.stdout.Trim()){throw 'exact_profile_container_missing'}
$beforeJson=$before.stdout|ConvertFrom-Json;if(@($beforeJson).Count-ne1){throw 'exact_profile_container_ambiguous'}
if([string]$beforeJson[0].State.Status-eq'running'){throw 'profile_container_not_stopped'}
if(-not$PSCmdlet.ShouldProcess($Profile,'start unchanged Minikube profile while capturing live bootstrap process and journal evidence, then stop it')){return}
New-Item -ItemType Directory -Path $root|Out-Null
$boundary=New-HostEventRecordIdBoundary;$failure=$null;$startProcess=$null;$samples=@();$liveContainerSeen=$false;$timedOut=$false
WriteJson(Join-Path $root 'host-before.json')$boundary
WriteJson(Join-Path $root 'diagnostic-manifest.json')([ordered]@{schema_version=1;gate_id='P2-KUBERNETES-BOOTSTRAP-OBS-DIAG-001';diagnostic_id=$DiagnosticId;code_revision=(& git -C $repo rev-parse HEAD).Trim();profile=$Profile;driver='docker';kubernetes_version='v1.34.0';cpus=4;memory_mib=6144;disk_gib=32;container_runtime='containerd';reuses_preserved_profile=$true;profile_deleted=$false;application_manifest_applied=$false;workload_started=$false;toxic_created=$false;scientific_fault_started=$false;scientific_window_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false})
WriteJson(Join-Path $root 'prestart-container-inspect.json')$beforeJson[0]
try{
 $stdout=Join-Path $root 'minikube-start.stdout.txt';$stderr=Join-Path $root 'minikube-start.stderr.txt'
 $args=@('start','--profile',$Profile,'--driver=docker','--kubernetes-version=v1.34.0','--cpus=4','--memory=6144mb','--disk-size=32g','--container-runtime=containerd')
 $startProcess=Start-Process -FilePath $minikubeExe -ArgumentList $args -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru -WindowStyle Hidden
 $deadline=[datetimeoffset]::UtcNow.AddSeconds(420)
 do{
  $inspect=Capture $dockerExe @('inspect',$Profile);$state=$null
  if($inspect.exit_code-eq0-and$inspect.stdout.Trim()){$obj=$inspect.stdout|ConvertFrom-Json;$state=[string]$obj[0].State.Status;if($state-eq'running'){$liveContainerSeen=$true}}
  $processes=if($state-eq'running'){Capture $dockerExe @('exec',$Profile,'sh','-c','ps -eo pid,comm,args | grep -E "kube-apiserver|etcd|kubelet|containerd" | grep -v grep')}else{$null}
  $samples+=,[ordered]@{observed_utc=NowUtc;start_process_exited=$startProcess.HasExited;container_state=$state;inspect_exit_code=$inspect.exit_code;control_plane_exit_code=$(if($processes){$processes.exit_code}else{$null});control_plane_stdout=$(if($processes){$processes.stdout}else{$null});control_plane_stderr=$(if($processes){$processes.stderr}else{$null})}
  if($startProcess.HasExited){break};Start-Sleep -Seconds 5
 }while([datetimeoffset]::UtcNow-lt$deadline)
 if(-not$startProcess.HasExited){$timedOut=$true;Stop-Process -Id $startProcess.Id -Force;$startProcess.WaitForExit()}
 $startProcess.WaitForExit();$startExit=$startProcess.ExitCode
 WriteJson(Join-Path $root 'bootstrap-process-observations.json')([ordered]@{timeout_seconds=420;poll_seconds=5;timed_out=$timedOut;start_exit_code=$startExit;live_container_seen=$liveContainerSeen;observations=$samples})
 $finalInspect=Capture $dockerExe @('inspect',$Profile);WriteJson(Join-Path $root 'final-container-inspect-capture.json')$finalInspect
 if($liveContainerSeen){
  WriteJson(Join-Path $root 'kubelet-journal-capture.json')(Capture $dockerExe @('exec',$Profile,'sh','-c','journalctl -u kubelet --since "15 minutes ago" --no-pager'))
  WriteJson(Join-Path $root 'containerd-journal-capture.json')(Capture $dockerExe @('exec',$Profile,'sh','-c','journalctl -u containerd --since "15 minutes ago" --no-pager'))
  WriteJson(Join-Path $root 'cri-control-plane-capture.json')(Capture $dockerExe @('exec',$Profile,'sh','-c','crictl --timeout=10s ps -a'))
 }
 WriteJson(Join-Path $root 'minikube-last-start-capture.json')(Capture $minikubeExe @('logs','--profile',$Profile,'--last-start-only'))
 $classification=if($timedOut){'bootstrap_client_timeout_observed'}elseif($startExit-eq0){'bootstrap_start_succeeded_observed'}elseif($liveContainerSeen){'bootstrap_start_failed_with_live_evidence'}else{'bootstrap_start_failed_without_live_container'}
 WriteJson(Join-Path $root 'assessment.json')([ordered]@{schema_version=1;diagnostic_id=$DiagnosticId;classification=$classification;start_exit_code=$startExit;sample_count=$samples.Count;live_container_seen=$liveContainerSeen;profile_deleted=$false;profile_stopped_after_capture=$true;application_manifest_applied=$false;workload_started=$false;scientific_fault_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false;causal_conclusion=$false;limitations=@('Process and journal evidence may narrow bootstrap hypotheses but does not by itself establish a unique root cause.','A successful start is operational evidence only and does not authorize application deployment or a replacement normal run.','This diagnostic reuses the preserved stopped profile and therefore does not test a clean-bootstrap condition.')})
}
catch{$failure=$_.Exception.Message;WriteJson(Join-Path $root 'run-error.json')([ordered]@{failed_utc=NowUtc;error=$failure;scientific_fault_started=$false})}
finally{
 if($startProcess-and-not$startProcess.HasExited){Stop-Process -Id $startProcess.Id -Force}
 & $minikubeExe stop --profile $Profile|Out-Null
 try{WriteJson(Join-Path $root 'host-after.json')(Measure-HostEventsAfterRecordIdBoundary -Boundary $boundary)}catch{WriteJson(Join-Path $root 'host-after-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}
}
if($failure){& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create;throw "bootstrap_observability_failed:$failure"}
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'verify-kubernetes-bootstrap-observability-diagnostic.ps1')-ArtifactRoot $root -ExpectedDiagnosticId $DiagnosticId
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create
Write-Output "kubernetes_bootstrap_observability_diagnostic=completed id=$DiagnosticId"

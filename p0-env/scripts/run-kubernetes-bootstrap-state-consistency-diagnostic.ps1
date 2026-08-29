[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]
param([string]$DiagnosticId='ob-k8s-bootstrap-state-consistency-001',[string]$Profile='p0-online-boutique',[switch]$ExecutionApproved)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1');. (Join-Path $PSScriptRoot 'host-event-recordid.ps1');. (Join-Path $PSScriptRoot 'native-command-capture.ps1')
$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path;$gate='P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001';$root=Join-Path $repo "p0-env\artifacts\$gate\$DiagnosticId"
function Utc{[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')}
function Json([string]$p,[object]$v){New-Item -ItemType Directory -Path(Split-Path -Parent $p)-Force|Out-Null;[IO.File]::WriteAllText($p,($v|ConvertTo-Json -Depth 80),[Text.UTF8Encoding]::new($false))}
function Capture([string]$f,[string[]]$a){$w=$WhatIfPreference;$WhatIfPreference=$false;try{Invoke-NativeCommandCapture -FilePath $f -ArgumentList $a}finally{$WhatIfPreference=$w}}
function State([string]$docker,[string]$phase){
 $paths='/var/lib/kubelet/kubeadm-flags.env /var/lib/kubelet/config.yaml /var/lib/minikube/etcd /etc/kubernetes/bootstrap-kubelet.conf /etc/kubernetes/kubelet.conf /etc/kubernetes/manifests/kube-apiserver.yaml /etc/kubernetes/manifests/etcd.yaml /var/tmp/minikube/kubeadm.yaml /var/tmp/minikube/kubeadm.yaml.new'
 $script='for p in '+$paths+'; do if [ -e "$p" ]; then printf "PRESENT|%s|" "$p"; stat -c "%F|%s|%Y" "$p"; if [ -f "$p" ]; then sha256sum "$p"; fi; else printf "MISSING|%s\n" "$p"; fi; done'
 Json (Join-Path $root "state-$phase.json") (Capture $docker @('exec',$Profile,'sh','-c',$script))
}
if(-not$ExecutionApproved){throw 'explicit_bootstrap_state_consistency_approval_required'}
if($DiagnosticId-ne'ob-k8s-bootstrap-state-consistency-001'){throw 'unexpected_diagnostic_id'}
if(@(& git -C $repo status --porcelain).Count){throw 'working_tree_not_clean'};if(Test-Path -LiteralPath $root){throw 'immutable_diagnostic_output_exists'}
$docker=(Get-Command docker -CommandType Application|Select-Object -First 1).Source;$minikube=(Get-Command minikube -CommandType Application|Select-Object -First 1).Source
$di=Capture $docker @('info','--format','{{.ServerVersion}}');if($di.exit_code-ne0-or-not$di.stdout.Trim()){throw 'docker_engine_not_ready'}
$before=Capture $docker @('inspect',$Profile);if($before.exit_code-ne0-or-not$before.stdout.Trim()){throw 'exact_profile_container_missing'};$bj=$before.stdout|ConvertFrom-Json
if(@($bj).Count-ne1){throw 'exact_profile_container_ambiguous'};if([string]$bj[0].State.Status-eq'running'){throw 'profile_container_not_stopped'}
if(-not$PSCmdlet.ShouldProcess($Profile,'start unchanged preserved profile and capture bootstrap state consistency, then stop it')){return}
New-Item -ItemType Directory -Path $root|Out-Null;$boundary=New-HostEventRecordIdBoundary;$failure=$null;$proc=$null;$live=$false;$samples=@();$timedOut=$false
Json (Join-Path $root 'host-before.json') $boundary;Json (Join-Path $root 'prestart-container-inspect.json') $bj[0]
Json (Join-Path $root 'diagnostic-manifest.json') ([ordered]@{schema_version=1;gate_id=$gate;diagnostic_id=$DiagnosticId;code_revision=(& git -C $repo rev-parse HEAD).Trim();profile=$Profile;driver='docker';kubernetes_version='v1.34.0';cpus=4;memory_mib=6144;disk_gib=32;container_runtime='containerd';timeout_seconds=420;poll_seconds=5;reuses_preserved_profile=$true;profile_deleted=$false;application_manifest_applied=$false;workload_started=$false;toxic_created=$false;scientific_fault_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false})
try{
 $out=Join-Path $root 'minikube-start.stdout.txt';$err=Join-Path $root 'minikube-start.stderr.txt';$args=@('start','--profile',$Profile,'--driver=docker','--kubernetes-version=v1.34.0','--cpus=4','--memory=6144mb','--disk-size=32g','--container-runtime=containerd')
 $proc=Start-Process -FilePath $minikube -ArgumentList $args -RedirectStandardOutput $out -RedirectStandardError $err -PassThru -WindowStyle Hidden;$deadline=[datetimeoffset]::UtcNow.AddSeconds(420)
 do{$i=Capture $docker @('inspect',$Profile);$s=$null;if($i.exit_code-eq0-and$i.stdout.Trim()){$s=[string](($i.stdout|ConvertFrom-Json)[0].State.Status);if($s-eq'running'-and-not$live){$live=$true;State $docker 'first-live'}};$samples+=,[ordered]@{observed_utc=Utc;start_process_exited=$proc.HasExited;container_state=$s};if($proc.HasExited){break};Start-Sleep 5}while([datetimeoffset]::UtcNow-lt$deadline)
 if(-not$proc.HasExited){$timedOut=$true;Stop-Process -Id $proc.Id -Force};$proc.WaitForExit();$proc.Refresh();if($null-eq$proc.ExitCode){throw 'start_exit_code_unavailable'};$exit=[int]$proc.ExitCode
 Json (Join-Path $root 'bootstrap-process-observations.json') ([ordered]@{timeout_seconds=420;poll_seconds=5;timed_out=$timedOut;start_exit_code=$exit;live_container_seen=$live;observations=$samples})
 if($live){State $docker 'final-live';Json (Join-Path $root 'kubelet-journal-capture.json')(Capture $docker @('exec',$Profile,'sh','-c','journalctl -u kubelet --since "15 minutes ago" --no-pager'));Json (Join-Path $root 'containerd-journal-capture.json')(Capture $docker @('exec',$Profile,'sh','-c','journalctl -u containerd --since "15 minutes ago" --no-pager'));Json (Join-Path $root 'cri-version-capture.json')(Capture $docker @('exec',$Profile,'crictl','--version'));Json (Join-Path $root 'cri-containers-capture.json')(Capture $docker @('exec',$Profile,'crictl','ps','-a'))}
 Json (Join-Path $root 'minikube-last-start-capture.json')(Capture $minikube @('logs','--profile',$Profile,'--last-start-only'));Json (Join-Path $root 'final-container-inspect-capture.json')(Capture $docker @('inspect',$Profile))
 $class=if($timedOut){'bootstrap_client_timeout_observed'}elseif($exit-eq0){'bootstrap_start_succeeded_observed'}elseif($live){'bootstrap_start_failed_with_state_evidence'}else{'bootstrap_start_failed_without_live_container'}
 Json (Join-Path $root 'assessment.json')([ordered]@{schema_version=1;diagnostic_id=$DiagnosticId;classification=$class;start_exit_code=$exit;live_container_seen=$live;profile_deleted=$false;profile_stopped_after_capture=$true;application_manifest_applied=$false;workload_started=$false;scientific_fault_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false;causal_conclusion=$false})
}catch{$failure=$_.Exception.Message;Json (Join-Path $root 'run-error.json')([ordered]@{failed_utc=Utc;error=$failure;scientific_fault_started=$false})}finally{if($proc-and-not$proc.HasExited){Stop-Process -Id $proc.Id -Force};& $minikube stop --profile $Profile|Out-Null;try{Json (Join-Path $root 'host-after.json')(Measure-HostEventsAfterRecordIdBoundary -Boundary $boundary)}catch{Json (Join-Path $root 'host-after-error.json')([ordered]@{failed_utc=Utc;error=$_.Exception.Message})}}
if($failure){& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create;throw "bootstrap_state_consistency_failed:$failure"}
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'verify-kubernetes-bootstrap-state-consistency-diagnostic.ps1')-ArtifactRoot $root -ExpectedDiagnosticId $DiagnosticId;& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create
Write-Output "kubernetes_bootstrap_state_consistency_diagnostic=completed id=$DiagnosticId"

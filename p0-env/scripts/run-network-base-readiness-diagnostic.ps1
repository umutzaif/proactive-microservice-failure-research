[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='Low')]
param(
 [Parameter(Mandatory)][string]$DiagnosticId,
 [string]$Profile='p0-online-boutique',
 [Parameter(Mandatory)][string]$RuntimeStateRoot,
 [Parameter(Mandatory)][string]$OnlineBoutiqueSourceRoot,
 [switch]$ExecutionApproved
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'kubernetes-optional-property.ps1')
. (Join-Path $PSScriptRoot 'host-event-recordid.ps1')
. (Join-Path $PSScriptRoot 'native-command-capture.ps1')
$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path;$namespace='online-boutique';$base=Join-Path $repo 'p0-env\config\online-boutique'
$expectedSourceRevision='5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb';$predecessorRevision='09bf0e077f291318df561f16e48d38cc805ebcd7'
$root=Join-Path $repo "p0-env\artifacts\P2-NETWORK-DELAY-BASE-READINESS-DIAG-001\$DiagnosticId"
function NowUtc{[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')}
function WriteJson([string]$Path,[object]$Value){New-Item -ItemType Directory -Path(Split-Path -Parent $Path)-Force|Out-Null;[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 80),[Text.UTF8Encoding]::new($false))}
function KJson([string[]]$KubectlArguments){$raw=& minikube kubectl --profile $Profile -- @KubectlArguments 2>&1;if($LASTEXITCODE){throw "kubectl_failed:$($raw-join' | ')"};($raw-join"`n")|ConvertFrom-Json}
function CaptureText([string]$Name,[scriptblock]$Command){$lines=@(& $Command 2>&1)|ForEach-Object{[string]$_};[IO.File]::WriteAllLines((Join-Path $root $Name),$lines,[Text.UTF8Encoding]::new($false))}
function Snapshot{$pods=KJson @('-n',$namespace,'get','pods','-l','app=recommendationservice','-o','json');[ordered]@{observed_utc=NowUtc;pods=@($pods.items|ForEach-Object{ConvertTo-KubernetesPodView $_})}}
function AssertPinnedSource{if(-not(Test-Path -LiteralPath $source -PathType Container)){throw 'online_boutique_source_missing'};$actual=@(& git -C $source rev-parse HEAD 2>&1);if($LASTEXITCODE){throw 'online_boutique_source_revision_unreadable'};$actualRevision=($actual-join'').Trim();if($actualRevision-ne$expectedSourceRevision){throw "online_boutique_source_revision_mismatch:$actualRevision"}}
function AssertStoppedRecoveredProfile{
 $profileConfigPath=Join-Path $runtimeState '.minikube\profiles\p0-online-boutique\config.json'
 if(-not(Test-Path -LiteralPath $profileConfigPath -PathType Leaf)){throw 'recovered_profile_config_missing'}
 $profileConfig=Get-Content -LiteralPath $profileConfigPath -Raw|ConvertFrom-Json
 if($profileConfig.Name-ne$p0Profile-or$profileConfig.Driver-ne'docker'-or[int]$profileConfig.CPUs-ne4-or[int]$profileConfig.Memory-ne6144-or[int]$profileConfig.DiskSize-ne32768-or$profileConfig.KubernetesConfig.KubernetesVersion-ne'v1.34.0'-or$profileConfig.KubernetesConfig.ContainerRuntime-ne'containerd'){throw 'recovered_profile_contract_mismatch'}
 $containerRaw=@(& docker inspect --type container $p0Profile 2>&1);if($LASTEXITCODE){throw 'recovered_profile_container_missing'};$containers=@(($containerRaw-join"`n")|ConvertFrom-Json)
 if($containers.Count-ne1-or$containers[0].Name-ne"/$p0Profile"-or$containers[0].State.Running-ne$false-or$containers[0].State.Status-ne'exited'-or[int]$containers[0].State.ExitCode-ne130-or$containers[0].State.OOMKilled-ne$false){throw 'recovered_profile_container_state_mismatch'}
 $volumeRaw=@(& docker volume inspect $p0Profile 2>&1);if($LASTEXITCODE){throw 'recovered_profile_volume_missing'};$volumes=@(($volumeRaw-join"`n")|ConvertFrom-Json)
 if($volumes.Count-ne1-or$volumes[0].Name-ne$p0Profile){throw 'recovered_profile_volume_mismatch'}
 [ordered]@{schema_version=1;predecessor_decision='D-094';predecessor_diagnostic_id='ob-docker-disk-recovery-001';predecessor_merge_revision=$predecessorRevision;runtime_state_root_resolved=$runtimeState;source_root_resolved=$source;profile_config=$profileConfigPath;profile=$p0Profile;driver='docker';kubernetes_version='v1.34.0';cpus=4;memory_mib=6144;disk_mib=32768;container_runtime='containerd';container_status='exited';container_exit_code=130;container_oom_killed=$false;volume_present=$true;passed=$true}
}
if(-not$ExecutionApproved){throw 'explicit_diagnostic_approval_required'}
$closedDiagnosticIds=@('ob-network-base-readiness-008');$allowedDiagnosticIds=@()
if($DiagnosticId-in$closedDiagnosticIds){throw 'closed_diagnostic_id'}
if($DiagnosticId-notin$allowedDiagnosticIds){throw 'no_preregistered_diagnostic_id'}
if($Profile-ne'p0-online-boutique'){throw 'unexpected_profile'}
if(@(& git -C $repo status --porcelain).Count){throw 'working_tree_not_clean'}
if(Test-Path $root){throw 'immutable_diagnostic_output_exists'}
if(-not(Test-Path -LiteralPath $RuntimeStateRoot -PathType Container)){throw 'runtime_state_root_missing'}
if(-not(Test-Path -LiteralPath $OnlineBoutiqueSourceRoot -PathType Container)){throw 'online_boutique_source_missing'}
$runtimeState=(Resolve-Path -LiteralPath $RuntimeStateRoot -ErrorAction Stop).Path
$source=(Resolve-Path -LiteralPath $OnlineBoutiqueSourceRoot -ErrorAction Stop).Path
$env:MINIKUBE_HOME=$runtimeState;$p0Profile='p0-online-boutique'
AssertPinnedSource
$preflight=AssertStoppedRecoveredProfile
if(-not$PSCmdlet.ShouldProcess($DiagnosticId,'run no-fault base readiness diagnosis')){return}
New-Item -ItemType Directory -Path $root|Out-Null
$hostBoundary=New-HostEventRecordIdBoundary;$stopped=$false;$observations=@();$available=$false;$stabilityStart=$null;$failure=$null
WriteJson(Join-Path $root 'host-before.json')$hostBoundary
WriteJson(Join-Path $root 'preflight-provenance.json')$preflight
WriteJson(Join-Path $root 'diagnostic-manifest.json')([ordered]@{schema_version=1;gate_id='P2-NETWORK-DELAY-BASE-READINESS-DIAG-001';diagnostic_id=$DiagnosticId;code_revision=(& git -C $repo rev-parse HEAD).Trim();predecessor_decision='D-094';predecessor_diagnostic_id='ob-docker-disk-recovery-001';predecessor_merge_revision=$predecessorRevision;runtime_state_root_resolved=$runtimeState;source_root_resolved=$source;base_config='p0-env/config/online-boutique';workload_profile_id='ob-default-10u-1r-v1';online_boutique_source_revision_expected=$expectedSourceRevision;proxy_overlay_applied=$false;toxic_created=$false;scientific_fault_started=$false;scientific_window_started=$false;dataset_inclusion=$false;headroom_decision_inclusion=$false})
try{
 $startCapture=Invoke-NativeCommandCapture -FilePath 'minikube' -ArgumentList @('start','--profile',$Profile,'--driver','docker','--kubernetes-version','v1.34.0','--cpus','4','--memory','6144mb','--disk-size','32g','--container-runtime','containerd')
 WriteJson(Join-Path $root 'minikube-start.json')([ordered]@{exit_code=$startCapture.exit_code;stdout=$startCapture.stdout;stderr=$startCapture.stderr})
 if($startCapture.exit_code-ne0){throw 'minikube_start_failed'}
 & minikube kubectl --profile $Profile -- apply -k $base|Out-Null;if($LASTEXITCODE){throw 'base_apply_failed'}
 & minikube kubectl --profile $Profile -- -n $namespace rollout restart deployment/opentelemetrycollector deployment/prometheus|Out-Null;if($LASTEXITCODE){throw 'observability_restart_failed'}
 $deadline=[datetimeoffset]::UtcNow.AddSeconds(900)
 do{$snap=Snapshot;$observations+=,$snap;$active=@($snap.pods|Where-Object{$null-eq$_.deletion_timestamp});if($active.Count-eq1){$ready=@($active[0].conditions|Where-Object{$_.type-eq'Ready'-and$_.status-eq'True'});if($ready.Count-eq1){$available=$true;break}};Start-Sleep -Seconds 5}while([datetimeoffset]::UtcNow-lt$deadline)
 if($available){$stabilityStart=[datetimeoffset]::UtcNow;$stabilityDeadline=$stabilityStart.AddSeconds(180);do{$observations+=,(Snapshot);Start-Sleep -Seconds 5}while([datetimeoffset]::UtcNow-lt$stabilityDeadline)}
 WriteJson(Join-Path $root 'readiness-observations.json')([ordered]@{convergence_timeout_seconds=900;stability_duration_seconds=180;poll_seconds=5;availability_reached=$available;stability_start_utc=$(if($stabilityStart){$stabilityStart.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')}else{$null});observations=$observations})
 WriteJson(Join-Path $root 'deployment.json')(KJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json'))
 WriteJson(Join-Path $root 'replicasets.json')(KJson @('-n',$namespace,'get','replicaset','-l','app=recommendationservice','-o','json'))
 WriteJson(Join-Path $root 'events.json')(KJson @('-n',$namespace,'get','events','--field-selector','involvedObject.kind=Pod','-o','json'))
 WriteJson(Join-Path $root 'node.json')(KJson @('get','node',$Profile,'-o','json'))
 $current=@((KJson @('-n',$namespace,'get','pods','-l','app=recommendationservice','-o','json')).items|Where-Object{$null-eq(Get-KubernetesOptionalProperty $_.metadata 'deletionTimestamp')}|Select-Object -First 1)
 if($current.Count){$pod=[string]$current[0].metadata.name;CaptureText 'pod-describe.txt' {& minikube kubectl --profile $Profile -- -n $namespace describe pod $pod};CaptureText 'server-current.log' {& minikube kubectl --profile $Profile -- -n $namespace logs $pod -c server --timestamps=true};CaptureText 'server-previous.log' {& minikube kubectl --profile $Profile -- -n $namespace logs $pod -c server --previous --timestamps=true}}
 CaptureText 'kubelet-journal.txt' {& minikube ssh --profile $Profile -- 'sudo journalctl -u kubelet --since "30 minutes ago" --no-pager'}
 $stableSamples=if($stabilityStart){@($observations|Where-Object{[datetimeoffset]::Parse($_.observed_utc)-ge$stabilityStart})}else{@()};$uids=@();$restarts=@();$allReady=$true;$badState=$false
 foreach($sample in $stableSamples){$pods=@($sample.pods|Where-Object{$null-eq$_.deletion_timestamp});if($pods.Count-ne1){$allReady=$false;continue};$uids+=,[string]$pods[0].uid;$server=@($pods[0].containers|Where-Object{$_.name-eq'server'});if($server.Count-ne1-or-not$server[0].ready){$allReady=$false;continue};$restarts+=,[int]$server[0].restart_count;if($null-ne(Get-KubernetesOptionalProperty $server[0].state 'waiting')-or$null-ne(Get-KubernetesOptionalProperty $server[0].state 'terminated')){$badState=$true}}
 $supported=$available-and$stableSamples.Count-ge30-and$allReady-and-not$badState-and@($uids|Select-Object -Unique).Count-eq1-and@($restarts|Select-Object -Unique).Count-eq1
 WriteJson(Join-Path $root 'assessment.json')([ordered]@{schema_version=1;diagnostic_id=$DiagnosticId;classification=$(if($supported){'fresh_base_stability_supported'}else{'fresh_base_stability_not_supported'});availability_reached=$available;stability_sample_count=$stableSamples.Count;unique_pod_uids=@($uids|Select-Object -Unique);restart_counts=@($restarts|Select-Object -Unique);all_samples_server_ready=$allReady;bad_container_state_observed=$badState;dataset_inclusion=$false;headroom_decision_inclusion=$false;causal_conclusion=$false;limitations=@('This no-fault diagnostic does not establish the cause of ob-netdelay-500m-normal-10u-002.','It does not validate the 500m no-toxic overlay or authorize a replacement normal run.')})
}
catch{$failure=$_.Exception.Message;WriteJson(Join-Path $root 'run-error.json')([ordered]@{failed_utc=NowUtc;error=$failure;scientific_fault_started=$false})}
finally{if(-not$stopped){& minikube stop --profile $Profile|Out-Null;$stopped=$true};try{WriteJson(Join-Path $root 'host-after.json')(Measure-HostEventsAfterRecordIdBoundary -Boundary $hostBoundary)}catch{WriteJson(Join-Path $root 'host-after-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}}
if($failure){& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create;throw "diagnostic_failed:$failure"}
$verifierOutput=@(& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'verify-network-base-readiness-diagnostic.ps1')-ArtifactRoot $root -ExpectedDiagnosticId $DiagnosticId 2>&1);$verifierExit=$LASTEXITCODE
$verifierOutput|ForEach-Object{Write-Output ([string]$_)}
if($verifierExit-ne0){& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create;throw "semantic_verifier_failed:$verifierExit"}
& pwsh -NoProfile -File(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-ArtifactRoot $root -Mode Create
Write-Output "network_base_readiness_diagnostic=completed id=$DiagnosticId"

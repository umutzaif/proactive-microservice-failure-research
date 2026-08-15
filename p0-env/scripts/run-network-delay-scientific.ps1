[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$RunId = 'ob-netdelay-15u-004',
    [string]$FaultProfileRelative = 'p0-env/config/faults/network-delay-recommendation-productcatalog-15u-v1.json',
    [string]$WorkloadProfileRelative = 'p0-env/config/workloads/ob-second-15u-1r-v1.json',
    [Parameter(Mandatory = $true)][string]$PythonPath,
    [Parameter(Mandatory = $true)][switch]$ExecutionApproved,
    [string]$Profile = 'p0-online-boutique'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'phase-duration.ps1')
. (Join-Path $PSScriptRoot 'canonical-utc.ps1')
. (Join-Path $PSScriptRoot 'proxy-pod-readiness.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$namespace = 'online-boutique'
$artifactRoot = Join-Path $repo "p0-env\artifacts\P2-NETWORK-DELAY-001\$RunId"
$metadataRoot = Join-Path $repo "p0-env\artifacts\scientific-run-metadata\$RunId"
$telemetryRoot = Join-Path $repo "p0-env\artifacts\telemetry\$RunId"
$rawRoot = Join-Path $repo "p0-env\artifacts\runs\$RunId"
$derivedRoot = Join-Path $repo "p0-env\artifacts\derived\$RunId"
$finalRoot = Join-Path $repo "p0-env\artifacts\finalized\$RunId"
$profilePath = Join-Path $repo ($FaultProfileRelative.Replace('/','\'))
$workloadPath = Join-Path $repo ($WorkloadProfileRelative.Replace('/','\'))
$sloRelative = 'p0-env/config/slo/p2-network-delay-001-slo-v1.json'
$sloPath = Join-Path $repo ($sloRelative.Replace('/','\'))
$baseConfig = Join-Path $repo 'p0-env\config\online-boutique'
$proxyConfig = Join-Path $repo 'p0-env\config\network-delay-design'
$draftPath = Join-Path $artifactRoot 'draft-metadata.json'
$rampPath = Join-Path $artifactRoot 'ramp-evidence.json'
$cleanupPath = Join-Path $artifactRoot 'cleanup-evidence.json'
$effectPath = Join-Path $artifactRoot 'injector-evidence.json'
$manifestationPath = Join-Path $artifactRoot 'manifestation-evidence.json'
$assessmentPath = Join-Path $artifactRoot 'run-assessment.json'
$metadataPath = Join-Path $metadataRoot 'scientific-run-metadata.json'
$stabilityPath = Join-Path $artifactRoot 'target-pod-stability.json'
$portForward = $null
$faultStarted = $false
$cleanupVerified = $false
$rollbackVerified = $false
$stopped = $false
$captureStart = $null

function NowUtc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function WriteJson([string]$Path,[object]$Value) { New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null; [IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 40),(New-Object Text.UTF8Encoding($false))) }
function Hash([string]$Relative) { (Get-FileHash (Join-Path $repo ($Relative.Replace('/','\'))) -Algorithm SHA256).Hash.ToLowerInvariant() }
function HostCounts { [ordered]@{whea_event_17=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WHEA-Logger';Id=17} -ErrorAction SilentlyContinue).Count;kernel_power_41=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Kernel-Power';Id=41} -ErrorAction SilentlyContinue).Count;bugcheck=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WER-SystemErrorReporting';Id=1001} -ErrorAction SilentlyContinue).Count} }
function Native([string]$Name,[scriptblock]$Command) { Write-Output "step_started=$Name"; $out=& $Command 2>&1; $code=$LASTEXITCODE; $out|ForEach-Object{Write-Output([string]$_)}; if($code-ne 0){throw "step_failed:$Name exit=$code"}; Write-Output "step_passed=$Name" }
function InvokeScript([string]$Name,[string]$Path,[object[]]$Arguments) { Native $Name { & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments } }
function KubectlJson([string[]]$Arguments) { $raw=& minikube kubectl --profile $Profile -- @Arguments 2>&1;if($LASTEXITCODE-ne 0){throw "kubectl_failed:$($raw-join ' | ')"};return(($raw-join"`n")|ConvertFrom-Json) }
function SnapshotPods([string]$Name) {
    $pods=KubectlJson @('-n',$namespace,'get','pods','-o','json');$result=[ordered]@{}
    foreach($pod in @($pods.items)){ $app=[string]$pod.metadata.labels.app;if(-not $app){continue};if($result.Contains($app)){throw "multiple_pods_for_app:$app"};$statuses=[ordered]@{};foreach($c in @($pod.status.containerStatuses)){$statuses[[string]$c.name]=[ordered]@{container_id=[string]$c.containerID;restart_count=[int]$c.restartCount;ready=[bool]$c.ready}};$result[$app]=[ordered]@{pod_name=[string]$pod.metadata.name;uid=[string]$pod.metadata.uid;containers=$statuses} }
    if($result.Count-ne 15){throw "tracked_pod_count_invalid:$($result.Count)"};WriteJson(Join-Path $artifactRoot "$Name.json")([ordered]@{observed_utc=NowUtc;components=$result});return $result
}
function Same([object]$A,[object]$B){(($A|ConvertTo-Json -Depth 20 -Compress)-eq($B|ConvertTo-Json -Depth 20 -Compress))}
function WaitForSingleReadyProxyPod {
    param([int]$TimeoutSeconds=120,[int]$PollSeconds=5)
    $deadline=[datetimeoffset]::UtcNow.AddSeconds($TimeoutSeconds);$observations=@()
    do {
        $pods=KubectlJson @('-n',$namespace,'get','pods','-l','app=recommendationservice','-o','json')
        $items=@($pods.items);$ready=$false;$podName=$null
        if($items.Count-eq 1){$podName=[string]$items[0].metadata.name;$ready=Test-SingleReadyProxyPod -Items $items}
        $observations+=,[ordered]@{observed_utc=NowUtc;pod_count=$items.Count;pod_name=$podName;ready=$ready}
        if($ready){WriteJson(Join-Path $artifactRoot 'proxy-pod-convergence.json')([ordered]@{passed=$true;timeout_seconds=$TimeoutSeconds;poll_seconds=$PollSeconds;observations=$observations});return}
        Start-Sleep -Seconds $PollSeconds
    }while([datetimeoffset]::UtcNow-lt$deadline)
    WriteJson(Join-Path $artifactRoot 'proxy-pod-convergence.json')([ordered]@{passed=$false;timeout_seconds=$TimeoutSeconds;poll_seconds=$PollSeconds;observations=$observations})
    throw 'live_proxy_single_ready_pod_timeout'
}
function StartProxyForward {
    $exe=(Get-Command minikube -ErrorAction Stop).Source;$stdout=Join-Path $artifactRoot 'proxy-port-forward.stdout.log';$stderr=Join-Path $artifactRoot 'proxy-port-forward.stderr.log'
    $script:portForward=Start-Process -FilePath $exe -ArgumentList @('kubectl','--profile',$Profile,'--','-n',$namespace,'port-forward','deployment/recommendationservice','18474:8474') -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr;Start-Sleep -Seconds 4
}
function StopProxyForward { if($null-ne $script:portForward-and-not $script:portForward.HasExited){Stop-Process -Id $script:portForward.Id -Force;$script:portForward.WaitForExit()};$script:portForward=$null }
function ResetProxy([string]$EvidencePath) { & $PythonPath (Join-Path $PSScriptRoot 'manage-network-delay-toxic.py') --api-base http://127.0.0.1:18474 --profile $profilePath --action cleanup --evidence $EvidencePath;if($LASTEXITCODE-ne 0){throw 'network_delay_cleanup_failed'};$script:cleanupVerified=$true }
function AssertLiveProxyContract {
    $deployment=KubectlJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json');$containers=@($deployment.spec.template.spec.containers)
    $deploymentNames=(@($containers.name|Sort-Object)-join ',')
    if($deploymentNames-ne'network-delay-proxy,server'){throw 'live_proxy_container_set_mismatch'}
    $server=@($containers|Where-Object{$_.name-eq'server'})[0];$proxy=@($containers|Where-Object{$_.name-eq'network-delay-proxy'})[0]
    $address=@($server.env|Where-Object{$_.name-eq'PRODUCT_CATALOG_SERVICE_ADDR'});if($address.Count-ne 1-or$address[0].value-ne'127.0.0.1:3551'){throw 'live_proxy_address_mismatch'}
    if($proxy.image-ne$faultProfile.injector.image-or$proxy.securityContext.privileged-ne$false-or$proxy.securityContext.allowPrivilegeEscalation-ne$false-or(@($proxy.securityContext.capabilities.drop)-join',')-ne'ALL'){throw 'live_proxy_image_or_security_mismatch'}
    $pods=KubectlJson @('-n',$namespace,'get','pods','-l','app=recommendationservice','-o','json');if(@($pods.items).Count-ne 1){throw 'live_proxy_pod_count_mismatch'}
    $podNames=(@($pods.items[0].spec.containers.name|Sort-Object)-join ',')
    if($podNames-ne'network-delay-proxy,server'){throw 'live_proxy_pod_container_set_mismatch'}
    WriteJson(Join-Path $artifactRoot 'live-proxy-contract.json')([ordered]@{verified_utc=NowUtc;passed=$true;image=[string]$proxy.image;containers=@($containers.name);address=[string]$address[0].value})
}
function EmergencyCapture {
    if($null-eq$script:captureStart){return}
    $end=NowUtc
    if(-not(Test-Path $rawRoot)){try{InvokeScript 'emergency_archive_raw_logs' (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') @('-RunId',$RunId,'-SinceUtc',$script:captureStart,'-UntilUtc',$end)}catch{WriteJson(Join-Path $artifactRoot 'emergency-raw-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}}
    if(-not(Test-Path $telemetryRoot)){try{InvokeScript 'emergency_archive_telemetry' (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') @('-RunId',$RunId,'-StartUtc',$script:captureStart,'-EndUtc',$end,'-MetricStepSeconds','5','-TraceLimitPerService','5000','-TraceQueryChunkSeconds','300')}catch{WriteJson(Join-Path $artifactRoot 'emergency-telemetry-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}}
    WriteJson(Join-Path $artifactRoot 'emergency-capture.json')([ordered]@{attempted_utc=NowUtc;start_utc=$script:captureStart;end_utc=$end;raw_exists=(Test-Path $rawRoot);telemetry_exists=(Test-Path $telemetryRoot)})
}
function Rollback {
    StopProxyForward
    Native 'rollback_apply_base' { & minikube kubectl --profile $Profile -- apply -k $baseConfig }
    Native 'rollback_wait_recommendation' { & minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m }
    Native 'rollback_delete_proxy_configmap' { & minikube kubectl --profile $Profile -- -n $namespace delete configmap network-delay-proxy-config --ignore-not-found=true }
    $d=KubectlJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json');$containers=@($d.spec.template.spec.containers);$address=@($containers[0].env|Where-Object{$_.name-eq'PRODUCT_CATALOG_SERVICE_ADDR'})
    if($containers.Count-ne 1-or $containers[0].name-ne'server'-or $address.Count-ne 1-or $address[0].value-ne'productcatalogservice:3550'){throw 'rollback_contract_failed'}
    WriteJson(Join-Path $artifactRoot 'rollback-verification.json')([ordered]@{verified_utc=NowUtc;passed=$true;containers=@($containers.name);product_catalog_address=[string]$address[0].value;proxy_configmap_absent=$true});$script:rollbackVerified=$true
}

if(-not $ExecutionApproved){throw 'explicit_runtime_execution_approval_required'}
if(-not(Test-Path $PythonPath -PathType Leaf)){throw 'python_runtime_missing'}
if($RunId-ne'ob-netdelay-15u-004'){throw 'unexpected_run_id'}
if(@(& git -C $repo status --porcelain).Count-ne 0){throw 'working_tree_not_clean'}
foreach($path in @($artifactRoot,$metadataRoot,$telemetryRoot,$rawRoot,$derivedRoot,$finalRoot)){if(Test-Path $path){throw "immutable_output_already_exists:$path"}}
$faultProfile=Get-Content $profilePath -Raw|ConvertFrom-Json;$workload=Get-Content $workloadPath -Raw|ConvertFrom-Json
if($faultProfile.scientific_run_id-ne$RunId-or$faultProfile.workload_profile_id-ne'ob-second-15u-1r-v1'){throw 'profile_binding_mismatch'}
if([int]$workload.loadgenerator.users-ne 15-or[int]$workload.loadgenerator.spawn_rate_per_second-ne 1-or[int]$workload.loadgenerator.random_seed-ne 1){throw 'workload_contract_mismatch'}
if(-not $PSCmdlet.ShouldProcess($RunId,'execute preregistered scientific network-delay run')){return}

New-Item -ItemType Directory -Path $artifactRoot -Force|Out-Null
$codeRevision=(& git -C $repo rev-parse HEAD).Trim();$hostBefore=HostCounts;$resetUtc=NowUtc;$failure=$null
WriteJson(Join-Path $artifactRoot 'host-before.json')([ordered]@{observed_utc=NowUtc;counts=$hostBefore})
try {
    Native 'deploy_base' { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'deploy.ps1') }
    Native 'apply_proxy_overlay' { & minikube kubectl --profile $Profile -- apply -k $proxyConfig }
    Native 'wait_proxy_rollout' { & minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m }
    WaitForSingleReadyProxyPod -TimeoutSeconds 120 -PollSeconds 5
    InvokeScript 'active_run_id' (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    InvokeScript 'active_workload' (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') @('-ExpectedProfileRelative',$WorkloadProfileRelative)
    & $PythonPath (Join-Path $PSScriptRoot 'verify-network-delay-proxy-overlay.py') --overlay-root $proxyConfig
    if($LASTEXITCODE-ne 0){throw 'proxy_overlay_verification_failed'}
    AssertLiveProxyContract
    StartProxyForward
    & $PythonPath (Join-Path $PSScriptRoot 'manage-network-delay-proxy.py') --api-base http://127.0.0.1:18474 --profile (Join-Path $repo 'p0-env/config/faults/network-delay-recommendation-productcatalog-v1.json') --action verify-clean --evidence (Join-Path $artifactRoot 'preflight-proxy-clean.json')
    if($LASTEXITCODE-ne 0){throw 'preflight_proxy_not_clean'}
    InvokeScript 'target_stability' (Join-Path $PSScriptRoot 'verify-target-pod-stability.ps1') @('-Namespace',$namespace,'-Deployment','recommendationservice','-Container','server','-EvidencePath',$stabilityPath,'-Profile',$Profile,'-DurationSeconds','120','-PollSeconds','5')

    $warmupStart=NowUtc;$captureStart=$warmupStart;$warmupEnd=Wait-UntilMinimumUtcDuration -StartUtc $warmupStart -MinimumSeconds 300
    $baseBefore=SnapshotPods 'baseline-before';$baselineStart=NowUtc;$baselineEnd=Wait-UntilMinimumUtcDuration -StartUtc $baselineStart -MinimumSeconds 300;$baseAfter=SnapshotPods 'baseline-after';$baseStable=Same $baseBefore $baseAfter
    $faultStarted=$true
    & $PythonPath (Join-Path $PSScriptRoot 'manage-network-delay-toxic.py') --api-base http://127.0.0.1:18474 --profile $profilePath --action ramp --evidence $rampPath
    if($LASTEXITCODE-ne 0){throw 'toxic_ramp_failed'}
    $ramp=Get-Content $rampPath -Raw|ConvertFrom-Json;$injectionStart=ConvertTo-CanonicalUtcString $ramp.ramp_start_utc;$rampEnd=ConvertTo-CanonicalUtcString $ramp.ramp_end_utc
    $steadyBefore=SnapshotPods 'steady-before';$injectionEnd=Wait-UntilMinimumUtcDuration -StartUtc $rampEnd -MinimumSeconds 300;$steadyAfter=SnapshotPods 'steady-after';$steadyStable=Same $steadyBefore $steadyAfter
    ResetProxy $cleanupPath;$cleanup=Get-Content $cleanupPath -Raw|ConvertFrom-Json;$cooldownStart=ConvertTo-CanonicalUtcString $cleanup.cleanup_utc
    $cooldownBefore=SnapshotPods 'cooldown-before';$cooldownEnd=Wait-UntilMinimumUtcDuration -StartUtc $cooldownStart -MinimumSeconds 300;$cooldownAfter=SnapshotPods 'cooldown-after';$cooldownStable=Same $cooldownBefore $cooldownAfter
    $phases=[ordered]@{reset_health_check_utc=$resetUtc;warmup_start_utc=$warmupStart;warmup_end_utc=$warmupEnd;normal_baseline_start_utc=$baselineStart;normal_baseline_end_utc=$baselineEnd;injection_start_utc=$injectionStart;ramp_end_utc=$rampEnd;injection_end_utc=$injectionEnd;cooldown_start_utc=$cooldownStart;cooldown_end_utc=$cooldownEnd}
    WriteJson $draftPath([ordered]@{run_id=$RunId;fault_profile=[string]$faultProfile.profile_id;phases=$phases})
    InvokeScript 'archive_raw_logs' (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') @('-RunId',$RunId,'-SinceUtc',$warmupStart,'-UntilUtc',$cooldownEnd)
    InvokeScript 'verify_raw_logs' (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') @('-ArchivePath',$rawRoot)
    InvokeScript 'enrich_logs' (Join-Path $PSScriptRoot 'enrich-log-run-id.ps1') @('-ArchivePath',$rawRoot)
    InvokeScript 'verify_enriched_logs' (Join-Path $PSScriptRoot 'verify-enriched-logs.ps1') @('-DerivedPath',$derivedRoot)
    InvokeScript 'archive_telemetry' (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$cooldownEnd,'-MetricStepSeconds','5','-TraceLimitPerService','5000','-TraceQueryChunkSeconds','300')
    InvokeScript 'verify_telemetry' (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') @('-TelemetryPath',$telemetryRoot)
    & $PythonPath (Join-Path $PSScriptRoot 'analyze-network-delay-fault-effect.py') --telemetry-root $telemetryRoot --draft-metadata $draftPath --fault-profile $profilePath --ramp-evidence $rampPath --cleanup-evidence $cleanupPath --output $effectPath;$effectExit=$LASTEXITCODE
    & $PythonPath (Join-Path $PSScriptRoot 'detect-fault-manifestation.py') --telemetry-root $telemetryRoot --draft-metadata $draftPath --slo-config $sloPath --output $manifestationPath;if($LASTEXITCODE-ne 0){throw 'manifestation_detection_failed'}
    StopProxyForward;Rollback
    Native 'stop_minikube' { & minikube stop --profile $Profile };$stopped=$true;$hostAfter=HostCounts
    $hostHealth=[ordered]@{whea_event_17_before=$hostBefore.whea_event_17;whea_event_17_after=$hostAfter.whea_event_17;whea_event_17_delta=($hostAfter.whea_event_17-$hostBefore.whea_event_17);kernel_power_41_before=$hostBefore.kernel_power_41;kernel_power_41_after=$hostAfter.kernel_power_41;kernel_power_41_delta=($hostAfter.kernel_power_41-$hostBefore.kernel_power_41);bugcheck_before=$hostBefore.bugcheck;bugcheck_after=$hostAfter.bugcheck;bugcheck_delta=($hostAfter.bugcheck-$hostBefore.bugcheck)}
    WriteJson(Join-Path $artifactRoot 'host-after.json')([ordered]@{observed_utc=NowUtc;counts=$hostAfter;deltas=$hostHealth})
    $effect=Get-Content $effectPath -Raw|ConvertFrom-Json;$manifestation=Get-Content $manifestationPath -Raw|ConvertFrom-Json
    $valid=($effectExit-eq 0-and[bool]$effect.physical_effect_verified-and$baseStable-and$steadyStable-and$cooldownStable-and$cleanupVerified-and$rollbackVerified-and$hostHealth.whea_event_17_delta-eq 0-and$hostHealth.kernel_power_41_delta-eq 0-and$hostHealth.bugcheck_delta-eq 0)
    $metadata=[ordered]@{schema_version=1;run_id=$RunId;experiment_id='P2-NETWORK-DELAY-001';run_kind='fault_calibration';system='online-boutique';code_revision=$codeRevision;deployment_revision="kustomization_sha256:$(Hash 'p0-env/config/online-boutique/kustomization.yaml');observability_sha256:$(Hash 'p0-env/config/online-boutique/observability.yaml')";fault_class='network_delay';target_service='recommendationservice';target_edge='recommendationservice->productcatalogservice';fault_profile=[string]$faultProfile.profile_id;fault_profile_path=$FaultProfileRelative;fault_profile_sha256=(Hash $FaultProfileRelative);slo_id='p2-network-delay-001-slo-v1';slo_path=$sloRelative;slo_sha256=(Hash $sloRelative);workload_profile_id=[string]$workload.profile_id;workload_profile_path=$WorkloadProfileRelative;workload_profile_sha256=(Hash $WorkloadProfileRelative);random_seed=[int]$workload.loadgenerator.random_seed;injector_evidence_path="p0-env/artifacts/P2-NETWORK-DELAY-001/$RunId/injector-evidence.json";injector_evidence_sha256=(Get-FileHash $effectPath -Algorithm SHA256).Hash.ToLowerInvariant();manifestation_evidence_path="p0-env/artifacts/P2-NETWORK-DELAY-001/$RunId/manifestation-evidence.json";manifestation_evidence_sha256=(Get-FileHash $manifestationPath -Algorithm SHA256).Hash.ToLowerInvariant();failure_manifestation=$manifestation.failure_manifestation;first_symptom_utc=$effect.first_symptom_utc;phases=$phases;host_health=$hostHealth;runtime_evidence=[ordered]@{tracked_deployment_count=15;baseline_stable=$baseStable;steady_stable=$steadyStable;cooldown_stable=$cooldownStable;target_stability='passed';cleanup_verified=$cleanupVerified;rollback_verified=$rollbackVerified};valid_run=$valid}
    WriteJson $metadataPath $metadata;WriteJson $assessmentPath([ordered]@{run_id=$RunId;valid_run=$valid;physical_effect_verified=[bool]$effect.physical_effect_verified;coverage_verified=[bool]$effect.coverage_verified;cleanup_verified=$cleanupVerified;pod_lifecycle_stable=($baseStable-and$steadyStable-and$cooldownStable);host_health=$hostHealth;first_symptom_utc=$effect.first_symptom_utc;failure_manifestation=$manifestation.failure_manifestation})
    & $PythonPath (Join-Path $PSScriptRoot 'verify-network-delay-scientific-metadata.py') --repo-root $repo --metadata $metadataPath;if($LASTEXITCODE-ne 0){throw 'network_delay_metadata_verification_failed'}
    InvokeScript 'finalize_receipt' (Join-Path $PSScriptRoot 'finalize-run-artifacts.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$cooldownEnd,'-ScientificRunMetadataPath',$metadataPath)
    InvokeScript 'verify_finalized_receipt' (Join-Path $PSScriptRoot 'verify-finalized-run.ps1') @('-ReceiptPath',$finalRoot)
    if(-not $valid){throw 'scientific_validity_gate_failed_evidence_preserved'}
    Write-Output "network_delay_scientific_run=valid run_id=$RunId"
}
catch { $failure=$_;WriteJson(Join-Path $artifactRoot 'run-error.json')([ordered]@{run_id=$RunId;status='invalid_or_incomplete';failed_utc=NowUtc;fault_started=$faultStarted;error=$_.Exception.Message});throw }
finally {
    if($faultStarted-and-not$cleanupVerified-and$null-ne$portForward){try{ResetProxy(Join-Path $artifactRoot 'emergency-cleanup-evidence.json')}catch{WriteJson(Join-Path $artifactRoot 'emergency-cleanup-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}}
    if($faultStarted-and(-not(Test-Path $finalRoot))){EmergencyCapture}
    if(-not$rollbackVerified){try{Rollback}catch{WriteJson(Join-Path $artifactRoot 'rollback-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}}
    if(-not$stopped){& minikube stop --profile $Profile 2>&1|ForEach-Object{Write-Output([string]$_)};$stopped=$true}
    if(-not(Test-Path(Join-Path $artifactRoot 'host-after.json'))){$hostAfter=HostCounts;$hostHealth=[ordered]@{whea_event_17_before=$hostBefore.whea_event_17;whea_event_17_after=$hostAfter.whea_event_17;whea_event_17_delta=($hostAfter.whea_event_17-$hostBefore.whea_event_17);kernel_power_41_before=$hostBefore.kernel_power_41;kernel_power_41_after=$hostAfter.kernel_power_41;kernel_power_41_delta=($hostAfter.kernel_power_41-$hostBefore.kernel_power_41);bugcheck_before=$hostBefore.bugcheck;bugcheck_after=$hostAfter.bugcheck;bugcheck_delta=($hostAfter.bugcheck-$hostBefore.bugcheck)};WriteJson(Join-Path $artifactRoot 'host-after.json')([ordered]@{observed_utc=NowUtc;counts=$hostAfter;deltas=$hostHealth;capture_mode='finally_after_cluster_stop'})}
}

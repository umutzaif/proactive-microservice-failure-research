[CmdletBinding(SupportsShouldProcess=$true,ConfirmImpact='High')]
param(
    [string]$DiagnosticId='ob-network-server-termination-001',
    [string]$Profile='p0-online-boutique',
    [switch]$ExecutionApproved
)

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'kubernetes-optional-property.ps1')
$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path
$namespace='online-boutique';$base=Join-Path $repo 'p0-env\config\online-boutique';$overlay=Join-Path $repo 'p0-env\config\network-delay-design'
$experiment=if($DiagnosticId-eq'ob-network-probe-resource-001'){'P2-NETWORK-DELAY-PROBE-RESOURCE-DIAG-001'}else{'P2-NETWORK-DELAY-SERVER-TERMINATION-DIAG-001'}
$root=Join-Path $repo "p0-env\artifacts\$experiment\$DiagnosticId"
function NowUtc{[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')}
function WriteJson([string]$Path,[object]$Value){New-Item -ItemType Directory -Path(Split-Path -Parent $Path)-Force|Out-Null;[IO.File]::WriteAllText($Path,($Value|ConvertTo-Json -Depth 60),[Text.UTF8Encoding]::new($false))}
function KJson([string[]]$Arguments){$raw=& minikube kubectl --profile $Profile -- @Arguments 2>&1;if($LASTEXITCODE){throw"kubectl_failed:$($raw-join' | ')"};($raw-join"`n")|ConvertFrom-Json}
function QueryPrometheus([string]$StartUtc,[string]$EndUtc){$names='container_cpu_usage_seconds_total|container_cpu_cfs_periods_total|container_cpu_cfs_throttled_periods_total|container_cpu_cfs_throttled_seconds_total|container_memory_working_set_bytes|container_memory_rss|container_memory_usage_bytes|container_memory_failcnt|container_oom_events_total|container_pressure_cpu_stalled_seconds_total|container_pressure_cpu_waiting_seconds_total|container_pressure_memory_stalled_seconds_total|container_pressure_memory_waiting_seconds_total';$query='{experiment_run_id="ob-netdelay-15u-005",namespace="online-boutique",pod=~"recommendationservice-.*",container="server",__name__=~"'+$names+'"}';$path='/api/v1/namespaces/online-boutique/services/http:prometheus:9090/proxy/api/v1/query_range?query='+[uri]::EscapeDataString($query)+'&start='+[uri]::EscapeDataString($StartUtc)+'&end='+[uri]::EscapeDataString($EndUtc)+'&step=5';$response=KJson @('get','--raw',$path);if($response.status-ne'success'-or$response.data.resultType-ne'matrix'){throw'prometheus_resource_query_failed'};WriteJson(Join-Path $root 'prometheus-resource-metrics.json')$response}
function CaptureText([string]$Name,[scriptblock]$Command){$text=@(& $Command 2>&1)|ForEach-Object{[string]$_};[IO.File]::WriteAllLines((Join-Path $root $Name),$text,[Text.UTF8Encoding]::new($false))}
function HostCounts{[ordered]@{whea_event_17=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WHEA-Logger';Id=17}-ErrorAction SilentlyContinue).Count;kernel_power_41=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Kernel-Power';Id=41}-ErrorAction SilentlyContinue).Count;bugcheck=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WER-SystemErrorReporting';Id=1001}-ErrorAction SilentlyContinue).Count}}
function Rollback{& minikube kubectl --profile $Profile -- apply -k $base|Out-Null;if($LASTEXITCODE){throw'rollback_apply_failed'};& minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m|Out-Null;if($LASTEXITCODE){throw'rollback_rollout_failed'};& minikube kubectl --profile $Profile -- -n $namespace delete configmap network-delay-proxy-config --ignore-not-found=true|Out-Null;$d=KJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json');$containers=@($d.spec.template.spec.containers);$address=@($containers[0].env|Where-Object{$_.name-eq'PRODUCT_CATALOG_SERVICE_ADDR'});$ok=($containers.Count-eq1-and$containers[0].name-eq'server'-and$address[0].value-eq'productcatalogservice:3550');WriteJson(Join-Path $root 'rollback.json')([ordered]@{verified_utc=NowUtc;passed=$ok;containers=@($containers.name);address=[string]$address[0].value});if(-not$ok){throw'rollback_contract_failed'}}

if(-not$ExecutionApproved){throw'explicit_diagnostic_approval_required'}
if($DiagnosticId-notin@('ob-network-server-termination-001','ob-network-probe-resource-001')){throw'unexpected_diagnostic_id'}
if(@(& git -C $repo status --porcelain).Count){throw'working_tree_not_clean'}
if(Test-Path $root){throw'immutable_diagnostic_output_exists'}
if(-not$PSCmdlet.ShouldProcess($DiagnosticId,'run no-fault server termination diagnosis')){return}
New-Item -ItemType Directory -Path $root|Out-Null
$before=HostCounts;$rollback=$false;$stopped=$false
WriteJson(Join-Path $root 'host-before.json')([ordered]@{observed_utc=NowUtc;counts=$before})
try{
    & pwsh -NoProfile -File(Join-Path $PSScriptRoot 'deploy.ps1');if($LASTEXITCODE){throw'deploy_failed'}
    & minikube kubectl --profile $Profile -- apply -k $overlay|Out-Null;if($LASTEXITCODE){throw'overlay_apply_failed'}
    & minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m|Out-Null;if($LASTEXITCODE){throw'overlay_rollout_failed'}
    WriteJson(Join-Path $root 'deployment.json')(KJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json'))
    WriteJson(Join-Path $root 'node-before.json')(KJson @('get','node','p0-online-boutique','-o','json'))
    $start=[datetimeoffset]::UtcNow;$startUtc=$start.ToString('yyyy-MM-ddTHH:mm:ss.fffZ');$deadline=$start.AddSeconds(180);$observations=@()
    do{
        $pods=KJson @('-n',$namespace,'get','pods','-l','app=recommendationservice','-o','json');$podViews=@()
        foreach($pod in @($pods.items)){$podViews+=,[ordered]@{name=[string]$pod.metadata.name;uid=[string]$pod.metadata.uid;deletion_timestamp=(Get-KubernetesOptionalProperty $pod.metadata 'deletionTimestamp');phase=[string]$pod.status.phase;qos_class=[string](Get-KubernetesOptionalProperty $pod.status 'qosClass');conditions=@($pod.status.conditions|ForEach-Object{[ordered]@{type=[string]$_.type;status=[string]$_.status;reason=(Get-KubernetesOptionalProperty $_ 'reason');message=(Get-KubernetesOptionalProperty $_ 'message')}});containers=@($pod.status.containerStatuses|ForEach-Object{[ordered]@{name=[string]$_.name;ready=[bool]$_.ready;started=(Get-KubernetesOptionalProperty $_ 'started');restart_count=[int]$_.restartCount;container_id=[string]$_.containerID;state=(Get-KubernetesOptionalProperty $_ 'state');last_state=(Get-KubernetesOptionalProperty $_ 'lastState')}})}}
        $observations+=,[ordered]@{observed_utc=NowUtc;pods=$podViews};Start-Sleep -Seconds 5
    }while([datetimeoffset]::UtcNow-lt$deadline)
    $endUtc=[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    WriteJson(Join-Path $root 'pod-observations.json')([ordered]@{duration_seconds=180;poll_seconds=5;observations=$observations})
    if($DiagnosticId-eq'ob-network-probe-resource-001'){QueryPrometheus $startUtc $endUtc}
    WriteJson(Join-Path $root 'replicasets.json')(KJson @('-n',$namespace,'get','replicaset','-l','app=recommendationservice','-o','json'))
    WriteJson(Join-Path $root 'events.json')(KJson @('-n',$namespace,'get','events','--field-selector','involvedObject.kind=Pod','-o','json'))
    WriteJson(Join-Path $root 'node-after.json')(KJson @('get','node','p0-online-boutique','-o','json'))
    CaptureText 'metrics-api.txt' {& minikube kubectl --profile $Profile -- get --raw /apis/metrics.k8s.io/v1beta1/namespaces/$namespace/pods}
    $current=@((KJson @('-n',$namespace,'get','pods','-l','app=recommendationservice','-o','json')).items|Where-Object{$null-eq(Get-KubernetesOptionalProperty $_.metadata 'deletionTimestamp')}|Select-Object -First 1)
    if($current.Count){$pod=[string]$current[0].metadata.name;CaptureText 'pod-describe.txt' {& minikube kubectl --profile $Profile -- -n $namespace describe pod $pod};foreach($container in @('server','network-delay-proxy')){CaptureText "$container-current.log" {& minikube kubectl --profile $Profile -- -n $namespace logs $pod -c $container --timestamps=true};CaptureText "$container-previous.log" {& minikube kubectl --profile $Profile -- -n $namespace logs $pod -c $container --previous --timestamps=true}}}
    CaptureText 'kubelet-journal.txt' {& minikube ssh --profile $Profile -- 'sudo journalctl -u kubelet --since "10 minutes ago" --no-pager'}
    Rollback;$rollback=$true;& minikube stop --profile $Profile|Out-Null;$stopped=$true
}
catch{WriteJson(Join-Path $root 'run-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message});throw}
finally{if(-not$rollback){try{Rollback;$rollback=$true}catch{WriteJson(Join-Path $root 'rollback-error.json')([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message})}};if(-not$stopped){& minikube stop --profile $Profile|Out-Null;$stopped=$true};$after=HostCounts;WriteJson(Join-Path $root 'host-after.json')([ordered]@{observed_utc=NowUtc;counts=$after;deltas=[ordered]@{whea_event_17=($after.whea_event_17-$before.whea_event_17);kernel_power_41=($after.kernel_power_41-$before.kernel_power_41);bugcheck=($after.bugcheck-$before.bugcheck)}})}
Write-Output "network_server_termination_diagnostic=completed id=$DiagnosticId"

[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$RunId = 'ob-network-proxy-live-001',
    [string]$WorkloadProfileRelative = 'p0-env/config/workloads/ob-second-15u-1r-v1.json',
    [string]$PythonPath,
    [string]$Profile = 'p0-online-boutique'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$namespace = 'online-boutique'
$stageRoot = Join-Path $repo 'p0-env\artifacts\P2-NETWORK-DELAY-PROXY-LIVE-001'
$evidenceRoot = Join-Path $stageRoot $RunId
$profilePath = Join-Path $repo 'p0-env\config\faults\network-delay-recommendation-productcatalog-v1.json'
$baseConfig = Join-Path $repo 'p0-env\config\online-boutique'
$proxyConfig = Join-Path $repo 'p0-env\config\network-delay-design'
$telemetryRoot = Join-Path $repo 'p0-env\artifacts\telemetry'
$rawRoot = Join-Path $repo 'p0-env\artifacts\runs'
$rollbackAttempted = $false
$portForward = $null
$minikubeStopped = $false

function NowUtc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function WriteJson([string]$Path, [object]$Value) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 40), (New-Object Text.UTF8Encoding($false)))
}
function Native([string]$Name, [scriptblock]$Command) {
    Write-Output "step_started=$Name"
    $output = & $Command 2>&1
    $code = $LASTEXITCODE
    $output | ForEach-Object { Write-Output ([string]$_) }
    if ($code -ne 0) { throw "step_failed:$Name exit=$code" }
    Write-Output "step_passed=$Name"
}
function HostSnapshot {
    $definitions = @(
        [ordered]@{name='whea_event_17';provider='Microsoft-Windows-WHEA-Logger';id=17},
        [ordered]@{name='kernel_power_41';provider='Microsoft-Windows-Kernel-Power';id=41},
        [ordered]@{name='bugcheck';provider='Microsoft-Windows-WER-SystemErrorReporting';id=1001}
    )
    $result = [ordered]@{observed_utc=NowUtc;events=[ordered]@{}}
    foreach ($definition in $definitions) {
        $events = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName=$definition.provider;Id=$definition.id} -ErrorAction SilentlyContinue)
        $latest = $events | Sort-Object RecordId -Descending | Select-Object -First 1
        $result.events[$definition.name] = [ordered]@{
            count=$events.Count
            latest_record_id=if ($null -eq $latest) {$null} else {[long]$latest.RecordId}
            latest_time_utc=if ($null -eq $latest) {$null} else {$latest.TimeCreated.ToUniversalTime().ToString('o')}
        }
    }
    return $result
}
function KubectlJson([string[]]$Arguments) {
    $raw = & minikube kubectl --profile $Profile -- @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "kubectl_failed:$($raw -join ' | ')" }
    return (($raw -join "`n") | ConvertFrom-Json)
}
function Snapshot([string]$Name) {
    $value = [ordered]@{
        observed_utc=NowUtc
        pods=KubectlJson @('-n',$namespace,'get','pods','-o','json')
        deployments=KubectlJson @('-n',$namespace,'get','deployments','-o','json')
    }
    WriteJson (Join-Path $evidenceRoot "$Name.json") $value
    return $value
}
function RecommendationIdentity([object]$Snapshot) {
    $pod = @($Snapshot.pods.items | Where-Object {$_.metadata.labels.app -eq 'recommendationservice'})
    if ($pod.Count -ne 1) { throw "recommendation_pod_count_invalid:$($pod.Count)" }
    $restarts = [ordered]@{}
    foreach ($status in @($pod[0].status.containerStatuses)) { $restarts[[string]$status.name] = [int]$status.restartCount }
    return [ordered]@{pod_name=[string]$pod[0].metadata.name;uid=[string]$pod[0].metadata.uid;restarts=$restarts}
}
function AssertSameIdentity([object]$Before,[object]$After,[string]$Phase) {
    $a = RecommendationIdentity $Before
    $b = RecommendationIdentity $After
    if ($a.uid -ne $b.uid -or (($a.restarts | ConvertTo-Json -Compress) -ne ($b.restarts | ConvertTo-Json -Compress))) {
        throw "recommendation_identity_changed_during_$Phase"
    }
}
function CaptureRecommendationLogs([string]$Name,[object]$Snapshot) {
    $identity = RecommendationIdentity $Snapshot
    foreach ($container in $identity.restarts.Keys) {
        $raw = & minikube kubectl --profile $Profile -- -n $namespace logs $identity.pod_name -c $container 2>&1
        if ($LASTEXITCODE -ne 0) { throw "recommendation_log_capture_failed:${Name}:${container}" }
        $path = Join-Path $evidenceRoot "$Name-$container.log"
        [IO.File]::WriteAllText($path, ($raw -join "`n"), (New-Object Text.UTF8Encoding($false)))
    }
}
function InvokeVerifier([string]$Path,[object[]]$Arguments) {
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "verifier_failed:$([IO.Path]::GetFileName($Path))" }
}
function WaitMinimum([string]$StartUtc,[int]$Seconds) {
    $start = [datetimeoffset]::Parse($StartUtc)
    $deadline = $start.AddSeconds($Seconds)
    while ([datetimeoffset]::UtcNow -lt $deadline) {
        $remaining = [math]::Ceiling(($deadline - [datetimeoffset]::UtcNow).TotalSeconds)
        Start-Sleep -Seconds ([math]::Min(5,[math]::Max(1,$remaining)))
    }
}
function Rollback {
    $script:rollbackAttempted = $true
    Native 'rollback_apply_base' { & minikube kubectl --profile $Profile -- apply -k $baseConfig }
    Native 'rollback_wait_recommendation' { & minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m }
    Native 'rollback_delete_proxy_configmap' { & minikube kubectl --profile $Profile -- -n $namespace delete configmap network-delay-proxy-config --ignore-not-found=true }
    $deployment = KubectlJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json')
    $containers = @($deployment.spec.template.spec.containers)
    if ($containers.Count -ne 1 -or [string]$containers[0].name -ne 'server') { throw 'rollback_sidecar_residual' }
    $address = @($containers[0].env | Where-Object {$_.name -eq 'PRODUCT_CATALOG_SERVICE_ADDR'})
    if ($address.Count -ne 1 -or [string]$address[0].value -ne 'productcatalogservice:3550') { throw 'rollback_address_residual' }
    WriteJson (Join-Path $evidenceRoot 'rollback-verification.json') ([ordered]@{verified_utc=NowUtc;passed=$true;containers=@($containers.name);product_catalog_address=[string]$address[0].value;proxy_configmap_absent=$true})
}

if ([string]::IsNullOrWhiteSpace($PythonPath) -or -not (Test-Path $PythonPath -PathType Leaf)) { throw 'python_runtime_missing' }
if ($RunId -ne 'ob-network-proxy-live-001') { throw 'unexpected_operational_run_id' }
if (@(& git -C $repo status --porcelain).Count -ne 0) { throw 'working_tree_not_clean' }
if ((Test-Path $evidenceRoot) -or (Test-Path (Join-Path $telemetryRoot $RunId)) -or (Test-Path (Join-Path $rawRoot $RunId))) { throw 'immutable_output_already_exists' }
$workload = Get-Content (Join-Path $repo ($WorkloadProfileRelative.Replace('/','\'))) -Raw | ConvertFrom-Json
if ($workload.profile_id -ne 'ob-second-15u-1r-v1' -or [int]$workload.loadgenerator.users -ne 15 -or [int]$workload.loadgenerator.spawn_rate_per_second -ne 1 -or [int]$workload.loadgenerator.random_seed -ne 1) { throw 'workload_contract_mismatch' }
if (-not $PSCmdlet.ShouldProcess($RunId, 'run fault-free live proxy compatibility gate')) { return }

New-Item -ItemType Directory -Path $evidenceRoot -Force | Out-Null
$codeRevision = (& git -C $repo rev-parse HEAD).Trim()
$hostBefore = HostSnapshot
WriteJson (Join-Path $evidenceRoot 'host-before.json') $hostBefore
$phases = [ordered]@{}
try {
    Native 'deploy_base' { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'deploy.ps1') }
    InvokeVerifier (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    InvokeVerifier (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') @('-ExpectedProfileRelative',$WorkloadProfileRelative)
    $initial = Snapshot 'initial-base'

    $phases.base_warmup_start_utc = NowUtc
    WaitMinimum $phases.base_warmup_start_utc 300
    $phases.base_warmup_end_utc = NowUtc
    $baseBefore = Snapshot 'base-measurement-before'
    $phases.base_measurement_start_utc = NowUtc
    WaitMinimum $phases.base_measurement_start_utc 300
    $phases.base_measurement_end_utc = NowUtc
    $baseAfter = Snapshot 'base-measurement-after'
    AssertSameIdentity $baseBefore $baseAfter 'base_measurement'
    CaptureRecommendationLogs 'base-recommendation' $baseAfter

    Native 'apply_no_toxic_proxy_overlay' { & minikube kubectl --profile $Profile -- apply -k $proxyConfig }
    Native 'wait_proxy_rollout' { & minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m }
    InvokeVerifier (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    InvokeVerifier (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') @('-ExpectedProfileRelative',$WorkloadProfileRelative)
    $proxyBeforeStabilization = Snapshot 'proxy-stabilization-before'

    $minikubeExe = (Get-Command minikube -ErrorAction Stop).Source
    $stdout = Join-Path $evidenceRoot 'proxy-port-forward.stdout.log'
    $stderr = Join-Path $evidenceRoot 'proxy-port-forward.stderr.log'
    $portForward = Start-Process -FilePath $minikubeExe -ArgumentList @('kubectl','--profile',$Profile,'--','-n',$namespace,'port-forward','deployment/recommendationservice','18474:8474') -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdout -RedirectStandardError $stderr
    Start-Sleep -Seconds 4
    & $PythonPath (Join-Path $PSScriptRoot 'manage-network-delay-proxy.py') --api-base http://127.0.0.1:18474 --profile $profilePath --action verify-clean --evidence (Join-Path $evidenceRoot 'proxy-clean-before.json')
    if ($LASTEXITCODE -ne 0) { throw 'proxy_clean_before_failed' }

    $phases.proxy_stabilization_start_utc = NowUtc
    WaitMinimum $phases.proxy_stabilization_start_utc 120
    $phases.proxy_stabilization_end_utc = NowUtc
    $proxyBefore = Snapshot 'proxy-measurement-before'
    $phases.proxy_measurement_start_utc = NowUtc
    WaitMinimum $phases.proxy_measurement_start_utc 300
    $phases.proxy_measurement_end_utc = NowUtc
    $proxyAfter = Snapshot 'proxy-measurement-after'
    AssertSameIdentity $proxyBefore $proxyAfter 'proxy_measurement'
    CaptureRecommendationLogs 'proxy-recommendation' $proxyAfter
    & $PythonPath (Join-Path $PSScriptRoot 'manage-network-delay-proxy.py') --api-base http://127.0.0.1:18474 --profile $profilePath --action verify-clean --evidence (Join-Path $evidenceRoot 'proxy-clean-after.json')
    if ($LASTEXITCODE -ne 0) { throw 'proxy_clean_after_failed' }
    WriteJson (Join-Path $evidenceRoot 'phases.json') ([ordered]@{schema_version=1;gate_id='P2-NETWORK-DELAY-PROXY-LIVE-001';run_id=$RunId;code_revision=$codeRevision;workload_profile_id=$workload.profile_id;scientific_fault_started=$false;phases=$phases;base_recommendation=(RecommendationIdentity $baseBefore);proxy_recommendation=(RecommendationIdentity $proxyBefore)})

    Native 'archive_raw_logs' { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') -RunId $RunId -SinceUtc $phases.base_warmup_start_utc -UntilUtc $phases.proxy_measurement_end_utc }
    InvokeVerifier (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') @('-ArchivePath',(Join-Path $rawRoot $RunId))
    Native 'archive_telemetry' { & powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') -RunId $RunId -StartUtc $phases.base_warmup_start_utc -EndUtc $phases.proxy_measurement_end_utc -MetricStepSeconds 5 -TraceLimitPerService 5000 -TraceQueryChunkSeconds 300 }
    InvokeVerifier (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') @('-TelemetryPath',(Join-Path $telemetryRoot $RunId))

    if ($null -ne $portForward -and -not $portForward.HasExited) { Stop-Process -Id $portForward.Id -Force; $portForward.WaitForExit() }
    $portForward = $null
    Rollback
    Snapshot 'rollback-final' | Out-Null
    Native 'stop_minikube' { & minikube stop --profile $Profile }
    $minikubeStopped = $true
    $hostAfter = HostSnapshot
    WriteJson (Join-Path $evidenceRoot 'host-after.json') $hostAfter
    Write-Output "network_delay_proxy_live_capture=passed run_id=$RunId"
}
catch {
    WriteJson (Join-Path $evidenceRoot 'run-error.json') ([ordered]@{run_id=$RunId;status='invalid_or_incomplete';failed_utc=NowUtc;error=$_.Exception.Message;scientific_fault_started=$false})
    throw
}
finally {
    if ($null -ne $portForward -and -not $portForward.HasExited) { Stop-Process -Id $portForward.Id -Force -ErrorAction SilentlyContinue }
    if (-not $rollbackAttempted) {
        try { Rollback } catch { WriteJson (Join-Path $evidenceRoot 'rollback-error.json') ([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message}) }
    }
    if (-not $minikubeStopped) {
        try { & minikube stop --profile $Profile 2>&1 | ForEach-Object { Write-Output ([string]$_) }; $script:minikubeStopped = $true } catch {}
        try { WriteJson (Join-Path $evidenceRoot 'host-after.json') (HostSnapshot) } catch {}
    }
}

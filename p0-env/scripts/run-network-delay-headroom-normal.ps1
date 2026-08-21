[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [Parameter(Mandatory = $true)][string]$RunId,
    [Parameter(Mandatory = $true)][string]$WorkloadProfileRelative,
    [Parameter(Mandatory = $true)][string]$PythonPath,
    [Parameter(Mandatory = $true)][switch]$ExecutionApproved,
    [string]$Profile = 'p0-online-boutique'
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$env:P0_PYTHON_PATH = $PythonPath
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'phase-duration.ps1')
. (Join-Path $PSScriptRoot 'host-event-recordid.ps1')
. (Join-Path $PSScriptRoot 'native-json-command.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$namespace = 'online-boutique'
$experimentId = 'P2-NETWORK-DELAY-HEADROOM-001'
$artifactRoot = Join-Path $repo "p0-env\artifacts\$experimentId\$RunId"
$metadataRoot = Join-Path $repo "p0-env\artifacts\scientific-run-metadata\$RunId"
$telemetryRoot = Join-Path $repo "p0-env\artifacts\telemetry\$RunId"
$workloadPath = Join-Path $repo ($WorkloadProfileRelative.Replace('/', '\'))
$sloRelative = 'p0-env/config/slo/p2-network-delay-001-slo-v1.json'
$sloPath = Join-Path $repo ($sloRelative.Replace('/', '\'))
$baseConfig = Join-Path $repo 'p0-env\config\online-boutique'
$overlayConfig = Join-Path $repo 'p0-env\config\network-delay-resource-compatibility'
$proxyDesignProfile = Join-Path $repo 'p0-env/config/faults/network-delay-recommendation-productcatalog-v1.json'
$draftPath = Join-Path $artifactRoot 'draft-metadata.json'
$preCleanPath = Join-Path $artifactRoot 'proxy-clean-pre.json'
$postCleanPath = Join-Path $artifactRoot 'proxy-clean-post.json'
$manifestationPath = Join-Path $artifactRoot 'manifestation-evidence.json'
$headroomInputPath = Join-Path $artifactRoot 'headroom-input.json'
$metadataPath = Join-Path $metadataRoot 'scientific-run-metadata.json'
$portForward = $null
$rollbackVerified = $false
$stopped = $false

function NowUtc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function WriteJson([string]$Path, [object]$Value) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 40), (New-Object Text.UTF8Encoding($false)))
}
function HashRelative([string]$Relative) {
    (Get-FileHash (Join-Path $repo ($Relative.Replace('/', '\'))) -Algorithm SHA256).Hash.ToLowerInvariant()
}
function InvokeScript([string]$Name, [string]$Path, [object[]]$Arguments) {
    Write-Output "step_started=$Name"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "step_failed:$Name" }
    Write-Output "step_passed=$Name"
}
function KubectlJson([string[]]$Arguments) {
    Invoke-NativeJsonCommand -FilePath (Get-Command kubectl -CommandType Application | Select-Object -First 1).Source -ArgumentList $Arguments -Operation 'kubectl_json_failed' -DiagnosticPath (Join-Path $artifactRoot 'kubectl-stderr.log')
}
function SnapshotPods([string]$Name) {
    $pods = KubectlJson @('-n', $namespace, 'get', 'pods', '-o', 'json')
    $components = [ordered]@{}
    foreach ($pod in @($pods.items)) {
        $app = [string]$pod.metadata.labels.app
        if (-not $app) { continue }
        if ($components.Contains($app)) { throw "multiple_pods_for_app:$app" }
        $containers = [ordered]@{}
        foreach ($container in @($pod.status.containerStatuses)) {
            $containers[[string]$container.name] = [ordered]@{container_id=[string]$container.containerID;restart_count=[int]$container.restartCount;ready=[bool]$container.ready}
        }
        $components[$app] = [ordered]@{pod_name=[string]$pod.metadata.name;uid=[string]$pod.metadata.uid;containers=$containers}
    }
    if ($components.Count -ne 15) { throw "tracked_pod_count_invalid:$($components.Count)" }
    WriteJson (Join-Path $artifactRoot "$Name.json") ([ordered]@{observed_utc=NowUtc;components=$components})
    return $components
}
function Same([object]$A, [object]$B) { (($A | ConvertTo-Json -Depth 20 -Compress) -eq ($B | ConvertTo-Json -Depth 20 -Compress)) }
function StartProxyForward {
    $exe = (Get-Command minikube -ErrorAction Stop).Source
    $script:portForward = Start-Process -FilePath $exe -ArgumentList @('kubectl','--profile',$Profile,'--','-n',$namespace,'port-forward','deployment/recommendationservice','18474:8474') -PassThru -WindowStyle Hidden -RedirectStandardOutput (Join-Path $artifactRoot 'proxy-port-forward.stdout.log') -RedirectStandardError (Join-Path $artifactRoot 'proxy-port-forward.stderr.log')
    Start-Sleep -Seconds 4
}
function StopProxyForward {
    if ($null -ne $script:portForward -and -not $script:portForward.HasExited) { Stop-Process -Id $script:portForward.Id -Force; $script:portForward.WaitForExit() }
    $script:portForward = $null
}
function AssertProxyClean([string]$Stage, [string]$Path) {
    & $PythonPath (Join-Path $PSScriptRoot 'manage-network-delay-proxy.py') --api-base http://127.0.0.1:18474 --profile $proxyDesignProfile --action verify-clean --evidence $Path
    if ($LASTEXITCODE -ne 0) { throw "proxy_not_clean:$Stage" }
    $evidence = Get-Content $Path -Raw | ConvertFrom-Json
    $evidence | Add-Member -NotePropertyName run_id -NotePropertyValue $RunId
    $evidence | Add-Member -NotePropertyName stage -NotePropertyValue $Stage
    WriteJson $Path $evidence
}
function AssertLiveResourceContract {
    $deployment = KubectlJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json')
    $server = @($deployment.spec.template.spec.containers | Where-Object { $_.name -eq 'server' })
    $proxy = @($deployment.spec.template.spec.containers | Where-Object { $_.name -eq 'network-delay-proxy' })
    if ($server.Count -ne 1 -or $proxy.Count -ne 1) { throw 'live_proxy_container_contract_mismatch' }
    if ($server[0].resources.limits.cpu -ne '500m' -or $server[0].resources.requests.cpu -ne '100m' -or $proxy[0].resources.limits.cpu -ne '100m') { throw 'live_resource_contract_mismatch' }
    WriteJson (Join-Path $artifactRoot 'live-resource-contract.json') ([ordered]@{passed=$true;verified_utc=NowUtc;server_cpu_limit='500m';server_cpu_request='100m';proxy_cpu_limit='100m'})
}
function Rollback {
    StopProxyForward
    & minikube kubectl --profile $Profile -- apply -k $baseConfig | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'rollback_apply_failed' }
    & minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'rollback_rollout_failed' }
    $deployment = KubectlJson @('-n',$namespace,'get','deployment/recommendationservice','-o','json')
    if (@($deployment.spec.template.spec.containers).Count -ne 1) { throw 'rollback_proxy_still_present' }
    $script:rollbackVerified = $true
    WriteJson (Join-Path $artifactRoot 'rollback-verification.json') ([ordered]@{passed=$true;verified_utc=NowUtc})
}

$allowed = [ordered]@{
    'ob-netdelay-500m-normal-15u-001'='ob-second-15u-1r-v1';'ob-netdelay-500m-normal-15u-002'='ob-second-15u-1r-v1';'ob-netdelay-500m-normal-10u-001'='ob-default-10u-1r-v1';'ob-netdelay-500m-normal-10u-002'='ob-default-10u-1r-v1';'ob-netdelay-500m-normal-15u-003'='ob-second-15u-1r-v1';'ob-netdelay-500m-normal-10u-003'='ob-default-10u-1r-v1';'ob-netdelay-500m-normal-15u-004'='ob-second-15u-1r-v1'
}
if (-not $ExecutionApproved) { throw 'explicit_runtime_execution_approval_required' }
if (-not $allowed.Contains($RunId)) { throw 'unexpected_run_id' }
if (-not (Test-Path $PythonPath -PathType Leaf)) { throw 'python_runtime_missing' }
$workload = Get-Content $workloadPath -Raw | ConvertFrom-Json
if ($workload.profile_id -ne $allowed[$RunId]) { throw 'workload_binding_mismatch' }
if (@(& git -C $repo status --porcelain).Count -ne 0) { throw 'working_tree_not_clean' }
foreach ($path in @($artifactRoot,$metadataRoot,$telemetryRoot,(Join-Path $repo "p0-env/artifacts/runs/$RunId"),(Join-Path $repo "p0-env/artifacts/derived/$RunId"),(Join-Path $repo "p0-env/artifacts/finalized/$RunId"))) { if (Test-Path $path) { throw "immutable_output_exists:$path" } }
if (-not $PSCmdlet.ShouldProcess($RunId, 'execute D-067 no-toxic proxy normal baseline')) { return }

New-Item -ItemType Directory -Path $artifactRoot -Force | Out-Null
$codeRevision = (& git -C $repo rev-parse HEAD).Trim()
$hostBefore = New-HostEventRecordIdBoundary
WriteJson (Join-Path $artifactRoot 'host-before.json') $hostBefore
try {
    InvokeScript 'deploy_base' (Join-Path $PSScriptRoot 'deploy.ps1') @()
    & minikube kubectl --profile $Profile -- apply -k $overlayConfig | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'overlay_apply_failed' }
    & minikube kubectl --profile $Profile -- -n $namespace rollout status deployment/recommendationservice --timeout=10m | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'overlay_rollout_failed' }
    InvokeScript 'active_run' (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    InvokeScript 'active_workload' (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') @('-ExpectedProfileRelative',$WorkloadProfileRelative)
    InvokeScript 'target_stability' (Join-Path $PSScriptRoot 'verify-target-pod-stability.ps1') @('-Namespace',$namespace,'-Deployment','recommendationservice','-Container','server','-EvidencePath',(Join-Path $artifactRoot 'target-pod-stability.json'),'-Profile',$Profile,'-DurationSeconds','120','-PollSeconds','5')
    AssertLiveResourceContract
    StartProxyForward
    AssertProxyClean 'pre' $preCleanPath
    $warmupStart = NowUtc
    $warmupEnd = Wait-UntilMinimumUtcDuration -StartUtc $warmupStart -MinimumSeconds 300
    $podsBefore = SnapshotPods 'baseline-before'
    $baselineStart = NowUtc
    $baselineEnd = Wait-UntilMinimumUtcDuration -StartUtc $baselineStart -MinimumSeconds 300
    $podsAfter = SnapshotPods 'baseline-after'
    $podStable = Same $podsBefore $podsAfter
    AssertProxyClean 'post' $postCleanPath
    $phases = [ordered]@{warmup_start_utc=$warmupStart;warmup_end_utc=$warmupEnd;normal_baseline_start_utc=$baselineStart;normal_baseline_end_utc=$baselineEnd}
    WriteJson $draftPath ([ordered]@{run_id=$RunId;phases=[ordered]@{normal_baseline_start_utc=$baselineStart;cooldown_end_utc=$baselineEnd}})
    InvokeScript 'archive_raw' (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') @('-RunId',$RunId,'-SinceUtc',$warmupStart,'-UntilUtc',$baselineEnd)
    InvokeScript 'verify_raw' (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') @('-ArchivePath',(Join-Path $repo "p0-env/artifacts/runs/$RunId"))
    InvokeScript 'enrich' (Join-Path $PSScriptRoot 'enrich-log-run-id.ps1') @('-ArchivePath',(Join-Path $repo "p0-env/artifacts/runs/$RunId"))
    InvokeScript 'verify_enriched' (Join-Path $PSScriptRoot 'verify-enriched-logs.ps1') @('-DerivedPath',(Join-Path $repo "p0-env/artifacts/derived/$RunId"))
    InvokeScript 'archive_telemetry' (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$baselineEnd,'-MetricStepSeconds','5','-TraceLimitPerService','5000','-TraceQueryChunkSeconds','300')
    InvokeScript 'verify_telemetry' (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') @('-TelemetryPath',$telemetryRoot)
    & $PythonPath (Join-Path $PSScriptRoot 'detect-fault-manifestation.py') --telemetry-root $telemetryRoot --draft-metadata $draftPath --slo-config $sloPath --output $manifestationPath
    if ($LASTEXITCODE -ne 0) { throw 'manifestation_analysis_failed' }
    & $PythonPath (Join-Path $PSScriptRoot 'analyze-network-delay-headroom-normal.py') --manifestation-evidence $manifestationPath --run-id $RunId --workload-profile-id $workload.profile_id --output $headroomInputPath
    if ($LASTEXITCODE -ne 0) { throw 'headroom_input_failed' }
    StopProxyForward
    Rollback
    & minikube stop --profile $Profile | Out-Host
    if ($LASTEXITCODE -ne 0) { throw 'minikube_stop_failed' }
    $stopped = $true
    $hostAfter = Measure-HostEventsAfterRecordIdBoundary $hostBefore
    WriteJson (Join-Path $artifactRoot 'host-after.json') $hostAfter
    $hostHealth = [ordered]@{whea_event_17_delta=[int]$hostAfter.counts.whea_event_17;kernel_power_41_delta=[int]$hostAfter.counts.kernel_power_41;bugcheck_delta=[int]$hostAfter.counts.bugcheck}
    $manifestation = Get-Content $manifestationPath -Raw | ConvertFrom-Json
    $valid = $podStable -and $rollbackVerified -and $null -eq $manifestation.failure_manifestation -and $hostHealth.whea_event_17_delta -eq 0 -and $hostHealth.kernel_power_41_delta -eq 0 -and $hostHealth.bugcheck_delta -eq 0
    $relative = "p0-env/artifacts/$experimentId/$RunId"
    $metadata = [ordered]@{schema_version=1;run_id=$RunId;experiment_id=$experimentId;run_kind='network_delay_normal_baseline';fault_class='normal';scientific_fault_started=$false;normal_topology='no_toxic_proxy_overlay';code_revision=$codeRevision;workload_profile_id=[string]$workload.profile_id;workload_profile_path=$WorkloadProfileRelative;workload_profile_sha256=(HashRelative $WorkloadProfileRelative);slo_path=$sloRelative;slo_sha256=(HashRelative $sloRelative);proxy_clean_pre_evidence_path="$relative/proxy-clean-pre.json";proxy_clean_pre_evidence_sha256=(Get-FileHash $preCleanPath -Algorithm SHA256).Hash.ToLowerInvariant();proxy_clean_post_evidence_path="$relative/proxy-clean-post.json";proxy_clean_post_evidence_sha256=(Get-FileHash $postCleanPath -Algorithm SHA256).Hash.ToLowerInvariant();manifestation_evidence_path="$relative/manifestation-evidence.json";manifestation_evidence_sha256=(Get-FileHash $manifestationPath -Algorithm SHA256).Hash.ToLowerInvariant();headroom_input_path="$relative/headroom-input.json";headroom_input_sha256=(Get-FileHash $headroomInputPath -Algorithm SHA256).Hash.ToLowerInvariant();failure_manifestation=$manifestation.failure_manifestation;resources=[ordered]@{server_cpu_limit='500m';server_cpu_request='100m';proxy_cpu_limit='100m'};phases=$phases;host_health=$hostHealth;runtime_evidence=[ordered]@{tracked_deployment_count=15;pod_lifecycle_stable=$podStable;proxy_clean_pre_verified=$true;proxy_clean_post_verified=$true;rollback_verified=$rollbackVerified};valid_run=$valid}
    WriteJson $metadataPath $metadata
    & $PythonPath (Join-Path $PSScriptRoot 'verify-network-delay-headroom-normal-metadata.py') --repo-root $repo --metadata $metadataPath
    if ($LASTEXITCODE -ne 0) { throw 'metadata_verification_failed' }
    InvokeScript 'finalize' (Join-Path $PSScriptRoot 'finalize-run-artifacts.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$baselineEnd,'-ScientificRunMetadataPath',$metadataPath)
    InvokeScript 'verify_receipt' (Join-Path $PSScriptRoot 'verify-finalized-run.ps1') @('-ReceiptPath',(Join-Path $repo "p0-env/artifacts/finalized/$RunId"))
    if (-not $valid) { throw 'scientific_validity_failed_evidence_preserved' }
    Write-Output "headroom_normal=valid run_id=$RunId"
}
catch {
    WriteJson (Join-Path $artifactRoot 'run-error.json') ([ordered]@{run_id=$RunId;failed_utc=NowUtc;scientific_fault_started=$false;error=$_.Exception.Message})
    throw
}
finally {
    StopProxyForward
    if (-not $rollbackVerified) { try { Rollback } catch { WriteJson (Join-Path $artifactRoot 'rollback-error.json') ([ordered]@{failed_utc=NowUtc;error=$_.Exception.Message}) } }
    if (-not $stopped) { & minikube stop --profile $Profile | Out-Host }
}

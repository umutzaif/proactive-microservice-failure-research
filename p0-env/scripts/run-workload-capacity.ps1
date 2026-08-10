[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)][ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')][string]$RunId,
    [Parameter(Mandatory = $true)][string]$WorkloadProfileRelative,
    [Parameter(Mandatory = $true)][string]$PythonPath,
    [string]$Profile = 'p0-online-boutique'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactRoot = Join-Path $repo "p0-env\artifacts\P1-WORKLOAD-CAPACITY-001\$RunId"
$telemetryRoot = Join-Path $repo "p0-env\artifacts\telemetry\$RunId"
$profilePath = Join-Path $repo ($WorkloadProfileRelative.Replace('/', '\'))
$sloPath = Join-Path $repo 'p0-env\config\slo\p1-cpu-001-slo-v1.json'
$draftPath = Join-Path $artifactRoot 'draft-metadata.json'
$manifestationPath = Join-Path $artifactRoot 'manifestation-evidence.json'
$analysisPath = Join-Path $artifactRoot 'capacity-analysis.json'
$assessmentPath = Join-Path $artifactRoot 'run-assessment.json'
$stopped = $false

function NowUtc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function WriteJson([string]$Path, [object]$Value) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
}
function HostCounts {
    [ordered]@{
        whea_event_17=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WHEA-Logger';Id=17} -ErrorAction SilentlyContinue).Count
        kernel_power_41=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Kernel-Power';Id=41} -ErrorAction SilentlyContinue).Count
        bugcheck=@(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WER-SystemErrorReporting';Id=1001} -ErrorAction SilentlyContinue).Count
    }
}
function SnapshotPods {
    $raw = & minikube kubectl --profile $Profile -- -n online-boutique get pods -o json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "pod_snapshot_failed:$($raw -join ' | ')" }
    $result = [ordered]@{}
    foreach ($pod in @((($raw -join "`n") | ConvertFrom-Json).items)) {
        $app = [string]$pod.metadata.labels.app
        if ([string]::IsNullOrWhiteSpace($app)) { continue }
        if ($result.Contains($app)) { throw "multiple_pods_for_app:$app" }
        $restart = (@($pod.status.containerStatuses) | Measure-Object restartCount -Sum).Sum
        $result[$app] = [ordered]@{pod_name=[string]$pod.metadata.name;uid=[string]$pod.metadata.uid;restart_count=[int]$restart}
    }
    if ($result.Count -ne 15) { throw "tracked_pod_count_invalid:$($result.Count)" }
    return $result
}
function InvokeScript([string]$Name,[string]$Path,[object[]]$Arguments) {
    Write-Output "step_started=$Name"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "step_failed:$Name" }
    Write-Output "step_passed=$Name"
}

if (-not (Test-Path $PythonPath -PathType Leaf)) { throw 'python_runtime_missing' }
if (-not (Test-Path $profilePath -PathType Leaf)) { throw 'workload_profile_missing' }
if (@(& git -C $repo status --porcelain).Count -ne 0) { throw 'working_tree_not_clean' }
if ((Test-Path $artifactRoot) -or (Test-Path $telemetryRoot)) { throw 'run_artifact_path_already_exists' }
$workload = Get-Content $profilePath -Raw | ConvertFrom-Json
$kustom = Get-Content (Join-Path $repo 'p0-env\config\online-boutique\kustomization.yaml') -Raw
if ($kustom -notmatch ('name: WORKLOAD_PROFILE_ID\s+value: "' + [regex]::Escape([string]$workload.profile_id) + '"')) { throw 'workload_profile_not_bound' }
if ($kustom -notmatch ('env/1/value\s+value: "' + [regex]::Escape([string]$workload.loadgenerator.users) + '"')) { throw 'workload_users_not_bound' }
if (-not $PSCmdlet.ShouldProcess($RunId, 'execute fault-free workload capacity run')) { return }

$hostBefore = HostCounts
try {
    InvokeScript 'active_run_id' (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    $warmupStart = NowUtc
    Write-Output "phase=warmup start_utc=$warmupStart"
    Start-Sleep -Seconds ([int]$workload.phases.warmup_seconds)
    $baselineStart = NowUtc
    $podsBefore = SnapshotPods
    Write-Output "phase=measurement start_utc=$baselineStart"
    Start-Sleep -Seconds ([int]$workload.phases.measurement_seconds)
    $baselineEnd = NowUtc
    $podsAfter = SnapshotPods
    $podStable = (($podsBefore | ConvertTo-Json -Depth 8 -Compress) -eq ($podsAfter | ConvertTo-Json -Depth 8 -Compress))
    $draft = [ordered]@{run_id=$RunId;workload_profile_id=[string]$workload.profile_id;phases=[ordered]@{warmup_start_utc=$warmupStart;normal_baseline_start_utc=$baselineStart;normal_baseline_end_utc=$baselineEnd;cooldown_end_utc=$baselineEnd}}
    WriteJson $draftPath $draft

    InvokeScript 'archive_raw_logs' (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') @('-RunId',$RunId,'-SinceUtc',$warmupStart,'-UntilUtc',$baselineEnd)
    InvokeScript 'verify_raw_logs' (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') @('-ArchivePath',(Join-Path $repo "p0-env\artifacts\runs\$RunId"))
    InvokeScript 'archive_telemetry' (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$baselineEnd,'-TraceLimitPerService','5000','-TraceQueryChunkSeconds','300')
    InvokeScript 'verify_telemetry' (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') @('-TelemetryPath',$telemetryRoot)
    & $PythonPath (Join-Path $PSScriptRoot 'detect-fault-manifestation.py') --telemetry-root $telemetryRoot --draft-metadata $draftPath --slo-config $sloPath --output $manifestationPath
    if ($LASTEXITCODE -ne 0) { throw 'manifestation_detection_failed' }
    & $PythonPath (Join-Path $PSScriptRoot 'analyze-workload-capacity.py') --telemetry-root $telemetryRoot --draft-metadata $draftPath --workload-profile $profilePath --manifestation-evidence $manifestationPath --slo-config $sloPath --output $analysisPath
    if ($LASTEXITCODE -ne 0) { throw 'capacity_analysis_failed' }

    & minikube stop --profile $Profile
    if ($LASTEXITCODE -ne 0) { throw 'minikube_stop_failed' }
    $stopped = $true
    $hostAfter = HostCounts
    $hostHealth = [ordered]@{
        whea_event_17_before=$hostBefore.whea_event_17;whea_event_17_after=$hostAfter.whea_event_17;whea_event_17_delta=($hostAfter.whea_event_17-$hostBefore.whea_event_17)
        kernel_power_41_before=$hostBefore.kernel_power_41;kernel_power_41_after=$hostAfter.kernel_power_41;kernel_power_41_delta=($hostAfter.kernel_power_41-$hostBefore.kernel_power_41)
        bugcheck_before=$hostBefore.bugcheck;bugcheck_after=$hostAfter.bugcheck;bugcheck_delta=($hostAfter.bugcheck-$hostBefore.bugcheck)
    }
    $analysis = Get-Content $analysisPath -Raw | ConvertFrom-Json
    $valid = ($podStable -and $hostHealth.whea_event_17_delta -eq 0 -and $hostHealth.kernel_power_41_delta -eq 0 -and $hostHealth.bugcheck_delta -eq 0 -and $null -eq $analysis.failure_manifestation)
    WriteJson $assessmentPath ([ordered]@{schema_version=1;run_id=$RunId;status=$(if($valid){'valid_capacity_evidence'}else{'invalid'});dataset_inclusion=$false;workload_profile_id=[string]$workload.profile_id;users=[int]$workload.loadgenerator.users;pod_lifecycle_stable=$podStable;host_health=$hostHealth;failure_manifestation=$analysis.failure_manifestation;code_revision=(& git -C $repo rev-parse HEAD).Trim()})
    if (-not $valid) { throw 'capacity_validity_gate_failed_evidence_preserved' }
    Write-Output "workload_capacity=passed run_id=$RunId users=$($workload.loadgenerator.users)"
}
catch {
    WriteJson (Join-Path $artifactRoot 'run-error.json') ([ordered]@{run_id=$RunId;status='invalid_or_incomplete';failed_utc=(NowUtc);error=$_.Exception.Message})
    throw
}
finally {
    if (-not $stopped) { & minikube stop --profile $Profile 2>&1 | ForEach-Object { Write-Output ([string]$_) } }
}

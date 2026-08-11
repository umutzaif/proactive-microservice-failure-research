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
$experimentRoot = Join-Path $repo "p0-env\artifacts\P1-CPU-001\$RunId"
$metadataRoot = Join-Path $repo "p0-env\artifacts\scientific-run-metadata\$RunId"
$telemetryRoot = Join-Path $repo "p0-env\artifacts\telemetry\$RunId"
$profilePath = Join-Path $repo ($WorkloadProfileRelative.Replace('/', '\'))
$sloRelative = 'p0-env/config/slo/p1-cpu-001-slo-v1.json'
$sloPath = Join-Path $repo ($sloRelative.Replace('/', '\'))
$draftPath = Join-Path $experimentRoot 'draft-metadata.json'
$manifestationPath = Join-Path $experimentRoot 'manifestation-evidence.json'
$analysisPath = Join-Path $experimentRoot 'normal-analysis.json'
$assessmentPath = Join-Path $experimentRoot 'run-assessment.json'
$metadataPath = Join-Path $metadataRoot 'scientific-run-metadata.json'
$stopped = $false

function NowUtc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function WriteJson([string]$Path, [object]$Value) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30), (New-Object Text.UTF8Encoding($false)))
}
function Hash([string]$Relative) {
    (Get-FileHash (Join-Path $repo ($Relative.Replace('/', '\'))) -Algorithm SHA256).Hash.ToLowerInvariant()
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
$reserved = @(
    $experimentRoot,$metadataRoot,$telemetryRoot,
    (Join-Path $repo "p0-env\artifacts\runs\$RunId"),
    (Join-Path $repo "p0-env\artifacts\derived\$RunId"),
    (Join-Path $repo "p0-env\artifacts\finalized\$RunId")
)
foreach ($path in $reserved) { if (Test-Path $path) { throw "run_artifact_path_already_exists:$path" } }
$workload = Get-Content $profilePath -Raw | ConvertFrom-Json
if ([string]$workload.profile_id -ne 'ob-second-15u-1r-v1') { throw 'unexpected_second_workload_profile' }
if ([int]$workload.loadgenerator.users -ne 15 -or [int]$workload.loadgenerator.spawn_rate_per_second -ne 1) { throw 'second_workload_contract_mismatch' }
if ([int]$workload.loadgenerator.random_seed -ne 1) { throw 'workload_seed_must_remain_one' }
if ([int]$workload.phases.warmup_seconds -ne 300 -or [int]$workload.phases.normal_baseline_seconds -ne 300) { throw 'normal_phase_contract_mismatch' }
if (-not $PSCmdlet.ShouldProcess($RunId, 'execute preregistered fault-free scientific normal baseline')) { return }

$codeRevision = (& git -C $repo rev-parse HEAD).Trim()
$kustomHash = Hash 'p0-env/config/online-boutique/kustomization.yaml'
$observabilityHash = Hash 'p0-env/config/online-boutique/observability.yaml'
$hostBefore = HostCounts
$resetUtc = NowUtc
try {
    InvokeScript 'active_run_id_before' (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    InvokeScript 'active_workload_before' (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') @('-ExpectedProfileRelative',$WorkloadProfileRelative)
    $warmupStart = NowUtc
    Start-Sleep -Seconds 300
    $warmupEnd = NowUtc
    $baselineStart = NowUtc
    $podsBefore = SnapshotPods
    Start-Sleep -Seconds 300
    $baselineEnd = NowUtc
    $podsAfter = SnapshotPods
    $podStable = (($podsBefore | ConvertTo-Json -Depth 8 -Compress) -eq ($podsAfter | ConvertTo-Json -Depth 8 -Compress))
    InvokeScript 'active_run_id_after' (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    InvokeScript 'active_workload_after' (Join-Path $PSScriptRoot 'verify-active-workload-profile.ps1') @('-ExpectedProfileRelative',$WorkloadProfileRelative)
    $phases = [ordered]@{reset_health_check_utc=$resetUtc;warmup_start_utc=$warmupStart;warmup_end_utc=$warmupEnd;normal_baseline_start_utc=$baselineStart;normal_baseline_end_utc=$baselineEnd}
    WriteJson $draftPath ([ordered]@{run_id=$RunId;workload_profile_id=[string]$workload.profile_id;target_pod=[string]$podsBefore.recommendationservice.pod_name;phases=[ordered]@{warmup_start_utc=$warmupStart;normal_baseline_start_utc=$baselineStart;normal_baseline_end_utc=$baselineEnd;cooldown_end_utc=$baselineEnd}})

    InvokeScript 'archive_raw_logs' (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') @('-RunId',$RunId,'-SinceUtc',$warmupStart,'-UntilUtc',$baselineEnd)
    InvokeScript 'verify_raw_logs' (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') @('-ArchivePath',(Join-Path $repo "p0-env\artifacts\runs\$RunId"))
    InvokeScript 'enrich_logs' (Join-Path $PSScriptRoot 'enrich-log-run-id.ps1') @('-ArchivePath',(Join-Path $repo "p0-env\artifacts\runs\$RunId"))
    InvokeScript 'verify_enriched_logs' (Join-Path $PSScriptRoot 'verify-enriched-logs.ps1') @('-DerivedPath',(Join-Path $repo "p0-env\artifacts\derived\$RunId"))
    InvokeScript 'archive_telemetry' (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$baselineEnd,'-TraceLimitPerService','5000','-TraceQueryChunkSeconds','300')
    InvokeScript 'verify_telemetry' (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') @('-TelemetryPath',$telemetryRoot)
    & $PythonPath (Join-Path $PSScriptRoot 'detect-fault-manifestation.py') --telemetry-root $telemetryRoot --draft-metadata $draftPath --slo-config $sloPath --output $manifestationPath
    if ($LASTEXITCODE -ne 0) { throw 'normal_manifestation_detection_failed' }
    & $PythonPath (Join-Path $PSScriptRoot 'analyze-workload-capacity.py') --telemetry-root $telemetryRoot --draft-metadata $draftPath --workload-profile $profilePath --manifestation-evidence $manifestationPath --slo-config $sloPath --output $analysisPath
    if ($LASTEXITCODE -ne 0) { throw 'normal_diagnostic_analysis_failed' }

    & minikube stop --profile $Profile
    if ($LASTEXITCODE -ne 0) { throw 'minikube_stop_failed' }
    $stopped = $true
    $hostAfter = HostCounts
    $hostHealth = [ordered]@{whea_event_17_before=$hostBefore.whea_event_17;whea_event_17_after=$hostAfter.whea_event_17;whea_event_17_delta=($hostAfter.whea_event_17-$hostBefore.whea_event_17);kernel_power_41_before=$hostBefore.kernel_power_41;kernel_power_41_after=$hostAfter.kernel_power_41;kernel_power_41_delta=($hostAfter.kernel_power_41-$hostBefore.kernel_power_41);bugcheck_before=$hostBefore.bugcheck;bugcheck_after=$hostAfter.bugcheck;bugcheck_delta=($hostAfter.bugcheck-$hostBefore.bugcheck)}
    $manifestation = Get-Content $manifestationPath -Raw | ConvertFrom-Json
    $analysis = Get-Content $analysisPath -Raw | ConvertFrom-Json
    $valid = ($podStable -and $hostHealth.whea_event_17_delta -eq 0 -and $hostHealth.kernel_power_41_delta -eq 0 -and $hostHealth.bugcheck_delta -eq 0 -and $null -eq $manifestation.failure_manifestation)
    $metadata = [ordered]@{schema_version=1;run_id=$RunId;experiment_id='P1-CPU-001';run_kind='normal_baseline';system='online-boutique';code_revision=$codeRevision;deployment_revision="kustomization_sha256:$kustomHash;observability_sha256:$observabilityHash";fault_class='normal';target_service=$null;fault_profile='none';workload_profile_id=[string]$workload.profile_id;workload_profile_path=$WorkloadProfileRelative;workload_profile_sha256=(Hash $WorkloadProfileRelative);random_seed=[int]$workload.loadgenerator.random_seed;phases=$phases;host_health=$hostHealth;runtime_evidence=[ordered]@{tracked_deployment_count=15;baseline_components_before=$podsBefore;baseline_components_after=$podsAfter;active_run_id_gate_before='passed';active_run_id_gate_after='passed';active_workload_gate_before='passed';active_workload_gate_after='passed'};operator_notes='Preregistered second-workload normal baseline; no fault injection.';valid_run=$valid}
    WriteJson $metadataPath $metadata
    WriteJson $assessmentPath ([ordered]@{schema_version=1;run_id=$RunId;valid_run=$valid;dataset_inclusion=$valid;workload_profile_id=[string]$workload.profile_id;users=15;pod_lifecycle_stable=$podStable;host_health=$hostHealth;failure_manifestation=$manifestation.failure_manifestation;recommendationservice_cpu_mean_millicores=$analysis.recommendationservice_cpu_mean_millicores;normal_cpu_40m_selection_gate_is_not_a_run_exclusion=$true;code_revision=$codeRevision})
    if (-not $valid) { throw 'scientific_normal_validity_gate_failed_evidence_preserved' }
    InvokeScript 'verify_scientific_metadata' (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') @('-MetadataPath',$metadataPath,'-ExpectedRunId',$RunId,'-ExpectedStartUtc',$warmupStart,'-ExpectedEndUtc',$baselineEnd)
    InvokeScript 'finalize_receipt' (Join-Path $PSScriptRoot 'finalize-run-artifacts.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$baselineEnd,'-ScientificRunMetadataPath',$metadataPath)
    InvokeScript 'verify_finalized_receipt' (Join-Path $PSScriptRoot 'verify-finalized-run.ps1') @('-ReceiptPath',(Join-Path $repo "p0-env\artifacts\finalized\$RunId"))
    Write-Output "scientific_normal_baseline=passed run_id=$RunId workload=$($workload.profile_id)"
}
catch {
    WriteJson (Join-Path $experimentRoot 'run-error.json') ([ordered]@{run_id=$RunId;status='invalid_or_incomplete';failed_utc=(NowUtc);error=$_.Exception.Message})
    throw
}
finally {
    if (-not $stopped) { & minikube stop --profile $Profile 2>&1 | ForEach-Object { Write-Output ([string]$_) } }
}

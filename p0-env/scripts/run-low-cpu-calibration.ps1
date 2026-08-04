[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$RunId = 'ob-cpu-low-002',
    [Parameter(Mandatory = $true)][string]$PythonPath,
    [string]$Profile = 'p0-online-boutique'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$artifactRoot = Join-Path $repo "p0-env\artifacts\P1-CPU-001\$RunId"
$metadataRoot = Join-Path $repo "p0-env\artifacts\scientific-run-metadata\$RunId"
$faultRelative = 'p0-env/config/faults/cpu-recommendation-low-v1.json'
$sloRelative = 'p0-env/config/slo/p1-cpu-001-slo-v1.json'
$workloadRelative = 'p0-env/config/workloads/ob-default-10u-1r-v1.json'
$executionRelative = "p0-env/artifacts/P1-CPU-001/$RunId/injector-execution.json"
$effectRelative = "p0-env/artifacts/P1-CPU-001/$RunId/injector-evidence.json"
$manifestationRelative = "p0-env/artifacts/P1-CPU-001/$RunId/manifestation-evidence.json"
$executionPath = Join-Path $repo ($executionRelative.Replace('/', '\'))
$effectPath = Join-Path $repo ($effectRelative.Replace('/', '\'))
$manifestationPath = Join-Path $repo ($manifestationRelative.Replace('/', '\'))
$draftPath = Join-Path $artifactRoot 'draft-metadata.json'
$assessmentPath = Join-Path $artifactRoot 'run-assessment.json'
$metadataPath = Join-Path $metadataRoot 'scientific-run-metadata.json'

function NowUtc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function WriteJson([string]$Path, [object]$Value) {
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    [System.IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 30), (New-Object System.Text.UTF8Encoding($false)))
}
function Hash([string]$Relative) {
    (Get-FileHash (Join-Path $repo ($Relative.Replace('/', '\'))) -Algorithm SHA256).Hash.ToLowerInvariant()
}
function HostCounts {
    [ordered]@{
        whea_event_17 = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WHEA-Logger';Id=17} -ErrorAction SilentlyContinue).Count
        kernel_power_41 = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-Kernel-Power';Id=41} -ErrorAction SilentlyContinue).Count
        bugcheck = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName='Microsoft-Windows-WER-SystemErrorReporting';Id=1001} -ErrorAction SilentlyContinue).Count
    }
}
function SnapshotPods {
    $raw = & minikube kubectl --profile $Profile -- -n online-boutique get pods -o json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "pod_snapshot_failed:$($raw -join ' | ')" }
    $items = @((($raw -join "`n") | ConvertFrom-Json).items)
    $result = [ordered]@{}
    foreach ($pod in $items) {
        $app = [string]$pod.metadata.labels.app
        if ([string]::IsNullOrWhiteSpace($app)) { continue }
        if ($result.Contains($app)) { throw "multiple_pods_for_app:$app" }
        $restart = (@($pod.status.containerStatuses) | Measure-Object restartCount -Sum).Sum
        $result[$app] = [ordered]@{ pod_name=[string]$pod.metadata.name; uid=[string]$pod.metadata.uid; restart_count=[int]$restart }
    }
    if ($result.Count -ne 15) { throw "tracked_pod_count_invalid:$($result.Count)" }
    return $result
}
function InvokeScript([string]$Name, [string]$Path, [object[]]$Arguments) {
    Write-Output "step_started=$Name"
    & powershell -NoProfile -ExecutionPolicy Bypass -File $Path @Arguments
    if ($LASTEXITCODE -ne 0) { throw "step_failed:$Name" }
    Write-Output "step_passed=$Name"
}

if (-not (Test-Path -LiteralPath $PythonPath -PathType Leaf)) { throw 'python_runtime_missing' }
if (@(& git -C $repo status --porcelain).Count -ne 0) { throw 'working_tree_not_clean' }
if ((Test-Path $artifactRoot) -or (Test-Path $metadataRoot)) { throw 'run_artifact_path_already_exists' }
if (-not $PSCmdlet.ShouldProcess($RunId, 'execute preregistered scientific low CPU calibration')) { return }

$codeRevision = (& git -C $repo rev-parse HEAD).Trim()
$kustomHash = Hash 'p0-env/config/online-boutique/kustomization.yaml'
$observabilityHash = Hash 'p0-env/config/online-boutique/observability.yaml'
$hostBefore = HostCounts
$resetUtc = NowUtc
$stopped = $false
$failure = $null

try {
    InvokeScript 'active_run_id' (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') @('-ExpectedRunId',$RunId)
    $warmupStart = NowUtc
    Write-Output "phase=warmup start_utc=$warmupStart"
    Start-Sleep -Seconds 300
    $warmupEnd = NowUtc
    $baselineStart = NowUtc
    $podsBefore = SnapshotPods
    Write-Output "phase=normal_baseline start_utc=$baselineStart"
    Start-Sleep -Seconds 300
    $baselineEnd = NowUtc

    Write-Output 'step_started=bounded_cpu_injection'
    & (Join-Path $PSScriptRoot 'invoke-cpu-stress.ps1') `
        -ProfilePath (Join-Path $repo $faultRelative) `
        -RunId $RunId `
        -EvidencePath $executionPath `
        -Profile $Profile `
        -Confirm:$false
    Write-Output 'step_passed=bounded_cpu_injection'
    $execution = Get-Content -Raw $executionPath | ConvertFrom-Json
    $injectionStart = [string]$execution.injection_start_utc
    $injectionEnd = [string]$execution.injection_end_utc
    $rampEnd = ([datetimeoffset]::Parse($injectionStart).AddSeconds(120)).ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
    $cooldownStart = $injectionEnd
    Write-Output "phase=cooldown start_utc=$cooldownStart"
    Start-Sleep -Seconds 300
    $cooldownEnd = NowUtc
    $podsAfter = SnapshotPods
    $podStable = (($podsBefore | ConvertTo-Json -Depth 8 -Compress) -eq ($podsAfter | ConvertTo-Json -Depth 8 -Compress))

    $phases = [ordered]@{
        reset_health_check_utc=$resetUtc; warmup_start_utc=$warmupStart; warmup_end_utc=$warmupEnd
        normal_baseline_start_utc=$baselineStart; normal_baseline_end_utc=$baselineEnd
        injection_start_utc=$injectionStart; ramp_end_utc=$rampEnd; injection_end_utc=$injectionEnd
        cooldown_start_utc=$cooldownStart; cooldown_end_utc=$cooldownEnd
    }
    $draft = [ordered]@{ run_id=$RunId; fault_profile='cpu-recommendation-low-v1'; phases=$phases }
    WriteJson $draftPath $draft

    InvokeScript 'archive_raw_logs' (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') @('-RunId',$RunId,'-SinceUtc',$warmupStart,'-UntilUtc',$cooldownEnd)
    InvokeScript 'verify_raw_logs' (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') @('-ArchivePath',(Join-Path $repo "p0-env\artifacts\runs\$RunId"))
    InvokeScript 'enrich_logs' (Join-Path $PSScriptRoot 'enrich-log-run-id.ps1') @('-ArchivePath',(Join-Path $repo "p0-env\artifacts\runs\$RunId"))
    InvokeScript 'verify_enriched_logs' (Join-Path $PSScriptRoot 'verify-enriched-logs.ps1') @('-DerivedPath',(Join-Path $repo "p0-env\artifacts\derived\$RunId"))
    InvokeScript 'archive_telemetry' (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$cooldownEnd,'-TraceLimitPerService','5000','-TraceQueryChunkSeconds','300')
    InvokeScript 'verify_telemetry' (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') @('-TelemetryPath',(Join-Path $repo "p0-env\artifacts\telemetry\$RunId"))

    & $PythonPath (Join-Path $PSScriptRoot 'analyze-cpu-fault-effect.py') --telemetry-root (Join-Path $repo "p0-env\artifacts\telemetry\$RunId") --draft-metadata $draftPath --execution-evidence $executionPath --fault-profile (Join-Path $repo $faultRelative) --output $effectPath
    $effectExit = $LASTEXITCODE
    & $PythonPath (Join-Path $PSScriptRoot 'detect-fault-manifestation.py') --telemetry-root (Join-Path $repo "p0-env\artifacts\telemetry\$RunId") --draft-metadata $draftPath --slo-config (Join-Path $repo $sloRelative) --output $manifestationPath
    if ($LASTEXITCODE -ne 0) { throw 'manifestation_detection_failed' }
    $manifestation = Get-Content -Raw $manifestationPath | ConvertFrom-Json

    & minikube stop --profile $Profile
    if ($LASTEXITCODE -ne 0) { throw 'minikube_stop_failed' }
    $stopped = $true
    $hostAfter = HostCounts
    $hostHealth = [ordered]@{
        whea_event_17_before=$hostBefore.whea_event_17; whea_event_17_after=$hostAfter.whea_event_17; whea_event_17_delta=($hostAfter.whea_event_17-$hostBefore.whea_event_17)
        kernel_power_41_before=$hostBefore.kernel_power_41; kernel_power_41_after=$hostAfter.kernel_power_41; kernel_power_41_delta=($hostAfter.kernel_power_41-$hostBefore.kernel_power_41)
        bugcheck_before=$hostBefore.bugcheck; bugcheck_after=$hostAfter.bugcheck; bugcheck_delta=($hostAfter.bugcheck-$hostBefore.bugcheck)
    }
    $effect = Get-Content -Raw $effectPath | ConvertFrom-Json
    $valid = ($effectExit -eq 0 -and [bool]$effect.physical_effect_verified -and $podStable -and $hostHealth.whea_event_17_delta -eq 0 -and $hostHealth.kernel_power_41_delta -eq 0 -and $hostHealth.bugcheck_delta -eq 0)
    $metadata = [ordered]@{
        schema_version=1; run_id=$RunId; experiment_id='P1-CPU-001'; run_kind='fault_calibration'; system='online-boutique'
        code_revision=$codeRevision; deployment_revision="kustomization_sha256:$kustomHash;observability_sha256:$observabilityHash"
        fault_class='cpu_stress'; target_service='recommendationservice'; fault_profile='cpu-recommendation-low-v1'
        fault_profile_path=$faultRelative; fault_profile_sha256=(Hash $faultRelative)
        slo_id='p1-cpu-001-slo-v1'; slo_path=$sloRelative; slo_sha256=(Hash $sloRelative)
        workload_profile_id='ob-default-10u-1r-v1'; workload_profile_path=$workloadRelative; workload_profile_sha256=(Hash $workloadRelative); random_seed=1
        injector_evidence_path=$effectRelative; injector_evidence_sha256=(Hash $effectRelative)
        manifestation_evidence_path=$manifestationRelative; manifestation_evidence_sha256=(Hash $manifestationRelative)
        failure_manifestation=$manifestation.failure_manifestation; phases=$phases; host_health=$hostHealth
        runtime_evidence=[ordered]@{tracked_deployment_count=15; components_before=$podsBefore; components_after=$podsAfter; pod_lifecycle_stable=$podStable}
        operator_notes='First preregistered low CPU-stress calibration.'; valid_run=$valid
    }
    WriteJson $metadataPath $metadata
    WriteJson $assessmentPath ([ordered]@{run_id=$RunId; valid_run=$valid; physical_effect_verified=[bool]$effect.physical_effect_verified; pod_lifecycle_stable=$podStable; host_health=$hostHealth; failure_manifestation=$manifestation.failure_manifestation})
    if (-not $valid) { throw 'scientific_validity_gate_failed_evidence_preserved' }
    InvokeScript 'finalize_receipt' (Join-Path $PSScriptRoot 'finalize-run-artifacts.ps1') @('-RunId',$RunId,'-StartUtc',$warmupStart,'-EndUtc',$cooldownEnd,'-ScientificRunMetadataPath',$metadataPath)
    InvokeScript 'verify_finalized_receipt' (Join-Path $PSScriptRoot 'verify-finalized-run.ps1') @('-ReceiptPath',(Join-Path $repo "p0-env\artifacts\finalized\$RunId"))
    Write-Output 'low_cpu_calibration=passed'
}
catch {
    $failure = $_
    WriteJson (Join-Path $artifactRoot 'run-error.json') ([ordered]@{run_id=$RunId; status='invalid_or_incomplete'; failed_utc=(NowUtc); error=$_.Exception.Message})
    throw
}
finally {
    if (-not $stopped) {
        & minikube stop --profile $Profile 2>&1 | ForEach-Object { Write-Output ([string]$_) }
    }
}

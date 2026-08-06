[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$MetadataPath,
    [string]$ExpectedRunId,
    [string]$ExpectedStartUtc,
    [string]$ExpectedEndUtc
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$failures = New-Object System.Collections.Generic.List[string]
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$metadata = Get-Content -LiteralPath (Resolve-Path $MetadataPath) -Raw | ConvertFrom-Json

function Fail([string]$Message) { [void]$script:failures.Add($Message) }
function Has([object]$Object, [string]$Name, [string]$Context) {
    if ($Object.PSObject.Properties.Name -notcontains $Name) {
        Fail "missing_property:$Context.$Name"
        return $false
    }
    return $true
}
function Utc([string]$Value, [string]$Name) {
    if ($Value -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$') {
        Fail "invalid_utc:$Name=$Value"
        return $null
    }
    try { return [datetimeoffset]::Parse($Value).ToUniversalTime() }
    catch { Fail "invalid_utc:$Name=$Value"; return $null }
}
function RepoFile([string]$RelativePath, [string]$Name) {
    if ([System.IO.Path]::IsPathRooted($RelativePath)) {
        Fail "absolute_path_not_allowed:$Name"
        return $null
    }
    $path = [System.IO.Path]::GetFullPath((Join-Path $repositoryRoot $RelativePath))
    $prefix = $repositoryRoot.TrimEnd('\') + '\'
    if (-not $path.StartsWith($prefix, [System.StringComparison]::OrdinalIgnoreCase)) {
        Fail "path_escape_not_allowed:$Name"
        return $null
    }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        Fail "file_missing:$Name"
        return $null
    }
    return $path
}
function VerifyHash([string]$Path, [string]$Expected, [string]$Name) {
    if ($null -ne $Path) {
        $actual = (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($actual -ne $Expected.ToLowerInvariant()) { Fail "checksum_mismatch:$Name" }
    }
}

foreach ($name in @(
    'schema_version','run_id','experiment_id','run_kind','system','code_revision',
    'deployment_revision','fault_class','target_service','fault_profile',
    'fault_profile_path','fault_profile_sha256','slo_id','slo_path','slo_sha256',
    'workload_profile_id','workload_profile_path','workload_profile_sha256',
    'random_seed','injector_evidence_path','injector_evidence_sha256',
    'manifestation_evidence_path','manifestation_evidence_sha256','failure_manifestation','phases',
    'host_health','valid_run'
)) { [void](Has $metadata $name 'metadata') }

if ([int]$metadata.schema_version -ne 1) { Fail 'unsupported_metadata_schema' }
if ([string]$metadata.run_id -notmatch '^[a-z0-9][a-z0-9-]{2,63}$') { Fail 'invalid_run_id' }
if ($ExpectedRunId -and [string]$metadata.run_id -ne $ExpectedRunId) { Fail 'expected_run_id_mismatch' }
if ([string]$metadata.experiment_id -ne 'P1-CPU-001') { Fail 'unexpected_experiment_id' }
if ([string]$metadata.run_kind -ne 'fault_calibration') { Fail 'unexpected_run_kind' }
if ([string]$metadata.system -ne 'online-boutique') { Fail 'unexpected_system' }
if ([string]$metadata.fault_class -ne 'cpu_stress') { Fail 'unexpected_fault_class' }
if ([string]$metadata.target_service -ne 'recommendationservice') { Fail 'unexpected_target_service' }
$allowedCoverageIntervals = @{
    'cpu-recommendation-low-v1' = 240
    'cpu-recommendation-low-v2' = 48
    'cpu-recommendation-low-v3' = 48
}
$profileId = [string]$metadata.fault_profile
if (-not $allowedCoverageIntervals.ContainsKey($profileId)) { Fail 'unexpected_fault_profile' }
if ([string]$metadata.slo_id -ne 'p1-cpu-001-slo-v1') { Fail 'unexpected_slo_id' }
if ([string]$metadata.workload_profile_id -ne 'ob-default-10u-1r-v1') { Fail 'unexpected_workload_profile' }
if ([int]$metadata.random_seed -ne 1) { Fail 'unexpected_random_seed' }

$faultPath = RepoFile ([string]$metadata.fault_profile_path) 'fault_profile'
$sloPath = RepoFile ([string]$metadata.slo_path) 'slo'
$workloadPath = RepoFile ([string]$metadata.workload_profile_path) 'workload_profile'
$injectorPath = RepoFile ([string]$metadata.injector_evidence_path) 'injector_evidence'
$manifestationPath = RepoFile ([string]$metadata.manifestation_evidence_path) 'manifestation_evidence'
VerifyHash $faultPath ([string]$metadata.fault_profile_sha256) 'fault_profile'
VerifyHash $sloPath ([string]$metadata.slo_sha256) 'slo'
VerifyHash $workloadPath ([string]$metadata.workload_profile_sha256) 'workload_profile'
VerifyHash $injectorPath ([string]$metadata.injector_evidence_sha256) 'injector_evidence'
VerifyHash $manifestationPath ([string]$metadata.manifestation_evidence_sha256) 'manifestation_evidence'

if ($null -ne $faultPath) {
    $profile = Get-Content -LiteralPath $faultPath -Raw | ConvertFrom-Json
    if ([string]$profile.profile_id -ne $profileId) { Fail 'fault_profile_id_mismatch' }
    if ([int]$profile.physical_effect_verification.minimum_cpu_intervals_per_300_second_phase -ne $allowedCoverageIntervals[$profileId]) { Fail 'fault_coverage_contract_mismatch' }
    if ([int]$profile.injector.target_additional_cpu_millicores -ne 50) { Fail 'fault_target_millicores_mismatch' }
    if ([int]$profile.injector.ramp_seconds -ne 120) { Fail 'fault_ramp_seconds_mismatch' }
    if ([int]$profile.injector.steady_seconds -ne 300) { Fail 'fault_steady_seconds_mismatch' }
    if ($profileId -eq 'cpu-recommendation-low-v3' -and [string]$profile.injector.lifecycle_utc_source -ne 'worker-started-completed-events') { Fail 'fault_lifecycle_utc_source_mismatch' }
}
if ($null -ne $injectorPath) {
    $evidence = Get-Content -LiteralPath $injectorPath -Raw | ConvertFrom-Json
    if ([bool]$evidence.bounded_worker_verification -ne $true) { Fail 'bounded_worker_not_verified' }
    if ([bool]$evidence.physical_effect_verified -ne $true) { Fail 'physical_effect_not_verified' }
    if ([string]$evidence.run_id -ne [string]$metadata.run_id) { Fail 'injector_run_id_mismatch' }
    if ([string]$evidence.pod_uid_before -ne [string]$evidence.pod_uid_after) { Fail 'injector_pod_uid_changed' }
    if ([int]$evidence.restart_count_before -ne [int]$evidence.restart_count_after) { Fail 'injector_restart_count_changed' }
    if ($null -ne $faultPath -and [string]$evidence.worker_sha256 -ne [string]$profile.injector.worker_sha256) { Fail 'injector_worker_checksum_mismatch' }
    if ([string]$evidence.injection_start_utc -ne [string]$metadata.phases.injection_start_utc) { Fail 'injector_start_utc_mismatch' }
    if ([string]$evidence.injection_end_utc -ne [string]$metadata.phases.injection_end_utc) { Fail 'injector_end_utc_mismatch' }
    if ($profileId -eq 'cpu-recommendation-low-v3') {
        foreach ($name in @('transport_start_utc','transport_end_utc','worker_wall_duration_seconds','worker_monotonic_duration_seconds')) {
            [void](Has $evidence $name 'injector_evidence')
        }
        [void](Utc ([string]$evidence.transport_start_utc) 'injector_evidence.transport_start_utc')
        [void](Utc ([string]$evidence.transport_end_utc) 'injector_evidence.transport_end_utc')
        if ([math]::Abs([double]$evidence.worker_wall_duration_seconds - 420) -gt 5) { Fail 'worker_wall_duration_mismatch' }
        if ([math]::Abs([double]$evidence.worker_monotonic_duration_seconds - 420) -gt 5) { Fail 'worker_monotonic_duration_mismatch' }
    }
}
if ($null -ne $manifestationPath) {
    $manifestation = Get-Content -LiteralPath $manifestationPath -Raw | ConvertFrom-Json
    if ([string]$manifestation.run_id -ne [string]$metadata.run_id) { Fail 'manifestation_run_id_mismatch' }
    if ([string]$manifestation.slo_id -ne [string]$metadata.slo_id) { Fail 'manifestation_slo_id_mismatch' }
    if ([string]$manifestation.window_anchor_utc -ne [string]$metadata.phases.normal_baseline_start_utc) { Fail 'manifestation_window_anchor_mismatch' }
    if ([bool]$manifestation.phase_boundary_realignment -ne $false) { Fail 'manifestation_phase_realignment_forbidden' }
    if ([string]$manifestation.failure_manifestation -ne [string]$metadata.failure_manifestation) { Fail 'failure_manifestation_mismatch' }
}

$phaseNames = @(
    'reset_health_check_utc','warmup_start_utc','warmup_end_utc',
    'normal_baseline_start_utc','normal_baseline_end_utc','injection_start_utc',
    'ramp_end_utc','injection_end_utc','cooldown_start_utc','cooldown_end_utc'
)
$times = @{}
foreach ($name in $phaseNames) {
    if (Has $metadata.phases $name 'metadata.phases') {
        $times[$name] = Utc ([string]$metadata.phases.$name) $name
    }
}
for ($i=1; $i -lt $phaseNames.Count; $i++) {
    if ($null -ne $times[$phaseNames[$i-1]] -and $null -ne $times[$phaseNames[$i]] -and $times[$phaseNames[$i-1]] -gt $times[$phaseNames[$i]]) {
        Fail "phase_order_invalid:$($phaseNames[$i-1])>$($phaseNames[$i])"
    }
}
if ($null -ne $times.warmup_end_utc -and $null -ne $times.warmup_start_utc -and ($times.warmup_end_utc-$times.warmup_start_utc).TotalSeconds -lt 300) { Fail 'warmup_too_short' }
if ($null -ne $times.normal_baseline_end_utc -and $null -ne $times.normal_baseline_start_utc -and ($times.normal_baseline_end_utc-$times.normal_baseline_start_utc).TotalSeconds -lt 300) { Fail 'normal_baseline_too_short' }
if ($null -ne $times.ramp_end_utc -and $null -ne $times.injection_start_utc -and [math]::Abs(($times.ramp_end_utc-$times.injection_start_utc).TotalSeconds-120) -gt 5) { Fail 'ramp_duration_mismatch' }
if ($null -ne $times.injection_end_utc -and $null -ne $times.ramp_end_utc -and [math]::Abs(($times.injection_end_utc-$times.ramp_end_utc).TotalSeconds-300) -gt 5) { Fail 'steady_duration_mismatch' }
if ($null -ne $times.cooldown_end_utc -and $null -ne $times.cooldown_start_utc -and ($times.cooldown_end_utc-$times.cooldown_start_utc).TotalSeconds -lt 300) { Fail 'cooldown_too_short' }
if ($ExpectedStartUtc -and (Utc $ExpectedStartUtc 'ExpectedStartUtc') -ne $times.warmup_start_utc) { Fail 'metadata_start_utc_mismatch' }
if ($ExpectedEndUtc -and (Utc $ExpectedEndUtc 'ExpectedEndUtc') -ne $times.cooldown_end_utc) { Fail 'metadata_end_utc_mismatch' }

$actualRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]$metadata.code_revision -ne $actualRevision) { Fail 'code_revision_mismatch' }
foreach ($name in @('whea_event_17_delta','kernel_power_41_delta','bugcheck_delta')) {
    if (-not (Has $metadata.host_health $name 'metadata.host_health') -or [int]$metadata.host_health.$name -ne 0) { Fail "host_health_delta_nonzero_or_missing:$name" }
}
if ([bool]$metadata.valid_run -ne $true) { Fail 'metadata_not_marked_valid' }

Write-Output "metadata_path=$((Resolve-Path $MetadataPath).Path)"
Write-Output "run_id=$($metadata.run_id)"
Write-Output "fault_profile=$($metadata.fault_profile)"
Write-Output "failure_count=$($failures.Count)"
$failures | ForEach-Object { Write-Output "failure=$_" }
if ($failures.Count) { throw "Scientific fault-run metadata verification failed with $($failures.Count) failure(s)." }
Write-Output 'scientific_fault_run_metadata_verification=passed'

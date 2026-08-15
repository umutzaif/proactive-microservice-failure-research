[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$MetadataPath,
    [string]$ExpectedRunId,
    [string]$ExpectedStartUtc,
    [string]$ExpectedEndUtc
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$failures = [System.Collections.Generic.List[string]]::new()
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$metadata = Get-Content -LiteralPath (Resolve-Path $MetadataPath) -Raw | ConvertFrom-Json

function Fail([string]$Message) { [void]$script:failures.Add($Message) }
function Has([object]$Object, [string]$Name, [string]$Context) {
    if ($null -eq $Object -or $Object.PSObject.Properties.Name -notcontains $Name) {
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
    if ([string]::IsNullOrWhiteSpace($RelativePath) -or [System.IO.Path]::IsPathRooted($RelativePath)) {
        Fail "invalid_repository_relative_path:$Name"
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
    'fault_class','target_service','target_edge','fault_profile','fault_profile_path',
    'fault_profile_sha256','slo_id','slo_path','slo_sha256','workload_profile_id',
    'workload_profile_path','workload_profile_sha256','random_seed','injector_evidence_path',
    'injector_evidence_sha256','manifestation_evidence_path','manifestation_evidence_sha256',
    'failure_manifestation','phases','host_health','runtime_evidence','valid_run'
)) { [void](Has $metadata $name 'metadata') }

if ([int]$metadata.schema_version -ne 1) { Fail 'unsupported_metadata_schema' }
if ([string]$metadata.run_id -notmatch '^[a-z0-9][a-z0-9-]{2,63}$') { Fail 'invalid_run_id' }
if ($ExpectedRunId -and [string]$metadata.run_id -ne $ExpectedRunId) { Fail 'expected_run_id_mismatch' }
if ([string]$metadata.experiment_id -ne 'P2-NETWORK-DELAY-001') { Fail 'unexpected_experiment_id' }
if ([string]$metadata.run_kind -ne 'fault_calibration') { Fail 'unexpected_run_kind' }
if ([string]$metadata.system -ne 'online-boutique') { Fail 'unexpected_system' }
if ([string]$metadata.fault_class -ne 'network_delay') { Fail 'unexpected_fault_class' }
if ([string]$metadata.target_service -ne 'recommendationservice') { Fail 'unexpected_target_service' }
if ([string]$metadata.target_edge -ne 'recommendationservice->productcatalogservice') { Fail 'unexpected_target_edge' }
if ([string]$metadata.workload_profile_id -ne 'ob-second-15u-1r-v1' -or [int]$metadata.random_seed -ne 1) { Fail 'unexpected_workload_contract' }
if ([string]$metadata.slo_id -ne 'p2-network-delay-001-slo-v1') { Fail 'unexpected_slo_id' }

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
    if ([string]$profile.profile_id -ne [string]$metadata.fault_profile) { Fail 'fault_profile_id_mismatch' }
    if ([string]$profile.scientific_run_id -ne [string]$metadata.run_id) { Fail 'fault_profile_run_id_mismatch' }
    if ([string]$profile.workload_profile_id -ne [string]$metadata.workload_profile_id) { Fail 'fault_workload_profile_mismatch' }
    if ([int]$profile.injector.steady_latency_ms -ne 750) { Fail 'fault_steady_latency_mismatch' }
    if ([int]$profile.physical_effect.minimum_steady_minus_baseline_median_ms -ne 500) { Fail 'fault_physical_effect_mismatch' }
}
if ($null -ne $injectorPath) {
    $effect = Get-Content -LiteralPath $injectorPath -Raw | ConvertFrom-Json
    if ([string]$effect.run_id -ne [string]$metadata.run_id) { Fail 'injector_run_id_mismatch' }
    foreach ($name in @('physical_effect_verified','cleanup_verified','ramp_contract_verified')) {
        if (-not (Has $effect $name 'injector_evidence') -or [bool]$effect.$name -ne $true) { Fail "injector_gate_failed:$name" }
    }
    if ([string]$effect.first_symptom_utc -ne [string]$metadata.first_symptom_utc) { Fail 'first_symptom_mismatch' }
}
if ($null -ne $manifestationPath) {
    $manifestation = Get-Content -LiteralPath $manifestationPath -Raw | ConvertFrom-Json
    if ([string]$manifestation.run_id -ne [string]$metadata.run_id) { Fail 'manifestation_run_id_mismatch' }
    if ([string]$manifestation.slo_id -ne [string]$metadata.slo_id) { Fail 'manifestation_slo_id_mismatch' }
    if ([string]$manifestation.failure_manifestation -ne [string]$metadata.failure_manifestation) { Fail 'failure_manifestation_mismatch' }
}

$phaseNames = @('reset_health_check_utc','warmup_start_utc','warmup_end_utc','normal_baseline_start_utc','normal_baseline_end_utc','injection_start_utc','ramp_end_utc','injection_end_utc','cooldown_start_utc','cooldown_end_utc')
$times = @{}
foreach ($name in $phaseNames) {
    if (Has $metadata.phases $name 'metadata.phases') { $times[$name] = Utc ([string]$metadata.phases.$name) $name }
}
for ($index = 1; $index -lt $phaseNames.Count; $index++) {
    if ($null -ne $times[$phaseNames[$index - 1]] -and $null -ne $times[$phaseNames[$index]] -and $times[$phaseNames[$index - 1]] -gt $times[$phaseNames[$index]]) { Fail 'phase_order_invalid' }
}
if (($times.warmup_end_utc - $times.warmup_start_utc).TotalSeconds -lt 300) { Fail 'warmup_too_short' }
if (($times.normal_baseline_end_utc - $times.normal_baseline_start_utc).TotalSeconds -lt 300) { Fail 'baseline_too_short' }
if ([math]::Abs(($times.ramp_end_utc - $times.injection_start_utc).TotalSeconds - 120) -gt 5) { Fail 'ramp_duration_mismatch' }
if ([math]::Abs(($times.injection_end_utc - $times.ramp_end_utc).TotalSeconds - 300) -gt 5) { Fail 'steady_duration_mismatch' }
if (($times.cooldown_end_utc - $times.cooldown_start_utc).TotalSeconds -lt 300) { Fail 'cooldown_too_short' }
if ($ExpectedStartUtc -and (Utc $ExpectedStartUtc 'ExpectedStartUtc') -ne $times.warmup_start_utc) { Fail 'metadata_start_utc_mismatch' }
if ($ExpectedEndUtc -and (Utc $ExpectedEndUtc 'ExpectedEndUtc') -ne $times.cooldown_end_utc) { Fail 'metadata_end_utc_mismatch' }

$actualRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0 -or [string]$metadata.code_revision -ne $actualRevision) { Fail 'code_revision_mismatch' }
foreach ($name in @('whea_event_17_delta','kernel_power_41_delta','bugcheck_delta')) {
    if (-not (Has $metadata.host_health $name 'metadata.host_health') -or [int]$metadata.host_health.$name -ne 0) { Fail "host_health_delta_nonzero_or_missing:$name" }
}
$runtime = $metadata.runtime_evidence
if ([int]$runtime.tracked_deployment_count -ne 15) { Fail 'tracked_deployment_count_mismatch' }
foreach ($name in @('baseline_stable','steady_stable','cooldown_stable','cleanup_verified','rollback_verified')) {
    if (-not (Has $runtime $name 'runtime_evidence') -or [bool]$runtime.$name -ne $true) { Fail "runtime_gate_failed:$name" }
}
if ([string]$runtime.target_stability -ne 'passed') { Fail 'target_stability_failed' }
if ([bool]$metadata.valid_run -ne $true) { Fail 'metadata_not_marked_valid' }

Write-Output "metadata_path=$((Resolve-Path $MetadataPath).Path)"
Write-Output "run_id=$($metadata.run_id)"
Write-Output 'fault_class=network_delay'
Write-Output "failure_count=$($failures.Count)"
$failures | ForEach-Object { Write-Output "failure=$_" }
if ($failures.Count) { throw "Network-delay scientific metadata verification failed with $($failures.Count) failure(s)." }
Write-Output 'network_delay_scientific_metadata_verification=passed'

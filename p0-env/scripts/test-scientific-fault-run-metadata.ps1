[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$testRoot = Join-Path $repositoryRoot 'p0-env\state\tests\fault-metadata'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null

function Write-Json([string]$Path, [object]$Value) {
    [System.IO.File]::WriteAllText(
        $Path,
        ($Value | ConvertTo-Json -Depth 20),
        (New-Object System.Text.UTF8Encoding($false))
    )
}

$faultRelative = 'p0-env/config/faults/cpu-recommendation-low-v4.json'
$sloRelative = 'p0-env/config/slo/p1-cpu-001-slo-v1.json'
$workloadRelative = 'p0-env/config/workloads/ob-default-10u-1r-v1.json'
$evidenceRelative = 'p0-env/state/tests/fault-metadata/injector-evidence.json'
$evidencePath = Join-Path $repositoryRoot ($evidenceRelative.Replace('/', '\'))
$manifestationRelative = 'p0-env/state/tests/fault-metadata/manifestation-evidence.json'
$manifestationPath = Join-Path $repositoryRoot ($manifestationRelative.Replace('/', '\'))
$metadataPath = Join-Path $testRoot 'metadata.json'

$evidence = [ordered]@{
    run_id = 'ob-cpu-low-test-001'
    bounded_worker_verification = $true
    physical_effect_verified = $true
    pod_uid_before = 'pod-uid-a'
    pod_uid_after = 'pod-uid-a'
    restart_count_before = 0
    restart_count_after = 0
    worker_sha256 = '20cdfb9b360cf42c7b51e2a191eb3b3e04926f24b18e7179fa60ce85594337d4'
    worker_hash_normalization = 'utf8-lf'
    injection_start_utc = '2026-08-03T00:11:00Z'
    injection_end_utc = '2026-08-03T00:18:00Z'
    transport_start_utc = '2026-08-03T00:10:59Z'
    transport_end_utc = '2026-08-03T00:18:05Z'
    worker_wall_duration_seconds = 420
    worker_monotonic_duration_seconds = 420
}
Write-Json $evidencePath $evidence
Write-Json $manifestationPath ([ordered]@{
    run_id = 'ob-cpu-low-test-001'
    slo_id = 'p1-cpu-001-slo-v1'
    window_anchor_utc = '2026-08-03T00:06:00Z'
    phase_boundary_realignment = $false
    failure_manifestation = $null
})

$metadata = [ordered]@{
    schema_version = 1
    run_id = 'ob-cpu-low-test-001'
    experiment_id = 'P1-CPU-001'
    run_kind = 'fault_calibration'
    system = 'online-boutique'
    code_revision = (& git -C $repositoryRoot rev-parse HEAD).Trim()
    deployment_revision = 'synthetic-test'
    fault_class = 'cpu_stress'
    target_service = 'recommendationservice'
    fault_profile = 'cpu-recommendation-low-v4'
    fault_profile_path = $faultRelative
    fault_profile_sha256 = (Get-FileHash (Join-Path $repositoryRoot $faultRelative) -Algorithm SHA256).Hash.ToLowerInvariant()
    slo_id = 'p1-cpu-001-slo-v1'
    slo_path = $sloRelative
    slo_sha256 = (Get-FileHash (Join-Path $repositoryRoot $sloRelative) -Algorithm SHA256).Hash.ToLowerInvariant()
    workload_profile_id = 'ob-default-10u-1r-v1'
    workload_profile_path = $workloadRelative
    workload_profile_sha256 = (Get-FileHash (Join-Path $repositoryRoot $workloadRelative) -Algorithm SHA256).Hash.ToLowerInvariant()
    random_seed = 1
    injector_evidence_path = $evidenceRelative
    injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
    manifestation_evidence_path = $manifestationRelative
    manifestation_evidence_sha256 = (Get-FileHash $manifestationPath -Algorithm SHA256).Hash.ToLowerInvariant()
    failure_manifestation = $null
    phases = [ordered]@{
        reset_health_check_utc = '2026-08-03T00:00:00Z'
        warmup_start_utc = '2026-08-03T00:01:00Z'
        warmup_end_utc = '2026-08-03T00:06:00Z'
        normal_baseline_start_utc = '2026-08-03T00:06:00Z'
        normal_baseline_end_utc = '2026-08-03T00:11:00Z'
        injection_start_utc = '2026-08-03T00:11:00Z'
        ramp_end_utc = '2026-08-03T00:13:00Z'
        injection_end_utc = '2026-08-03T00:18:00Z'
        cooldown_start_utc = '2026-08-03T00:18:00Z'
        cooldown_end_utc = '2026-08-03T00:23:00Z'
    }
    host_health = [ordered]@{
        whea_event_17_delta = 0
        kernel_power_41_delta = 0
        bugcheck_delta = 0
    }
    valid_run = $true
}
Write-Json $metadataPath $metadata

$positive = @(& powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
    -MetadataPath $metadataPath `
    -ExpectedRunId 'ob-cpu-low-test-001' `
    -ExpectedStartUtc '2026-08-03T00:01:00Z' `
    -ExpectedEndUtc '2026-08-03T00:23:00Z' 2>&1)
if ($LASTEXITCODE -ne 0 -or ($positive -join "`n") -notmatch 'scientific_fault_run_metadata_verification=passed') {
    throw "Positive fault metadata fixture failed: $($positive -join ' | ')"
}

$evidence.physical_effect_verified = $false
Write-Json $evidencePath $evidence
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $negative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
if ($LASTEXITCODE -eq 0 -or ($negative -join "`n") -notmatch 'physical_effect_not_verified') {
    throw 'Fault metadata verifier accepted missing physical-effect evidence.'
}

$evidence.physical_effect_verified = $true
Write-Json $evidencePath $evidence
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
$metadata.phases.injection_start_utc = '2026-08-03T00:11:00+00:00'
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $utcNegative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
if ($LASTEXITCODE -eq 0 -or ($utcNegative -join "`n") -notmatch 'invalid_utc:injection_start_utc') {
    throw 'Fault metadata verifier accepted a non-canonical UTC offset.'
}
if (($utcNegative -join "`n") -match 'op_Subtraction') {
    throw 'Fault metadata verifier crashed while reporting invalid UTC.'
}

$metadata.phases.injection_start_utc = '2026-08-03T00:11:00Z'
$evidence.injection_start_utc = '2026-08-03T00:11:01Z'
Write-Json $evidencePath $evidence
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $sourceNegative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
if ($LASTEXITCODE -eq 0 -or ($sourceNegative -join "`n") -notmatch 'injector_start_utc_mismatch') {
    throw 'Fault metadata verifier accepted mismatched worker and metadata UTC.'
}

$evidence.injection_start_utc = '2026-08-03T00:11:00Z'
$evidence.worker_hash_normalization = 'raw-bytes'
Write-Json $evidencePath $evidence
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $normalizationNegative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally {
    $ErrorActionPreference = $previousErrorActionPreference
}
if ($LASTEXITCODE -eq 0 -or ($normalizationNegative -join "`n") -notmatch 'injector_worker_hash_normalization_mismatch') {
    throw 'Fault metadata verifier accepted mismatched worker hash normalization.'
}

Write-Output 'fault_metadata_positive_fixture=passed'
Write-Output 'fault_metadata_physical_effect_negative_fixture=passed'
Write-Output 'fault_metadata_noncanonical_utc_negative_fixture=passed'
Write-Output 'fault_metadata_worker_utc_mismatch_negative_fixture=passed'
Write-Output 'fault_metadata_worker_hash_normalization_negative_fixture=passed'

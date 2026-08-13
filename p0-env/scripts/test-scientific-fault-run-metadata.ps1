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

$mediumRelative = 'p0-env/config/faults/cpu-recommendation-medium-v1.json'
$evidence.worker_hash_normalization = 'utf8-lf'
Write-Json $evidencePath $evidence
$metadata.fault_profile = 'cpu-recommendation-medium-v1'
$metadata.fault_profile_path = $mediumRelative
$metadata.fault_profile_sha256 = (Get-FileHash (Join-Path $repositoryRoot $mediumRelative) -Algorithm SHA256).Hash.ToLowerInvariant()
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$mediumPositive = @(& powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
    -MetadataPath $metadataPath 2>&1)
if ($LASTEXITCODE -ne 0 -or ($mediumPositive -join "`n") -notmatch 'scientific_fault_run_metadata_verification=passed') {
    throw "Medium metadata positive fixture failed: $($mediumPositive -join ' | ')"
}

$invalidMediumRelative = 'p0-env/state/tests/fault-metadata/invalid-medium-profile.json'
$invalidMediumPath = Join-Path $repositoryRoot ($invalidMediumRelative.Replace('/', '\'))
$invalidMedium = Get-Content (Join-Path $repositoryRoot $mediumRelative) -Raw | ConvertFrom-Json
$invalidMedium.physical_effect_verification.minimum_steady_minus_baseline_mean_millicores = 49
Write-Json $invalidMediumPath $invalidMedium
$metadata.fault_profile_path = $invalidMediumRelative
$metadata.fault_profile_sha256 = (Get-FileHash $invalidMediumPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $mediumNegative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally { $ErrorActionPreference = $previousErrorActionPreference }
if ($LASTEXITCODE -eq 0 -or ($mediumNegative -join "`n") -notmatch 'fault_minimum_increase_contract_mismatch') {
    throw 'Scientific metadata verifier accepted a 49 mCPU medium minimum-increase gate.'
}

Write-Output 'fault_metadata_medium_positive_fixture=passed'
Write-Output 'fault_metadata_medium_minimum_increase_negative_fixture=passed'

$highRelative = 'p0-env/config/faults/cpu-recommendation-high-v1.json'
$metadata.fault_profile = 'cpu-recommendation-high-v1'
$metadata.fault_profile_path = $highRelative
$metadata.fault_profile_sha256 = (Get-FileHash (Join-Path $repositoryRoot $highRelative) -Algorithm SHA256).Hash.ToLowerInvariant()
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$highPositive = @(& powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'verify-scientific-fault-run-metadata.ps1') `
    -MetadataPath $metadataPath 2>&1)
if ($LASTEXITCODE -ne 0 -or ($highPositive -join "`n") -notmatch 'scientific_fault_run_metadata_verification=passed') {
    throw "High metadata positive fixture failed: $($highPositive -join ' | ')"
}

$invalidHighRelative = 'p0-env/state/tests/fault-metadata/invalid-high-profile.json'
$invalidHighPath = Join-Path $repositoryRoot ($invalidHighRelative.Replace('/', '\'))
$invalidHigh = Get-Content (Join-Path $repositoryRoot $highRelative) -Raw | ConvertFrom-Json
$invalidHigh.physical_effect_verification.minimum_steady_minus_baseline_mean_millicores = 74
Write-Json $invalidHighPath $invalidHigh
$metadata.fault_profile_path = $invalidHighRelative
$metadata.fault_profile_sha256 = (Get-FileHash $invalidHighPath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $highNegative = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-fault-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally { $ErrorActionPreference = $previousErrorActionPreference }
if ($LASTEXITCODE -eq 0 -or ($highNegative -join "`n") -notmatch 'fault_minimum_increase_contract_mismatch') {
    throw 'Scientific metadata verifier accepted a 74 mCPU high minimum-increase gate.'
}

Write-Output 'fault_metadata_high_positive_fixture=passed'
Write-Output 'fault_metadata_high_minimum_increase_negative_fixture=passed'

$high15Relative = 'p0-env/config/faults/cpu-recommendation-high-15u-v1.json'
$workload15Relative = 'p0-env/config/workloads/ob-second-15u-1r-v1.json'
$evidence.pod_name = 'recommendationservice-test'
$evidence.container_id_before = 'containerd://stable'
$evidence.target_stability_policy_id = 'd038-target-pod-stability-v1'
$evidence.target_stability_evidence_sha256 = ('a' * 64)
$evidence.target_stability = [ordered]@{
    policy_id = 'd038-target-pod-stability-v1'
    required_duration_seconds = 120
    poll_seconds = 5
    stable = $true
    final_snapshot = [ordered]@{
        pod_name = 'recommendationservice-test'
        pod_uid = 'pod-uid-a'
        container_id = 'containerd://stable'
        restart_count = 0
    }
}
Write-Json $evidencePath $evidence
$metadata.fault_profile = 'cpu-recommendation-high-15u-v1'
$metadata.fault_profile_path = $high15Relative
$metadata.fault_profile_sha256 = (Get-FileHash (Join-Path $repositoryRoot $high15Relative) -Algorithm SHA256).Hash.ToLowerInvariant()
$metadata.workload_profile_id = 'ob-second-15u-1r-v1'
$metadata.workload_profile_path = $workload15Relative
$metadata.workload_profile_sha256 = (Get-FileHash (Join-Path $repositoryRoot $workload15Relative) -Algorithm SHA256).Hash.ToLowerInvariant()
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$high15Positive = @(& powershell -NoProfile -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'verify-scientific-fault-run-metadata.ps1') `
    -MetadataPath $metadataPath 2>&1)
if ($LASTEXITCODE -ne 0 -or ($high15Positive -join "`n") -notmatch 'scientific_fault_run_metadata_verification=passed') {
    throw "15-user high metadata positive fixture failed: $($high15Positive -join ' | ')"
}

$evidence.target_stability.final_snapshot.restart_count = 1
Write-Json $evidencePath $evidence
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $stabilityMismatch = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-fault-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally { $ErrorActionPreference = $previousErrorActionPreference }
if ($LASTEXITCODE -eq 0 -or ($stabilityMismatch -join "`n") -notmatch 'target_stability_restart_count_mismatch') {
    throw 'Fault metadata verifier accepted mismatched D-038 restart evidence.'
}
Write-Output 'fault_metadata_15u_stability_restart_negative_fixture=passed'
$evidence.target_stability.final_snapshot.restart_count = 0
Write-Json $evidencePath $evidence
$metadata.injector_evidence_sha256 = (Get-FileHash $evidencePath -Algorithm SHA256).Hash.ToLowerInvariant()

$metadata.workload_profile_id = 'ob-default-10u-1r-v1'
$metadata.workload_profile_path = $workloadRelative
$metadata.workload_profile_sha256 = (Get-FileHash (Join-Path $repositoryRoot $workloadRelative) -Algorithm SHA256).Hash.ToLowerInvariant()
Write-Json $metadataPath $metadata
$previousErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try {
    $workloadMismatch = @(& powershell -NoProfile -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-scientific-fault-run-metadata.ps1') `
        -MetadataPath $metadataPath 2>&1)
}
finally { $ErrorActionPreference = $previousErrorActionPreference }
if ($LASTEXITCODE -eq 0 -or ($workloadMismatch -join "`n") -notmatch 'fault_workload_profile_mismatch') {
    throw 'Fault metadata verifier accepted a 15-user fault profile with 10-user metadata.'
}

Write-Output 'fault_metadata_15u_high_positive_fixture=passed'
Write-Output 'fault_metadata_15u_workload_mismatch_negative_fixture=passed'
exit 0

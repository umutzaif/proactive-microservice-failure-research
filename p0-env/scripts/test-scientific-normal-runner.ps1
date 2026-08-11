[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runner = Join-Path $PSScriptRoot 'run-scientific-normal-baseline.ps1'
$tokens = $null
$parseErrors = $null
[void][System.Management.Automation.Language.Parser]::ParseFile($runner, [ref]$tokens, [ref]$parseErrors)
if (@($parseErrors).Count -ne 0) { throw "normal_runner_parse_failed:$($parseErrors -join ' | ')" }
$runnerText = Get-Content $runner -Raw
foreach ($forbidden in @('invoke-cpu-stress','FaultProfileRelative','injection_start_utc','bounded_cpu_injection')) {
    if ($runnerText -match [regex]::Escape($forbidden)) { throw "normal_runner_contains_fault_path:$forbidden" }
}
foreach ($required in @('verify-active-run-id.ps1','verify-active-workload-profile.ps1','archive-run-telemetry.ps1','verify-scientific-run-metadata.ps1','finalize-run-artifacts.ps1','verify-finalized-run.ps1')) {
    if ($runnerText -notmatch [regex]::Escape($required)) { throw "normal_runner_missing_gate:$required" }
}

$testRoot = Join-Path $repo 'p0-env\state\tests\normal-15u-metadata'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$metadataPath = Join-Path $testRoot 'metadata.json'
$workloadRelative = 'p0-env/config/workloads/ob-second-15u-1r-v1.json'
$workloadPath = Join-Path $repo ($workloadRelative.Replace('/', '\'))
function WriteMetadata([string]$ProfileId) {
    $metadata = [ordered]@{
        schema_version=1;run_id='ob-cpu-15u-normal-test';experiment_id='P1-CPU-001';run_kind='normal_baseline';system='online-boutique'
        code_revision=(& git -C $repo rev-parse HEAD).Trim();deployment_revision='synthetic-test';fault_class='normal';target_service=$null;fault_profile='none'
        workload_profile_id=$ProfileId;workload_profile_path=$workloadRelative;workload_profile_sha256=(Get-FileHash $workloadPath -Algorithm SHA256).Hash.ToLowerInvariant();random_seed=1
        phases=[ordered]@{reset_health_check_utc='2026-08-11T00:00:00Z';warmup_start_utc='2026-08-11T00:00:00Z';warmup_end_utc='2026-08-11T00:05:00Z';normal_baseline_start_utc='2026-08-11T00:05:00Z';normal_baseline_end_utc='2026-08-11T00:10:00Z'}
        host_health=[ordered]@{whea_event_17_before=1;whea_event_17_after=1;whea_event_17_delta=0;kernel_power_41_before=1;kernel_power_41_after=1;kernel_power_41_delta=0;bugcheck_before=1;bugcheck_after=1;bugcheck_delta=0}
        valid_run=$true
    }
    [IO.File]::WriteAllText($metadataPath, ($metadata | ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
}

WriteMetadata 'ob-second-15u-1r-v1'
$positive = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') -MetadataPath $metadataPath -ExpectedRunId 'ob-cpu-15u-normal-test' -ExpectedStartUtc '2026-08-11T00:00:00Z' -ExpectedEndUtc '2026-08-11T00:10:00Z' 2>&1)
if ($LASTEXITCODE -ne 0 -or ($positive -join "`n") -notmatch 'scientific_run_metadata_verification=passed') { throw "normal_15u_metadata_positive_failed:$($positive -join ' | ')" }

WriteMetadata 'ob-default-10u-1r-v1'
$previous = $ErrorActionPreference
$ErrorActionPreference = 'Continue'
try { $negative = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') -MetadataPath $metadataPath 2>&1) }
finally { $ErrorActionPreference = $previous }
if ($LASTEXITCODE -eq 0 -or ($negative -join "`n") -notmatch 'workload_profile_id_mismatch') { throw 'normal metadata verifier accepted mismatched 10u ID with 15u profile hash.' }

Write-Output 'scientific_normal_runner_parse_and_no_fault_fixture=passed'
Write-Output 'scientific_normal_runner_required_gates_fixture=passed'
Write-Output 'scientific_normal_15u_metadata_positive_fixture=passed'
Write-Output 'scientific_normal_15u_metadata_mismatch_negative_fixture=passed'
exit 0

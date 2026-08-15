$ErrorActionPreference = 'Stop'
$script = Get-Content (Join-Path $PSScriptRoot 'run-network-delay-proxy-live.ps1') -Raw

foreach ($required in @(
    "RunId = 'ob-network-proxy-live-001'",
    "WorkloadProfileRelative = 'p0-env/config/workloads/ob-second-15u-1r-v1.json'",
    "WaitMinimum `$phases.base_warmup_start_utc 300",
    "WaitMinimum `$phases.base_measurement_start_utc 300",
    "WaitMinimum `$phases.proxy_stabilization_start_utc 120",
    "WaitMinimum `$phases.proxy_measurement_start_utc 300",
    "--action verify-clean",
    "scientific_fault_started=`$false",
    "-TraceQueryChunkSeconds 300",
    "Rollback"
)) {
    if (-not $script.Contains($required)) { throw "runner_contract_missing:$required" }
}
foreach ($forbidden in @('/toxics','latency_toxic','target_latency_ms','scientific_run_authorized=true')) {
    if ($script.Contains($forbidden)) { throw "runner_fault_capability_forbidden:$forbidden" }
}
if (([regex]::Matches($script, '--action verify-clean')).Count -ne 2) { throw 'proxy_clean_check_count_invalid' }
Write-Output 'network_delay_proxy_live_runner_contract=passed'

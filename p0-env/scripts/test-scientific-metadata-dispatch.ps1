$ErrorActionPreference = 'Stop'
$dispatcher = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') -Raw
$network = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'verify-network-delay-scientific-metadata.ps1') -Raw

foreach ($required in @(
    "fault_class -eq 'network_delay'",
    "'verify-network-delay-scientific-metadata.ps1'",
    "fault_class -eq 'cpu_stress'",
    "'verify-scientific-fault-run-metadata.ps1'",
    'Unsupported fault_class'
)) {
    if (-not $dispatcher.Contains($required)) { throw "metadata_dispatch_contract_missing:$required" }
}
foreach ($required in @(
    "fault_class -ne 'network_delay'",
    "experiment_id -ne 'P2-NETWORK-DELAY-001'",
    'minimum_steady_minus_baseline_median_ms',
    'runtime_gate_failed',
    'host_health_delta_nonzero_or_missing'
)) {
    if (-not $network.Contains($required)) { throw "network_metadata_contract_missing:$required" }
}
if ($network.Contains('$profile.severity')) { throw 'network_metadata_cpu_severity_coupling_detected' }
Write-Output 'scientific_metadata_fault_class_dispatch=passed'

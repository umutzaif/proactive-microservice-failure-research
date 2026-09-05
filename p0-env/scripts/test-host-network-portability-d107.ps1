$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$runner = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'run-host-network-portability-diagnostic.ps1') -Raw
foreach ($required in @(
    "`$closedDiagnosticId='ob-host-network-portability-wifi-001'",
    "if(`$DiagnosticId-eq`$closedDiagnosticId){throw 'closed_diagnostic_id'}",
    "`$e2eRunId='ob-host-network-portability-wifi-002-e2e'",
    "`$DiagnosticId-ne'ob-host-network-portability-wifi-002'",
    "preregistration_decision='D-107'"
)) {
    if (-not $runner.Contains($required)) {
        throw "d107_runner_contract_missing:$required"
    }
}
if ($runner.Contains("`$DiagnosticId-ne'ob-host-network-portability-wifi-001'")) {
    throw 'd107_closed_id_reenabled'
}
Write-Output 'host_network_portability_d107_contract=passed'

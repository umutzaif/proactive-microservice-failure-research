$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$scriptPath = Join-Path $PSScriptRoot 'archive-raw-logs.ps1'
$script = Get-Content -LiteralPath $scriptPath -Raw

foreach ($required in @(
    '$clusterStatusLines = [string[]]@(& minikube status',
    '$clusterStatusExitCode = $LASTEXITCODE',
    '$clusterStatus = ($clusterStatusLines -join "`n").Trim()',
    '$clusterStatusExitCode -ne 0'
)) {
    if (-not $script.Contains($required)) {
        throw "raw_log_status_capture_contract_missing:$required"
    }
}

if ($script.Contains('(& minikube status --profile $Profile 2>&1 | Out-String).Trim()')) {
    throw 'raw_log_status_capture_pipeline_regression'
}

$captureIndex = $script.IndexOf('$clusterStatusLines = [string[]]@(& minikube status')
$exitIndex = $script.IndexOf('$clusterStatusExitCode = $LASTEXITCODE')
$joinIndex = $script.IndexOf('$clusterStatus = ($clusterStatusLines -join "`n").Trim()')
if ($captureIndex -lt 0 -or $exitIndex -le $captureIndex -or $joinIndex -le $exitIndex) {
    throw 'raw_log_status_capture_order_invalid'
}

Write-Output 'raw_log_minikube_status_capture_tests=passed'

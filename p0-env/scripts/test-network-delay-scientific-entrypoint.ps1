param([Parameter(Mandatory)][string]$PythonPath)
$ErrorActionPreference = 'Stop'
$runner = Join-Path $PSScriptRoot 'run-network-delay-scientific.ps1'
$output = & pwsh -NoProfile -ExecutionPolicy Bypass -File $runner -RunId ob-netdelay-15u-repeat-001 -PythonPath $PythonPath -ExecutionApproved -WhatIf 2>&1
if ($LASTEXITCODE -ne 0) { throw "entrypoint_whatif_failed:$($output -join ' | ')" }
if (($output -join "`n") -notmatch 'What if:') { throw 'entrypoint_whatif_evidence_missing' }
Write-Output 'network_delay_scientific_entrypoint=passed confirm_impact=Low whatif=no-mutation'

$ErrorActionPreference='Stop'
$source=Get-Content -LiteralPath(Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1')-Raw
foreach($required in @('manifest_already_exists','sealed_file_missing','sealed_hash_mismatch','sealed_size_mismatch','sealed_file_count_mismatch','diagnostic_offline_verification=passed')){if(-not$source.Contains($required)){throw"diagnostic_seal_contract_missing:$required"}}
Write-Output 'diagnostic_seal_contract=passed'

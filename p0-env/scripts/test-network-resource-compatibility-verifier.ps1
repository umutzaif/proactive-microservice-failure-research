$ErrorActionPreference='Stop';$s=Get-Content -LiteralPath(Join-Path $PSScriptRoot 'verify-network-resource-compatibility.ps1')-Raw
foreach($guard in @('host_gate_failed','rollback_gate_failed','proxy_clean_gate_failed','duration_contract_failed','target_uid_changed','lifecycle_gate_failed','metric_type_coverage_failed','metric_time_coverage_failed','throttled_fraction_gate_failed','cpu_pressure_gate_failed','memory_gate_failed','node_pressure_gate_failed')){if(-not$s.Contains($guard)){throw "resource_compat_verifier_guard_missing:$guard"}}
if(-not$s.Contains('$fraction-ge0.50')-or-not$s.Contains('$pressure-ge10.635359')){throw 'frozen_threshold_contract_missing'}
Write-Output 'network_resource_compatibility_verifier_contract=passed'

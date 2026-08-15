$ErrorActionPreference='Stop'
$source=Get-Content -LiteralPath(Join-Path $PSScriptRoot 'verify-network-probe-resource-diagnostic.ps1')-Raw
foreach($required in @('host_gate_failed','rollback_gate_failed','pod_coverage_failed','restart_not_reproduced','metric_type_coverage_failed','metric_time_coverage_failed','completed_valid_diagnostic','liveness_killing_event_objects','liveness_killing_occurrences','cfs_throttled_period_fraction','oom_events_delta')){if(-not$source.Contains($required)){throw"probe_resource_verifier_contract_missing:$required"}}
Write-Output 'network_probe_resource_verifier_contract=passed'

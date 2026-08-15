$ErrorActionPreference='Stop'
$source=Get-Content -Raw(Join-Path $PSScriptRoot 'run-network-delay-proxy-readiness-diagnostic.ps1')
foreach($required in @("DiagnosticId='ob-network-proxy-readiness-002'",'working_tree_not_clean','duration_seconds=180','poll_seconds=5','containerStatuses','last_state','kubernetes-optional-property.ps1','replicasets.json','events.json','$container-current.log','$container-previous.log','Rollback','HostCounts','minikube stop','explicit_diagnostic_approval_required')){if(-not$source.Contains($required)){throw "diagnostic_contract_missing:$required"}}
foreach($forbidden in @('--action ramp','manage-network-delay-toxic.py','faultStarted','warmup')){if($source.Contains($forbidden)){throw "diagnostic_fault_capability_forbidden:$forbidden"}}
Write-Output 'network_proxy_readiness_diagnostic_contract=passed'

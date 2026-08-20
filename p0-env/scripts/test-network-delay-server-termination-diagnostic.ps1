$ErrorActionPreference='Stop'
$source=Get-Content -Raw(Join-Path $PSScriptRoot 'run-network-delay-server-termination-diagnostic.ps1')
foreach($required in @("DiagnosticId='ob-network-server-termination-001'",'explicit_diagnostic_approval_required','working_tree_not_clean','duration_seconds=180','poll_seconds=5','qos_class','container_id','restart_count','events.json','node-before.json','node-after.json','metrics-api.txt','pod-describe.txt','$container-current.log','$container-previous.log','kubelet-journal.txt','Rollback','minikube stop','New-HostEventRecordIdBoundary','Measure-HostEventsAfterRecordIdBoundary')){if(-not$source.Contains($required)){throw "server_termination_diagnostic_contract_missing:$required"}}
if($source.Contains('manage-network-delay-toxic.py')-or$source.Contains('--action ramp')){throw 'fault_path_forbidden'}
Write-Output 'network_server_termination_diagnostic_contract=passed'

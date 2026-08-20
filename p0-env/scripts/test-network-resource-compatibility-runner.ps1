$ErrorActionPreference='Stop';$s=Get-Content -LiteralPath(Join-Path $PSScriptRoot 'run-network-resource-compatibility.ps1')-Raw
foreach($required in @('ob-network-resource-compat-004','network-delay-resource-compatibility','explicit_execution_approval_required','working_tree_not_clean','immutable_output_exists','Observe 120','Observe 180','-RequireStable','500m','100m','proxy_clean_before_failed','proxy_clean_after_failed','New-HostEventRecordIdBoundary','Measure-HostEventsAfterRecordIdBoundary','Rollback','scientific_fault_started=$false','Invoke-NativeJsonCommand','kubectl-stderr.log','[string[]]$KubectlArguments','-ArgumentList $KubectlArguments')){if(-not$s.Contains($required)){throw "resource_compat_runner_contract_missing:$required"}}
if($s.Contains('[string[]]$Args')){throw 'powershell_automatic_args_parameter_forbidden'}
function Test-KubectlArgumentBinding([string[]]$KubectlArguments){[pscustomobject]@{count=$KubectlArguments.Count;first=$KubectlArguments[0];second=$KubectlArguments[1]}}
$bound=Test-KubectlArgumentBinding @('get','node')
if($bound.count-ne2-or$bound.first-ne'get'-or$bound.second-ne'node'){throw 'kubectl_argument_binding_fixture_failed'}
if($s.Contains('minikube kubectl --profile $Profile -- @Args 2>&1')){throw 'json_stderr_merge_forbidden'}
foreach($forbidden in @('manage-network-delay-toxic.py','--action ramp','faultStarted=$true')){if($s.Contains($forbidden)){throw "fault_capability_forbidden:$forbidden"}}
Write-Output 'network_resource_compatibility_runner_contract=passed'

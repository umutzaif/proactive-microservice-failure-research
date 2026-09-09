$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$state = Join-Path $repo ('p0-env/state/tests/d111-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $state -Force | Out-Null
$shell = (Get-Process -Id $PID).Path
function WriteFixture($path,$value) { [IO.File]::WriteAllText($path,($value | ConvertTo-Json -Depth 50),[Text.UTF8Encoding]::new($false)) }
function NewPod([string]$Uid,[bool]$Ready=$true,[bool]$Terminating=$false) {
    $metadata = [ordered]@{name="pod-$Uid";uid=$Uid}
    if ($Terminating) { $metadata['deletionTimestamp']='2026-09-09T00:00:00Z' }
    [ordered]@{metadata=$metadata;spec=@{containers=@(@{name='server'},@{name='network-delay-proxy'})};status=@{conditions=@(@{type='Ready';status=$(if($Ready){'True'}else{'False'})});containerStatuses=@(@{name='server';ready=$Ready;restartCount=0;containerID="containerd://$Uid"},@{name='network-delay-proxy';ready=$Ready;restartCount=0;containerID="containerd://proxy-$Uid"})}}
}
function Snapshot([double]$Elapsed,[object[]]$Pods) { @{elapsed_seconds=$Elapsed;pod_list=@{items=$Pods}} }
function RunFixture($script,$arguments) {
    $old=$ErrorActionPreference; $ErrorActionPreference='Continue'
    try { $output=@(& $shell -NoProfile -File (Join-Path $PSScriptRoot $script) @arguments 2>&1); $code=$LASTEXITCODE } finally { $ErrorActionPreference=$old }
    @{code=$code;text=($output -join "`n")}
}
function ConvergenceCase($name,$snapshots,[bool]$expected) {
    $inputPath=Join-Path $state "$name-input.json"; $outputPath=Join-Path $state "$name-output.json"
    WriteFixture $inputPath @{snapshots=$snapshots}
    $run=RunFixture 'wait-normal-proxy-convergence.ps1' @('-EvidencePath',$outputPath,'-FixtureSnapshotsPath',$inputPath)
    $e=Get-Content $outputPath -Raw | ConvertFrom-Json
    if (($run.code -eq 0) -ne $expected -or $e.passed -ne $expected -or $e.timeout_seconds -ne 120 -or $e.poll_seconds -ne 5) { throw "convergence_case_failed:$name" }
    return $e
}
$oldPod=NewPod 'old' $true $true; $newPod=NewPod 'new'
$e=ConvergenceCase 'two-to-one' @((Snapshot 0 @($oldPod,$newPod)),(Snapshot 5 @($newPod))) $true
if ($e.observations[0].pod_count -ne 2 -or -not $e.observations[0].pod_list.items[0].metadata.deletionTimestamp -or $e.observations.Count -ne 2) { throw 'terminating_predecessor_not_preserved' }
[void](ConvergenceCase 'permanent-two' @((Snapshot 0 @($oldPod,$newPod)),(Snapshot 120 @($oldPod,$newPod))) $false)
[void](ConvergenceCase 'late-ready' @((Snapshot 0 @()),(Snapshot 125 @($newPod))) $false)
[void](ConvergenceCase 'not-ready' @((Snapshot 0 @((NewPod 'pending' $false))),(Snapshot 120 @((NewPod 'pending' $false)))) $false)
[void](ConvergenceCase 'sole-terminating' @((Snapshot 0 @($oldPod)),(Snapshot 120 @($oldPod))) $false)
$e=ConvergenceCase 'missing-status' @((Snapshot 0 @(@{metadata=@{name='pending';uid='pending'}})),(Snapshot 5 @($newPod))) $true
if ($e.observations[0].ready) { throw 'pending_pod_accepted' }
$beforeHash=(Get-FileHash (Join-Path $state 'two-to-one-output.json')).Hash
$retry=RunFixture 'wait-normal-proxy-convergence.ps1' @('-EvidencePath',(Join-Path $state 'two-to-one-output.json'),'-FixtureSnapshotsPath',(Join-Path $state 'two-to-one-input.json'))
if ($retry.code -eq 0 -or $beforeHash -ne (Get-FileHash (Join-Path $state 'two-to-one-output.json')).Hash) { throw 'convergence_evidence_overwritten' }

$stabilityInput=Join-Path $state 'stability-input.json'; $stabilityOutput=Join-Path $state 'stability.json'
WriteFixture $stabilityInput @{snapshots=@(@{items=@($oldPod,$newPod)},@{items=@($newPod)})}
$run=RunFixture 'verify-target-pod-stability.ps1' @('-Namespace','online-boutique','-Deployment','recommendationservice','-Container','server','-EvidencePath',$stabilityOutput,'-FixtureSnapshotsPath',$stabilityInput)
$failure=Get-Content "$stabilityOutput.failure.json" -Raw | ConvertFrom-Json
if ($run.code -eq 0 -or $failure.error -ne 'target_pod_count_invalid:2' -or $failure.pod_list.items.Count -ne 2 -or $failure.stable -ne $false -or (Test-Path $stabilityOutput)) { throw 'stability_failure_evidence_missing' }

. (Join-Path $PSScriptRoot 'normal-failure-closure.ps1')
$script:mode='ok'
function Measure-HostEventsAfterRecordIdBoundary { param($Boundary) if($script:mode -eq 'host-denied'){throw 'access_denied'}; @{passed=($script:mode -ne 'host-event');counts=@{whea_event_17=$(if($script:mode -eq 'host-event'){1}else{0});kernel_power_41=0;bugcheck=0}} }
function Get-HostNetworkContext { param($ExpectedTransport) if($script:mode -eq 'network-lost'){throw 'network_lost'}; @{transport='ethernet'} }
function Assert-HostNetworkContextStable { param($Before,$After) $true }
function minikube { if($args[0] -ne 'status'){throw 'live_mutation_forbidden'}; $global:LASTEXITCODE=7; if($script:mode -eq 'running'){'{"Host":"Running","Kubelet":"Running","APIServer":"Running"}'}else{'{"Host":"Stopped","Kubelet":"Stopped","APIServer":"Stopped"}'} }
function docker { if($args[0] -ne 'inspect'){throw 'live_mutation_forbidden'}; $global:LASTEXITCODE=0; if($script:mode -eq 'oom'){'{"Status":"exited","Running":false,"OOMKilled":true,"ExitCode":137}'}else{'{"Status":"exited","Running":false,"OOMKilled":false,"ExitCode":137}'} }
foreach($mode in @('ok','host-denied','host-event','network-lost','running','oom','stop-failed')) {
    $script:mode=$mode; $directory=Join-Path $state $mode; New-Item -ItemType Directory -Path $directory | Out-Null
    $stopCode=if($mode -eq 'stop-failed'){1}else{0}
    $closure=Save-NormalFailureClosure -ArtifactRoot $directory -Profile p0-online-boutique -HostBefore @{} -NetworkBefore @{} -NetworkTransport ethernet -StopExitCode $stopCode
    if ($closure.passed -ne ($mode -eq 'ok') -or $null -eq $closure.container_state) { throw "closure_case_failed:$mode" }
}
$runner=Get-Content (Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1') -Raw
$closed=RunFixture 'run-network-delay-headroom-normal.ps1' @('-RunId','ob-netdelay-500m-normal-10u-005','-WorkloadProfileRelative','p0-env/config/workloads/ob-default-10u-1r-v1.json','-PythonPath','unused','-NetworkTransport','ethernet','-ExecutionApproved')
if ($closed.code -eq 0 -or $closed.text -notmatch 'closed_run_id') { throw 'consumed_run_not_rejected' }
if ($runner.IndexOf("InvokeScript 'proxy_convergence'") -gt $runner.IndexOf("InvokeScript 'target_stability'")) { throw 'convergence_after_stability' }
if ($runner -notmatch "closed_run_id" -or $runner -notmatch 'Save-NormalFailureClosure' -or $runner -notmatch '\$runFailed = \$true') { throw 'runner_failure_wiring_missing' }
foreach($file in @('wait-normal-proxy-convergence.ps1','normal-failure-closure.ps1','verify-target-pod-stability.ps1','run-network-delay-headroom-normal.ps1')) {
    $tokens=$null;$errors=$null;[void][Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot $file),[ref]$tokens,[ref]$errors)
    if($errors.Count){throw "parse_failed:$file"}
}
Write-Output 'd111_fixture_checks=passed convergence=7 stability_failure=1 closure=7 runtime=none'

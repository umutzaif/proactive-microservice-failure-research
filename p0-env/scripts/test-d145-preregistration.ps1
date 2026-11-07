$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$shell = (Get-Process -Id $PID).Path
$runnerPath = Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
$runner = Get-Content -LiteralPath $runnerPath -Raw
$candidate = 'ob-netdelay-500m-normal-10u-013'
$preregistrationPath = Join-Path $PSScriptRoot "..\artifacts\P2-NETWORK-DELAY-HEADROOM-001\$candidate-preregistration.md"
$preregistration = Get-Content -LiteralPath $preregistrationPath -Raw

foreach ($token in @(
    'D-145',
    $candidate,
    'ob-netdelay-500m-normal-10u-012',
    '10u `1/3` plus 15u `2/3` (`3/6`)',
    'usb_tether_wifi',
    'wifi_only_cellular_disabled',
    '3+4 static identity gate',
    'source-bound bundle',
    'manual run with no retry',
    'fresh explicit runtime approval',
    'neither runtime nor fault execution',
    '`execution_authorized` remains false'
)) {
    if (-not $preregistration.Contains($token)) {
        throw "d145_preregistration_contract_missing:$token"
    }
}

$cases = @(
    @{arguments=@('-NetworkTransport','usb_tether_wifi','-PhoneUpstreamDeclaration','wifi_only_cellular_disabled','-BackgroundLoadNote','fixture');error='ExecutionApproved|MissingMandatoryParameter'},
    @{arguments=@('-ExecutionApproved','-NetworkTransport','usb_tether_wifi','-PhoneUpstreamDeclaration','wifi_only_cellular_disabled','-BackgroundLoadNote','fixture');error='closed_run_id'}
)
foreach ($case in $cases) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $base = @('-NoProfile','-File',$runnerPath,'-RunId',$candidate,'-WorkloadProfileRelative','p0-env/config/workloads/ob-default-10u-1r-v1.json','-PythonPath','__d145_nonexistent_python__')
        $invokeArguments = $base + @($case.arguments)
        $output = @(& $shell @invokeArguments 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }
    if ($exitCode -eq 0 -or ($output -join "`n") -notmatch $case.error) {
        throw "d145_gate_failed:$($case.error)"
    }
}

foreach ($token in @(
    $candidate,
    "'D-145'",
    'verify-static-run-id-config.ps1',
    'source-bound-normal-deployment-bundle.ps1',
    'New-NetworkDelayNormalDeploymentBundle',
    '$deploymentBundle.base_config',
    '$deploymentBundle.overlay_config',
    'deployment_bundle_provenance_path',
    'deployment_bundle_provenance_sha256'
)) {
    if (-not $runner.Contains($token)) { throw "d145_runner_contract_missing:$token" }
}

$closedLine = @($runner -split "`r?`n" | Where-Object { $_ -match "closed_run_id" })[0]
if ($closedLine -notmatch '10u-002' -or $closedLine -notmatch '10u-004' -or $closedLine -notmatch '10u-012' -or $closedLine -notmatch '10u-013') {
    throw 'd145_closed_id_contract_invalid'
}

$closedGate = $runner.IndexOf("throw 'closed_run_id'")
$transportGate = $runner.IndexOf("throw 'usb_tether_wifi_only'")
$staticGate = $runner.IndexOf('verify-static-run-id-config.ps1')
$sourceGate = $runner.IndexOf("throw 'explicit_online_boutique_source_root_required'")
$bundleGate = $runner.IndexOf('$deploymentBundle = New-NetworkDelayNormalDeploymentBundle')
$artifactGate = $runner.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')
$runtimeGate = $runner.IndexOf('$infrastructureStarted = $true')
if ($closedGate -lt 0 -or $transportGate -le $closedGate -or $sourceGate -le $transportGate -or $staticGate -le $sourceGate -or $bundleGate -le $staticGate -or $artifactGate -le $bundleGate -or $runtimeGate -le $artifactGate) {
    throw 'd145_gate_order_invalid'
}

$inputs = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\config\analysis\network-delay-headroom-decision-inputs-v1.json') -Raw | ConvertFrom-Json
if ($inputs.collection_sequence.next_slot_status -ne 'replacement_required_not_preregistered') { throw 'd146_slot_status_invalid' }
if ($null -ne $inputs.collection_sequence.effective_collection_run_ids[3]) { throw 'd146_slot_not_null' }
if (@($inputs.collection_sequence.invalid_run_ids | Where-Object { $_ -eq 'ob-netdelay-500m-normal-10u-012' }).Count -ne 1) { throw 'd145_closed_012_missing' }
if (@($inputs.collection_sequence.invalid_run_ids | Where-Object { $_ -eq $candidate }).Count -ne 1) { throw 'd146_closed_013_missing' }
if (@($inputs.decision_ids | Where-Object { $_ -eq 'D-145' }).Count -ne 1) { throw 'd145_decision_missing' }
if (@($inputs.decision_ids | Where-Object { $_ -eq 'D-146' }).Count -ne 1) { throw 'd146_decision_missing' }
if ($inputs.execution_authorized -or $inputs.fault_or_normal_run_started_by_this_profile) { throw 'd145_runtime_authority_changed' }

& (Join-Path $PSScriptRoot 'verify-static-run-id-config.ps1') -ExpectedRunId $candidate | Out-Null

Write-Output 'd145_preregistration=passed historical=preserved d146_closure=013_closed negative=2 runtime=none'

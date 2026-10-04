$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$shell = (Get-Process -Id $PID).Path
$runnerPath = Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
$runner = Get-Content -LiteralPath $runnerPath -Raw
$preregistrationPath = Join-Path $PSScriptRoot '..\artifacts\P2-NETWORK-DELAY-HEADROOM-001\ob-netdelay-500m-normal-10u-012-preregistration.md'
$preregistration = Get-Content -LiteralPath $preregistrationPath -Raw
$candidate = 'ob-netdelay-500m-normal-10u-012'

foreach ($token in @(
    'D-127',
    $candidate,
    'ob-netdelay-500m-normal-10u-011',
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
        throw "d127_preregistration_contract_missing:$token"
    }
}

$cases = @(
    @{transport='ethernet';declaration='wifi_only_cellular_disabled';note='fixture';error='usb_tether_wifi_only'},
    @{transport='usb_tether_wifi';declaration='mobile_data';note='fixture';error='phone_wifi_only_declaration_required'},
    @{transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note=' ';error='background_load_note_required'},
    @{transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note='fixture';error='explicit_online_boutique_source_root_required'}
)
foreach ($case in $cases) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $output = @(& $shell -NoProfile -File $runnerPath -RunId $candidate -WorkloadProfileRelative 'p0-env/config/workloads/ob-default-10u-1r-v1.json' -PythonPath '__d127_nonexistent_python__' -ExecutionApproved -NetworkTransport $case.transport -PhoneUpstreamDeclaration $case.declaration -BackgroundLoadNote $case.note 2>&1)
        $exitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $old
    }
    if ($exitCode -eq 0 -or ($output -join "`n") -notmatch $case.error) {
        throw "d127_gate_failed:$($case.error)"
    }
}

foreach ($token in @(
    $candidate,
    "'D-127'",
    'verify-static-run-id-config.ps1',
    'source-bound-normal-deployment-bundle.ps1',
    'New-NetworkDelayNormalDeploymentBundle',
    '$deploymentBundle.base_config',
    '$deploymentBundle.overlay_config',
    'deployment_bundle_provenance_path',
    'deployment_bundle_provenance_sha256'
)) {
    if (-not $runner.Contains($token)) { throw "d127_runner_contract_missing:$token" }
}

$closedLine = @($runner -split "`r?`n" | Where-Object { $_ -match "closed_run_id" })[0]
if ($closedLine -notmatch '10u-002' -or $closedLine -notmatch '10u-004' -or $closedLine -notmatch '10u-011' -or $closedLine -match '10u-012') {
    throw 'd127_closed_id_contract_invalid'
}

$closedGate = $runner.IndexOf("throw 'closed_run_id'")
$transportGate = $runner.IndexOf("throw 'usb_tether_wifi_only'")
$staticGate = $runner.IndexOf('verify-static-run-id-config.ps1')
$sourceGate = $runner.IndexOf("throw 'explicit_online_boutique_source_root_required'")
$bundleGate = $runner.IndexOf('$deploymentBundle = New-NetworkDelayNormalDeploymentBundle')
$artifactGate = $runner.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')
$runtimeGate = $runner.IndexOf('$infrastructureStarted = $true')
if ($closedGate -lt 0 -or $transportGate -le $closedGate -or $sourceGate -le $transportGate -or $staticGate -le $sourceGate -or $bundleGate -le $staticGate -or $artifactGate -le $bundleGate -or $runtimeGate -le $artifactGate) {
    throw 'd127_gate_order_invalid'
}

$inputs = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\config\analysis\network-delay-headroom-decision-inputs-v1.json') -Raw | ConvertFrom-Json
if ($inputs.profile_status -ne 'replacement_preregistered_runtime_not_authorized') { throw 'd127_profile_status_invalid' }
if ($inputs.collection_sequence.next_slot_status -ne 'replacement_preregistered_runtime_not_authorized') { throw 'd127_slot_status_invalid' }
if ($inputs.collection_sequence.effective_collection_run_ids[3] -ne $candidate) { throw 'd127_slot_identity_invalid' }
if (@($inputs.collection_sequence.invalid_run_ids | Where-Object { $_ -eq 'ob-netdelay-500m-normal-10u-011' }).Count -ne 1) { throw 'd127_closed_011_missing' }
if (@($inputs.collection_sequence.invalid_run_ids | Where-Object { $_ -eq $candidate }).Count -ne 0) { throw 'd127_candidate_marked_invalid' }
if (@($inputs.decision_ids | Where-Object { $_ -eq 'D-127' }).Count -ne 1) { throw 'd127_decision_missing' }
if ($inputs.execution_authorized -or $inputs.fault_or_normal_run_started_by_this_profile) { throw 'd127_runtime_authority_changed' }

& (Join-Path $PSScriptRoot 'verify-static-run-id-config.ps1') -ExpectedRunId $candidate | Out-Null

$artifactRoot = Join-Path $PSScriptRoot "..\artifacts\P2-NETWORK-DELAY-HEADROOM-001\$candidate"
if (Test-Path -LiteralPath $artifactRoot) { throw 'd127_runtime_artifact_exists' }

Write-Output 'd127_preregistration=passed negative=4 successor=012 runtime=none'

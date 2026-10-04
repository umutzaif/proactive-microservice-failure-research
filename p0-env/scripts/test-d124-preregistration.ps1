$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$shell = (Get-Process -Id $PID).Path
$runner = Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
$prereg = Join-Path $PSScriptRoot '..\artifacts\P2-NETWORK-DELAY-HEADROOM-001\ob-netdelay-500m-normal-10u-011-preregistration.md'
$preregText = Get-Content -LiteralPath $prereg -Raw
foreach ($token in @('D-124','ob-netdelay-500m-normal-10u-011','ob-netdelay-500m-normal-10u-010','10u `1/3` plus 15u `2/3` (`3/6`)','usb_tether_wifi','wifi_only_cellular_disabled','3+4 static identity gate','manual run with no retry','fresh explicit runtime approval','authorize','neither runtime nor fault execution')) {
    if (-not $preregText.Contains($token)) { throw "d124_preregistration_contract_missing:$token" }
}

foreach ($case in @(
        @{transport='ethernet';declaration='wifi_only_cellular_disabled';note='fixture';error='closed_run_id'},
        @{transport='usb_tether_wifi';declaration='mobile_data';note='fixture';error='closed_run_id'},
        @{transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note=' ';error='closed_run_id'},
        @{transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note='fixture';error='closed_run_id'}
)) {
    $old = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $out = @(& $shell -NoProfile -File $runner -RunId 'ob-netdelay-500m-normal-10u-011' -WorkloadProfileRelative 'p0-env/config/workloads/ob-default-10u-1r-v1.json' -PythonPath '__d124_nonexistent_python__' -ExecutionApproved -NetworkTransport $case.transport -PhoneUpstreamDeclaration $case.declaration -BackgroundLoadNote $case.note 2>&1)
        $code = $LASTEXITCODE
    }
    finally { $ErrorActionPreference = $old }
    if ($code -eq 0 -or ($out -join "`n") -notmatch $case.error) { throw "d124_gate_failed:$($case.error)" }
}

$text = Get-Content -LiteralPath $runner -Raw
foreach ($token in @('verify-static-run-id-config.ps1',"'D-124'",'ob-netdelay-500m-normal-10u-011','ob-netdelay-500m-normal-10u-010')) {
    if (-not $text.Contains($token)) { throw "d124_runner_contract_missing:$token" }
}
$closedLine = @($text -split "`r?`n" | Where-Object { $_ -match "closed_run_id" })[0]
if ($closedLine -notmatch '10u-002' -or $closedLine -notmatch '10u-004' -or $closedLine -notmatch '10u-010' -or $closedLine -notmatch '10u-011') { throw 'd124_closed_id_contract_invalid' }
$staticGate = $text.IndexOf("verify-static-run-id-config.ps1")
$closedGate = $text.IndexOf("'closed_run_id'")
$artifactGate = $text.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')
$runtimeGate = $text.IndexOf('$PSCmdlet.ShouldProcess')
if ($closedGate -lt 0 -or $staticGate -lt 0 -or $artifactGate -lt 0 -or $runtimeGate -lt 0 -or $closedGate -gt $staticGate -or $staticGate -gt $artifactGate -or $staticGate -gt $runtimeGate) { throw 'd124_closed_and_static_gate_order_invalid' }

Write-Output 'd124_closure=passed cases=4 runtime=none'

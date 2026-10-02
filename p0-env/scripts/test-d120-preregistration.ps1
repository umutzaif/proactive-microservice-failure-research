$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$shell=(Get-Process -Id $PID).Path
$runner=Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
foreach($case in @(
    @{transport='ethernet';declaration='wifi_only_cellular_disabled';note='fixture';error='closed_run_id'},
    @{transport='usb_tether_wifi';declaration='mobile_data';note='fixture';error='closed_run_id'},
    @{transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note=' ';error='closed_run_id'},
    @{transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note='fixture';error='closed_run_id'}
)) {
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try {$out=@(& $shell -NoProfile -File $runner -RunId 'ob-netdelay-500m-normal-10u-010' -WorkloadProfileRelative 'p0-env/config/workloads/ob-default-10u-1r-v1.json' -PythonPath '__d120_nonexistent_python__' -ExecutionApproved -NetworkTransport $case.transport -PhoneUpstreamDeclaration $case.declaration -BackgroundLoadNote $case.note 2>&1);$code=$LASTEXITCODE} finally {$ErrorActionPreference=$old}
    if($code -eq 0 -or ($out -join "`n") -notmatch $case.error){throw "d120_gate_failed:$($case.error)"}
}
$text=Get-Content -LiteralPath $runner -Raw
foreach($token in @('verify-static-run-id-config.ps1',"'D-120'",'ob-netdelay-500m-normal-10u-010')){if(-not $text.Contains($token)){throw "d120_runner_contract_missing:$token"}}
$staticGate=$text.IndexOf("verify-static-run-id-config.ps1")
$closedGate=$text.IndexOf("'closed_run_id'")
$artifactGate=$text.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')
$runtimeGate=$text.IndexOf('$PSCmdlet.ShouldProcess')
if($closedGate -lt 0 -or $staticGate -lt 0 -or $artifactGate -lt 0 -or $runtimeGate -lt 0 -or $closedGate -gt $staticGate -or $staticGate -gt $artifactGate -or $staticGate -gt $runtimeGate){throw 'd120_closed_and_static_gate_order_invalid'}
Write-Output 'd120_closure=passed cases=4 runtime=none'

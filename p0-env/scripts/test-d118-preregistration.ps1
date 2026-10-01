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
    try {$out=@(& $shell -NoProfile -File $runner -RunId 'ob-netdelay-500m-normal-10u-009' -WorkloadProfileRelative 'p0-env/config/workloads/ob-default-10u-1r-v1.json' -PythonPath '__d118_nonexistent_python__' -ExecutionApproved -NetworkTransport $case.transport -PhoneUpstreamDeclaration $case.declaration -BackgroundLoadNote $case.note 2>&1);$code=$LASTEXITCODE} finally {$ErrorActionPreference=$old}
    if($code -eq 0 -or ($out -join "`n") -notmatch $case.error){throw "d118_gate_failed:$($case.error)"}
}
$text=Get-Content -LiteralPath $runner -Raw
foreach($token in @('RequireHostEthernetDisabled',"'D-118'",'ob-netdelay-500m-normal-10u-009')){if(-not $text.Contains($token)){throw "d118_runner_contract_missing:$token"}}
Write-Output 'd119_d118_closure=passed cases=4 runtime=none'

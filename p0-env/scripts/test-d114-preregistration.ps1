$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$runner=Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
$shell=(Get-Process -Id $PID).Path
foreach($case in @(
    @{id='ob-netdelay-500m-normal-10u-006';transport='ethernet';error='closed_run_id'},
    @{id='ob-netdelay-500m-normal-10u-007';transport='wifi';error='d115_usb_tether_wifi_only'},
    @{id='ob-netdelay-500m-normal-10u-007';transport='ethernet';error='d115_usb_tether_wifi_only'}
)) {
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try { $out=@(& $shell -NoProfile -File $runner -RunId $case.id -NetworkTransport $case.transport -WorkloadProfileRelative 'p0-env/config/workloads/ob-default-10u-1r-v1.json' -PythonPath unused -ExecutionApproved 2>&1);$code=$LASTEXITCODE } finally {$ErrorActionPreference=$old}
    if($code -eq 0 -or ($out -join "`n") -notmatch $case.error){throw "gate_not_rejected:$($case.error)"}
}
Write-Output 'd114_preregistration=passed negative=3 runtime=none'

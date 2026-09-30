$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$shell=(Get-Process -Id $PID).Path
$runner=Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
foreach($case in @(
    @{id='007';transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note='fixture';error='closed_run_id'},
    @{id='008';transport='ethernet';declaration='wifi_only_cellular_disabled';note='fixture';error='d115_usb_tether_wifi_only'},
    @{id='008';transport='usb_tether_wifi';declaration='mobile_data';note='fixture';error='phone_wifi_only_declaration_required'},
    @{id='008';transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note=' ';error='background_load_note_required'},
    @{id='008';transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note='fixture';error='python_runtime_missing'}
)) {
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try {$out=@(& $shell -NoProfile -File $runner -RunId "ob-netdelay-500m-normal-10u-$($case.id)" -WorkloadProfileRelative p0-env/config/workloads/ob-default-10u-1r-v1.json -PythonPath '__d117_nonexistent_python__' -ExecutionApproved -NetworkTransport $case.transport -PhoneUpstreamDeclaration $case.declaration -BackgroundLoadNote $case.note 2>&1);$code=$LASTEXITCODE} finally {$ErrorActionPreference=$old}
    if($code -eq 0 -or ($out -join "`n") -notmatch $case.error){throw "d117_gate_failed:$($case.error)"}
}
Write-Output 'd117_preregistration=passed cases=5 runtime=none'

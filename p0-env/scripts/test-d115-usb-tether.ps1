$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'host-network-context.ps1')
$usb=[pscustomobject]@{Name='Ethernet 2';InterfaceDescription='Remote NDIS based Internet Sharing Device';ifIndex=13;Status='Up';DriverVersion='10.0.26100.1';HardwareInterface=$true;NdisPhysicalMedium=0;PnPDeviceID='USB\fixture'}
$route=[pscustomobject]@{InterfaceIndex=13;State='Alive';effective_metric=25}
$context=Select-HostNetworkContext -ExpectedTransport usb_tether_wifi -Adapters @($usb) -DefaultRoutes @($route)
if ($context.transport -ne 'usb_tether_wifi' -or $context.Contains('PnPDeviceID')) {throw 'usb_identity_or_privacy_failed'}
foreach ($case in @('bus','description','virtual','route','duplicate','ethernet')) {
    $candidate=$usb.PSObject.Copy();$adapters=@($candidate);$routes=@($route);$transport='usb_tether_wifi'
    switch ($case) {
        bus {$candidate.PnPDeviceID='ROOT\fixture'}
        description {$candidate.InterfaceDescription='Unknown adapter'}
        virtual {$candidate.HardwareInterface=$false}
        route {$routes=@()}
        duplicate {$adapters=@($candidate,$usb)}
        ethernet {$transport='ethernet'}
    }
    $failed=$false
    try { Select-HostNetworkContext -ExpectedTransport $transport -Adapters $adapters -DefaultRoutes $routes | Out-Null } catch {$failed=$true}
    if (-not $failed) {throw "usb_negative_accepted:$case"}
}
$shell=(Get-Process -Id $PID).Path
$runner=Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
foreach ($case in @(
    @{transport='ethernet';declaration='wifi_only_cellular_disabled';note='fixture';error='d115_usb_tether_wifi_only'},
    @{transport='usb_tether_wifi';declaration='mobile_data';note='fixture';error='phone_wifi_only_declaration_required'},
    @{transport='usb_tether_wifi';declaration='wifi_only_cellular_disabled';note=' ';error='background_load_note_required'}
)) {
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try {$out=@(& $shell -NoProfile -File $runner -RunId ob-netdelay-500m-normal-10u-007 -WorkloadProfileRelative p0-env/config/workloads/ob-default-10u-1r-v1.json -PythonPath unused -ExecutionApproved -NetworkTransport $case.transport -PhoneUpstreamDeclaration $case.declaration -BackgroundLoadNote $case.note 2>&1);$code=$LASTEXITCODE} finally {$ErrorActionPreference=$old}
    if ($code -eq 0 -or ($out -join "`n") -notmatch $case.error) {throw "runner_gate_failed:$($case.error)"}
}
Write-Output 'd115_usb_tether=passed classifier_positive=1 classifier_negative=6 runner_negative=3 runtime=none'

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'host-network-context.ps1')
$wifi=[pscustomobject]@{Name='Wi-Fi';InterfaceDescription='MediaTek Wi-Fi 6 MT7921 Wireless LAN Card';ifIndex=7;Status='Up';DriverVersion='3.0.1.1314';HardwareInterface=$true;NdisPhysicalMedium='802.11'}
$ethernet=[pscustomobject]@{Name='Ethernet';InterfaceDescription='Realtek PCIe GbE Family Controller';ifIndex=5;Status='Up';DriverVersion='1168.8.515.2022';HardwareInterface=$true;NdisPhysicalMedium='802.3'}
$route=[pscustomobject]@{InterfaceIndex=7;State='Alive';effective_metric=25};$otherRoute=[pscustomobject]@{InterfaceIndex=5;State='Alive';effective_metric=50}
$context=Select-HostNetworkContext -ExpectedTransport wifi -Adapters @($wifi,$ethernet) -DefaultRoutes @($route,$otherRoute)
if($context.transport-ne'wifi'-or$context.driver_version-ne'3.0.1.1314'-or$context.privacy_contract-ne'ssid_bssid_mac_ip_gateway_omitted'){throw'network_context_positive_failed'}
[void](Assert-HostNetworkContextStable -Before $context -After $context)
$changed=[ordered]@{};foreach($key in $context.Keys){$changed[$key]=$context[$key]};$changed.driver_version='changed';try{Assert-HostNetworkContextStable -Before $context -After $changed;throw'changed_driver_accepted'}catch{if($_.Exception.Message-ne'host_network_context_changed:driver_version'){throw}}
$fixture=Join-Path ([IO.Path]::GetTempPath()) 'd102-wifi-qualification-fixture.json'
$qualification=[ordered]@{diagnostic_id='ob-host-network-portability-wifi-001';classification='wifi_host_portability_supported';passed=$true;transport='wifi';adapter_name=$context.adapter_name;interface_description=$context.interface_description;driver_version=$context.driver_version;active_load_windows_completed=2;active_load_window_seconds=@(1800,1800);e2e_closure_seconds=600;application_telemetry_closure_passed=$true;host_event_windows=@(@{whea_event_17=0;kernel_power_41=0;bugcheck=0},@{whea_event_17=0;kernel_power_41=0;bugcheck=0},@{whea_event_17=0;kernel_power_41=0;bugcheck=0})}
[IO.File]::WriteAllText($fixture,($qualification|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))
try{[void](Assert-WifiQualificationEvidence -Path $fixture -CurrentContext $context)}finally{Remove-Item -LiteralPath $fixture -Force}
$forbidden=Join-Path ([IO.Path]::GetTempPath()) 'd102-wifi-qualification-forbidden-fixture.json'
$qualification['ssid']='private';[IO.File]::WriteAllText($forbidden,($qualification|ConvertTo-Json -Depth 10),(New-Object Text.UTF8Encoding($false)))
try{try{Assert-WifiQualificationEvidence -Path $forbidden -CurrentContext $context;throw'forbidden_identifier_accepted'}catch{if($_.Exception.Message-ne'wifi_qualification_contains_forbidden_identifier'){throw}}}finally{Remove-Item -LiteralPath $forbidden -Force}
Write-Output 'host_network_context_positive=passed';Write-Output 'host_network_driver_change_negative=passed';Write-Output 'host_network_privacy_negative=passed'

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Select-HostNetworkContext {
    param(
        [Parameter(Mandatory)][ValidateSet('ethernet','wifi')][string]$ExpectedTransport,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Adapters,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$DefaultRoutes
    )
    $adapter = @($Adapters | Where-Object {
        $medium = [string]$_.NdisPhysicalMedium
        $kind = if ($medium -eq '9' -or $medium -match '802\.11|Wireless|Native802') { 'wifi' } elseif ($medium -eq '14' -or $medium -match '802\.3|Ethernet') { 'ethernet' } else { 'unsupported' }
        [bool]$_.HardwareInterface -and [string]$_.Status -eq 'Up' -and $kind -eq $ExpectedTransport
    })
    if ($adapter.Count -ne 1) { throw "expected_active_physical_adapter_count:${ExpectedTransport}:$($adapter.Count)" }
    $selected = $adapter[0]
    $routes = @($DefaultRoutes | Where-Object {
        [int]$_.InterfaceIndex -eq [int]$selected.ifIndex -and [string]$_.State -eq 'Alive'
    })
    if ($routes.Count -lt 1) { throw "active_default_route_missing:$ExpectedTransport" }
    $aliveRoutes = @($DefaultRoutes | Where-Object { [string]$_.State -eq 'Alive' })
    $minimumMetric = ($aliveRoutes | Measure-Object effective_metric -Minimum).Minimum
    $effective = @($routes | Where-Object { [int]$_.effective_metric -eq [int]$minimumMetric })
    $winningInterfaces = @($aliveRoutes | Where-Object { [int]$_.effective_metric -eq [int]$minimumMetric } | Select-Object -ExpandProperty InterfaceIndex -Unique)
    if ($effective.Count -lt 1 -or $winningInterfaces.Count -ne 1) { throw "expected_transport_not_unique_effective_default_route:$ExpectedTransport" }
    [ordered]@{
        schema_version = 1
        observed_utc = [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
        transport = $ExpectedTransport
        adapter_name = [string]$selected.Name
        interface_description = [string]$selected.InterfaceDescription
        interface_index = [int]$selected.ifIndex
        status = [string]$selected.Status
        driver_version = [string]$selected.DriverVersion
        default_route_present = $true
        effective_route_metric = [int]$minimumMetric
        privacy_contract = 'ssid_bssid_mac_ip_gateway_omitted'
    }
}

function Get-HostNetworkContext {
    param([Parameter(Mandatory)][ValidateSet('ethernet','wifi')][string]$ExpectedTransport)
    $adapters = @(Get-NetAdapter -Physical -ErrorAction Stop)
    $interfaces = @(Get-NetIPInterface -AddressFamily IPv4 -ErrorAction Stop)
    $routes = @(Get-NetRoute -DestinationPrefix '0.0.0.0/0' -ErrorAction Stop | ForEach-Object {
        $route = $_
        $ipInterface = @($interfaces | Where-Object { [int]$_.InterfaceIndex -eq [int]$route.InterfaceIndex })
        if ($ipInterface.Count -ne 1) { throw "default_route_interface_metric_missing:$($route.InterfaceIndex)" }
        [pscustomobject]@{InterfaceIndex=[int]$route.InterfaceIndex;State=[string]$route.State;effective_metric=([int]$route.RouteMetric+[int]$ipInterface[0].InterfaceMetric)}
    })
    Select-HostNetworkContext -ExpectedTransport $ExpectedTransport -Adapters $adapters -DefaultRoutes $routes
}

function Assert-HostNetworkContextStable {
    param([Parameter(Mandatory)]$Before,[Parameter(Mandatory)]$After)
    foreach ($field in @('transport','adapter_name','interface_description','interface_index','driver_version')) {
        if ([string]$Before.$field -ne [string]$After.$field) { throw "host_network_context_changed:$field" }
    }
    if (-not [bool]$Before.default_route_present -or -not [bool]$After.default_route_present) { throw 'host_network_default_route_not_stable' }
    $true
}

function Assert-WifiQualificationEvidence {
    param([Parameter(Mandatory)][string]$Path,[Parameter(Mandatory)]$CurrentContext)
    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'wifi_qualification_evidence_missing' }
    $evidence = Get-Content -LiteralPath $Path -Raw | ConvertFrom-Json
    if ([string]$evidence.diagnostic_id -ne 'ob-host-network-portability-wifi-001' -or
        [string]$evidence.classification -ne 'wifi_host_portability_supported' -or
        -not [bool]$evidence.passed -or [string]$evidence.transport -ne 'wifi' -or
        [int]$evidence.active_load_windows_completed -ne 2 -or
        @($evidence.active_load_window_seconds | Where-Object { [int]$_ -ge 1800 }).Count -ne 2 -or
        [int]$evidence.e2e_closure_seconds -lt 600 -or
        -not [bool]$evidence.application_telemetry_closure_passed -or
        @($evidence.host_event_windows | Where-Object { [int]$_.whea_event_17 -eq 0 -and [int]$_.kernel_power_41 -eq 0 -and [int]$_.bugcheck -eq 0 }).Count -ne 3) { throw 'wifi_qualification_evidence_invalid' }
    if ([string]$evidence.adapter_name -ne [string]$CurrentContext.adapter_name -or
        [string]$evidence.interface_description -ne [string]$CurrentContext.interface_description -or
        [string]$evidence.driver_version -ne [string]$CurrentContext.driver_version) { throw 'wifi_adapter_or_driver_requires_requalification' }
    foreach ($forbidden in @('ssid','bssid','mac_address','ip_address','gateway')) {
        if ($null -ne $evidence.PSObject.Properties[$forbidden]) { throw 'wifi_qualification_contains_forbidden_identifier' }
    }
    $true
}

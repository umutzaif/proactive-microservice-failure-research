$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'ethernet-normal-preflight.ps1')
$script:scenario = 'ok'
$script:nativeCalls = @()
function Resolve-Path { param($LiteralPath,$ErrorAction) [pscustomobject]@{Path=$LiteralPath} }
function Test-Path {
    param($LiteralPath,$PathType)
    if ($LiteralPath -like '*config.json' -and $LiteralPath.Replace('\','/') -notlike '*.minikube/profiles/p0-online-boutique/config.json') { throw 'incorrect_minikube_state_layout' }
    return ($script:scenario -ne 'missing_source' -or $LiteralPath -notlike '*kustomization.yaml')
}
function git {
    $global:LASTEXITCODE = 0
    if ($args -contains 'rev-parse') { if ($script:scenario -eq 'wrong_source') { 'wrong' } else { '5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb' } }
    elseif ($script:scenario -eq 'dirty_source') { ' M source.yaml' }
}
function Get-Content {
    param($LiteralPath,[switch]$Raw)
    if ($LiteralPath -like '*config.json') {
        if ($script:scenario -eq 'wrong_profile') { return '{"Name":"wrong"}' }
        return '{"Name":"p0-online-boutique","Driver":"docker","CPUs":4,"Memory":6144,"DiskSize":32768,"KubernetesConfig":{"KubernetesVersion":"v1.34.0","ContainerRuntime":"containerd"}}'
    }
    Microsoft.PowerShell.Management\Get-Content -LiteralPath $LiteralPath -Raw
}
function Get-NetAdapter { param([switch]$Physical,$ErrorAction) [pscustomobject]@{NdisPhysicalMedium=9;Status=$(if ($script:scenario -eq 'wifi_disconnected') {'Disconnected'} else {'Disabled'})} }
function Get-HostNetworkContext { param($ExpectedTransport) if ($script:scenario -eq 'wrong_route') { throw 'expected_transport_not_unique_effective_default_route:ethernet' }; @{transport=$ExpectedTransport} }
function Get-CimInstance { param($ClassName,$ErrorAction) [pscustomobject]@{LastBootUpTime=[datetime]'2026-09-08T10:00:00'} }
function Get-WinEvent {
    param($ListLog,$LogName,[switch]$Oldest,$MaxEvents,$FilterHashtable,$ErrorAction)
    if ($ListLog) { return [pscustomobject]@{IsEnabled=($script:scenario -ne 'log_disabled')} }
    if ($Oldest) { return [pscustomobject]@{TimeCreated=$(if ($script:scenario -eq 'log_truncated') {[datetime]'2026-09-08T11:00:00'} else {[datetime]'2026-09-07T10:00:00'})} }
    if ($script:scenario -eq 'log_denied') { throw 'event_access_denied' }
    if ($script:scenario -eq 'whea' -and $FilterHashtable.Id -eq 17) { return [pscustomobject]@{Id=17} }
    $record = [Management.Automation.ErrorRecord]::new([Exception]::new('no events'),'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand',[Management.Automation.ErrorCategory]::ObjectNotFound,$null)
    throw $record
}
function Get-PSDrive { param($Name,$ErrorAction) [pscustomobject]@{Free=$(if ($script:scenario -eq 'low_disk') {14GB} else {16GB})} }
function docker { $script:nativeCalls += 'docker'; $global:LASTEXITCODE = $(if ($script:scenario -eq 'docker_down') {1} else {0}); '"fixture"' }
function minikube {
    if ($args[0] -ne 'status') { throw 'fixture_forbids_runtime' }
    $script:nativeCalls += 'status'
    $global:LASTEXITCODE = $(if ($script:scenario -eq 'bad_exit') {1} else {7})
    if ($script:scenario -eq 'running') { '{"Host":"Running","Kubelet":"Running","APIServer":"Running"}' } else { '{"Host":"Stopped","Kubelet":"Stopped","APIServer":"Stopped"}' }
}
$savedState = $env:MINIKUBE_HOME
try {
    $result = Get-EthernetNormalPreflight -Repo 'C:\fixture\repo' -RuntimeStateRoot 'C:\fixture\state' -Profile 'p0-online-boutique'
    if (-not $result.passed -or $result.profile_status_native_exit_code -ne 7 -or $env:MINIKUBE_HOME -ne 'C:\fixture\state') { throw 'positive_preflight_failed' }
    $usbResult = Get-EthernetNormalPreflight -Repo 'C:\fixture\repo' -RuntimeStateRoot 'C:\fixture\state' -Profile 'p0-online-boutique' -ExpectedTransport usb_tether_wifi
    if (-not $usbResult.passed -or $usbResult.network.transport -ne 'usb_tether_wifi') {throw 'usb_preflight_transport_not_propagated'}
    $cases = [ordered]@{missing_source='source_base_missing';wrong_source='source_revision_mismatch';dirty_source='source_not_clean';wifi_disconnected='wireless_adapter_not_disabled';wrong_route='expected_transport_not_unique_effective_default_route:ethernet';log_disabled='system_event_log_disabled';log_truncated='system_log_does_not_cover_boot';log_denied='event_access_denied';whea='clean_boot_host_event_preflight_failed';low_disk='host_free_space_below_15_gib';docker_down='docker_engine_not_ready';bad_exit='existing_profile_not_stopped';running='existing_profile_not_stopped'}
    $cases['wrong_profile'] = 'existing_profile_contract_mismatch'
    foreach ($case in $cases.Keys) {
        $script:scenario = $case
        $failure = $null
        try { Get-EthernetNormalPreflight -Repo 'C:\fixture\repo' -RuntimeStateRoot 'C:\fixture\state' -Profile 'p0-online-boutique' | Out-Null } catch { $failure = $_.Exception.Message }
        if ($failure -ne $cases[$case]) { throw "negative_not_rejected:${case}:$failure" }
    }
    $runner = Get-Content (Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1') -Raw
    if ($runner.IndexOf('$ethernetPreflight = Get-EthernetNormalPreflight') -gt $runner.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')) { throw 'preflight_after_artifact' }
    foreach ($token in @('d110_ethernet_only','explicit_runtime_state_root_required','ethernet_preflight_sha256')) { if (-not $runner.Contains($token)) { throw "runner_contract_missing:$token" } }
    Write-Output 'ethernet_normal_preflight=passed positive=1 negative=14 runtime=mocked'
} finally { $env:MINIKUBE_HOME = $savedState }

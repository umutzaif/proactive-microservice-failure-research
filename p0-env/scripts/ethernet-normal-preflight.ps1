$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Read-only D-110 gates. No service, adapter, profile or event-log mutation.
function Get-EthernetNormalPreflight {
    param([Parameter(Mandatory)][string]$Repo,
          [Parameter(Mandatory)][string]$RuntimeStateRoot,
          [Parameter(Mandatory)][string]$Profile,
          [ValidateSet('ethernet','usb_tether_wifi')][string]$ExpectedTransport='ethernet')
    if ($Profile -ne 'p0-online-boutique') { throw 'unexpected_profile' }
    if (-not [IO.Path]::IsPathRooted($RuntimeStateRoot)) { throw 'absolute_runtime_state_root_required' }
    $state = (Resolve-Path -LiteralPath $RuntimeStateRoot -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath (Join-Path $state ".minikube/profiles/$Profile/config.json") -PathType Leaf)) { throw 'existing_profile_config_missing' }
    $config = Get-Content -LiteralPath (Join-Path $state ".minikube/profiles/$Profile/config.json") -Raw | ConvertFrom-Json
    if ($config.Name -ne $Profile -or $config.Driver -ne 'docker' -or [int]$config.CPUs -ne 4 -or [int]$config.Memory -ne 6144 -or [int]$config.DiskSize -ne 32768 -or $config.KubernetesConfig.KubernetesVersion -ne 'v1.34.0' -or $config.KubernetesConfig.ContainerRuntime -ne 'containerd') { throw 'existing_profile_contract_mismatch' }
    $source = (Resolve-Path -LiteralPath (Join-Path $Repo 'p0-env/source/microservices-demo') -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath (Join-Path $source 'kustomize/base/kustomization.yaml') -PathType Leaf)) { throw 'source_base_missing' }
    $revision = (& git -C $source rev-parse HEAD).Trim()
    if ($LASTEXITCODE -ne 0 -or $revision -ne '5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb') { throw 'source_revision_mismatch' }
    $dirty = @(& git -C $source status --porcelain)
    if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) { throw 'source_not_clean' }
    $wireless = @(Get-NetAdapter -Physical -ErrorAction Stop | Where-Object {
        [string]$_.NdisPhysicalMedium -eq '9' -or [string]$_.NdisPhysicalMedium -match '802\.11|Wireless|Native802'
    })
    if (@($wireless | Where-Object { [string]$_.Status -ne 'Disabled' }).Count) { throw 'wireless_adapter_not_disabled' }
    $network = Get-HostNetworkContext -ExpectedTransport $ExpectedTransport
    $boot = [datetimeoffset](Get-CimInstance Win32_OperatingSystem -ErrorAction Stop).LastBootUpTime
    $log = Get-WinEvent -ListLog System -ErrorAction Stop
    if (-not $log.IsEnabled) { throw 'system_event_log_disabled' }
    $oldest = Get-WinEvent -LogName System -Oldest -MaxEvents 1 -ErrorAction Stop
    if ([datetimeoffset]$oldest.TimeCreated -gt $boot) { throw 'system_log_does_not_cover_boot' }
    $counts = [ordered]@{}
    foreach ($target in @(
        @{key='whea_event_17';provider='Microsoft-Windows-WHEA-Logger';id=17},
        @{key='kernel_power_41';provider='Microsoft-Windows-Kernel-Power';id=41},
        @{key='bugcheck';provider='Microsoft-Windows-WER-SystemErrorReporting';id=1001}
    )) {
        $events = @()
        try { $events = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName=$target.provider;Id=$target.id;StartTime=$boot.LocalDateTime} -ErrorAction Stop) }
        catch { if ($_.FullyQualifiedErrorId -notlike 'NoMatchingEventsFound*') { throw } }
        $counts[$target.key] = $events.Count
    }
    if (($counts.whea_event_17 + $counts.kernel_power_41 + $counts.bugcheck) -ne 0) { throw 'clean_boot_host_event_preflight_failed' }
    $free = [long](Get-PSDrive -Name C -ErrorAction Stop).Free
    if ($free -lt 15GB) { throw 'host_free_space_below_15_gib' }
    $docker = @(& docker info --format '{{json .ServerVersion}}' 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'docker_engine_not_ready' }
    $env:MINIKUBE_HOME = $state
    [string[]]$raw = @(& minikube status --profile $Profile --output=json 2>&1)
    $statusExit = $LASTEXITCODE
    $status = ($raw -join "`n") | ConvertFrom-Json -ErrorAction Stop
    if ($statusExit -notin @(0,7) -or $status.Host -ne 'Stopped' -or $status.Kubelet -ne 'Stopped' -or $status.APIServer -ne 'Stopped') { throw 'existing_profile_not_stopped' }
    [ordered]@{schema_version=1;decision_id='D-110';passed=$true;runtime_state_root=$state;source_root=$source;source_revision=$revision;source_clean=$true;wireless_disabled_or_absent=$true;network=$network;boot_utc=$boot.ToUniversalTime().ToString('o');events_since_boot=$counts;free_space_bytes=$free;minimum_free_space_bytes=[long](15GB);docker_ready=$true;profile=$Profile;profile_status_native_exit_code=$statusExit;profile_status=$status}
}

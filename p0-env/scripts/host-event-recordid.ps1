$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-SystemEventLogState {
    $log = Get-WinEvent -ListLog System -ErrorAction Stop
    $latest = Get-WinEvent -LogName System -MaxEvents 1 -ErrorAction Stop
    [ordered]@{
        observed_utc = [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
        latest_record_id = [long]$latest.RecordId
        record_count = [long]$log.RecordCount
        file_size_bytes = [long]$log.FileSize
        maximum_size_bytes = [long]$log.MaximumSizeInBytes
        log_mode = [string]$log.LogMode
        is_enabled = [bool]$log.IsEnabled
    }
}

function New-HostEventRecordIdBoundary {
    [ordered]@{
        schema_version = 1
        method = 'system_log_record_id_boundary'
        system_log = Get-SystemEventLogState
    }
}

function Select-HostEventsAfterRecordId {
    param(
        [Parameter(Mandatory)][long]$BoundaryRecordId,
        [Parameter(Mandatory)][long]$LatestRecordId,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Events
    )
    if ($LatestRecordId -lt $BoundaryRecordId) { throw 'system_log_record_id_regressed' }
    @($Events | Where-Object { [long]$_.RecordId -gt $BoundaryRecordId } | Sort-Object RecordId)
}

function Measure-HostEventsAfterRecordIdBoundary {
    param([Parameter(Mandatory)]$Boundary)
    if ([string]$Boundary.method -ne 'system_log_record_id_boundary') { throw 'unexpected_host_boundary_method' }
    $beforeId = [long]$Boundary.system_log.latest_record_id
    $after = Get-SystemEventLogState
    $targets = @(
        [ordered]@{ key='whea_event_17'; provider='Microsoft-Windows-WHEA-Logger'; id=17 },
        [ordered]@{ key='kernel_power_41'; provider='Microsoft-Windows-Kernel-Power'; id=41 },
        [ordered]@{ key='bugcheck'; provider='Microsoft-Windows-WER-SystemErrorReporting'; id=1001 }
    )
    $counts = [ordered]@{}
    $identities = [ordered]@{}
    foreach ($target in $targets) {
        $all = @(Get-WinEvent -FilterHashtable @{LogName='System';ProviderName=$target.provider;Id=$target.id} -ErrorAction SilentlyContinue)
        $selected = @(Select-HostEventsAfterRecordId -BoundaryRecordId $beforeId -LatestRecordId ([long]$after.latest_record_id) -Events $all)
        $counts[$target.key] = $selected.Count
        $identities[$target.key] = @($selected | ForEach-Object {
            [ordered]@{
                record_id = [long]$_.RecordId
                time_created_utc = ([datetimeoffset]$_.TimeCreated).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
                provider = [string]$_.ProviderName
                event_id = [int]$_.Id
                level = [string]$_.LevelDisplayName
            }
        })
    }
    [ordered]@{
        schema_version = 1
        method = 'system_log_record_id_boundary'
        boundary_record_id = $beforeId
        system_log_after = $after
        record_id_monotonic = $true
        counts = $counts
        events = $identities
        passed = (($counts.whea_event_17 + $counts.kernel_power_41 + $counts.bugcheck) -eq 0)
    }
}

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'host-event-recordid.ps1')

$old=[pscustomobject]@{RecordId=99}
$new=[pscustomobject]@{RecordId=101}
if(@(Select-HostEventsAfterRecordId -BoundaryRecordId 100 -LatestRecordId 110 -Events @($old)).Count-ne 0){throw'old_retained_event_selected'}
if(@(Select-HostEventsAfterRecordId -BoundaryRecordId 100 -LatestRecordId 110 -Events @($old,$new)).Count-ne 1){throw'new_event_not_selected'}
try{Select-HostEventsAfterRecordId -BoundaryRecordId 100 -LatestRecordId 90 -Events @();throw'reset_not_rejected'}catch{if($_.Exception.Message-ne'system_log_record_id_regressed'){throw}}

$source=Get-Content -LiteralPath(Join-Path $PSScriptRoot 'host-event-recordid.ps1')-Raw
foreach($required in @('system_log_record_id_boundary','latest_record_id','record_id_monotonic','Microsoft-Windows-WHEA-Logger','Microsoft-Windows-Kernel-Power','Microsoft-Windows-WER-SystemErrorReporting')){if(-not$source.Contains($required)){throw"host_recordid_contract_missing:$required"}}
Write-Output 'host_event_recordid_fixtures=passed cases=3'

# No-match is zero; query errors must never become a clean host result.
function Get-SystemEventLogState { [ordered]@{latest_record_id=110} }
$script:queryMode='empty'
function Get-WinEvent {
    param($FilterHashtable,$ErrorAction)
    if ($script:queryMode -eq 'denied') { throw 'fixture_access_denied' }
    throw [Management.Automation.ErrorRecord]::new([Exception]::new('empty'),'NoMatchingEventsFound,Microsoft.PowerShell.Commands.GetWinEventCommand',[Management.Automation.ErrorCategory]::ObjectNotFound,$null)
}
$boundary=[pscustomobject]@{method='system_log_record_id_boundary';system_log=[pscustomobject]@{latest_record_id=100}}
$result=Measure-HostEventsAfterRecordIdBoundary $boundary
if (-not $result.passed) { throw 'no_match_not_zero' }
$script:queryMode='denied'
try { Measure-HostEventsAfterRecordIdBoundary $boundary; throw 'denied_not_rejected' } catch { if ($_.Exception.Message -ne 'fixture_access_denied') { throw } }
Write-Output 'host_event_query_error_fixtures=passed cases=2'

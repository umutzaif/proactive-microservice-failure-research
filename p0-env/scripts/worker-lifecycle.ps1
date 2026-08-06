Set-StrictMode -Version Latest

function Resolve-WorkerLifecycle {
    param(
        [Parameter(Mandatory = $true)][object[]]$Events,
        [Parameter(Mandatory = $true)][int]$RampSeconds,
        [Parameter(Mandatory = $true)][int]$SteadySeconds,
        [double]$DurationToleranceSeconds = 5
    )

    $started = @($Events | Where-Object event -eq 'started')
    $completed = @($Events | Where-Object event -eq 'completed')
    if ($started.Count -ne 1 -or $completed.Count -ne 1) {
        throw "worker_lifecycle_event_count_invalid:started=$($started.Count),completed=$($completed.Count)"
    }

    $canonicalUtc = '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$'
    $startText = [string]$started[0].event_utc
    $endText = [string]$completed[0].event_utc
    if ($startText -notmatch $canonicalUtc) { throw 'worker_started_utc_not_canonical' }
    if ($endText -notmatch $canonicalUtc) { throw 'worker_completed_utc_not_canonical' }

    $start = [datetimeoffset]::Parse($startText).ToUniversalTime()
    $end = [datetimeoffset]::Parse($endText).ToUniversalTime()
    if ($end -le $start) { throw 'worker_lifecycle_utc_order_invalid' }

    $expected = $RampSeconds + $SteadySeconds
    $wallDuration = ($end - $start).TotalSeconds
    $monotonicDuration = [double]$completed[0].elapsed_seconds
    if ([math]::Abs($wallDuration - $expected) -gt $DurationToleranceSeconds) {
        throw "worker_wall_duration_mismatch:expected=$expected,actual=$wallDuration"
    }
    if ([math]::Abs($monotonicDuration - $expected) -gt $DurationToleranceSeconds) {
        throw "worker_monotonic_duration_mismatch:expected=$expected,actual=$monotonicDuration"
    }

    [pscustomobject]@{
        injection_start_utc = $startText
        injection_end_utc = $endText
        wall_duration_seconds = $wallDuration
        monotonic_duration_seconds = $monotonicDuration
    }
}

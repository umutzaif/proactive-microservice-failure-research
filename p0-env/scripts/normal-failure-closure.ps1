$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Called after best-effort rollback and stop. Capture each result independently.
function Save-NormalFailureClosure {
    param([Parameter(Mandatory)][string]$ArtifactRoot,
          [Parameter(Mandatory)][string]$Profile,
          [Parameter(Mandatory)]$HostBefore,
          [Parameter(Mandatory)]$NetworkBefore,
          [Parameter(Mandatory)][string]$NetworkTransport,
          $StopExitCode)
    $result = [ordered]@{schema_version=1;observed_utc=[datetimeoffset]::UtcNow.ToString('o');stop_exit_code=$StopExitCode;host=$null;network=$null;profile_status=$null;container_state=$null;errors=[ordered]@{};passed=$false}
    try { $result.host = Measure-HostEventsAfterRecordIdBoundary $HostBefore } catch { $result.errors['host'] = $_.Exception.Message }
    try {
        $result.network = Get-HostNetworkContext -ExpectedTransport $NetworkTransport
        [void](Assert-HostNetworkContextStable -Before $NetworkBefore -After $result.network)
    } catch { $result.errors['network'] = $_.Exception.Message }
    try {
        [string[]]$raw = @(& minikube status --profile $Profile --output=json 2>&1)
        $statusExit = $LASTEXITCODE
        $result['profile_status_exit'] = $statusExit
        $result.profile_status = ($raw -join "`n") | ConvertFrom-Json -ErrorAction Stop
        if ($statusExit -notin @(0,7) -or $result.profile_status.Host -ne 'Stopped' -or $result.profile_status.Kubelet -ne 'Stopped' -or $result.profile_status.APIServer -ne 'Stopped') { throw 'failure_closure_profile_not_stopped' }
    } catch { $result.errors['profile_status'] = $_.Exception.Message }
    try {
        [string[]]$raw = @(& docker inspect --type container $Profile --format '{{json .State}}' 2>&1)
        $inspectExit = $LASTEXITCODE
        if ($inspectExit -ne 0) { throw "failure_closure_container_query_failed:$inspectExit" }
        $result.container_state = ($raw -join "`n") | ConvertFrom-Json -ErrorAction Stop
        if ($result.container_state.Running -ne $false -or $result.container_state.Status -ne 'exited' -or $result.container_state.OOMKilled -ne $false) { throw 'failure_closure_container_not_safely_stopped' }
    } catch { $result.errors['container_state'] = $_.Exception.Message }
    if ($null -ne $result.host -and -not $result.host.passed) { $result.errors['host_gate'] = 'host_events_nonzero' }
    if ($null -ne $StopExitCode -and $StopExitCode -ne 0) { $result.errors['stop_command'] = "stop_failed:$StopExitCode" }
    $result.passed = ($result.errors.Count -eq 0)
    $path = Join-Path $ArtifactRoot 'failure-closure.json'
    if (Test-Path -LiteralPath $path) { throw 'failure_closure_evidence_exists' }
    [IO.File]::WriteAllText($path, ($result | ConvertTo-Json -Depth 40), [Text.UTF8Encoding]::new($false))
    return $result
}

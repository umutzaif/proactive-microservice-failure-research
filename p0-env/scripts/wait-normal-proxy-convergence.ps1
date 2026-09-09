[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$EvidencePath,
    [string]$Profile = 'p0-online-boutique',
    [string]$FixtureSnapshotsPath
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'kubernetes-optional-property.ps1')
. (Join-Path $PSScriptRoot 'proxy-pod-readiness.ps1')
. (Join-Path $PSScriptRoot 'native-json-command.ps1')
$path = [IO.Path]::GetFullPath($EvidencePath)
if (Test-Path -LiteralPath $path) { throw 'convergence_evidence_exists' }
$timeoutSeconds = 120
$pollSeconds = 5
$observations = New-Object Collections.Generic.List[object]
$passed = $false
$failure = $null
$fixtures = @()
if ($FixtureSnapshotsPath) {
    $fixtures = @((Get-Content -LiteralPath $FixtureSnapshotsPath -Raw | ConvertFrom-Json).snapshots)
    if ($fixtures.Count -eq 0) { throw 'convergence_fixture_empty' }
}
$clock = [Diagnostics.Stopwatch]::StartNew()
$index = 0
$previousElapsed = -1.0
try {
    while ($true) {
        if ($FixtureSnapshotsPath) {
            if ($index -ge $fixtures.Count) { break }
            $elapsed = [double]$fixtures[$index].elapsed_seconds
            if ($elapsed -lt 0 -or $elapsed -lt $previousElapsed) { throw 'convergence_fixture_time_invalid' }
            $pods = $fixtures[$index].pod_list
        } else {
            if ($clock.Elapsed.TotalSeconds -gt $timeoutSeconds) { break }
            $pods = Invoke-NativeJsonCommand -FilePath (Get-Command minikube -CommandType Application).Source -ArgumentList @('kubectl','--profile',$Profile,'--','-n','online-boutique','get','pods','-l','app=recommendationservice','-o','json','--request-timeout=5s') -Operation 'convergence_pod_query_failed'
            $elapsed = $clock.Elapsed.TotalSeconds
        }
        $items = @($pods.items)
        $ready = $false
        # Count the complete selector set, including terminating predecessors.
        if ($items.Count -eq 1) {
            $status = Get-KubernetesOptionalProperty $items[0] 'status'
            $statuses = Get-KubernetesOptionalProperty $status 'containerStatuses'
            $conditions = Get-KubernetesOptionalProperty $status 'conditions'
            $deletion = Get-KubernetesOptionalProperty $items[0].metadata 'deletionTimestamp'
            if ($null -ne $statuses -and $null -ne $conditions -and $null -eq $deletion) {
                $ready = Test-SingleReadyProxyPod -Items $items
            }
        }
        $observations.Add([ordered]@{observed_utc=[datetimeoffset]::UtcNow.ToString('o');elapsed_seconds=$elapsed;pod_count=$items.Count;ready=$ready;pod_list=$pods})
        if ($elapsed -le $timeoutSeconds -and $ready) { $passed = $true; break }
        if ($elapsed -ge $timeoutSeconds) { break }
        $index++
        $previousElapsed = $elapsed
        if (-not $FixtureSnapshotsPath) { Start-Sleep -Milliseconds ([int][Math]::Min($pollSeconds * 1000, [Math]::Max(0, ($timeoutSeconds - $clock.Elapsed.TotalSeconds) * 1000))) }
    }
    if (-not $passed) { throw 'live_proxy_single_ready_pod_timeout' }
} catch { $failure = $_.Exception.Message }
finally {
    $clock.Stop()
    New-Item -ItemType Directory -Path (Split-Path -Parent $path) -Force | Out-Null
    $evidence = [ordered]@{schema_version=1;decision_id='D-111';passed=$passed;timeout_seconds=$timeoutSeconds;poll_seconds=$pollSeconds;fixture_mode=[bool]$FixtureSnapshotsPath;observations=$observations.ToArray();error=$failure}
    [IO.File]::WriteAllText($path, ($evidence | ConvertTo-Json -Depth 80), [Text.UTF8Encoding]::new($false))
}
if ($failure) { throw $failure }
Write-Output 'normal_proxy_convergence=passed'

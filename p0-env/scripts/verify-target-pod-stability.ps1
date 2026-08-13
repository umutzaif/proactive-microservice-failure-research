[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$Namespace,
    [Parameter(Mandatory = $true)][string]$Deployment,
    [Parameter(Mandatory = $true)][string]$Container,
    [Parameter(Mandatory = $true)][string]$EvidencePath,
    [string]$Profile = 'p0-online-boutique',
    [ValidateRange(1, 3600)][int]$DurationSeconds = 120,
    [ValidateRange(1, 60)][int]$PollSeconds = 5,
    [string]$FixtureSnapshotsPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Utf8NoBom([string]$Path, [object]$Value) {
    $parent = Split-Path -Parent $Path
    New-Item -ItemType Directory -Path $parent -Force | Out-Null
    [IO.File]::WriteAllText(
        $Path,
        ($Value | ConvertTo-Json -Depth 20),
        (New-Object Text.UTF8Encoding($false))
    )
}

function ConvertTo-StabilitySnapshot([object]$PodList) {
    $pods = @($PodList.items)
    if ($pods.Count -ne 1) { throw "target_pod_count_invalid:$($pods.Count)" }
    $pod = $pods[0]
    $specContainer = @($pod.spec.containers | Where-Object name -eq $Container)
    $statusContainer = @($pod.status.containerStatuses | Where-Object name -eq $Container)
    if ($specContainer.Count -ne 1 -or $statusContainer.Count -ne 1) {
        throw "target_container_missing:$Container"
    }
    $readyCondition = @($pod.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' })
    if ($readyCondition.Count -ne 1 -or -not [bool]$statusContainer[0].ready) {
        throw 'target_container_not_ready'
    }
    if ([string]::IsNullOrWhiteSpace([string]$statusContainer[0].containerID)) {
        throw 'target_container_id_missing'
    }
    [ordered]@{
        observed_utc = [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
        pod_name = [string]$pod.metadata.name
        pod_uid = [string]$pod.metadata.uid
        container = $Container
        container_id = [string]$statusContainer[0].containerID
        restart_count = [int]$statusContainer[0].restartCount
        ready = $true
    }
}

function Get-LivePodList {
    $raw = & minikube kubectl --profile $Profile -- `
        -n $Namespace get pods -l "app=$Deployment" -o json 2>&1
    if ($LASTEXITCODE -ne 0) { throw "target_pod_query_failed:$($raw -join ' | ')" }
    ($raw -join "`n") | ConvertFrom-Json
}

$fixtureSnapshots = $null
if (-not [string]::IsNullOrWhiteSpace($FixtureSnapshotsPath)) {
    $fixtureSnapshots = @((Get-Content -Raw -LiteralPath $FixtureSnapshotsPath | ConvertFrom-Json).snapshots)
    if ($fixtureSnapshots.Count -lt 2) { throw 'fixture_requires_at_least_two_snapshots' }
}

$requiredObservations = if ($null -ne $fixtureSnapshots) {
    $fixtureSnapshots.Count
} else {
    [int][Math]::Ceiling($DurationSeconds / [double]$PollSeconds) + 1
}
$observations = New-Object Collections.Generic.List[object]
$identity = $null

for ($index = 0; $index -lt $requiredObservations; $index++) {
    $podList = if ($null -ne $fixtureSnapshots) { $fixtureSnapshots[$index] } else { Get-LivePodList }
    $snapshot = ConvertTo-StabilitySnapshot -PodList $podList
    $currentIdentity = "$($snapshot.pod_name)|$($snapshot.pod_uid)|$($snapshot.container_id)|$($snapshot.restart_count)"
    if ($null -eq $identity) { $identity = $currentIdentity }
    elseif ($currentIdentity -ne $identity) { throw 'target_pod_identity_or_restart_changed' }
    $observations.Add($snapshot)
    if ($null -eq $fixtureSnapshots -and $index -lt ($requiredObservations - 1)) {
        Start-Sleep -Seconds $PollSeconds
    }
}

$evidence = [ordered]@{
    schema_version = 1
    policy_id = 'd038-target-pod-stability-v1'
    namespace = $Namespace
    deployment = $Deployment
    container = $Container
    required_duration_seconds = $DurationSeconds
    poll_seconds = $PollSeconds
    observation_count = $observations.Count
    first_snapshot = $observations[0]
    final_snapshot = $observations[$observations.Count - 1]
    stable = $true
}
$resolvedEvidence = [IO.Path]::GetFullPath($EvidencePath)
if (Test-Path -LiteralPath $resolvedEvidence) { throw 'target_stability_evidence_exists' }
Write-Utf8NoBom -Path $resolvedEvidence -Value $evidence
(Get-Item -LiteralPath $resolvedEvidence).IsReadOnly = $true
Write-Output "target_stability_observation_count=$($observations.Count)"
Write-Output "target_stability_restart_count=$($evidence.final_snapshot.restart_count)"
Write-Output 'target_pod_stability_verification=passed'

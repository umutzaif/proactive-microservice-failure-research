[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [Parameter(Mandatory = $true)]
    [string]$ProfilePath,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$RunId,

    [Parameter(Mandatory = $true)]
    [string]$EvidencePath,

    [string]$Profile = 'p0-online-boutique'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

function Get-Sha256 {
    param([string]$Path)
    $stream = [System.IO.File]::OpenRead($Path)
    try {
        $algorithm = [System.Security.Cryptography.SHA256]::Create()
        try { return ([System.BitConverter]::ToString($algorithm.ComputeHash($stream))).Replace('-', '').ToLowerInvariant() }
        finally { $algorithm.Dispose() }
    }
    finally { $stream.Dispose() }
}

$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$resolvedProfile = (Resolve-Path -LiteralPath $ProfilePath).Path
$faultProfile = Get-Content -LiteralPath $resolvedProfile -Raw | ConvertFrom-Json
$workerPath = [System.IO.Path]::GetFullPath(
    (Join-Path $repositoryRoot ([string]$faultProfile.injector.worker_source))
)
$repositoryPrefix = $repositoryRoot.TrimEnd('\') + '\'
if (-not $workerPath.StartsWith($repositoryPrefix, [System.StringComparison]::OrdinalIgnoreCase)) {
    throw 'Worker source escapes the repository.'
}
if (-not (Test-Path -LiteralPath $workerPath -PathType Leaf)) {
    throw "Worker source is missing: $workerPath"
}
$workerHash = Get-Sha256 -Path $workerPath
if ($workerHash -ne ([string]$faultProfile.injector.worker_sha256).ToLowerInvariant()) {
    throw 'Worker source checksum does not match the fault profile.'
}

$allowedCoverageIntervals = @{
    'cpu-recommendation-low-v1' = 240
    'cpu-recommendation-low-v2' = 48
}
$profileId = [string]$faultProfile.profile_id
if (
    -not $allowedCoverageIntervals.ContainsKey($profileId) -or
    [string]$faultProfile.fault_class -ne 'cpu_stress' -or
    [string]$faultProfile.severity -ne 'low' -or
    [int]$faultProfile.injector.target_additional_cpu_millicores -ne 50 -or
    [int]$faultProfile.injector.ramp_seconds -ne 120 -or
    [int]$faultProfile.injector.steady_seconds -ne 300 -or
    [bool]$faultProfile.injector.automatic_termination_required -ne $true -or
    [int]$faultProfile.physical_effect_verification.minimum_cpu_intervals_per_300_second_phase -ne $allowedCoverageIntervals[$profileId]
) {
    throw 'Fault profile does not match the preregistered low-stress contract.'
}

$namespace = [string]$faultProfile.target.namespace
$deployment = [string]$faultProfile.target.deployment
$container = [string]$faultProfile.target.container
$selector = "app=$deployment"

if (-not $PSCmdlet.ShouldProcess(
    "$namespace/deployment=$deployment container=$container",
    "run bounded CPU profile $($faultProfile.profile_id) for run $RunId"
)) {
    Write-Output 'cpu_stress_injection=not-executed'
    return
}

$podJson = & minikube kubectl --profile $Profile -- `
    -n $namespace get pods -l $selector -o json 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Could not resolve target pod: $($podJson -join ' | ')"
}
$pods = @(($podJson -join "`n" | ConvertFrom-Json).items)
if ($pods.Count -ne 1) {
    throw "Injector requires exactly one target pod; found $($pods.Count)."
}
$pod = $pods[0]
$podName = [string]$pod.metadata.name
$podUid = [string]$pod.metadata.uid
$restartBefore = [int](
    @($pod.status.containerStatuses | Where-Object name -eq $container)[0].restartCount
)

$workerSource = Get-Content -LiteralPath $workerPath -Raw
$workerBase64 = [Convert]::ToBase64String(
    [System.Text.Encoding]::UTF8.GetBytes($workerSource)
)
$remoteBootstrap = "import base64;exec(compile(base64.b64decode('$workerBase64'),'<cpu-duty-worker>','exec'))"
$remoteArguments = @(
    'python', '-c', $remoteBootstrap,
    '--target-millicores', [string]$faultProfile.injector.target_additional_cpu_millicores,
    '--ramp-seconds', [string]$faultProfile.injector.ramp_seconds,
    '--steady-seconds', [string]$faultProfile.injector.steady_seconds,
    '--cycle-milliseconds', [string]$faultProfile.injector.cycle_milliseconds,
    '--maximum-total-seconds', [string]$faultProfile.injector.maximum_total_seconds
)

$startedUtc = [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
$output = @(& minikube kubectl --profile $Profile -- `
    -n $namespace exec $podName -c $container -- @remoteArguments 2>&1)
$exitCode = $LASTEXITCODE
$endedUtc = [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')

$events = New-Object System.Collections.Generic.List[object]
foreach ($line in $output) {
    try {
        $event = ([string]$line | ConvertFrom-Json)
        $events.Add($event)
    }
    catch {
        # Kubernetes transport messages remain in raw_output for diagnosis.
    }
}

$podAfterJson = & minikube kubectl --profile $Profile -- `
    -n $namespace get pod $podName -o json 2>&1
if ($LASTEXITCODE -ne 0) {
    throw "Could not verify target pod after injection: $($podAfterJson -join ' | ')"
}
$podAfter = $podAfterJson -join "`n" | ConvertFrom-Json
$restartAfter = [int](
    @($podAfter.status.containerStatuses | Where-Object name -eq $container)[0].restartCount
)

$startedEvents = @($events | Where-Object event -eq 'started')
$completedEvents = @($events | Where-Object event -eq 'completed')
$heartbeatEvents = @($events | Where-Object event -eq 'heartbeat')
$passed = (
    $exitCode -eq 0 -and
    $startedEvents.Count -eq 1 -and
    $completedEvents.Count -eq 1 -and
    $heartbeatEvents.Count -gt 0 -and
    [string]$podAfter.metadata.uid -eq $podUid -and
    $restartAfter -eq $restartBefore
)

$evidence = [ordered]@{
    schema_version = 1
    run_id = $RunId
    fault_profile_id = [string]$faultProfile.profile_id
    fault_profile_sha256 = Get-Sha256 -Path $resolvedProfile
    worker_sha256 = $workerHash
    namespace = $namespace
    pod_name = $podName
    pod_uid_before = $podUid
    pod_uid_after = [string]$podAfter.metadata.uid
    container = $container
    restart_count_before = $restartBefore
    restart_count_after = $restartAfter
    injection_start_utc = $startedUtc
    injection_end_utc = $endedUtc
    command_exit_code = $exitCode
    worker_started_event_count = $startedEvents.Count
    worker_heartbeat_event_count = $heartbeatEvents.Count
    worker_completed_event_count = $completedEvents.Count
    bounded_worker_verification = $passed
    physical_effect_verified = $false
    physical_effect_verification_status = 'requires-prometheus-analysis'
    raw_output = @($output | ForEach-Object { [string]$_ })
}

$resolvedEvidence = [System.IO.Path]::GetFullPath($EvidencePath)
$evidenceParent = Split-Path -Parent $resolvedEvidence
New-Item -ItemType Directory -Path $evidenceParent -Force | Out-Null
if (Test-Path -LiteralPath $resolvedEvidence) {
    throw "Injection evidence already exists and will not be overwritten: $resolvedEvidence"
}
Write-Utf8NoBom -Path $resolvedEvidence -Content ($evidence | ConvertTo-Json -Depth 10)
(Get-Item -LiteralPath $resolvedEvidence).IsReadOnly = $true

Write-Output "injection_start_utc=$startedUtc"
Write-Output "injection_end_utc=$endedUtc"
Write-Output "worker_heartbeat_event_count=$($heartbeatEvents.Count)"
Write-Output "bounded_worker_verification=$passed"
Write-Output 'physical_effect_verification=required'

if (-not $passed) {
    throw 'Bounded CPU worker verification failed; evidence was preserved.'
}

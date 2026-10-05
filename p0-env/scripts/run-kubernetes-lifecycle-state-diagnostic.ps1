[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
param(
    [string]$DiagnosticId = 'ob-k8s-lifecycle-state-diagnostic-001',
    [string]$Profile = 'p0-online-boutique',
    [Parameter(Mandatory)][string]$RuntimeStateRoot,
    [switch]$ExecutionApproved
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'host-event-recordid.ps1')
. (Join-Path $PSScriptRoot 'native-command-capture.ps1')
. (Join-Path $PSScriptRoot 'lifecycle-state-diagnostic-contract.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gate = 'P2-KUBERNETES-LIFECYCLE-STATE-DIAG-001'
$namespace = 'online-boutique'
$artifactRoot = Join-Path $repo "p0-env\artifacts\$gate\$DiagnosticId"

function Utc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function Write-Json([string]$Path, [object]$Value) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText(
        $Path,
        ($Value | ConvertTo-Json -Depth 100),
        [Text.UTF8Encoding]::new($false)
    )
}
function Capture([string]$FilePath, [string[]]$ArgumentList) {
    $saved = $WhatIfPreference
    $WhatIfPreference = $false
    try { Invoke-NativeCommandCapture -FilePath $FilePath -ArgumentList $ArgumentList }
    finally { $WhatIfPreference = $saved }
}
function Capture-Kubectl([string[]]$Arguments) {
    Capture $minikube (@('kubectl', '--profile', $Profile, '--') + $Arguments)
}
function Require-Capture([object]$CaptureResult, [string]$Name) {
    if ([int]$CaptureResult.exit_code -ne 0 -or
        [string]::IsNullOrWhiteSpace([string]$CaptureResult.stdout)) {
        throw "lifecycle_capture_failed:$Name"
    }
}

if (-not $ExecutionApproved) { throw 'explicit_lifecycle_state_diagnostic_approval_required' }
if ($DiagnosticId -ne 'ob-k8s-lifecycle-state-diagnostic-001') { throw 'unexpected_diagnostic_id' }
if (@(& git -C $repo status --porcelain).Count) { throw 'working_tree_not_clean' }
if (Test-Path -LiteralPath $artifactRoot) { throw 'immutable_diagnostic_output_exists' }

$runtimeState = (Resolve-Path -LiteralPath $RuntimeStateRoot -ErrorAction Stop).Path
$env:MINIKUBE_HOME = $runtimeState
$driveRoot = [IO.Path]::GetPathRoot($runtimeState)
$freeBytes = [IO.DriveInfo]::new($driveRoot).AvailableFreeSpace
if ($freeBytes -lt 15GB) { throw 'insufficient_free_space' }

$docker = (Get-Command docker -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$minikube = (Get-Command minikube -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$dockerInfo = Capture $docker @('info', '--format', '{{.ServerVersion}}')
Require-Capture $dockerInfo 'docker_info'
$preInspect = Capture $docker @('inspect', $Profile)
Require-Capture $preInspect 'prestart_container_inspect'
$preInspectItems = @($preInspect.stdout | ConvertFrom-Json)
if ($preInspectItems.Count -ne 1 -or [bool]$preInspectItems[0].State.Running) {
    throw 'profile_container_not_stopped'
}
$profileStatus = Capture $minikube @('status', '--profile', $Profile, '--output=json')
if ([string]::IsNullOrWhiteSpace([string]$profileStatus.stdout)) { throw 'profile_status_missing' }
$profileStatusObject = $profileStatus.stdout | ConvertFrom-Json
foreach ($property in @('Host', 'Kubelet', 'APIServer', 'Kubeconfig')) {
    if ([string]$profileStatusObject.$property -ne 'Stopped') {
        throw "profile_component_not_stopped:$property"
    }
}
$boundary = New-HostEventRecordIdBoundary

if (-not $PSCmdlet.ShouldProcess(
    $Profile,
    'start preserved profile, capture lifecycle state without mutation, then stop profile'
)) { return }

New-Item -ItemType Directory -Path $artifactRoot | Out-Null
$failure = $null
$classification = 'diagnostic_incomplete'
Write-Json (Join-Path $artifactRoot 'host-before.json') $boundary
Write-Json (Join-Path $artifactRoot 'prestart-container-inspect.json') $preInspectItems[0]
Write-Json (Join-Path $artifactRoot 'prestart-profile-status-capture.json') $profileStatus
Write-Json (Join-Path $artifactRoot 'diagnostic-manifest.json') ([ordered]@{
    schema_version = 1
    gate_id = $gate
    diagnostic_id = $DiagnosticId
    preregistration_decision = 'D-129'
    code_revision = (& git -C $repo rev-parse HEAD).Trim()
    profile = $Profile
    namespace = $namespace
    runtime_state_root = $runtimeState
    free_space_bytes = $freeBytes
    minimum_free_space_bytes = 15GB
    reuses_preserved_profile = $true
    application_manifest_applied = $false
    rollout_restarted = $false
    object_mutated = $false
    finalizer_removed = $false
    profile_deleted_or_reset = $false
    docker_restarted = $false
    workload_started = $false
    scientific_fault_started = $false
    dataset_inclusion = $false
    headroom_decision_inclusion = $false
})

try {
    $stdout = Join-Path $artifactRoot 'minikube-start.stdout.txt'
    $stderr = Join-Path $artifactRoot 'minikube-start.stderr.txt'
    $startArguments = @(
        'start', '--profile', $Profile, '--driver=docker',
        '--kubernetes-version=v1.34.0', '--cpus=4', '--memory=6144mb',
        '--disk-size=32g', '--container-runtime=containerd'
    )
    $process = Start-Process -FilePath $minikube -ArgumentList $startArguments `
        -RedirectStandardOutput $stdout -RedirectStandardError $stderr `
        -PassThru -WindowStyle Hidden
    $completed = $process.WaitForExit(420000)
    if (-not $completed) {
        Stop-Process -Id $process.Id -Force
        $process.WaitForExit()
    }
    $process.Refresh()
    $startExit = [int]$process.ExitCode
    $process.Dispose()
    Write-Json (Join-Path $artifactRoot 'start-process.json') ([ordered]@{
        completed_within_timeout = $completed
        timeout_seconds = 420
        exit_code = $startExit
    })
    if (-not $completed -or $startExit -ne 0) { throw 'preserved_profile_start_failed' }

    $captures = [ordered]@{
        'nodes.json' = Capture-Kubectl @('get', 'nodes', '-o', 'json')
        'deployments.json' = Capture-Kubectl @('-n', $namespace, 'get', 'deployments', '-o', 'json')
        'replicasets.json' = Capture-Kubectl @('-n', $namespace, 'get', 'replicasets', '-o', 'json')
        'pods.json' = Capture-Kubectl @('-n', $namespace, 'get', 'pods', '-o', 'json')
        'events.json' = Capture-Kubectl @('-n', $namespace, 'get', 'events', '-o', 'json')
        'recommendation-deployment.json' = Capture-Kubectl @(
            '-n', $namespace, 'get', 'deployment/recommendationservice', '-o', 'json'
        )
        'controller-manager-log-capture.json' = Capture-Kubectl @(
            '-n', 'kube-system', 'logs', '-l', 'component=kube-controller-manager', '--tail=1000'
        )
    }
    foreach ($entry in $captures.GetEnumerator()) {
        Write-Json (Join-Path $artifactRoot $entry.Key) $entry.Value
    }
    foreach ($name in @(
        'nodes.json', 'deployments.json', 'replicasets.json', 'pods.json',
        'events.json', 'recommendation-deployment.json'
    )) { Require-Capture $captures[$name] $name }

    $deployment = $captures['recommendation-deployment.json'].stdout | ConvertFrom-Json
    $podList = $captures['pods.json'].stdout | ConvertFrom-Json
    $assessment = Get-LifecycleStateAssessment -Deployment $deployment -Pods @($podList.items)
    $classification = $assessment.classification
    $assessment['diagnostic_id'] = $DiagnosticId
    $assessment['causal_conclusion'] = $false
    $assessment['repair_authorized'] = $false
    $assessment['successor_authorized'] = $false
    $assessment['dataset_inclusion'] = $false
    $assessment['headroom_decision_inclusion'] = $false
    Write-Json (Join-Path $artifactRoot 'assessment.json') $assessment
    Write-Json (Join-Path $artifactRoot 'minikube-last-start-capture.json') (
        Capture $minikube @('logs', '--profile', $Profile, '--last-start-only')
    )
}
catch {
    $failure = $_.Exception.Message
    if (-not (Test-Path -LiteralPath (Join-Path $artifactRoot 'start-process.json'))) {
        Write-Json (Join-Path $artifactRoot 'start-process.json') ([ordered]@{
            completed_within_timeout = $false
            timeout_seconds = 420
            exit_code = $null
            error = $failure
        })
    }
    Write-Json (Join-Path $artifactRoot 'run-error.json') ([ordered]@{
        failed_utc = Utc
        error = $failure
        scientific_fault_started = $false
    })
    if (-not (Test-Path -LiteralPath (Join-Path $artifactRoot 'assessment.json'))) {
        Write-Json (Join-Path $artifactRoot 'assessment.json') ([ordered]@{
            schema_version = 1
            diagnostic_id = $DiagnosticId
            classification = 'diagnostic_incomplete'
            causal_conclusion = $false
            repair_authorized = $false
            successor_authorized = $false
            dataset_inclusion = $false
            headroom_decision_inclusion = $false
        })
    }
}
finally {
    $stopCapture = Capture $minikube @('stop', '--profile', $Profile)
    Write-Json (Join-Path $artifactRoot 'stop-capture.json') $stopCapture
    Write-Json (Join-Path $artifactRoot 'final-profile-status-capture.json') (
        Capture $minikube @('status', '--profile', $Profile, '--output=json')
    )
    Write-Json (Join-Path $artifactRoot 'final-container-inspect-capture.json') (
        Capture $docker @('inspect', $Profile)
    )
    try {
        Write-Json (Join-Path $artifactRoot 'host-after.json') (
            Measure-HostEventsAfterRecordIdBoundary -Boundary $boundary
        )
    }
    catch {
        Write-Json (Join-Path $artifactRoot 'host-after.json') ([ordered]@{
            passed = $false
            error = $_.Exception.Message
            counts = [ordered]@{ whea_event_17 = -1; kernel_power_41 = -1; bugcheck = -1 }
        })
        if ($null -eq $failure) { $failure = 'host_after_capture_failed' }
    }
}

if ($null -ne $failure) {
    $assessmentPath = Join-Path $artifactRoot 'assessment.json'
    $preliminaryClassification = $null
    if (Test-Path -LiteralPath $assessmentPath -PathType Leaf) {
        try {
            $existingAssessment = Get-Content -LiteralPath $assessmentPath -Raw | ConvertFrom-Json
            $preliminaryClassification = [string]$existingAssessment.classification
            Copy-Item -LiteralPath $assessmentPath -Destination (
                Join-Path $artifactRoot 'preliminary-assessment.json'
            ) -Force
        }
        catch { $preliminaryClassification = 'unreadable' }
    }
    Write-Json $assessmentPath ([ordered]@{
        schema_version = 1
        diagnostic_id = $DiagnosticId
        classification = 'diagnostic_incomplete'
        preliminary_classification = $preliminaryClassification
        failure = $failure
        causal_conclusion = $false
        repair_authorized = $false
        successor_authorized = $false
        dataset_inclusion = $false
        headroom_decision_inclusion = $false
    })
}

& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'verify-kubernetes-lifecycle-state-diagnostic.ps1') `
    -ArtifactRoot $artifactRoot -ExpectedDiagnosticId $DiagnosticId
if ($LASTEXITCODE -ne 0 -and $null -eq $failure) {
    $failure = 'semantic_verification_failed'
    $assessmentPath = Join-Path $artifactRoot 'assessment.json'
    if (Test-Path -LiteralPath $assessmentPath -PathType Leaf) {
        Copy-Item -LiteralPath $assessmentPath -Destination (
            Join-Path $artifactRoot 'preliminary-assessment.json'
        ) -Force
    }
    Write-Json $assessmentPath ([ordered]@{
        schema_version = 1
        diagnostic_id = $DiagnosticId
        classification = 'diagnostic_incomplete'
        preliminary_classification = $classification
        failure = $failure
        causal_conclusion = $false
        repair_authorized = $false
        successor_authorized = $false
        dataset_inclusion = $false
        headroom_decision_inclusion = $false
    })
}
& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1') `
    -ArtifactRoot $artifactRoot -Mode Create
if ($LASTEXITCODE -ne 0 -and $null -eq $failure) { $failure = 'diagnostic_seal_failed' }
if ($null -ne $failure) { throw "lifecycle_state_diagnostic_failed:$failure" }

Write-Output (
    "kubernetes_lifecycle_state_diagnostic=completed " +
    "id=$DiagnosticId classification=$classification"
)

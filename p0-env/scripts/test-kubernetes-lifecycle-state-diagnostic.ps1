[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'lifecycle-state-diagnostic-contract.ps1')

function From-Json([string]$Text) { $Text | ConvertFrom-Json }
function Assert-Equal([object]$Actual, [object]$Expected, [string]$Name) {
    if ($Actual -ne $Expected) { throw "assertion_failed:$Name actual=$Actual expected=$Expected" }
}

$deploymentCurrent = From-Json '{"metadata":{"name":"recommendationservice","generation":17},"status":{"observedGeneration":17}}'
$deploymentLagged = From-Json '{"metadata":{"name":"recommendationservice","generation":17},"status":{"observedGeneration":16}}'
$readyPod = From-Json '{"metadata":{"name":"recommendationservice-new","uid":"new","labels":{"app":"recommendationservice"}},"status":{"phase":"Running"}}'
$terminatingPod = From-Json '{"metadata":{"name":"recommendationservice-old","uid":"old","labels":{"app":"recommendationservice"},"deletionTimestamp":"2026-10-01T00:00:00Z"},"status":{"phase":"Running"}}'

$clean = Get-LifecycleStateAssessment -Deployment $deploymentCurrent -Pods @($readyPod)
Assert-Equal $clean.classification 'lifecycle_state_not_reproduced' 'clean_classification'
Assert-Equal $clean.terminating_pod_count 0 'clean_terminating_count'
Assert-Equal $clean.controller_generation_lag $false 'clean_generation_lag'

$terminating = Get-LifecycleStateAssessment -Deployment $deploymentCurrent -Pods @($readyPod, $terminatingPod)
Assert-Equal $terminating.classification 'stale_lifecycle_state_observed' 'terminating_classification'
Assert-Equal $terminating.terminating_pod_count 1 'terminating_count'

$lagged = Get-LifecycleStateAssessment -Deployment $deploymentLagged -Pods @($readyPod)
Assert-Equal $lagged.classification 'stale_lifecycle_state_observed' 'lagged_classification'
Assert-Equal $lagged.controller_generation_lag $true 'lagged_generation_flag'

$wrongDeployment = From-Json '{"metadata":{"name":"other","generation":1},"status":{"observedGeneration":1}}'
$rejected = $false
try { $null = Get-LifecycleStateAssessment -Deployment $wrongDeployment -Pods @() }
catch { $rejected = $_.Exception.Message -eq 'recommendation_deployment_identity_mismatch' }
if (-not $rejected) { throw 'wrong_deployment_identity_not_rejected' }

$runnerPath = Join-Path $PSScriptRoot 'run-kubernetes-lifecycle-state-diagnostic.ps1'
$verifierPath = Join-Path $PSScriptRoot 'verify-kubernetes-lifecycle-state-diagnostic.ps1'
$runner = Get-Content -LiteralPath $runnerPath -Raw
$verifier = Get-Content -LiteralPath $verifierPath -Raw

foreach ($required in @(
    'SupportsShouldProcess = $true',
    'explicit_lifecycle_state_diagnostic_approval_required',
    'working_tree_not_clean',
    'immutable_diagnostic_output_exists',
    'profile_container_not_stopped',
    'New-HostEventRecordIdBoundary',
    "Capture `$minikube @('stop', '--profile', `$Profile)",
    'Measure-HostEventsAfterRecordIdBoundary',
    'verify-kubernetes-lifecycle-state-diagnostic.ps1',
    'seal-diagnostic-artifacts.ps1'
)) {
    if (-not $runner.Contains($required)) { throw "runner_contract_missing:$required" }
}

$approvalIndex = $runner.IndexOf('if (-not $ExecutionApproved)')
$cleanIndex = $runner.IndexOf("throw 'working_tree_not_clean'")
$existsIndex = $runner.IndexOf("throw 'immutable_diagnostic_output_exists'")
$shouldProcessIndex = $runner.IndexOf('if (-not $PSCmdlet.ShouldProcess')
$artifactIndex = $runner.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')
if ($approvalIndex -lt 0 -or $cleanIndex -le $approvalIndex -or $existsIndex -le $cleanIndex -or
    $shouldProcessIndex -le $existsIndex -or $artifactIndex -le $shouldProcessIndex) {
    throw 'artifact_free_gate_order_invalid'
}

foreach ($pattern in @(
    "(?is)Capture-Kubectl\s+@\([^\)]*'(?:apply|delete|patch|rollout|scale|edit|replace)'",
    "(?is)Capture\s+\`$minikube\s+@\('delete'",
    "(?is)Capture\s+\`$docker\s+@\('restart'"
)) {
    if ($runner -match $pattern) { throw "forbidden_mutation_command_present:$pattern" }
}

foreach ($required in @(
    'lifecycle_manifest_scope_mismatch',
    'lifecycle_assessment_replay_mismatch',
    'profile_container_not_stopped_after_diagnostic',
    'host_health_gate_failed',
    'Get-LifecycleStateAssessment'
)) {
    if (-not $verifier.Contains($required)) { throw "verifier_contract_missing:$required" }
}

$parseErrors = @()
foreach ($path in @(
    (Join-Path $PSScriptRoot 'lifecycle-state-diagnostic-contract.ps1'),
    $runnerPath,
    $verifierPath
)) {
    $tokens = $null
    $errors = $null
    $null = [System.Management.Automation.Language.Parser]::ParseFile(
        $path,
        [ref]$tokens,
        [ref]$errors
    )
    $parseErrors += @($errors)
}
if ($parseErrors.Count -gt 0) {
    throw ('powershell_parse_errors:' + (($parseErrors | ForEach-Object Message) -join '|'))
}

function Write-FixtureJson([string]$Path, [object]$Value) {
    [IO.File]::WriteAllText(
        $Path,
        ($Value | ConvertTo-Json -Depth 40),
        [Text.UTF8Encoding]::new($false)
    )
}
function New-VerifierFixture(
    [string]$Root,
    [object]$Deployment,
    [object[]]$Pods,
    [switch]$Mutated
) {
    New-Item -ItemType Directory -Path $Root | Out-Null
    $computed = Get-LifecycleStateAssessment -Deployment $Deployment -Pods $Pods
    $manifest = [ordered]@{
        schema_version = 1
        gate_id = 'P2-KUBERNETES-LIFECYCLE-STATE-DIAG-001'
        diagnostic_id = 'ob-k8s-lifecycle-state-diagnostic-001'
        preregistration_decision = 'D-129'
        runtime_state_root = 'C:\fixture\minikube'
        reuses_preserved_profile = $true
        application_manifest_applied = $false
        rollout_restarted = $false
        object_mutated = [bool]$Mutated
        finalizer_removed = $false
        profile_deleted_or_reset = $false
        docker_restarted = $false
        workload_started = $false
        scientific_fault_started = $false
        dataset_inclusion = $false
        headroom_decision_inclusion = $false
    }
    Write-FixtureJson (Join-Path $Root 'diagnostic-manifest.json') $manifest
    Write-FixtureJson (Join-Path $Root 'prestart-container-inspect.json') ([ordered]@{ State = [ordered]@{ Running = $false } })
    Write-FixtureJson (Join-Path $Root 'start-process.json') ([ordered]@{ completed_within_timeout = $true; exit_code = 0 })
    $assessment = [ordered]@{
        schema_version = 1
        diagnostic_id = 'ob-k8s-lifecycle-state-diagnostic-001'
        classification = $computed.classification
        deployment_generation = $computed.deployment_generation
        observed_generation = $computed.observed_generation
        terminating_pod_count = $computed.terminating_pod_count
        causal_conclusion = $false
        repair_authorized = $false
        successor_authorized = $false
        dataset_inclusion = $false
        headroom_decision_inclusion = $false
    }
    Write-FixtureJson (Join-Path $Root 'assessment.json') $assessment
    Write-FixtureJson (Join-Path $Root 'stop-capture.json') ([ordered]@{ exit_code = 0; stdout = 'stopped'; stderr = '' })
    Write-FixtureJson (Join-Path $Root 'final-profile-status-capture.json') ([ordered]@{ exit_code = 7; stdout = '{"Host":"Stopped","Kubelet":"Stopped","APIServer":"Stopped","Kubeconfig":"Stopped"}'; stderr = '' })
    $inspectJson = @([ordered]@{ State = [ordered]@{ Running = $false; Status = 'exited'; ExitCode = 130; OOMKilled = $false } }) | ConvertTo-Json -Depth 10
    Write-FixtureJson (Join-Path $Root 'final-container-inspect-capture.json') ([ordered]@{ exit_code = 0; stdout = $inspectJson; stderr = '' })
    Write-FixtureJson (Join-Path $Root 'host-after.json') ([ordered]@{ passed = $true; counts = [ordered]@{ whea_event_17 = 0; kernel_power_41 = 0; bugcheck = 0 } })
    $deploymentJson = $Deployment | ConvertTo-Json -Depth 20
    $podListJson = ([ordered]@{ apiVersion = 'v1'; kind = 'PodList'; items = @($Pods) } | ConvertTo-Json -Depth 30)
    $captureFixtures = [ordered]@{
        'nodes.json' = '{}'
        'deployments.json' = '{}'
        'replicasets.json' = '{}'
        'pods.json' = $podListJson
        'events.json' = '{}'
        'recommendation-deployment.json' = $deploymentJson
        'controller-manager-log-capture.json' = 'fixture log'
    }
    foreach ($entry in $captureFixtures.GetEnumerator()) {
        Write-FixtureJson (Join-Path $Root $entry.Key) ([ordered]@{ exit_code = 0; stdout = $entry.Value; stderr = '' })
    }
}

$fixtureBase = Join-Path ([IO.Path]::GetTempPath()) ('d129-fixture-' + [guid]::NewGuid().ToString('N'))
try {
    $observedRoot = Join-Path $fixtureBase 'observed\ob-k8s-lifecycle-state-diagnostic-001'
    New-VerifierFixture -Root $observedRoot -Deployment $deploymentCurrent -Pods @($readyPod, $terminatingPod)
    $observedOutput = & $verifierPath -ArtifactRoot $observedRoot
    if ([string]$observedOutput -notmatch 'classification=stale_lifecycle_state_observed') {
        throw 'observed_fixture_verification_failed'
    }

    $cleanRoot = Join-Path $fixtureBase 'clean\ob-k8s-lifecycle-state-diagnostic-001'
    New-VerifierFixture -Root $cleanRoot -Deployment $deploymentCurrent -Pods @($readyPod)
    $cleanOutput = & $verifierPath -ArtifactRoot $cleanRoot
    if ([string]$cleanOutput -notmatch 'classification=lifecycle_state_not_reproduced') {
        throw 'clean_fixture_verification_failed'
    }

    $mutatedRoot = Join-Path $fixtureBase 'mutated\ob-k8s-lifecycle-state-diagnostic-001'
    New-VerifierFixture -Root $mutatedRoot -Deployment $deploymentCurrent -Pods @($readyPod) -Mutated
    $mutationRejected = $false
    try { $null = & $verifierPath -ArtifactRoot $mutatedRoot }
    catch { $mutationRejected = $_.Exception.Message -eq 'lifecycle_manifest_scope_mismatch' }
    if (-not $mutationRejected) { throw 'mutated_fixture_not_rejected' }
}
finally {
    $resolvedFixture = [IO.Path]::GetFullPath($fixtureBase)
    $resolvedTemp = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolvedFixture.StartsWith($resolvedTemp, [StringComparison]::OrdinalIgnoreCase) -and
        (Split-Path -Leaf $resolvedFixture).StartsWith('d129-fixture-', [StringComparison]::Ordinal)) {
        Remove-Item -LiteralPath $resolvedFixture -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Write-Output (
    'kubernetes_lifecycle_state_diagnostic_tests=passed ' +
    'classification=3 verifier_positive=2 identity_negative=1 mutation_negative=4 gate_order=passed'
)

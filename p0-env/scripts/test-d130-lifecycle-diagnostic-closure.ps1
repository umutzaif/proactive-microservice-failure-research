[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$diagnosticId = 'ob-k8s-lifecycle-state-diagnostic-001'
$expectedRevision = 'aad661da54f35c5c6c6eb409896a5e7d8804d9e1'
$expectedManifestHash = '85118c5235cfb3f14d4b52fa90bc17f068c3e258be259ff496e286fa911b0db7'
$artifact = Join-Path $repo 'p0-env/artifacts/P2-KUBERNETES-LIFECYCLE-STATE-DIAG-001/ob-k8s-lifecycle-state-diagnostic-001'
$report = Join-Path $repo 'p0-env/artifacts/P2-KUBERNETES-LIFECYCLE-STATE-DIAG-001/ob-k8s-lifecycle-state-diagnostic-001-report.md'

foreach ($path in @($artifact, $report)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "d130_path_missing:$path" }
}

$manifestPath = Join-Path $artifact 'sha256-manifest.json'
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ($manifestHash -ne $expectedManifestHash) { throw "d130_manifest_hash_mismatch:$manifestHash" }

$seal = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$entries = @($seal.files)
if ($entries.Count -ne 20) { throw "d130_seal_count_invalid:$($entries.Count)" }
foreach ($entry in $entries) {
    $path = Join-Path $artifact ([string]$entry.path)
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "d130_sealed_file_missing:$($entry.path)" }
    $file = Get-Item -LiteralPath $path
    if ([int64]$file.Length -ne [int64]$entry.bytes) { throw "d130_sealed_size_mismatch:$($entry.path)" }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne ([string]$entry.sha256).ToLowerInvariant()) { throw "d130_sealed_hash_mismatch:$($entry.path)" }
}

$assessment = Get-Content -LiteralPath (Join-Path $artifact 'assessment.json') -Raw | ConvertFrom-Json
if ($assessment.classification -ne 'stale_lifecycle_state_observed') { throw 'd130_classification_invalid' }
if ([int]$assessment.deployment_generation -ne 17 -or [int]$assessment.observed_generation -ne 16) { throw 'd130_generation_invalid' }
if (-not [bool]$assessment.controller_generation_lag) { throw 'd130_controller_lag_missing' }
if ([int]$assessment.terminating_pod_count -ne 1) { throw 'd130_terminating_count_invalid' }
if ([bool]$assessment.causal_conclusion -or [bool]$assessment.repair_authorized -or
    [bool]$assessment.successor_authorized -or [bool]$assessment.dataset_inclusion -or
    [bool]$assessment.headroom_decision_inclusion) { throw 'd130_authority_or_inclusion_leak' }

$diagnosticManifest = Get-Content -LiteralPath (Join-Path $artifact 'diagnostic-manifest.json') -Raw | ConvertFrom-Json
if ($diagnosticManifest.code_revision -ne $expectedRevision) { throw 'd130_revision_invalid' }
foreach ($field in @('application_manifest_applied','rollout_restarted','object_mutated','finalizer_removed','profile_deleted_or_reset','docker_restarted','workload_started','scientific_fault_started','dataset_inclusion','headroom_decision_inclusion')) {
    if ([bool]$diagnosticManifest.$field) { throw "d130_forbidden_claim_true:$field" }
}

$start = Get-Content -LiteralPath (Join-Path $artifact 'start-process.json') -Raw | ConvertFrom-Json
$stop = Get-Content -LiteralPath (Join-Path $artifact 'stop-capture.json') -Raw | ConvertFrom-Json
$hostAfter = Get-Content -LiteralPath (Join-Path $artifact 'host-after.json') -Raw | ConvertFrom-Json
$profile = Get-Content -LiteralPath (Join-Path $artifact 'final-profile-status-capture.json') -Raw | ConvertFrom-Json
$containerCapture = Get-Content -LiteralPath (Join-Path $artifact 'final-container-inspect-capture.json') -Raw | ConvertFrom-Json
$container = @((ConvertFrom-Json ([string]$containerCapture.stdout)))[0]
$controller = Get-Content -LiteralPath (Join-Path $artifact 'controller-manager-log-capture.json') -Raw | ConvertFrom-Json
if (-not [bool]$start.completed_within_timeout -or [int]$start.exit_code -ne 0) { throw 'd130_start_invalid' }
if ([int]$stop.exit_code -ne 0) { throw 'd130_stop_invalid' }
if (-not [bool]$hostAfter.passed -or [int]$hostAfter.counts.whea_event_17 -ne 0 -or [int]$hostAfter.counts.kernel_power_41 -ne 0 -or [int]$hostAfter.counts.bugcheck -ne 0) { throw 'd130_host_closure_invalid' }
if ([int]$profile.exit_code -ne 7 -or $profile.stdout -notmatch '"Host":"Stopped"' -or $profile.stdout -notmatch '"APIServer":"Stopped"') { throw 'd130_profile_closure_invalid' }
if ($container.State.Status -ne 'exited' -or [bool]$container.State.Running -or [bool]$container.State.OOMKilled -or [int]$container.State.ExitCode -ne 130) { throw 'd130_container_closure_invalid' }
if ([int]$controller.exit_code -ne 1 -or $controller.stderr -notmatch 'must be logged in') { throw 'd130_controller_log_limit_missing' }

$documents = @('research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md','pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md')
foreach ($relative in $documents) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    if ($text -notmatch 'D-130' -or $text -notmatch [regex]::Escape($diagnosticId)) { throw "d130_canonical_closure_missing:$relative" }
}
$reportText = Get-Content -LiteralPath $report -Raw
foreach ($term in @('controller-manager log capture','unique controller','D-067 remains','replacement slot remains','authorizes no retry')) {
    if ($reportText -notlike "*$term*") { throw "d130_report_term_missing:$term" }
}

Write-Output 'd130_lifecycle_diagnostic_closure=passed files=20 classification=stale_lifecycle_state_observed d067=3/6 replacement=null'

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-006'
$artifact = Join-Path $repo "p0-env\artifacts\P2-KUBERNETES-CLEAN-RECONSTRUCTION-006\$id"
$sealHash = 'f92c9e69ffa17079b2dfd7b662beb374bd09a4e9b2d547f4c68419425a363a10'

foreach ($relative in @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-144',$id,'fresh_kubernetes_reconstruction_supported',$sealHash,'3/6')) {
        if ($text -notlike "*$term*") { throw "d144_closure_term_missing:$relative`:$term" }
    }
}

$runner = Get-Content -LiteralPath (
    Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1'
) -Raw
$closedGate = $runner.IndexOf("throw 'closed_reconstruction_id'")
$revisionGate = $runner.IndexOf("throw 'expected_code_revision_mismatch'")
if (-not $runner.Contains("'$id'") -or $closedGate -lt 0 -or $revisionGate -le $closedGate) {
    throw 'd144_closed_identity_gate_invalid'
}
try {
    & (Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1') `
        -ReconstructionId $id -RuntimeStateRoot 'C:\fixture\state' `
        -BackupRoot 'C:\fixture\backup' -ExpectedCodeRevision 'fixture' `
        -ExecutionApproved -DestructiveResetApproved -Confirm:$false
    throw 'd144_closed_identity_rejection_missing'
}
catch {
    if ($_.Exception.Message -eq 'd144_closed_identity_rejection_missing' -or
        $_.Exception.Message -notlike '*closed_reconstruction_id*') { throw }
}

$assessment = Get-Content -LiteralPath (Join-Path $artifact 'assessment.json') -Raw |
    ConvertFrom-Json
$payload = Get-Content -LiteralPath (Join-Path $artifact 'bootstrap-observations.json') -Raw |
    ConvertFrom-Json
$summary = Assert-MonotonicReconstructionTickObservations `
    -Plan $payload.schedule -Observations @($payload.observations)
$assessmentFrequency = ConvertTo-JsonSafeInt64 `
    -Value $assessment.stopwatch_frequency_hz -FieldName 'assessment.stopwatch_frequency_hz'
$assessmentNumerator = ConvertTo-JsonSafeInt64 `
    -Value $assessment.maximum_lateness_numerator -FieldName 'assessment.maximum_lateness_numerator'
$assessmentCompletion = ConvertTo-JsonSafeInt64 `
    -Value $assessment.completed_elapsed_ticks -FieldName 'assessment.completed_elapsed_ticks'
if ($assessment.classification -ne 'fresh_kubernetes_reconstruction_supported' -or
    [int]$assessment.target_count -ne 36 -or [int]$assessment.sample_count -ne 36 -or
    [int]$assessment.stable_sample_count -ne 36 -or
    $assessmentFrequency -ne [long]$summary.stopwatch_frequency_hz -or
    $assessmentNumerator -ne [long]$summary.maximum_lateness_numerator -or
    $assessmentCompletion -ne [long]$summary.completed_elapsed_ticks -or
    [string]$assessment.maximum_lateness_ms_display -ne '55.1275' -or
    [string]$assessment.completed_elapsed_ms_display -ne '175995.8228' -or
    [bool]$assessment.display_values_authoritative -or
    [bool]$assessment.successor_authorized -or [bool]$assessment.dataset_inclusion -or
    [bool]$assessment.headroom_decision_inclusion) {
    throw 'd144_tick_assessment_invalid'
}

& (Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1') `
    -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null

$finalStatus = Get-Content -LiteralPath (
    Join-Path $artifact 'final-profile-status-capture.json'
) -Raw | ConvertFrom-Json
$status = $finalStatus.stdout | ConvertFrom-Json
foreach ($property in @('Host','Kubelet','APIServer','Kubeconfig')) {
    if ([string]$status.$property -ne 'Stopped') { throw "d144_final_profile_not_stopped:$property" }
}
$containerCapture = Get-Content -LiteralPath (
    Join-Path $artifact 'final-container-inspect-capture.json'
) -Raw | ConvertFrom-Json
$container = @($containerCapture.stdout | ConvertFrom-Json)[0]
if ($container.State.Status -ne 'exited' -or [int]$container.State.ExitCode -ne 130 -or
    [bool]$container.State.OOMKilled) { throw 'd144_final_container_state_invalid' }
$hostAfter = Get-Content -LiteralPath (Join-Path $artifact 'host-after.json') -Raw |
    ConvertFrom-Json
if (-not [bool]$hostAfter.passed -or [int]$hostAfter.counts.whea_event_17 -ne 0 -or
    [int]$hostAfter.counts.kernel_power_41 -ne 0 -or [int]$hostAfter.counts.bugcheck -ne 0) {
    throw 'd144_host_closure_invalid'
}
$backup = Get-Content -LiteralPath (Join-Path $artifact 'backup-verification.json') -Raw |
    ConvertFrom-Json
$delete = Get-Content -LiteralPath (Join-Path $artifact 'delete-verification.json') -Raw |
    ConvertFrom-Json
if (-not [bool]$backup.passed -or -not [bool]$delete.passed -or
    [bool]$delete.container_exists -or [bool]$delete.volume_exists) {
    throw 'd144_backup_or_delete_closure_invalid'
}

$manifestPath = Join-Path $artifact 'sha256-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$actualSealHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ([int]$manifest.file_count -ne 22 -or $actualSealHash -ne $sealHash) {
    throw 'd144_seal_identity_mismatch'
}
foreach ($entry in @($manifest.files)) {
    $sealedPath = Join-Path $artifact ([string]$entry.path).Replace('/','\')
    if (-not (Test-Path -LiteralPath $sealedPath -PathType Leaf) -or
        (Get-Item -LiteralPath $sealedPath).Length -ne [long]$entry.bytes -or
        (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne
            [string]$entry.sha256) { throw "d144_sealed_file_mismatch:$($entry.path)" }
}
$payloadCount = @(Get-ChildItem -LiteralPath $artifact -File -Recurse | Where-Object {
    $_.Name -notin @('sha256-manifest.json','offline-verification.txt')
}).Count
if ($payloadCount -ne 22) { throw 'd144_sealed_file_count_mismatch' }

Write-Output (
    'd144_reconstruction_006_closure=passed classification=fresh_kubernetes_reconstruction_supported ' +
    'targets=36 max_lateness_ms=55.1275 completion_ms=175995.8228 seal_files=22 ' +
    'id_consumed=true retry=false restore=false successor=none d067=3/6'
)

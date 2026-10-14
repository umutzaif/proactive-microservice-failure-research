[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-004'
$artifact = Join-Path $repo "p0-env\artifacts\P2-KUBERNETES-CLEAN-RECONSTRUCTION-004\$id"
$sealHash = 'a81c23f18d0478908592c902c488ef73f0f5868cad3439f32e8c69adad2628f6'

foreach ($relative in @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-139',$id,'reconstruction_incomplete','3/6')) {
        if ($text -notlike "*$term*") { throw "d139_closure_term_missing:$relative`:$term" }
    }
}

$assessment = Get-Content -LiteralPath (Join-Path $artifact 'assessment.json') -Raw | ConvertFrom-Json
if ($assessment.classification -ne 'reconstruction_incomplete' -or
    $assessment.failure -notlike '*argument "lateness_ms" is not valid*' -or
    [bool]$assessment.successor_authorized -or [bool]$assessment.dataset_inclusion -or
    [bool]$assessment.headroom_decision_inclusion) {
    throw 'd139_assessment_closure_invalid'
}

$payload = Get-Content -LiteralPath (Join-Path $artifact 'bootstrap-observations.json') -Raw |
    ConvertFrom-Json
$observations = @($payload.observations)
if ($observations.Count -ne 36 -or [int]$payload.schedule.target_count -ne 36) {
    throw 'd139_observation_count_invalid'
}
$actualLateness = @()
for ($index = 0; $index -lt $observations.Count; $index++) {
    $observation = $observations[$index]
    $expectedTarget = [long]($index * 5000)
    if ([int]$observation.target_index -ne $index -or
        [long]$observation.target_elapsed_ms -ne $expectedTarget -or
        [double]$observation.sample_started_elapsed_ms -lt $expectedTarget -or
        [double]$observation.sample_completed_elapsed_ms -lt [double]$observation.sample_started_elapsed_ms -or
        -not [bool]$observation.wait_guard_satisfied -or
        [int]$observation.exit_code -ne 0 -or $observation.host -ne 'Running' -or
        $observation.kubelet -ne 'Running' -or $observation.apiserver -ne 'Running' -or
        $observation.kubeconfig -ne 'Configured') {
        throw "d139_observation_invalid:$index"
    }
    $actualLateness += [double]$observation.sample_started_elapsed_ms - $expectedTarget
}
$maximumActualLateness = [double](($actualLateness | Measure-Object -Maximum).Maximum)
$minimumActualLateness = [double](($actualLateness | Measure-Object -Minimum).Minimum)
if ($minimumActualLateness -lt 0 -or $maximumActualLateness -ge 5000 -or
    [double]$observations[-1].sample_completed_elapsed_ms -gt 210000) {
    throw 'd139_independent_timing_boundary_invalid'
}
$roundedMismatchCount = @($observations | Where-Object {
    $actual = [double]$_.sample_started_elapsed_ms - [double]$_.target_elapsed_ms
    [Math]::Abs([double]$_.lateness_ms - $actual) -gt 0.01
}).Count
if ($roundedMismatchCount -ne 36) { throw 'd139_expected_rounded_lateness_evidence_missing' }

$finalStatus = Get-Content -LiteralPath (Join-Path $artifact 'final-profile-status-capture.json') -Raw |
    ConvertFrom-Json
$statusPayload = $finalStatus.stdout | ConvertFrom-Json
if ($statusPayload.Host -ne 'Stopped' -or $statusPayload.Kubelet -ne 'Stopped' -or
    $statusPayload.APIServer -ne 'Stopped' -or $statusPayload.Kubeconfig -ne 'Stopped') {
    throw 'd139_final_profile_not_stopped'
}
$containerCapture = Get-Content -LiteralPath (Join-Path $artifact 'final-container-inspect-capture.json') -Raw |
    ConvertFrom-Json
$container = @($containerCapture.stdout | ConvertFrom-Json)[0]
if ($container.State.Status -ne 'exited' -or [int]$container.State.ExitCode -ne 130 -or
    [bool]$container.State.OOMKilled) {
    throw 'd139_final_container_state_invalid'
}
$hostAfter = Get-Content -LiteralPath (Join-Path $artifact 'host-after.json') -Raw | ConvertFrom-Json
if (-not [bool]$hostAfter.passed -or [int]$hostAfter.counts.whea_event_17 -ne 0 -or
    [int]$hostAfter.counts.kernel_power_41 -ne 0 -or [int]$hostAfter.counts.bugcheck -ne 0) {
    throw 'd139_host_closure_invalid'
}

$manifestPath = Join-Path $artifact 'sha256-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$actualSealHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ([int]$manifest.file_count -ne 21 -or $actualSealHash -ne $sealHash) {
    throw 'd139_seal_identity_mismatch'
}

& (Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1') `
    -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
foreach ($entry in @($manifest.files)) {
    $sealedPath = Join-Path $artifact ([string]$entry.path).Replace('/','\')
    if (-not (Test-Path -LiteralPath $sealedPath -PathType Leaf) -or
        (Get-Item -LiteralPath $sealedPath).Length -ne [long]$entry.bytes -or
        (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne
            [string]$entry.sha256) {
        throw "d139_sealed_file_mismatch:$($entry.path)"
    }
}
$unsealedPayloadCount = @(Get-ChildItem -LiteralPath $artifact -File -Recurse | Where-Object {
    $_.Name -notin @('sha256-manifest.json','offline-verification.txt')
}).Count
if ($unsealedPayloadCount -ne [int]$manifest.file_count) {
    throw 'd139_sealed_file_count_mismatch'
}

Write-Output ("d139_reconstruction_004_closure=passed classification=reconstruction_incomplete " +
    "id_consumed=true observations=36 min_actual_lateness_ms=$minimumActualLateness " +
    "max_actual_lateness_ms=$maximumActualLateness rounded_lateness_records=36 " +
    "retry=false restore=false successor=none d067=3/6")

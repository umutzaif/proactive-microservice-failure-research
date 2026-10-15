[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-005'
$artifact = Join-Path $repo "p0-env\artifacts\P2-KUBERNETES-CLEAN-RECONSTRUCTION-005\$id"
$sealHash = 'f02c370c2a4582b995c47871ac42f8ce696f05cab6ca15ec1bdd1f794f4abaf7'

foreach ($relative in @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-141',$id,'reconstruction_incomplete',$sealHash,'3/6')) {
        if ($text -notlike "*$term*") { throw "d141_closure_term_missing:$relative`:$term" }
    }
}

$assessment = Get-Content -LiteralPath (Join-Path $artifact 'assessment.json') -Raw |
    ConvertFrom-Json
if ($assessment.classification -ne 'fresh_kubernetes_reconstruction_supported' -or
    [int]$assessment.target_count -ne 36 -or [int]$assessment.sample_count -ne 36 -or
    [int]$assessment.stable_sample_count -ne 36 -or [bool]$assessment.successor_authorized -or
    [bool]$assessment.dataset_inclusion -or [bool]$assessment.headroom_decision_inclusion) {
    throw 'd141_original_assessment_identity_invalid'
}

$payload = Get-Content -LiteralPath (Join-Path $artifact 'bootstrap-observations.json') -Raw |
    ConvertFrom-Json
$observations = @($payload.observations)
if ($observations.Count -ne 36 -or [int]$payload.schedule.target_count -ne 36) {
    throw 'd141_observation_count_invalid'
}

$actualLateness = @()
$mismatches = @()
for ($index = 0; $index -lt $observations.Count; $index++) {
    $observation = $observations[$index]
    $expectedTarget = [long]($index * 5000)
    if ([int]$observation.target_index -ne $index -or
        [long]$observation.target_elapsed_ms -ne $expectedTarget -or
        [double]$observation.sample_started_elapsed_ms -lt $expectedTarget -or
        [double]$observation.sample_completed_elapsed_ms -lt [double]$observation.sample_started_elapsed_ms -or
        $observation.wait_strategy -ne 'guarded_branch_then_ceiling' -or
        -not [bool]$observation.wait_guard_satisfied -or
        [int]$observation.exit_code -ne 0 -or $observation.host -ne 'Running' -or
        $observation.kubelet -ne 'Running' -or $observation.apiserver -ne 'Running' -or
        $observation.kubeconfig -ne 'Configured') {
        throw "d141_observation_invalid:$index"
    }
    $actual = [double]$observation.sample_started_elapsed_ms - $expectedTarget
    $actualLateness += $actual
    $stored = [double]$observation.lateness_ms
    if ($stored -ne $actual) {
        $bitDistance = [Math]::Abs(
            [double]([BitConverter]::DoubleToInt64Bits($stored) -
                [BitConverter]::DoubleToInt64Bits($actual))
        )
        $mismatches += [pscustomobject]@{
            target_index = $index
            target_elapsed_ms = $expectedTarget
            bit_distance = $bitDistance
        }
    }
}

$minimumActualLateness = [double](($actualLateness | Measure-Object -Minimum).Minimum)
$maximumActualLateness = [double](($actualLateness | Measure-Object -Maximum).Maximum)
$completedElapsed = [double]$observations[-1].sample_completed_elapsed_ms
if ($minimumActualLateness -lt 0 -or $maximumActualLateness -ge 5000 -or
    $completedElapsed -gt 210000) {
    throw 'd141_independent_timing_boundary_invalid'
}

$verifier = Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1'
$mismatchIndexes = @($mismatches | ForEach-Object { [int]$_.target_index })
if ($PSVersionTable.PSEdition -eq 'Desktop') {
    if (($mismatchIndexes -join ',') -ne '32,34,35' -or
        @($mismatches | Where-Object { $_.bit_distance -ne 1 }).Count -ne 0) {
        throw 'd141_windows_powershell_expected_one_ulp_mismatches_missing'
    }
    try {
        & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
        throw 'd141_windows_powershell_expected_semantic_rejection_missing'
    }
    catch {
        if ($_.Exception.Message -eq 'd141_windows_powershell_expected_semantic_rejection_missing' -or
            $_.Exception.Message -notlike '*monotonic_schedule_lateness_mismatch*') {
            throw
        }
    }
}
else {
    if ($mismatches.Count -ne 0) { throw 'd141_powershell7_unexpected_lateness_mismatch' }
    & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
}

$finalStatus = Get-Content -LiteralPath (Join-Path $artifact 'final-profile-status-capture.json') -Raw |
    ConvertFrom-Json
$statusPayload = $finalStatus.stdout | ConvertFrom-Json
if ($statusPayload.Host -ne 'Stopped' -or $statusPayload.Kubelet -ne 'Stopped' -or
    $statusPayload.APIServer -ne 'Stopped' -or $statusPayload.Kubeconfig -ne 'Stopped') {
    throw 'd141_final_profile_not_stopped'
}
$containerCapture = Get-Content -LiteralPath (Join-Path $artifact 'final-container-inspect-capture.json') -Raw |
    ConvertFrom-Json
$container = @($containerCapture.stdout | ConvertFrom-Json)[0]
if ($container.State.Status -ne 'exited' -or [int]$container.State.ExitCode -ne 130 -or
    [bool]$container.State.OOMKilled) {
    throw 'd141_final_container_state_invalid'
}
$hostAfter = Get-Content -LiteralPath (Join-Path $artifact 'host-after.json') -Raw | ConvertFrom-Json
if (-not [bool]$hostAfter.passed -or [int]$hostAfter.counts.whea_event_17 -ne 0 -or
    [int]$hostAfter.counts.kernel_power_41 -ne 0 -or [int]$hostAfter.counts.bugcheck -ne 0) {
    throw 'd141_host_closure_invalid'
}
$backup = Get-Content -LiteralPath (Join-Path $artifact 'backup-verification.json') -Raw |
    ConvertFrom-Json
$delete = Get-Content -LiteralPath (Join-Path $artifact 'delete-verification.json') -Raw |
    ConvertFrom-Json
if (-not [bool]$backup.passed -or -not [bool]$delete.passed -or
    [bool]$delete.container_exists -or [bool]$delete.volume_exists) {
    throw 'd141_backup_or_delete_closure_invalid'
}

$manifestPath = Join-Path $artifact 'sha256-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$actualSealHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ([int]$manifest.file_count -ne 22 -or $actualSealHash -ne $sealHash) {
    throw 'd141_seal_identity_mismatch'
}
foreach ($entry in @($manifest.files)) {
    $sealedPath = Join-Path $artifact ([string]$entry.path).Replace('/','\')
    if (-not (Test-Path -LiteralPath $sealedPath -PathType Leaf) -or
        (Get-Item -LiteralPath $sealedPath).Length -ne [long]$entry.bytes -or
        (Get-FileHash -LiteralPath $sealedPath -Algorithm SHA256).Hash.ToLowerInvariant() -ne
            [string]$entry.sha256) {
        throw "d141_sealed_file_mismatch:$($entry.path)"
    }
}
$unsealedPayloadCount = @(Get-ChildItem -LiteralPath $artifact -File -Recurse | Where-Object {
    $_.Name -notin @('sha256-manifest.json','offline-verification.txt')
}).Count
if ($unsealedPayloadCount -ne [int]$manifest.file_count) {
    throw 'd141_sealed_file_count_mismatch'
}

Write-Output ("d141_reconstruction_005_closure=passed classification=reconstruction_incomplete " +
    "sealed_assessment=fresh_kubernetes_reconstruction_supported runtime=$($PSVersionTable.PSEdition) " +
    "mismatch_count=$($mismatches.Count) mismatch_indexes=$($mismatchIndexes -join ',') " +
    "min_actual_lateness_ms=$minimumActualLateness max_actual_lateness_ms=$maximumActualLateness " +
    "completed_elapsed_ms=$completedElapsed id_consumed=true retry=false restore=false " +
    "successor=none d067=3/6")

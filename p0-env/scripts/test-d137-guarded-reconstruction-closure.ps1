[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-003'
$artifact = Join-Path $repo "p0-env\artifacts\P2-KUBERNETES-CLEAN-RECONSTRUCTION-003\$id"

foreach ($relative in @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    foreach ($term in @('D-137',$id,'monotonic_wait_nonpositive_delay_before_target','3/6')) {
        if ($text -notlike "*$term*") { throw "d137_closure_term_missing:$relative`:$term" }
    }
}

$assessment = Get-Content -LiteralPath (Join-Path $artifact 'assessment.json') -Raw | ConvertFrom-Json
if ($assessment.classification -ne 'reconstruction_incomplete' -or
    $assessment.failure -ne 'monotonic_wait_nonpositive_delay_before_target' -or
    [bool]$assessment.successor_authorized -or [bool]$assessment.dataset_inclusion -or
    [bool]$assessment.headroom_decision_inclusion) {
    throw 'd137_assessment_closure_invalid'
}
if (Test-Path -LiteralPath (Join-Path $artifact 'bootstrap-observations.json')) {
    throw 'd137_unexpected_complete_observation_artifact'
}
$manifestPath = Join-Path $artifact 'sha256-manifest.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$manifestHash = (Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant()
if ([int]$manifest.file_count -ne 20 -or
    $manifestHash -ne '37016adf3d435362ea34484666a074c1634811c474fed49030ab91bad6169e1a') {
    throw 'd137_seal_identity_mismatch'
}

& (Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1') `
    -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
& (Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1') `
    -ArtifactRoot $artifact -Mode Verify | Out-Null

Write-Output 'd137_guarded_reconstruction_closure=passed classification=reconstruction_incomplete id_consumed=true observations_complete=false retry=false restore=false successor=none d067=3/6'

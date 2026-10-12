[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$documents = @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)
foreach ($relative in $documents) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    if ($text -notmatch 'D-132' -or $text -notmatch 'current operator|current-user|operator SID') {
        throw "d132_acl_boundary_missing:$relative"
    }
}
$decisionText = Get-Content -LiteralPath (Join-Path $repo 'research_decisions.md') -Raw
$match = [regex]::Match($decisionText,'(?ms)^## D-132\b.*?(?=^## D-|\z)')
if (-not $match.Success) { throw 'd132_decision_missing' }
$decision = $match.Value -replace '\s+',' '
foreach ($term in @(
    'inheritance-protected','Local System','Administrators','fail closed',
    'runtime and profile deletion remain unauthorized','still 3/6'
)) {
    if ($decision -notlike "*$term*") { throw "d132_decision_term_missing:$term" }
}
$runner = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/run-kubernetes-clean-reconstruction.ps1') -Raw
$parentGate = $runner.IndexOf('Assert-KubernetesReconstructionBackupAcl -Path $backupParent')
$artifactBoundary = $runner.IndexOf("New-Item -ItemType Directory -Path `$artifactRoot")
$childCreate = $runner.IndexOf("New-Item -ItemType Directory -Path `$backupFull")
$childProtect = $runner.IndexOf('Set-KubernetesReconstructionBackupAcl -Path $backupFull')
$copy = $runner.IndexOf('Copy-Item -LiteralPath $_.FullName')
if ($parentGate -lt 0 -or $artifactBoundary -le $parentGate -or $childCreate -le $artifactBoundary -or
    $childProtect -le $childCreate -or $copy -le $childProtect) {
    throw 'd132_acl_gate_order_invalid'
}
Write-Output 'd132_reconstruction_backup_acl_preregistration=passed runtime_authorized=false reset_authorized=false d067=3/6'

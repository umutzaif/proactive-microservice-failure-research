[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$id = 'ob-k8s-clean-reconstruction-001'
$documents = @(
    'research_decisions.md','experiment_protocol.md','dataset_card.md','results_registry.md',
    'pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md'
)
foreach ($relative in $documents) {
    $text = Get-Content -LiteralPath (Join-Path $repo $relative) -Raw
    if ($text -notmatch 'D-131' -or $text -notmatch [regex]::Escape($id)) {
        throw "d131_preregistration_missing:$relative"
    }
}
$decisionText = Get-Content -LiteralPath (Join-Path $repo 'research_decisions.md') -Raw
$match = [regex]::Match($decisionText,'(?ms)^## D-131\b.*?(?=^## D-|\z)')
if (-not $match.Success) { throw 'd131_decision_missing' }
$decision = $match.Value -replace '\s+',' '
foreach ($term in @(
    'runtime and profile deletion remain unauthorized','external backup root',
    'exact merged revision','replacement slot remains','3/6',
    'no successor','no application','no workload','no fault'
)) {
    if ($decision -notlike "*$term*") { throw "d131_decision_term_missing:$term" }
}
$registry = Get-Content -LiteralPath (Join-Path $repo 'results_registry.md') -Raw
if ($registry -notmatch ([regex]::Escape($id) + '.*planned operational reconstruction')) {
    throw 'd131_registry_status_invalid'
}
$normalRunner = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/run-network-delay-headroom-normal.ps1') -Raw
if ($normalRunner -match [regex]::Escape($id)) { throw 'd131_identity_leaked_into_normal_runner' }

Write-Output 'd131_clean_reconstruction_preregistration=passed runtime_authorized=false delete_authorized=false successor=none d067=3/6'

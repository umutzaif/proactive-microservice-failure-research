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
    foreach ($term in @('D-133',$id,'reconstruction_incomplete','29','30','3/6')) {
        if ($text -notlike "*$term*") { throw "d133_closure_term_missing:$relative`:$term" }
    }
}

$decisionText = Get-Content -LiteralPath (Join-Path $repo 'research_decisions.md') -Raw
$match = [regex]::Match($decisionText,'(?ms)^## D-133\b.*?(?=^## D-|\z)')
if (-not $match.Success) { throw 'd133_decision_missing' }
$decision = $match.Value -replace '\s+',' '
foreach ($term in @(
    'clean_reconstruction_stability_not_supported','29 healthy samples','at least 30 samples',
    'Do not reinterpret','new identity','No retry','replacement slot remains null'
)) {
    if ($decision -notlike "*$term*") { throw "d133_decision_term_missing:$term" }
}

$registry = Get-Content -LiteralPath (Join-Path $repo 'results_registry.md') -Raw
if ($registry -notmatch ([regex]::Escape($id) + '.*invalid/incomplete operational reconstruction.*29/29')) {
    throw 'd133_registry_closure_invalid'
}
$normalRunner = Get-Content -LiteralPath (Join-Path $repo 'p0-env/scripts/run-network-delay-headroom-normal.ps1') -Raw
if ($normalRunner -match [regex]::Escape($id)) { throw 'd133_identity_leaked_into_normal_runner' }

Write-Output 'd133_clean_reconstruction_closure=passed classification=reconstruction_incomplete samples=29/30 id_consumed=true retry=false restore=false successor=none d067=3/6'

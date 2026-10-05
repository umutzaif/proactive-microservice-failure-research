[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$diagnosticId = 'ob-k8s-lifecycle-state-diagnostic-001'
$requiredDocuments = @(
    'research_decisions.md',
    'experiment_protocol.md',
    'dataset_card.md',
    'results_registry.md',
    'pilot_experiment_plan.md',
    'docs/researcher-datasheets/01-project-architecture.md'
)

foreach ($relative in $requiredDocuments) {
    $path = Join-Path $repo $relative
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "missing_required_document:$relative"
    }
    $text = Get-Content -LiteralPath $path -Raw
    if ($text -notmatch [regex]::Escape($diagnosticId)) {
        throw "diagnostic_id_missing:$relative"
    }
}

$decisionText = Get-Content -LiteralPath (Join-Path $repo 'research_decisions.md') -Raw
$decisionMatch = [regex]::Match(
    $decisionText,
    '(?ms)^## D-129\b.*?(?=^## D-|\z)'
)
if (-not $decisionMatch.Success) { throw 'd129_section_missing' }
$decision = $decisionMatch.Value

$requiredDecisionTerms = @(
    'runtime remains unauthorized',
    'effective replacement slot remains null',
    '3/6',
    'no runtime',
    'no pod/deployment/ReplicaSet patch or delete',
    'no finalizer removal',
    'no profile reset/delete/clean',
    'stale_lifecycle_state_observed',
    'lifecycle_state_not_reproduced',
    'diagnostic_incomplete'
)
foreach ($term in $requiredDecisionTerms) {
    if ($decision -notlike "*$term*") { throw "d129_term_missing:$term" }
}

if ($decision -match 'runtime_authorized\s*[:=]\s*true') {
    throw 'd129_runtime_authority_leak'
}

$normalRunner = Get-Content -LiteralPath (
    Join-Path $repo 'p0-env/scripts/run-network-delay-headroom-normal.ps1'
) -Raw
if ($normalRunner -match [regex]::Escape($diagnosticId)) {
    throw 'd129_diagnostic_must_not_enter_normal_runner'
}

foreach ($relative in @(
    'p0-env/scripts/lifecycle-state-diagnostic-contract.ps1',
    'p0-env/scripts/run-kubernetes-lifecycle-state-diagnostic.ps1',
    'p0-env/scripts/verify-kubernetes-lifecycle-state-diagnostic.ps1',
    'p0-env/scripts/test-kubernetes-lifecycle-state-diagnostic.ps1'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $repo $relative) -PathType Leaf)) {
        throw "d129_tooling_missing:$relative"
    }
}

$registry = Get-Content -LiteralPath (Join-Path $repo 'results_registry.md') -Raw
if ($registry -notmatch (
    [regex]::Escape($diagnosticId) + '.*prepared operational diagnostic'
)) {
    throw 'd129_registry_status_invalid'
}

Write-Output (
    'd129_lifecycle_diagnostic_preregistration=passed ' +
    'runtime_authorized=false successor=none replacement=null d067=3/6'
)

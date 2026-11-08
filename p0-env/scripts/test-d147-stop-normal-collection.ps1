$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$inputsPath = Join-Path $repo 'p0-env\config\analysis\network-delay-headroom-decision-inputs-v1.json'
$inputs = Get-Content -LiteralPath $inputsPath -Raw | ConvertFrom-Json

if ($inputs.profile_status -ne 'collection_stopped_incomplete_headroom_unavailable') {
    throw 'd147_profile_status_invalid'
}
if (@($inputs.decision_ids | Where-Object { $_ -eq 'D-147' }).Count -ne 1) {
    throw 'd147_decision_binding_invalid'
}
if ($inputs.collection_sequence.next_slot_status -ne 'collection_stopped_incomplete_no_replacement' -or
    $null -ne $inputs.collection_sequence.effective_collection_run_ids[3]) {
    throw 'd147_terminal_slot_contract_invalid'
}
if (@($inputs.collection_sequence.invalid_run_ids | Where-Object { $_ -eq 'ob-netdelay-500m-normal-10u-013' }).Count -ne 1) {
    throw 'd147_closed_013_missing'
}
if ([int]$inputs.current_eligibility_snapshot.eligible_500m_normal_run_count_10u -ne 1 -or
    [int]$inputs.current_eligibility_snapshot.eligible_500m_normal_run_count_15u -ne 2 -or
    $inputs.current_eligibility_snapshot.headroom_calculation_status -ne 'unavailable_collection_stopped_at_3_of_6') {
    throw 'd147_incomplete_count_contract_invalid'
}
if ([bool]$inputs.execution_authorized -or [bool]$inputs.fault_or_normal_run_started_by_this_profile) {
    throw 'd147_runtime_authority_changed'
}

$runner = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1') -Raw
$closedLine = @($runner -split "`r?`n" | Where-Object { $_ -match 'closed_run_id' })[0]
if ($closedLine -notmatch '10u-013') { throw 'd147_closed_013_guard_missing' }

$canonicalBindings = @(
    @{path='research_decisions.md'; token='## D-147'},
    @{path='experiment_protocol.md'; token='# D-147'},
    @{path='dataset_card.md'; token='### D-147'},
    @{path='pilot_experiment_plan.md'; token='### D-147'},
    @{path='docs/researcher-datasheets/01-project-architecture.md'; token='### D-147'},
    @{path='results_registry.md'; token='D-147 / P2-NETWORK-DELAY-HEADROOM-001 collection stop'}
)
foreach ($binding in $canonicalBindings) {
    $content = Get-Content -LiteralPath (Join-Path $repo $binding.path) -Raw
    if (-not $content.Contains($binding.token)) {
        throw "d147_canonical_binding_missing:$($binding.path)"
    }
    if ($content -match 'ob-netdelay-500m-normal-10u-014') {
        throw "d147_successor_014_forbidden:$($binding.path)"
    }
}

if ((Get-Content -LiteralPath $inputsPath -Raw) -match 'ob-netdelay-500m-normal-10u-014') {
    throw 'd147_successor_014_forbidden:decision_inputs'
}

Write-Output 'd147_stop_normal_collection=passed counts=3/6 replacement=null headroom=unavailable runtime=none'

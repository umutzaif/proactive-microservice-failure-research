$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$runId = 'ob-netdelay-500m-normal-10u-013'
$artifact = Join-Path $repo "p0-env\artifacts\P2-NETWORK-DELAY-HEADROOM-001\$runId"
$sealHash = 'db1b3ea0df0cde85ad0b7389ab2fc34536d3b68239319cd5629f5abe972d9098'

foreach ($name in @(
    'deployment-bundle-provenance.json',
    'environment-note.json',
    'ethernet-preflight.json',
    'failure-closure.json',
    'host-before.json',
    'host-network-before.json',
    'rollback-error.json',
    'run-error.json',
    'sha256-manifest.json',
    'offline-verification.txt'
)) {
    if (-not (Test-Path -LiteralPath (Join-Path $artifact $name) -PathType Leaf)) {
        throw "d146_closure_evidence_missing:$name"
    }
}

$manifest = Get-Content -LiteralPath (Join-Path $artifact 'sha256-manifest.json') -Raw | ConvertFrom-Json
$actualSealHash = (Get-FileHash -LiteralPath (Join-Path $artifact 'sha256-manifest.json') -Algorithm SHA256).Hash.ToLowerInvariant()
if ([int]$manifest.file_count -ne 8 -or $actualSealHash -ne $sealHash) { throw 'd146_seal_contract_failed' }
& (Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1') -ArtifactRoot $artifact -Mode Verify | Out-Null

$runError = Get-Content -LiteralPath (Join-Path $artifact 'run-error.json') -Raw | ConvertFrom-Json
if ($runError.run_id -ne $runId -or $runError.error -ne 'step_failed:deploy_base' -or [bool]$runError.scientific_fault_started) {
    throw 'd146_run_error_contract_failed'
}
$rollback = Get-Content -LiteralPath (Join-Path $artifact 'rollback-error.json') -Raw | ConvertFrom-Json
if ($rollback.error -ne 'rollback_rollout_failed') { throw 'd146_rollback_error_contract_failed' }
$closure = Get-Content -LiteralPath (Join-Path $artifact 'failure-closure.json') -Raw | ConvertFrom-Json
if (-not [bool]$closure.passed -or [int]$closure.stop_exit_code -ne 0 -or
    $closure.profile_status.Host -ne 'Stopped' -or $closure.profile_status.Kubelet -ne 'Stopped' -or
    $closure.profile_status.APIServer -ne 'Stopped' -or [bool]$closure.container_state.Running -or
    [bool]$closure.container_state.OOMKilled -or [int]$closure.container_state.ExitCode -ne 130 -or
    [int]$closure.host.counts.whea_event_17 -ne 0 -or [int]$closure.host.counts.kernel_power_41 -ne 0 -or
    [int]$closure.host.counts.bugcheck -ne 0 -or $closure.network.transport -ne 'usb_tether_wifi') {
    throw 'd146_failure_closure_contract_failed'
}
$environment = Get-Content -LiteralPath (Join-Path $artifact 'environment-note.json') -Raw | ConvertFrom-Json
if ($environment.decision_id -ne 'D-145' -or $environment.launch_mode -ne 'manual_single_run_no_retry' -or
    -not [bool]$environment.run_failed -or $environment.phone_upstream_declaration -ne 'wifi_only_cellular_disabled' -or
    [string]::IsNullOrWhiteSpace([string]$environment.background_load_note)) {
    throw 'd146_environment_contract_failed'
}
$preflight = Get-Content -LiteralPath (Join-Path $artifact 'ethernet-preflight.json') -Raw | ConvertFrom-Json
if (-not [bool]$preflight.passed -or $preflight.decision_id -ne 'D-145' -or
    $preflight.source_revision -ne '5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb' -or
    -not [bool]$preflight.source_clean -or -not [bool]$preflight.usb_bus_verified -or
    -not [bool]$preflight.wireless_disabled_or_absent -or -not [bool]$preflight.ethernet_disabled_or_absent) {
    throw 'd146_preflight_contract_failed'
}
$bundle = Get-Content -LiteralPath (Join-Path $artifact 'deployment-bundle-provenance.json') -Raw | ConvertFrom-Json
if (-not [bool]$bundle.passed -or [bool]$bundle.source_root_reparse_point -or
    [bool]$bundle.relative_checkout_source_reference_used -or [int]$bundle.base_render_line_count -ne 1407 -or
    [int]$bundle.overlay_render_line_count -ne 1452) {
    throw 'd146_bundle_contract_failed'
}

foreach ($relative in @(
    "p0-env/artifacts/scientific-run-metadata/$runId",
    "p0-env/artifacts/telemetry/$runId",
    "p0-env/artifacts/runs/$runId",
    "p0-env/artifacts/derived/$runId",
    "p0-env/artifacts/finalized/$runId"
)) {
    if (Test-Path -LiteralPath (Join-Path $repo $relative)) { throw "d146_unexpected_output_root:$relative" }
}

$inputs = Get-Content -LiteralPath (Join-Path $repo 'p0-env/config/analysis/network-delay-headroom-decision-inputs-v1.json') -Raw | ConvertFrom-Json
if ($inputs.collection_sequence.next_slot_status -ne 'replacement_required_not_preregistered' -or
    $null -ne $inputs.collection_sequence.effective_collection_run_ids[3] -or
    @($inputs.collection_sequence.invalid_run_ids | Where-Object { $_ -eq $runId }).Count -ne 1 -or
    [int]$inputs.current_eligibility_snapshot.eligible_500m_normal_run_count_10u -ne 1 -or
    [int]$inputs.current_eligibility_snapshot.eligible_500m_normal_run_count_15u -ne 2 -or
    @($inputs.decision_ids | Where-Object { $_ -eq 'D-146' }).Count -ne 1 -or
    [bool]$inputs.execution_authorized) {
    throw 'd146_decision_input_contract_failed'
}

$runner = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1') -Raw
$closedLine = @($runner -split "`r?`n" | Where-Object { $_ -match "closed_run_id" })[0]
if ($closedLine -notmatch '10u-013') { throw 'd146_runner_closed_id_missing' }
& (Join-Path $PSScriptRoot 'verify-static-run-id-config.ps1') -ExpectedRunId $runId | Out-Null

foreach ($binding in @(
    @{path='research_decisions.md';token='## D-146'},
    @{path='experiment_protocol.md';token='# D-146'},
    @{path='dataset_card.md';token='### D-146'},
    @{path='pilot_experiment_plan.md';token='### D-146'},
    @{path='docs/researcher-datasheets/01-project-architecture.md';token='### D-146'},
    @{path='results_registry.md';token=$sealHash}
)) {
    $content = Get-Content -LiteralPath (Join-Path $repo $binding.path) -Raw
    if (-not $content.Contains($binding.token)) { throw "d146_canonical_binding_missing:$($binding.path)" }
}

Write-Output "d146_normal_013_closure=passed payloads=8 seal=$sealHash status=invalid_incomplete slot=null runtime=none"

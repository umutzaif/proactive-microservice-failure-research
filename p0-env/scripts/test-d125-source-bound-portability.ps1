$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$runnerPath = Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
$runner = Get-Content -LiteralPath $runnerPath -Raw
$preflight = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'ethernet-normal-preflight.ps1') -Raw
$deploy = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'deploy.ps1') -Raw
$helper = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'source-bound-normal-deployment-bundle.ps1') -Raw
$finalizer = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'finalize-run-artifacts.ps1') -Raw
$receiptVerifier = Get-Content -LiteralPath (Join-Path $PSScriptRoot 'verify-finalized-run.ps1') -Raw

foreach ($required in @(
    'OnlineBoutiqueSourceRoot',
    'explicit_online_boutique_source_root_required',
    'source-bound-normal-deployment-bundle.ps1',
    'New-NetworkDelayNormalDeploymentBundle',
    'Assert-NetworkDelayNormalDeploymentBundle',
    'Remove-NetworkDelayNormalDeploymentBundle',
    'deployment-bundle-provenance.json',
    'deployment_bundle_provenance_path',
    'deployment_bundle_provenance_sha256',
    'kustomize_version',
    '$deploymentBundle.base_config',
    '$deploymentBundle.overlay_config',
    'relative_checkout_source_reference_used',
    '$infrastructureStarted -and -not $stopped',
    '$runFailed -and $infrastructureStarted'
)) {
    if (-not $runner.Contains($required)) { throw "d125_portability_runner_missing:$required" }
}

$closedGate = $runner.IndexOf("throw 'closed_run_id'")
$sourceGate = $runner.IndexOf("throw 'explicit_online_boutique_source_root_required'")
$bundleCreate = $runner.IndexOf('$deploymentBundle = New-NetworkDelayNormalDeploymentBundle')
$artifactCreate = $runner.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')
$infrastructureStart = $runner.IndexOf('$infrastructureStarted = $true')
$deployBase = $runner.IndexOf("InvokeScript 'deploy_base'")
if ($closedGate -lt 0 -or $sourceGate -le $closedGate -or $bundleCreate -le $sourceGate -or $artifactCreate -le $bundleCreate -or $infrastructureStart -le $artifactCreate -or $deployBase -le $infrastructureStart) {
    throw 'd125_portability_gate_order_invalid'
}

foreach ($required in @('OnlineBoutiqueSourceRoot','absolute_online_boutique_source_root_required','online_boutique_source_reparse_point_forbidden','$sourceItem.FullName')) {
    if (-not $preflight.Contains($required)) { throw "d125_preflight_source_contract_missing:$required" }
}
foreach ($required in @('param([string]$ConfigPath)','absolute_config_path_required','kustomization_missing')) {
    if (-not $deploy.Contains($required)) { throw "d125_deploy_config_contract_missing:$required" }
}
foreach ($required in @('online_boutique_source_reparse_point_forbidden','base_overlay_source_reference_contract_mismatch','deployment_bundle_content_mismatch','deployment_bundle_cleanup_path_escape','network-delay-normal-deploy-','upstream-base','../upstream-base')) {
    if (-not $helper.Contains($required)) { throw "d125_bundle_helper_contract_missing:$required" }
}
foreach ($required in @('deployment_bundle_provenance_path','deployment-bundle-provenance.json','deployment_bundle_provenance')) {
    if (-not $finalizer.Contains($required)) { throw "d125_finalizer_provenance_contract_missing:$required" }
}
foreach ($required in @('deployment_bundle_provenance_receipt_missing','deployment_bundle_provenance_metadata_receipt_mismatch','deployment_bundle_provenance')) {
    if (-not $receiptVerifier.Contains($required)) { throw "d125_receipt_verifier_provenance_contract_missing:$required" }
}

$decisionInputs = Get-Content -LiteralPath (Join-Path $PSScriptRoot '..\config\analysis\network-delay-headroom-decision-inputs-v1.json') -Raw | ConvertFrom-Json
if (@($decisionInputs.decision_ids | Where-Object { $_ -eq 'D-126' }).Count -ne 1) { throw 'd126_decision_missing' }
if (@($decisionInputs.collection_sequence.invalid_run_ids | Where-Object { $_ -eq 'ob-netdelay-500m-normal-10u-011' }).Count -ne 1) { throw 'd125_closed_011_missing' }
if ($decisionInputs.execution_authorized -or $decisionInputs.fault_or_normal_run_started_by_this_profile) { throw 'd125_runtime_authority_changed' }

Write-Output 'd125_source_bound_portability_contract=passed closed_011=true runtime=none'

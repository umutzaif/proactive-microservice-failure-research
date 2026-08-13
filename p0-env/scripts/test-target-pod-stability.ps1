[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$state = Join-Path $root 'p0-env\state\tests\target-pod-stability'
New-Item -ItemType Directory -Path $state -Force | Out-Null

function Pod([int]$Restart, [string]$ContainerId = 'containerd://stable', [bool]$IncludeContainer = $true) {
    $spec = if ($IncludeContainer) { @([ordered]@{name='server'}) } else { @([ordered]@{name='other'}) }
    $statuses = if ($IncludeContainer) {
        @([ordered]@{name='server';ready=$true;restartCount=$Restart;containerID=$ContainerId})
    } else {
        @([ordered]@{name='other';ready=$true;restartCount=0;containerID='containerd://other'})
    }
    [ordered]@{items=@([ordered]@{
        metadata=[ordered]@{name='recommendationservice-test';uid='uid-stable'}
        spec=[ordered]@{containers=$spec}
        status=[ordered]@{conditions=@([ordered]@{type='Ready';status='True'});containerStatuses=$statuses}
    })}
}
function Fixture([string]$Name, [object[]]$Snapshots) {
    $path = Join-Path $state "$Name.json"
    [IO.File]::WriteAllText($path, ([ordered]@{snapshots=$Snapshots}|ConvertTo-Json -Depth 20), (New-Object Text.UTF8Encoding($false)))
    $path
}
function ExpectFailure([string]$FixturePath, [string]$Pattern, [string]$EvidenceName) {
    $old = $ErrorActionPreference; $ErrorActionPreference = 'Continue'
    try {
        $out = @(& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-target-pod-stability.ps1') -Namespace online-boutique -Deployment recommendationservice -Container server -EvidencePath (Join-Path $state $EvidenceName) -FixtureSnapshotsPath $FixturePath 2>&1)
    } finally { $ErrorActionPreference = $old }
    if ($LASTEXITCODE -eq 0 -or ($out -join "`n") -notmatch $Pattern) { throw "expected_failure_missing:$Pattern" }
}

$positive = Fixture 'positive' @((Pod 3),(Pod 3),(Pod 3))
$positiveEvidence = Join-Path $state 'positive-evidence.json'
Remove-Item -LiteralPath $positiveEvidence -Force -ErrorAction SilentlyContinue
& powershell -NoProfile -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'verify-target-pod-stability.ps1') -Namespace online-boutique -Deployment recommendationservice -Container server -EvidencePath $positiveEvidence -FixtureSnapshotsPath $positive
if ($LASTEXITCODE -ne 0) { throw 'positive_stability_fixture_failed' }
Write-Output 'target_pod_stability_positive=passed'

ExpectFailure (Fixture 'restart-change' @((Pod 3),(Pod 4))) 'identity_or_restart_changed' 'restart-evidence.json'
Write-Output 'target_pod_stability_restart_negative=passed'
ExpectFailure (Fixture 'missing-container' @((Pod 3),(Pod 3 'containerd://stable' $false))) 'target_container_missing' 'missing-evidence.json'
Write-Output 'target_pod_stability_missing_container_negative=passed'
$runnerSource = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'run-low-cpu-calibration.ps1')
$injectorSource = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'invoke-cpu-stress.ps1')
$metadataVerifierSource = Get-Content -Raw -LiteralPath (Join-Path $PSScriptRoot 'verify-scientific-fault-run-metadata.ps1')
foreach ($required in @('target_pod_stability','verify-target-pod-stability.ps1','StabilityEvidencePath')) {
    if ($runnerSource -notmatch [regex]::Escape($required)) { throw "runner_d038_wiring_missing:$required" }
}
foreach ($required in @('d038_target_stability_evidence_required','d038_target_changed_after_stability_window','target_stability_evidence_sha256')) {
    if ($injectorSource -notmatch [regex]::Escape($required)) { throw "injector_d038_wiring_missing:$required" }
}
if ($metadataVerifierSource -notmatch 'target_stability_window_mismatch') { throw 'metadata_verifier_d038_wiring_missing' }
Write-Output 'target_pod_stability_end_to_end_wiring=passed'
$global:LASTEXITCODE = 0

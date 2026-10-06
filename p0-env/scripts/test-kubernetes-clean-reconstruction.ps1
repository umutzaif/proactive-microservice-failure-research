[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$runnerPath = Join-Path $PSScriptRoot 'run-kubernetes-clean-reconstruction.ps1'
$backupVerifier = Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction-backup.ps1'
$semanticVerifier = Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1'
$runner = Get-Content -LiteralPath $runnerPath -Raw
[void][scriptblock]::Create($runner)

foreach ($term in @(
    'explicit_clean_reconstruction_execution_approval_required',
    'explicit_profile_delete_approval_required','expected_code_revision_mismatch',
    'working_tree_not_clean','immutable_reconstruction_output_exists',
    'backup_root_must_be_external','immutable_backup_root_exists',
    'profile_component_not_stopped','insufficient_backup_free_space',
    'd130_predecessor_manifest_hash_mismatch','state_snapshot_files=$stateEntries',
    'profile_volume_archive_unreadable',
    'verify-kubernetes-clean-reconstruction-backup.ps1','backup_semantic_verification_failed',
    "Capture `$minikube @('delete','--profile',`$Profile)",
    '--kubernetes-version=v1.34.0','--cpus=4','--memory=6144mb','--disk-size=32g',
    '--container-runtime=containerd','duration_seconds=180','poll_seconds=5',
    'application_manifest_applied=$false','workload_started=$false',
    'scientific_fault_started=$false','successor_authorized=$false',
    'backup_contains_sensitive_runtime_credentials=$true',
    'backup_must_remain_outside_repository=$true',
    'Measure-HostEventsAfterRecordIdBoundary','seal-diagnostic-artifacts.ps1'
)) {
    if (-not $runner.Contains($term)) { throw "clean_reconstruction_runner_term_missing:$term" }
}
$backupVerifyIndex = $runner.IndexOf('backup_semantic_verification_failed')
$deleteIndex = $runner.IndexOf("Capture `$minikube @('delete','--profile',`$Profile)")
if ($backupVerifyIndex -lt 0 -or $deleteIndex -le $backupVerifyIndex) {
    throw 'clean_reconstruction_backup_gate_order_invalid'
}
foreach ($forbidden in @('apply -k','rollout restart','toxic add','run-loadgenerator')) {
    if ($runner.Contains($forbidden)) { throw "clean_reconstruction_forbidden_path:$forbidden" }
}

function Expect-RunnerFailure([hashtable]$Parameters, [string]$Expected) {
    try {
        & $runnerPath @Parameters -Confirm:$false
        throw "expected_runner_failure_missing:$Expected"
    }
    catch {
        if ($_.Exception.Message -notlike "*$Expected*") { throw }
    }
}
$baseParameters = @{
    RuntimeStateRoot='C:\fixture\state';BackupRoot='C:\fixture\backup'
    ExpectedCodeRevision='fixture-revision'
}
Expect-RunnerFailure $baseParameters 'explicit_clean_reconstruction_execution_approval_required'
$executionOnly = $baseParameters.Clone(); $executionOnly.ExecutionApproved = $true
Expect-RunnerFailure $executionOnly 'explicit_profile_delete_approval_required'
$wrongIdentity = $executionOnly.Clone(); $wrongIdentity.DestructiveResetApproved = $true
$wrongIdentity.ReconstructionId = 'wrong-id'
Expect-RunnerFailure $wrongIdentity 'unexpected_reconstruction_id'

$temp = Join-Path ([IO.Path]::GetTempPath()) ('d131-fixture-' + [guid]::NewGuid().ToString('N'))
$artifact = Join-Path $temp 'ob-k8s-clean-reconstruction-001'
$backup = Join-Path $temp 'external-backup'
$state = Join-Path $backup 'runtime-state\.minikube\profiles\p0-online-boutique'
New-Item -ItemType Directory -Path $artifact,$state -Force | Out-Null
try {
    [IO.File]::WriteAllText((Join-Path $state 'config.json'),'{}',[Text.UTF8Encoding]::new($false))
    [IO.File]::WriteAllText((Join-Path $backup 'profile-volume.tgz'),'fixture-volume',[Text.UTF8Encoding]::new($false))
    $stateRoot = Join-Path $backup 'runtime-state'
    $stateFiles = @(Get-ChildItem -LiteralPath $stateRoot -Recurse -Force -File)
    $archive = Join-Path $backup 'profile-volume.tgz'
    $backupManifest = [ordered]@{
        reconstruction_id='ob-k8s-clean-reconstruction-001';backup_root=$backup
        state_snapshot_file_count=$stateFiles.Count
        state_snapshot_bytes=[long](($stateFiles|Measure-Object Length -Sum).Sum)
        state_snapshot_files=@($stateFiles | ForEach-Object {
            [ordered]@{
                path=$_.FullName.Substring($stateRoot.Length + 1).Replace('\','/')
                bytes=$_.Length
                sha256=(Get-FileHash $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
        })
        volume_archive_bytes=(Get-Item $archive).Length
        volume_archive_sha256=(Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        source_container_id='fixture-container';source_volume_name='p0-online-boutique'
    }
    $backupManifest | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $artifact 'backup-manifest.json') -Encoding utf8
    [ordered]@{exit_code=0;stdout='./`n./var/`n';stderr=''} | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $artifact 'volume-backup-list-capture.json') -Encoding utf8
    & $backupVerifier -ArtifactRoot $artifact -BackupRoot $backup | Out-Null

    $reconstructionManifest = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-001'
        reconstruction_id='ob-k8s-clean-reconstruction-001';preregistration_decision='D-131'
        predecessor_decision='D-130';predecessor_manifest_sha256='85118c5235cfb3f14d4b52fa90bc17f068c3e258be259ff496e286fa911b0db7'
        runtime_state_root='C:\fixture\state';backup_root=$backup
        backup_contains_sensitive_runtime_credentials=$true
        backup_must_remain_outside_repository=$true
        application_manifest_applied=$false;workload_started=$false;toxic_created=$false
        scientific_fault_started=$false;scientific_window_started=$false
        dataset_inclusion=$false;headroom_decision_inclusion=$false;successor_authorized=$false
    }
    $assessment = [ordered]@{
        classification='fresh_kubernetes_reconstruction_supported';sample_count=30;stable_sample_count=30
        causal_conclusion=$false;repair_cause_proven=$false;successor_authorized=$false
        dataset_inclusion=$false;headroom_decision_inclusion=$false
    }
    $observations = 1..30 | ForEach-Object { [ordered]@{exit_code=0;host='Running';kubelet='Running';apiserver='Running';kubeconfig='Configured'} }
    $documents = [ordered]@{
        'reconstruction-manifest.json'=$reconstructionManifest
        'assessment.json'=$assessment
        'host-after.json'=[ordered]@{passed=$true;counts=[ordered]@{whea_event_17=0;kernel_power_41=0;bugcheck=0}}
        'final-profile-status-capture.json'=[ordered]@{exit_code=7;stdout='{"Host":"Stopped","Kubelet":"Stopped","APIServer":"Stopped","Kubeconfig":"Stopped"}'}
        'backup-verification.json'=[ordered]@{passed=$true}
        'delete-verification.json'=[ordered]@{passed=$true;container_exists=$false;volume_exists=$false}
        'bootstrap-observations.json'=[ordered]@{duration_seconds=180;poll_seconds=5;observations=$observations}
    }
    foreach ($entry in $documents.GetEnumerator()) {
        $entry.Value | ConvertTo-Json -Depth 20 | Set-Content -LiteralPath (Join-Path $artifact $entry.Key) -Encoding utf8
    }
    & $semanticVerifier -ArtifactRoot $artifact | Out-Null

    $assessment.successor_authorized = $true
    $assessment | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $artifact 'assessment.json') -Encoding utf8
    try { & $semanticVerifier -ArtifactRoot $artifact | Out-Null; throw 'expected_authority_negative_missing' }
    catch { if ($_.Exception.Message -eq 'expected_authority_negative_missing') { throw } }
    $assessment.successor_authorized = $false
    $assessment | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $artifact 'assessment.json') -Encoding utf8

    $delete = $documents['delete-verification.json']; $delete.volume_exists = $true
    $delete | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $artifact 'delete-verification.json') -Encoding utf8
    try { & $semanticVerifier -ArtifactRoot $artifact | Out-Null; throw 'expected_delete_negative_missing' }
    catch { if ($_.Exception.Message -eq 'expected_delete_negative_missing') { throw } }
    $delete.volume_exists = $false
    $delete | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $artifact 'delete-verification.json') -Encoding utf8

    [IO.File]::AppendAllText($archive,'tamper',[Text.UTF8Encoding]::new($false))
    try { & $backupVerifier -ArtifactRoot $artifact -BackupRoot $backup | Out-Null; throw 'expected_backup_tamper_negative_missing' }
    catch { if ($_.Exception.Message -eq 'expected_backup_tamper_negative_missing') { throw } }
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}

Write-Output 'kubernetes_clean_reconstruction_tests=passed parser=1 positive=2 negative=6 gate_order=passed runtime=none'

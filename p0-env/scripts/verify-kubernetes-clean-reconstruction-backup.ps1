[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArtifactRoot,
    [Parameter(Mandatory)][string]$BackupRoot,
    [string]$ExpectedReconstructionId = 'ob-k8s-clean-reconstruction-001'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$artifact = (Resolve-Path -LiteralPath $ArtifactRoot).Path
$backup = (Resolve-Path -LiteralPath $BackupRoot).Path
$manifest = Get-Content -LiteralPath (Join-Path $artifact 'backup-manifest.json') -Raw | ConvertFrom-Json
if ($manifest.reconstruction_id -ne $ExpectedReconstructionId) { throw 'backup_reconstruction_id_mismatch' }
if ([IO.Path]::GetFullPath([string]$manifest.backup_root) -ne $backup) { throw 'backup_root_mismatch' }

$stateSnapshot = Join-Path $backup 'runtime-state'
$profileConfig = Join-Path $stateSnapshot '.minikube\profiles\p0-online-boutique\config.json'
$volumeArchive = Join-Path $backup 'profile-volume.tgz'
foreach ($path in @($stateSnapshot, $profileConfig, $volumeArchive)) {
    if (-not (Test-Path -LiteralPath $path)) { throw "backup_component_missing:$path" }
}

$stateFiles = @(Get-ChildItem -LiteralPath $stateSnapshot -Recurse -Force -File)
$stateBytes = [long](($stateFiles | Measure-Object Length -Sum).Sum)
if ($stateFiles.Count -ne [int]$manifest.state_snapshot_file_count -or
    $stateBytes -ne [long]$manifest.state_snapshot_bytes) { throw 'state_snapshot_size_mismatch' }
$expectedStateFiles = @($manifest.state_snapshot_files)
if ($expectedStateFiles.Count -ne $stateFiles.Count) { throw 'state_snapshot_manifest_count_mismatch' }
foreach ($entry in $expectedStateFiles) {
    $path = Join-Path $stateSnapshot ([string]$entry.path).Replace('/','\')
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "state_snapshot_file_missing:$($entry.path)" }
    if ((Get-Item -LiteralPath $path).Length -ne [long]$entry.bytes) { throw "state_snapshot_file_size_mismatch:$($entry.path)" }
    $hash = (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($hash -ne [string]$entry.sha256) { throw "state_snapshot_file_hash_mismatch:$($entry.path)" }
}
if ((Get-Item -LiteralPath $volumeArchive).Length -ne [long]$manifest.volume_archive_bytes) {
    throw 'volume_archive_size_mismatch'
}
$archiveHash = (Get-FileHash -LiteralPath $volumeArchive -Algorithm SHA256).Hash.ToLowerInvariant()
if ($archiveHash -ne [string]$manifest.volume_archive_sha256) { throw 'volume_archive_hash_mismatch' }
if ([string]::IsNullOrWhiteSpace([string]$manifest.source_container_id) -or
    [string]::IsNullOrWhiteSpace([string]$manifest.source_volume_name)) {
    throw 'backup_source_identity_missing'
}
$archiveListCapture = Get-Content -LiteralPath (
    Join-Path $artifact 'volume-backup-list-capture.json'
) -Raw | ConvertFrom-Json
if ([int]$archiveListCapture.exit_code -ne 0 -or
    [string]::IsNullOrWhiteSpace([string]$archiveListCapture.stdout)) {
    throw 'volume_archive_readability_not_verified'
}

Write-Output (
    "clean_reconstruction_backup_verification=passed id=$ExpectedReconstructionId " +
    "state_files=$($stateFiles.Count) volume_sha256=$archiveHash"
)

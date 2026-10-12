[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param([Parameter(Mandatory)][string]$BackupParent)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'kubernetes-reconstruction-backup-acl.ps1')

if (-not [IO.Path]::IsPathRooted($BackupParent)) { throw 'backup_parent_must_be_absolute' }
$full = [IO.Path]::GetFullPath($BackupParent).TrimEnd('\')
if ([string]::IsNullOrWhiteSpace((Split-Path -Parent $full))) { throw 'backup_parent_must_not_be_drive_root' }

if (Test-Path -LiteralPath $full) {
    Assert-KubernetesReconstructionBackupAcl -Path $full | Out-Null
    Write-Output "kubernetes_reconstruction_backup_parent=verified path=$full"
    return
}
$ancestor = Split-Path -Parent $full
if (-not (Test-Path -LiteralPath $ancestor -PathType Container)) {
    throw 'backup_parent_ancestor_missing'
}
if (-not $PSCmdlet.ShouldProcess($full, 'create empty access-restricted reconstruction backup parent')) {
    return
}
New-Item -ItemType Directory -Path $full | Out-Null
try {
    Set-KubernetesReconstructionBackupAcl -Path $full | Out-Null
}
catch {
    throw "backup_parent_acl_initialization_failed:$($_.Exception.Message)"
}
Write-Output "kubernetes_reconstruction_backup_parent=initialized path=$full"

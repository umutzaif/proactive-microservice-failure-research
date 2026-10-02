[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$RuntimeStateRoot,
    [Parameter(Mandatory)][string]$RepairBackupRoot,
    [string]$Profile = 'p0-online-boutique',
    [string]$AuthorizedKeysFixturePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-PublicKeyMaterial([string]$Line) {
    $parts = @($Line.Trim() -split '\s+')
    if ($parts.Count -lt 2) { throw 'ssh_public_key_parse_failed' }
    "$($parts[0]) $($parts[1])"
}

function Get-PublicKeyFingerprint([string]$Path) {
    $output = @(& ssh-keygen -lf $Path 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "ssh_public_key_fingerprint_failed:$Path" }
    $match = [regex]::Match(($output -join ' '), 'SHA256:[A-Za-z0-9+/]+')
    if (-not $match.Success) { throw "ssh_public_key_fingerprint_parse_failed:$Path" }
    $match.Value
}

function Assert-KeyPair([string]$PrivatePath, [string]$PublicPath, [string]$Label, [string]$ScratchRoot) {
    foreach ($path in @($PrivatePath, $PublicPath)) {
        if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { throw "$Label`_key_missing:$path" }
    }
    $publicMaterial = Get-PublicKeyMaterial (Get-Content -LiteralPath $PublicPath -Raw)
    $validationPrivatePath = Join-Path $ScratchRoot "$Label-id_rsa"
    Copy-Item -LiteralPath $PrivatePath -Destination $validationPrivatePath
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $acl = [Security.AccessControl.FileSecurity]::new()
    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetOwner($identity.User)
    $acl.AddAccessRule([Security.AccessControl.FileSystemAccessRule]::new($identity.User, [Security.AccessControl.FileSystemRights]::FullControl, [Security.AccessControl.AccessControlType]::Allow))
    Set-Acl -LiteralPath $validationPrivatePath -AclObject $acl
    $derived = @(& ssh-keygen -y -f $validationPrivatePath 2>&1)
    if ($LASTEXITCODE -ne 0) { throw "$Label`_private_key_derivation_failed" }
    if ((Get-PublicKeyMaterial ($derived -join '')) -ne $publicMaterial) { throw "$Label`_private_public_key_mismatch" }
    [pscustomobject]@{
        material = $publicMaterial
        public_sha256 = (Get-FileHash -LiteralPath $PublicPath -Algorithm SHA256).Hash.ToLowerInvariant()
        public_fingerprint = Get-PublicKeyFingerprint $PublicPath
    }
}

$resolvedStateRoot = (Resolve-Path -LiteralPath $RuntimeStateRoot -ErrorAction Stop).Path
$machineRoot = [IO.Path]::GetFullPath((Join-Path $resolvedStateRoot ".minikube\machines\$Profile"))
if (-not (Test-Path -LiteralPath $machineRoot -PathType Container)) { throw 'profile_machine_root_missing' }
$resolvedBackupRoot = (Resolve-Path -LiteralPath $RepairBackupRoot -ErrorAction Stop).Path
if (-not $resolvedBackupRoot.StartsWith(($machineRoot + [IO.Path]::DirectorySeparatorChar), [StringComparison]::OrdinalIgnoreCase)) { throw 'repair_backup_outside_machine_root' }
if ((Split-Path -Leaf $resolvedBackupRoot) -notlike 'codex-key-backup-*') { throw 'repair_backup_name_invalid' }

$tempBase = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
$temporaryRoot = Join-Path $tempBase ('minikube-ssh-provenance-' + [guid]::NewGuid().ToString('N'))
$resolvedTemporaryRoot = [IO.Path]::GetFullPath($temporaryRoot)
if (-not $resolvedTemporaryRoot.StartsWith($tempBase, [StringComparison]::OrdinalIgnoreCase)) { throw 'temporary_path_escape' }
New-Item -ItemType Directory -Path $resolvedTemporaryRoot | Out-Null
try {
    $installed = Assert-KeyPair (Join-Path $machineRoot 'id_rsa') (Join-Path $machineRoot 'id_rsa.pub') 'installed' $resolvedTemporaryRoot
    $backup = Assert-KeyPair (Join-Path $resolvedBackupRoot 'id_rsa') (Join-Path $resolvedBackupRoot 'id_rsa.pub') 'backup' $resolvedTemporaryRoot
    if ($AuthorizedKeysFixturePath) {
        $authorizedKeysPath = (Resolve-Path -LiteralPath $AuthorizedKeysFixturePath -ErrorAction Stop).Path
        $containerState = 'fixture'
    }
    else {
        $containerState = (& docker inspect $Profile --format '{{.State.Status}}' 2>&1).Trim()
        if ($LASTEXITCODE -ne 0) { throw 'profile_container_inspect_failed' }
        if ($containerState -ne 'exited') { throw "profile_container_not_stopped:$containerState" }
        $authorizedKeysPath = Join-Path $resolvedTemporaryRoot 'authorized_keys'
        & docker cp "${Profile}:/home/docker/.ssh/authorized_keys" $authorizedKeysPath 2>&1 | Out-Null
        if ($LASTEXITCODE -ne 0) { throw 'container_authorized_keys_read_failed' }
    }

    $authorizedLines = @(Get-Content -LiteralPath $authorizedKeysPath | Where-Object { $_ -and -not $_.TrimStart().StartsWith('#') })
    if ($authorizedLines.Count -eq 0) { throw 'container_authorized_keys_empty' }
    $authorizedMaterials = @($authorizedLines | ForEach-Object { Get-PublicKeyMaterial $_ })
    $authorizedFingerprintOutput = @(& ssh-keygen -lf $authorizedKeysPath 2>&1)
    if ($LASTEXITCODE -ne 0) { throw 'container_authorized_keys_fingerprint_failed' }
    $authorizedFingerprints = @([regex]::Matches(($authorizedFingerprintOutput -join ' '), 'SHA256:[A-Za-z0-9+/]+') | ForEach-Object { $_.Value })

    [pscustomobject]@{
        schema_version = 1
        runtime_state_root = $resolvedStateRoot
        machine_root = $machineRoot
        repair_backup_root = $resolvedBackupRoot
        installed_public_sha256 = $installed.public_sha256
        installed_public_fingerprint = $installed.public_fingerprint
        installed_private_public_match = $true
        backup_public_sha256 = $backup.public_sha256
        backup_public_fingerprint = $backup.public_fingerprint
        backup_private_public_match = $true
        authorized_key_count = $authorizedMaterials.Count
        container_authorized_key_fingerprints = $authorizedFingerprints
        container_contains_installed_public = ($installed.material -in $authorizedMaterials)
        container_contains_backup_public = ($backup.material -in $authorizedMaterials)
        container_state = $containerState
        key_material_disclosed = $false
        passed = ($installed.material -in $authorizedMaterials)
    }
}
finally {
    if ($temporaryRoot -and (Test-Path -LiteralPath $temporaryRoot)) {
        Remove-Item -LiteralPath $temporaryRoot -Recurse -Force -WhatIf:$false -Confirm:$false
    }
}

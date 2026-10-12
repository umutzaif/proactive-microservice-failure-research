[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'kubernetes-reconstruction-backup-acl.ps1')
$initializer = Join-Path $PSScriptRoot 'initialize-kubernetes-reconstruction-backup-parent.ps1'
[void][scriptblock]::Create((Get-Content -LiteralPath $initializer -Raw))

function Expect-AclFailure([scriptblock]$Action, [string]$Expected) {
    try {
        & $Action
        throw "expected_acl_failure_missing:$Expected"
    }
    catch {
        if ($_.Exception.Message -notlike "*$Expected*") { throw }
    }
}

$temp = Join-Path ([IO.Path]::GetTempPath()) ('d132-acl-fixture-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $temp | Out-Null
try {
    $secure = Join-Path $temp 'secure'
    New-Item -ItemType Directory -Path $secure | Out-Null
    Set-KubernetesReconstructionBackupAcl -Path $secure | Out-Null
    $summary = Assert-KubernetesReconstructionBackupAcl -Path $secure
    if (-not $summary.inheritance_protected -or $summary.access_rule_count -ne 3) {
        throw 'secure_acl_positive_fixture_failed'
    }

    $inherited = Join-Path $temp 'inherited'
    New-Item -ItemType Directory -Path $inherited | Out-Null
    Expect-AclFailure { Assert-KubernetesReconstructionBackupAcl -Path $inherited | Out-Null } 'backup_acl_inheritance_not_protected'

    $extra = Join-Path $temp 'extra-principal'
    New-Item -ItemType Directory -Path $extra | Out-Null
    $principals = Get-KubernetesReconstructionBackupAclPrincipals
    $acl = [Security.AccessControl.DirectorySecurity]::new()
    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetOwner($principals.CurrentUser)
    foreach ($sid in $principals.Values) {
        $expectedRule = [Security.AccessControl.FileSystemAccessRule]::new(
            $sid,[Security.AccessControl.FileSystemRights]::FullControl,
            ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [Security.AccessControl.InheritanceFlags]::ObjectInherit),
            [Security.AccessControl.PropagationFlags]::None,[Security.AccessControl.AccessControlType]::Allow
        )
        [void]$acl.AddAccessRule($expectedRule)
    }
    $users = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-545')
    $rule = [Security.AccessControl.FileSystemAccessRule]::new(
        $users,[Security.AccessControl.FileSystemRights]::ReadAndExecute,
        [Security.AccessControl.AccessControlType]::Allow
    )
    [void]$acl.AddAccessRule($rule)
    Set-Acl -LiteralPath $extra -AclObject $acl
    Expect-AclFailure { Assert-KubernetesReconstructionBackupAcl -Path $extra | Out-Null } 'backup_acl_rule_count_mismatch'

    $unsafeExisting = Join-Path $temp 'unsafe-existing'
    New-Item -ItemType Directory -Path $unsafeExisting | Out-Null
    Expect-AclFailure { & $initializer -BackupParent $unsafeExisting -Confirm:$false } 'backup_acl_inheritance_not_protected'

    $initialized = Join-Path $temp 'initialized'
    & $initializer -BackupParent $initialized -Confirm:$false | Out-Null
    Assert-KubernetesReconstructionBackupAcl -Path $initialized | Out-Null
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}

Write-Output 'kubernetes_reconstruction_backup_acl_tests=passed positive=2 negative=3 principals=current-user,SYSTEM,Administrators'

Set-StrictMode -Version Latest

function Get-KubernetesReconstructionBackupAclPrincipals {
    $current = [Security.Principal.WindowsIdentity]::GetCurrent().User
    if ($null -eq $current) { throw 'backup_acl_current_user_sid_missing' }
    [ordered]@{
        CurrentUser = $current
        System = [Security.Principal.SecurityIdentifier]::new('S-1-5-18')
        Administrators = [Security.Principal.SecurityIdentifier]::new('S-1-5-32-544')
    }
}

function Set-KubernetesReconstructionBackupAcl {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw 'backup_acl_path_not_directory'
    }
    $principals = Get-KubernetesReconstructionBackupAclPrincipals
    $acl = [Security.AccessControl.DirectorySecurity]::new()
    $acl.SetAccessRuleProtection($true, $false)
    $acl.SetOwner($principals.CurrentUser)
    foreach ($sid in $principals.Values) {
        $rule = [Security.AccessControl.FileSystemAccessRule]::new(
            $sid,
            [Security.AccessControl.FileSystemRights]::FullControl,
            ([Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
                [Security.AccessControl.InheritanceFlags]::ObjectInherit),
            [Security.AccessControl.PropagationFlags]::None,
            [Security.AccessControl.AccessControlType]::Allow
        )
        [void]$acl.AddAccessRule($rule)
    }
    Set-Acl -LiteralPath $resolved -AclObject $acl
    Assert-KubernetesReconstructionBackupAcl -Path $resolved
}

function Assert-KubernetesReconstructionBackupAcl {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path)

    $resolved = (Resolve-Path -LiteralPath $Path -ErrorAction Stop).Path
    if (-not (Test-Path -LiteralPath $resolved -PathType Container)) {
        throw 'backup_acl_path_not_directory'
    }
    $principals = Get-KubernetesReconstructionBackupAclPrincipals
    $expected = @{}
    foreach ($sid in $principals.Values) { $expected[$sid.Value] = $true }
    $acl = Get-Acl -LiteralPath $resolved
    if (-not $acl.AreAccessRulesProtected) { throw 'backup_acl_inheritance_not_protected' }
    if ($acl.Owner -ne $principals.CurrentUser.Value -and
        $acl.Owner -ne $principals.CurrentUser.Translate([Security.Principal.NTAccount]).Value) {
        throw 'backup_acl_owner_mismatch'
    }
    $rules = @($acl.GetAccessRules($true, $true, [Security.Principal.SecurityIdentifier]))
    if ($rules.Count -ne $expected.Count) { throw 'backup_acl_rule_count_mismatch' }
    $seen = @{}
    foreach ($rule in $rules) {
        $sid = $rule.IdentityReference.Value
        if (-not $expected.ContainsKey($sid)) { throw "backup_acl_unexpected_principal:$sid" }
        if ($rule.IsInherited) { throw "backup_acl_inherited_rule_present:$sid" }
        if ($rule.AccessControlType -ne [Security.AccessControl.AccessControlType]::Allow) {
            throw "backup_acl_non_allow_rule_present:$sid"
        }
        if (($rule.FileSystemRights -band [Security.AccessControl.FileSystemRights]::FullControl) -ne
            [Security.AccessControl.FileSystemRights]::FullControl) {
            throw "backup_acl_full_control_missing:$sid"
        }
        $requiredInheritance = [Security.AccessControl.InheritanceFlags]::ContainerInherit -bor
            [Security.AccessControl.InheritanceFlags]::ObjectInherit
        if (($rule.InheritanceFlags -band $requiredInheritance) -ne $requiredInheritance -or
            $rule.PropagationFlags -ne [Security.AccessControl.PropagationFlags]::None) {
            throw "backup_acl_inheritance_contract_mismatch:$sid"
        }
        $seen[$sid] = $true
    }
    foreach ($sid in $expected.Keys) {
        if (-not $seen.ContainsKey($sid)) { throw "backup_acl_required_principal_missing:$sid" }
    }
    [pscustomobject]@{
        path = $resolved
        inheritance_protected = $true
        owner_sid = $principals.CurrentUser.Value
        allowed_principal_sids = @($expected.Keys | Sort-Object)
        access_rule_count = $rules.Count
    }
}

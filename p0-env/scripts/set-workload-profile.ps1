[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$CurrentProfileRelative,
    [Parameter(Mandatory = $true)][string]$NewProfileRelative
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$configPath = Join-Path $repo 'p0-env\config\online-boutique\kustomization.yaml'

function Read-Profile([string]$Relative) {
    $full = [IO.Path]::GetFullPath((Join-Path $repo ($Relative.Replace('/', '\'))))
    if (-not $full.StartsWith($repo, [StringComparison]::OrdinalIgnoreCase)) { throw 'workload_profile_path_escape' }
    if (-not (Test-Path -LiteralPath $full -PathType Leaf)) { throw "workload_profile_missing:$Relative" }
    $value = Get-Content -LiteralPath $full -Raw | ConvertFrom-Json
    if ([int]$value.schema_version -ne 1) { throw 'workload_profile_schema_invalid' }
    if ([int]$value.loadgenerator.users -lt 1 -or [int]$value.loadgenerator.users -gt 100) { throw 'workload_users_invalid' }
    if ([int]$value.loadgenerator.spawn_rate_per_second -lt 1) { throw 'workload_rate_invalid' }
    if ([int]$value.loadgenerator.random_seed -ne 1) { throw 'workload_seed_must_remain_one' }
    return $value
}

$current = Read-Profile $CurrentProfileRelative
$next = Read-Profile $NewProfileRelative
$text = [IO.File]::ReadAllText($configPath)

$replacements = @(
    [pscustomobject]@{pattern='(path: /spec/template/spec/containers/0/env/1/value\r?\n\s+value:) "' + [regex]::Escape([string]$current.loadgenerator.users) + '"'; replacement='$1 "' + [string]$next.loadgenerator.users + '"'},
    [pscustomobject]@{pattern='(path: /spec/template/spec/containers/0/env/2/value\r?\n\s+value:) "' + [regex]::Escape([string]$current.loadgenerator.spawn_rate_per_second) + '"'; replacement='$1 "' + [string]$next.loadgenerator.spawn_rate_per_second + '"'},
    [pscustomobject]@{pattern='(name: WORKLOAD_PROFILE_ID\r?\n\s+value:) "' + [regex]::Escape([string]$current.profile_id) + '"'; replacement='$1 "' + [string]$next.profile_id + '"'}
)

foreach ($pair in $replacements) {
    $matches = [regex]::Matches($text, $pair.pattern).Count
    if ($matches -ne 1) { throw "workload_binding_expected_once:$($pair.pattern):actual=$matches" }
    $text = [regex]::Replace($text, $pair.pattern, $pair.replacement, 1)
}

[IO.File]::WriteAllText($configPath, $text, (New-Object Text.UTF8Encoding($false)))
Write-Output "workload_profile_id=$($next.profile_id)"
Write-Output "workload_users=$($next.loadgenerator.users)"
Write-Output "workload_spawn_rate=$($next.loadgenerator.spawn_rate_per_second)"
Write-Output 'workload_profile_binding=passed'

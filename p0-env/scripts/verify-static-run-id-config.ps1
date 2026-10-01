[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$ExpectedRunId,

    [string]$ConfigRoot = (Join-Path $PSScriptRoot '..\config\online-boutique')
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedRoot = (Resolve-Path -LiteralPath $ConfigRoot -ErrorAction Stop).Path
$targets = [ordered]@{
    'kustomization.yaml' = 3
    'observability.yaml' = 4
}
$identityPattern = 'ob-netdelay-500m-normal-[0-9]+u-[0-9]{3}'

foreach ($entry in $targets.GetEnumerator()) {
    $path = Join-Path $resolvedRoot $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "static_run_id_config_missing:$($entry.Key)"
    }
    $content = [IO.File]::ReadAllText($path)
    $expectedCount = [regex]::Matches(
        $content,
        [regex]::Escape($ExpectedRunId)
    ).Count
    if ($expectedCount -ne [int]$entry.Value) {
        throw "static_run_id_count_mismatch:$($entry.Key):expected=$($entry.Value):actual=$expectedCount"
    }
    $identities = @(
        [regex]::Matches($content, $identityPattern) |
            ForEach-Object { $_.Value } |
            Sort-Object -Unique
    )
    if ($identities.Count -ne 1 -or $identities[0] -ne $ExpectedRunId) {
        throw "static_run_id_foreign_identity:$($entry.Key)"
    }
}

Write-Output "static_run_id_config=passed expected=$ExpectedRunId files=2 occurrences=7"

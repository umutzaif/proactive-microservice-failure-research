[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$CurrentRunId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$NewRunId
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

if ($CurrentRunId -eq $NewRunId) {
    throw 'CurrentRunId and NewRunId must be different.'
}

function Write-Utf8NoBom {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Content
    )

    [System.IO.File]::WriteAllText(
        $Path,
        $Content,
        (New-Object System.Text.UTF8Encoding($false))
    )
}

$configRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\config\online-boutique')
)
$artifactRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\artifacts')
)

$targets = @(
    [ordered]@{
        path = Join-Path $configRoot 'kustomization.yaml'
        expected_current_count = 3
    },
    [ordered]@{
        path = Join-Path $configRoot 'observability.yaml'
        expected_current_count = 2
    }
)

$existingRunPath = Join-Path $artifactRoot "runs\$NewRunId"
$existingDerivedPath = Join-Path $artifactRoot "derived\$NewRunId"

if (Test-Path -LiteralPath $existingRunPath) {
    throw "NewRunId already has a raw archive: $existingRunPath"
}

if (Test-Path -LiteralPath $existingDerivedPath) {
    throw "NewRunId already has derived output: $existingDerivedPath"
}

$originalContents = @{}
$updatedContents = @{}

foreach ($target in $targets) {
    $path = [string]$target.path

    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        throw "Configuration file is missing: $path"
    }

    $content = [System.IO.File]::ReadAllText($path)
    $currentCount = [regex]::Matches(
        $content,
        [regex]::Escape($CurrentRunId)
    ).Count
    $newCount = [regex]::Matches(
        $content,
        [regex]::Escape($NewRunId)
    ).Count

    if ($currentCount -ne [int]$target.expected_current_count) {
        throw (
            "Expected {0} occurrences of CurrentRunId in {1}; found {2}." -f
            $target.expected_current_count,
            $path,
            $currentCount
        )
    }

    if ($newCount -ne 0) {
        throw "NewRunId already appears in configuration: $path"
    }

    $originalContents[$path] = $content
    $updatedContents[$path] = $content.Replace(
        $CurrentRunId,
        $NewRunId
    )
}

try {
    foreach ($target in $targets) {
        $path = [string]$target.path
        Write-Utf8NoBom -Path $path -Content $updatedContents[$path]
    }

    foreach ($target in $targets) {
        $path = [string]$target.path
        $writtenContent = [System.IO.File]::ReadAllText($path)
        $oldCount = [regex]::Matches(
            $writtenContent,
            [regex]::Escape($CurrentRunId)
        ).Count
        $newCount = [regex]::Matches(
            $writtenContent,
            [regex]::Escape($NewRunId)
        ).Count

        if ($oldCount -ne 0) {
            throw "CurrentRunId remains after update: $path"
        }

        if ($newCount -ne [int]$target.expected_current_count) {
            throw (
                "Expected {0} occurrences of NewRunId in {1}; found {2}." -f
                $target.expected_current_count,
                $path,
                $newCount
            )
        }
    }
}
catch {
    $originalError = $_

    foreach ($target in $targets) {
        $path = [string]$target.path

        if ($originalContents.ContainsKey($path)) {
            Write-Utf8NoBom `
                -Path $path `
                -Content $originalContents[$path]
        }
    }

    throw $originalError
}

Write-Output "previous_run_id=$CurrentRunId"
Write-Output "new_run_id=$NewRunId"

foreach ($target in $targets) {
    $path = [string]$target.path
    $relativePath = $path.
        Substring(
            [System.IO.Path]::GetFullPath(
                (Join-Path $PSScriptRoot '..\..')
            ).Length + 1
        ).
        Replace('\', '/')
    $hash = (
        Get-FileHash -LiteralPath $path -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    Write-Output "updated_file=$relativePath"
    Write-Output "sha256=$hash"
}

Write-Output 'run_id_update=passed'
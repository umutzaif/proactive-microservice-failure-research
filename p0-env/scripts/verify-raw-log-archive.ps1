[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedArchive = (Resolve-Path -LiteralPath $ArchivePath).Path
$manifestPath = Join-Path $resolvedArchive 'sha256-manifest.json'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "SHA-256 manifest is missing: $manifestPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw |
    ConvertFrom-Json

if ($manifest.algorithm -ne 'SHA-256') {
    throw "Unsupported checksum algorithm: $($manifest.algorithm)"
}

$failures = New-Object System.Collections.Generic.List[string]
$verifiedCount = 0

foreach ($entry in $manifest.files) {
    $relativePath = [string]$entry.path

    if ([System.IO.Path]::IsPathRooted($relativePath)) {
        $failures.Add("absolute_path_not_allowed:$relativePath")
        continue
    }

    $candidatePath = [System.IO.Path]::GetFullPath(
        (Join-Path $resolvedArchive $relativePath)
    )
    $archivePrefix = $resolvedArchive.TrimEnd('\') + '\'

    if (-not $candidatePath.StartsWith(
        $archivePrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        $failures.Add("path_escape_not_allowed:$relativePath")
        continue
    }

    if (-not (Test-Path -LiteralPath $candidatePath -PathType Leaf)) {
        $failures.Add("missing:$relativePath")
        continue
    }

    $actualHash = (
        Get-FileHash -LiteralPath $candidatePath -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    $expectedHash = ([string]$entry.sha256).ToLowerInvariant()

    if ($actualHash -ne $expectedHash) {
        $failures.Add("checksum_mismatch:$relativePath")
        continue
    }

    $verifiedCount++
}

$allFiles = @(
    Get-ChildItem -LiteralPath $resolvedArchive -File -Recurse
)
$manifestRelativePaths = @(
    $manifest.files |
        ForEach-Object { ([string]$_.path).Replace('\', '/') }
)

$duplicateManifestPaths = @(
    $manifestRelativePaths |
        Group-Object |
        Where-Object { $_.Count -gt 1 }
)

foreach ($duplicate in $duplicateManifestPaths) {
    $failures.Add("duplicate_manifest_path:$($duplicate.Name)")
}

foreach ($actualFile in $allFiles) {
    if ($actualFile.FullName -eq $manifestPath) {
        continue
    }

    $actualRelativePath = $actualFile.FullName.
        Substring($resolvedArchive.Length + 1).
        Replace('\', '/')

    if ($manifestRelativePaths -notcontains $actualRelativePath) {
        $failures.Add("unexpected_unmanifested_file:$actualRelativePath")
    }
}
$readOnlyFiles = @(
    $allFiles | Where-Object { $_.IsReadOnly }
)
$rawLogFiles = @(
    Get-ChildItem `
        -LiteralPath (Join-Path $resolvedArchive 'raw\logs') `
        -File `
        -ErrorAction SilentlyContinue
)
if ($rawLogFiles.Count -eq 0) {
    $failures.Add('raw_log_files_missing')
}
if ($readOnlyFiles.Count -ne $allFiles.Count) {
    $failures.Add(
        "readonly_mismatch:expected=$($allFiles.Count),actual=$($readOnlyFiles.Count)"
    )
}

Write-Output "archive_path=$resolvedArchive"
Write-Output "run_id=$($manifest.run_id)"
Write-Output "manifest_file_count=$($manifest.files.Count)"
Write-Output "verified_file_count=$verifiedCount"
Write-Output "raw_log_file_count=$($rawLogFiles.Count)"
Write-Output "readonly_file_count=$($readOnlyFiles.Count)"
Write-Output "failure_count=$($failures.Count)"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "failure=$_" }
    throw 'Archive verification failed.'
}

Write-Output 'archive_verification=passed'
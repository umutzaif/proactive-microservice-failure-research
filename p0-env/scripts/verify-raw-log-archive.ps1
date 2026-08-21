[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedArchive = (Resolve-Path -LiteralPath $ArchivePath).Path
$manifestPath = Join-Path $resolvedArchive 'sha256-manifest.json'
$metadataPath = Join-Path $resolvedArchive 'metadata.json'

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "SHA-256 manifest is missing: $manifestPath"
}

if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    throw "Archive metadata is missing: $metadataPath"
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw |
    ConvertFrom-Json
$metadataRaw = Get-Content -LiteralPath $metadataPath -Raw
$metadata = $metadataRaw | ConvertFrom-Json

function Get-CanonicalUtcJsonString {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Json,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName,

        [Parameter(Mandatory = $true)]
        [bool]$Required
    )

    $escapedName = [System.Text.RegularExpressions.Regex]::Escape($PropertyName)
    $pattern = '"' + $escapedName + '"\s*:\s*"(?<value>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?Z)"'
    $matches = [System.Text.RegularExpressions.Regex]::Matches(
        $Json,
        $pattern,
        [System.Text.RegularExpressions.RegexOptions]::CultureInvariant
    )

    if ($matches.Count -eq 0 -and -not $Required) {
        return $null
    }

    if ($matches.Count -ne 1) {
        throw "canonical_utc_property_count_invalid:${PropertyName}:$($matches.Count)"
    }

    return [string]$matches[0].Groups['value'].Value
}

if ($manifest.algorithm -ne 'SHA-256') {
    throw "Unsupported checksum algorithm: $($manifest.algorithm)"
}

$failures = New-Object System.Collections.Generic.List[string]
$verifiedCount = 0
$timestampParseFailureCount = [int64]0
$timestampBeforeStartCount = [int64]0
$timestampAfterEndCount = [int64]0

if ([string]$metadata.run_id -ne [string]$manifest.run_id) {
    $failures.Add('metadata_manifest_run_id_mismatch')
}

try {
    $sinceUtcText = Get-CanonicalUtcJsonString `
        -Json $metadataRaw `
        -PropertyName 'since_utc' `
        -Required $true
    $sinceUtcValue = [datetimeoffset]::Parse(
        $sinceUtcText,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal
    ).ToUniversalTime()
}
catch {
    $failures.Add('metadata_since_utc_invalid')
    $sinceUtcValue = [datetimeoffset]::MinValue
}

$untilUtcValue = $null

if (
    $metadata.PSObject.Properties.Name -contains 'until_utc' -and
    -not [string]::IsNullOrWhiteSpace((Get-CanonicalUtcJsonString `
        -Json $metadataRaw `
        -PropertyName 'until_utc' `
        -Required $false))
) {
    try {
        $untilUtcText = Get-CanonicalUtcJsonString `
            -Json $metadataRaw `
            -PropertyName 'until_utc' `
            -Required $true
        $untilUtcValue = [datetimeoffset]::Parse(
            $untilUtcText,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AssumeUniversal
        ).ToUniversalTime()
    }
    catch {
        $failures.Add('metadata_until_utc_invalid')
    }

    if ($null -ne $untilUtcValue -and $untilUtcValue -le $sinceUtcValue) {
        $failures.Add('metadata_time_order_invalid')
    }
}

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

foreach ($rawLogFile in $rawLogFiles) {
    $reader = New-Object System.IO.StreamReader(
        $rawLogFile.FullName,
        [System.Text.Encoding]::UTF8,
        $true
    )

    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            if ($line -notmatch '^(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?Z)(?:\s|$)') {
                $timestampParseFailureCount++
                continue
            }

            try {
                $lineTimestamp = [datetimeoffset]::Parse(
                    [string]$Matches.timestamp,
                    [System.Globalization.CultureInfo]::InvariantCulture,
                    (
                        [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                        [System.Globalization.DateTimeStyles]::AdjustToUniversal
                    )
                )
            }
            catch {
                $timestampParseFailureCount++
                continue
            }

            if (
                $null -ne $untilUtcValue -and
                $lineTimestamp -lt $sinceUtcValue
            ) {
                $timestampBeforeStartCount++
            }

            if (
                $null -ne $untilUtcValue -and
                $lineTimestamp -gt $untilUtcValue
            ) {
                $timestampAfterEndCount++
            }
        }
    }
    finally {
        $reader.Dispose()
    }
}

if ($timestampParseFailureCount -gt 0) {
    $failures.Add("timestamp_parse_failure_count:$timestampParseFailureCount")
}

if ($timestampBeforeStartCount -gt 0) {
    $failures.Add("timestamp_before_start_count:$timestampBeforeStartCount")
}

if ($timestampAfterEndCount -gt 0) {
    $failures.Add("timestamp_after_end_count:$timestampAfterEndCount")
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
Write-Output "timestamp_parse_failure_count=$timestampParseFailureCount"
Write-Output "timestamp_before_start_count=$timestampBeforeStartCount"
Write-Output "timestamp_after_end_count=$timestampAfterEndCount"
Write-Output "failure_count=$($failures.Count)"

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Output "failure=$_" }
    throw 'Archive verification failed.'
}

Write-Output 'archive_verification=passed'

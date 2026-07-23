[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$DerivedPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedDerived = (Resolve-Path -LiteralPath $DerivedPath).Path
$metadataPath = Join-Path $resolvedDerived 'metadata.json'
$manifestPath = Join-Path $resolvedDerived 'sha256-manifest.json'
$parsedLogDirectory = Join-Path $resolvedDerived 'parsed\logs'

if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    throw "Derived metadata is missing: $metadataPath"
}

if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Derived manifest is missing: $manifestPath"
}

if (-not (Test-Path -LiteralPath $parsedLogDirectory -PathType Container)) {
    throw "Parsed log directory is missing: $parsedLogDirectory"
}

$metadata = Get-Content -LiteralPath $metadataPath -Raw |
    ConvertFrom-Json
$manifest = Get-Content -LiteralPath $manifestPath -Raw |
    ConvertFrom-Json

$runId = [string]$metadata.run_id
$failures = New-Object System.Collections.Generic.List[string]
$verifiedManifestFileCount = 0
$verifiedRecordCount = [int64]0
$timestampMissingCount = [int64]0
$jsonFailureCount = [int64]0
$runIdMismatchCount = [int64]0
$sequenceFailureCount = [int64]0

if ([string]::IsNullOrWhiteSpace($runId)) {
    $failures.Add('metadata_run_id_missing')
}

if ([string]$manifest.run_id -ne $runId) {
    $failures.Add('manifest_run_id_mismatch')
}

if ([string]$manifest.transform_version -ne [string]$metadata.transform_version) {
    $failures.Add('transform_version_mismatch')
}

$derivedPrefix = $resolvedDerived.TrimEnd('\') + '\'
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

foreach ($entry in $manifest.files) {
    $relativePath = ([string]$entry.path).Replace('\', '/')

    if ([System.IO.Path]::IsPathRooted($relativePath)) {
        $failures.Add("absolute_path_not_allowed:$relativePath")
        continue
    }

    $candidatePath = [System.IO.Path]::GetFullPath(
        (Join-Path $resolvedDerived $relativePath)
    )

    if (-not $candidatePath.StartsWith(
        $derivedPrefix,
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

    $verifiedManifestFileCount++
}

$allFiles = @(
    Get-ChildItem -LiteralPath $resolvedDerived -File -Recurse
)
$readOnlyFiles = @(
    $allFiles | Where-Object { $_.IsReadOnly }
)

foreach ($actualFile in $allFiles) {
    if ($actualFile.FullName -eq $manifestPath) {
        continue
    }

    $relativePath = $actualFile.FullName.
        Substring($resolvedDerived.Length + 1).
        Replace('\', '/')

    if ($manifestRelativePaths -notcontains $relativePath) {
        $failures.Add("unexpected_unmanifested_file:$relativePath")
    }
}

if ($readOnlyFiles.Count -ne $allFiles.Count) {
    $failures.Add(
        "readonly_mismatch:expected=$($allFiles.Count),actual=$($readOnlyFiles.Count)"
    )
}

$sourceManifestPath = Join-Path `
    ([string]$metadata.source_archive) `
    'sha256-manifest.json'

if (Test-Path -LiteralPath $sourceManifestPath -PathType Leaf) {
    $actualSourceManifestHash = (
        Get-FileHash `
            -LiteralPath $sourceManifestPath `
            -Algorithm SHA256
    ).Hash.ToLowerInvariant()

    if ($actualSourceManifestHash -ne ([string]$metadata.source_manifest_sha256).ToLowerInvariant()) {
        $failures.Add('source_manifest_checksum_mismatch')
    }
}
else {
    $failures.Add('source_manifest_unavailable')
}

$outputSummariesByPath = @{}

foreach ($summary in $metadata.output_files) {
    $outputRelativePath = ([string]$summary.output_file).Replace('\', '/')

    if ($outputSummariesByPath.ContainsKey($outputRelativePath)) {
        $failures.Add("duplicate_metadata_output:$outputRelativePath")
        continue
    }

    $outputSummariesByPath[$outputRelativePath] = $summary
}

$ndjsonFiles = @(
    Get-ChildItem -LiteralPath $parsedLogDirectory -Filter *.ndjson -File |
        Sort-Object Name
)

if ($ndjsonFiles.Count -eq 0) {
    $failures.Add('ndjson_files_missing')
}
if ($ndjsonFiles.Count -ne $outputSummariesByPath.Count) {
    $failures.Add(
        "metadata_output_count_mismatch:metadata=$($outputSummariesByPath.Count):actual=$($ndjsonFiles.Count)"
    )
}

foreach ($ndjsonFile in $ndjsonFiles) {
    $relativePath = $ndjsonFile.FullName.
        Substring($resolvedDerived.Length + 1).
        Replace('\', '/')

    if (-not $outputSummariesByPath.ContainsKey($relativePath)) {
        $failures.Add("metadata_output_missing:$relativePath")
        continue
    }

    $summary = $outputSummariesByPath[$relativePath]
    $reader = New-Object System.IO.StreamReader(
        $ndjsonFile.FullName,
        [System.Text.Encoding]::UTF8,
        $true
    )

    $lineNumber = [int64]0

    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            $lineNumber++
            $record = $null

            try {
                $record = $line | ConvertFrom-Json
            }
            catch {
                $jsonFailureCount++
                $failures.Add("invalid_json:${relativePath}:$lineNumber")
                continue
            }

            $requiredProperties = @(
                'schema_version',
                'transform_version',
                'run_id',
                'system',
                'service',
                'pod',
                'container',
                'timestamp',
                'timestamp_status',
                'raw_message',
                'source_file',
                'source_line_number',
                'source_sha256'
            )
            $missingRequiredProperty = $false
            foreach ($propertyName in $requiredProperties) {
                if ($record.PSObject.Properties.Name -notcontains $propertyName) {
                    $missingRequiredProperty = $true
                    $failures.Add(
                        "missing_property:${relativePath}:${lineNumber}:$propertyName"
                    )
                }
            }
            if ($missingRequiredProperty) {
                continue
            }

            if ([string]$record.run_id -ne $runId) {
                $runIdMismatchCount++
            }
            if ([string]$record.transform_version -ne [string]$metadata.transform_version) {
                $failures.Add(
                    "record_transform_version_mismatch:${relativePath}:$lineNumber"
                )
            }

            if ([string]$record.source_file -ne [string]$summary.source_file) {
                $failures.Add(
                    "record_source_file_mismatch:${relativePath}:$lineNumber"
                )
            }

            if (
                ([string]$record.source_sha256).ToLowerInvariant() -ne
                ([string]$summary.source_sha256).ToLowerInvariant()
            ) {
                $failures.Add(
                    "record_source_sha256_mismatch:${relativePath}:$lineNumber"
                )
            }

            if ([int64]$record.source_line_number -ne $lineNumber) {
                $sequenceFailureCount++
            }

            if ([string]$record.timestamp_status -eq 'missing') {
                $timestampMissingCount++
            }
            elseif ([string]::IsNullOrWhiteSpace([string]$record.timestamp)) {
                $failures.Add("timestamp_value_missing:${relativePath}:$lineNumber")
            }

            if ([string]::IsNullOrWhiteSpace([string]$record.service)) {
                $failures.Add("service_missing:${relativePath}:$lineNumber")
            }

            if ([string]::IsNullOrWhiteSpace([string]$record.source_sha256)) {
                $failures.Add("source_sha256_missing:${relativePath}:$lineNumber")
            }

            $verifiedRecordCount++
        }
    }
    finally {
        $reader.Dispose()
    }

    if ($lineNumber -ne [int64]$summary.record_count) {
        $failures.Add(
            "record_count_mismatch:${relativePath}:metadata=$($summary.record_count):actual=$lineNumber"
        )
    }
}

if ($verifiedRecordCount -ne [int64]$metadata.total_record_count) {
    $failures.Add(
        "total_record_count_mismatch:metadata=$($metadata.total_record_count):actual=$verifiedRecordCount"
    )
}

if ($timestampMissingCount -ne [int64]$metadata.missing_timestamp_count) {
    $failures.Add(
        "missing_timestamp_count_mismatch:metadata=$($metadata.missing_timestamp_count):actual=$timestampMissingCount"
    )
}

if ($jsonFailureCount -gt 0) {
    $failures.Add("json_failure_count:$jsonFailureCount")
}

if ($runIdMismatchCount -gt 0) {
    $failures.Add("run_id_mismatch_count:$runIdMismatchCount")
}

if ($sequenceFailureCount -gt 0) {
    $failures.Add("sequence_failure_count:$sequenceFailureCount")
}

Write-Output "derived_path=$resolvedDerived"
Write-Output "run_id=$runId"
Write-Output "transform_version=$($metadata.transform_version)"
Write-Output "manifest_file_count=$($manifest.files.Count)"
Write-Output "verified_manifest_file_count=$verifiedManifestFileCount"
Write-Output "ndjson_file_count=$($ndjsonFiles.Count)"
Write-Output "verified_record_count=$verifiedRecordCount"
Write-Output "timestamp_missing_count=$timestampMissingCount"
Write-Output "json_failure_count=$jsonFailureCount"
Write-Output "run_id_mismatch_count=$runIdMismatchCount"
Write-Output "sequence_failure_count=$sequenceFailureCount"
Write-Output "readonly_file_count=$($readOnlyFiles.Count)"
Write-Output "failure_count=$($failures.Count)"

if ($failures.Count -gt 0) {
    $failures |
        Select-Object -First 100 |
        ForEach-Object { Write-Output "failure=$_" }

    if ($failures.Count -gt 100) {
        Write-Output "failure=truncated:$($failures.Count - 100)_additional"
    }

    throw 'Enriched log verification failed.'
}

Write-Output 'enriched_log_verification=passed'
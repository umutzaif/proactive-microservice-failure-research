[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ArchivePath,

    [string]$OutputRoot,

    [string]$TransformVersion = 'log-envelope-v1'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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

$resolvedArchive = (Resolve-Path -LiteralPath $ArchivePath).Path
$metadataPath = Join-Path $resolvedArchive 'metadata.json'
$sourceManifestPath = Join-Path $resolvedArchive 'sha256-manifest.json'
$verifyScript = Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1'

if (-not (Test-Path -LiteralPath $metadataPath -PathType Leaf)) {
    throw "Source archive metadata is missing: $metadataPath"
}

if (-not (Test-Path -LiteralPath $sourceManifestPath -PathType Leaf)) {
    throw "Source archive manifest is missing: $sourceManifestPath"
}

$verificationOutput = & powershell `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File $verifyScript `
    -ArchivePath $resolvedArchive 2>&1

if ($LASTEXITCODE -ne 0) {
    throw "Source archive verification failed: $($verificationOutput -join ' | ')"
}

$metadata = Get-Content -LiteralPath $metadataPath -Raw |
    ConvertFrom-Json

$sourceManifest = Get-Content -LiteralPath $sourceManifestPath -Raw |
    ConvertFrom-Json

$runId = [string]$metadata.run_id

if ([string]::IsNullOrWhiteSpace($runId)) {
    throw 'Source archive metadata does not contain run_id.'
}

if ([string]$sourceManifest.run_id -ne $runId) {
    throw 'Source metadata run_id does not match source manifest run_id.'
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $resolvedOutputRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot '..\artifacts\derived')
    )
}
else {
    $resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
}

$outputDirectory = Join-Path $resolvedOutputRoot $runId
$parsedLogDirectory = Join-Path $outputDirectory 'parsed\logs'

$archivePrefix = $resolvedArchive.TrimEnd('\') + '\'
$outputFullPath = [System.IO.Path]::GetFullPath($outputDirectory)

if ($outputFullPath.StartsWith(
    $archivePrefix,
    [System.StringComparison]::OrdinalIgnoreCase
)) {
    throw 'Derived output must not be written inside the immutable source archive.'
}

if (Test-Path -LiteralPath $outputDirectory) {
    throw "Derived output already exists and will not be overwritten: $outputDirectory"
}

$sourceEntriesByPath = @{}

foreach ($entry in $sourceManifest.files) {
    $normalizedPath = ([string]$entry.path).Replace('\', '/')

    if ($sourceEntriesByPath.ContainsKey($normalizedPath)) {
        throw "Duplicate source manifest path: $normalizedPath"
    }

    $sourceEntriesByPath[$normalizedPath] = $entry
}

$rawLogDirectory = Join-Path $resolvedArchive 'raw\logs'
$rawLogFiles = @(
    Get-ChildItem -LiteralPath $rawLogDirectory -File |
        Sort-Object Name
)

if ($rawLogFiles.Count -eq 0) {
    throw 'Source archive does not contain raw log files.'
}

New-Item -ItemType Directory -Path $parsedLogDirectory -Force |
    Out-Null

$startedUtc = [datetimeoffset]::UtcNow
$totalRecordCount = [int64]0
$missingTimestampCount = [int64]0
$outputSummaries = New-Object System.Collections.Generic.List[object]

try {
    foreach ($rawLogFile in $rawLogFiles) {
        if ($rawLogFile.Name -notmatch '^(?<pod>.+)__(?<container>.+)\.log$') {
            throw "Unexpected raw log filename: $($rawLogFile.Name)"
        }

        $pod = [string]$Matches.pod
        $container = [string]$Matches.container

        if ($pod -match '^(?<service>.+)-[a-f0-9]{8,10}-[a-z0-9]{5}$') {
            $service = [string]$Matches.service
        }
        else {
            $service = $pod
        }

        $sourceRelativePath = (
            'raw/logs/{0}' -f $rawLogFile.Name
        )

        if (-not $sourceEntriesByPath.ContainsKey($sourceRelativePath)) {
            throw "Raw log is absent from source manifest: $sourceRelativePath"
        }

        $sourceEntry = $sourceEntriesByPath[$sourceRelativePath]
        $expectedSourceHash = ([string]$sourceEntry.sha256).
            ToLowerInvariant()
        $actualSourceHash = (
            Get-FileHash `
                -LiteralPath $rawLogFile.FullName `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        if ($actualSourceHash -ne $expectedSourceHash) {
            throw "Source checksum mismatch: $sourceRelativePath"
        }

        $outputName = [System.IO.Path]::GetFileNameWithoutExtension(
            $rawLogFile.Name
        ) + '.ndjson'
        $outputPath = Join-Path $parsedLogDirectory $outputName

        $reader = New-Object System.IO.StreamReader(
            $rawLogFile.FullName,
            [System.Text.Encoding]::UTF8,
            $true
        )
        $writer = New-Object System.IO.StreamWriter(
            $outputPath,
            $false,
            (New-Object System.Text.UTF8Encoding($false))
        )

        $sourceLineNumber = [int64]0
        $fileRecordCount = [int64]0
        $fileMissingTimestampCount = [int64]0

        try {
            while (($line = $reader.ReadLine()) -ne $null) {
                $sourceLineNumber++
                $timestamp = $null
                $rawMessage = $line
                $timestampStatus = 'missing'

                if ($line -match '^(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?Z)(?:\s(?<message>.*))?$') {
                    $timestamp = [string]$Matches.timestamp
                    if ($Matches.ContainsKey('message')) {
                        $rawMessage = [string]$Matches.message
                    }
                    else {
                        $rawMessage = ''
                    }
                    $timestampStatus = 'kubernetes-prefix'
                }
                else {
                    $missingTimestampCount++
                    $fileMissingTimestampCount++
                }

                $record = [ordered]@{
                    schema_version     = 1
                    transform_version  = $TransformVersion
                    run_id             = $runId
                    system             = [string]$metadata.system
                    service            = $service
                    pod                = $pod
                    container          = $container
                    timestamp          = $timestamp
                    timestamp_status   = $timestampStatus
                    raw_message        = $rawMessage
                    source_file        = $sourceRelativePath
                    source_line_number = $sourceLineNumber
                    source_sha256      = $actualSourceHash
                }

                $writer.WriteLine(
                    ($record | ConvertTo-Json -Compress -Depth 4)
                )

                $fileRecordCount++
                $totalRecordCount++
            }
        }
        finally {
            $reader.Dispose()
            $writer.Dispose()
        }

        $outputSummaries.Add(
            [ordered]@{
                source_file             = $sourceRelativePath
                source_sha256           = $actualSourceHash
                output_file             = (
                    'parsed/logs/{0}' -f $outputName
                )
                record_count            = $fileRecordCount
                missing_timestamp_count = $fileMissingTimestampCount
            }
        )
    }

    $completedUtc = [datetimeoffset]::UtcNow

    $derivedMetadata = [ordered]@{
        schema_version          = 1
        transform_version       = $TransformVersion
        run_id                  = $runId
        system                  = [string]$metadata.system
        source_archive          = $resolvedArchive
        source_manifest_sha256  = (
            Get-FileHash `
                -LiteralPath $sourceManifestPath `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        created_utc             = $completedUtc.ToString('o')
        started_utc             = $startedUtc.ToString('o')
        total_record_count      = $totalRecordCount
        missing_timestamp_count = $missingTimestampCount
        output_files            = $outputSummaries.ToArray()
        transformation          = 'One NDJSON envelope per physical raw log line; raw_message is not semantically parsed.'
        overwrite_policy        = 'deny'
    }

    $derivedMetadataPath = Join-Path $outputDirectory 'metadata.json'
    Write-Utf8NoBom `
        -Path $derivedMetadataPath `
        -Content ($derivedMetadata | ConvertTo-Json -Depth 8)

    $derivedManifestEntries = @(
        Get-ChildItem -LiteralPath $outputDirectory -File -Recurse |
            Sort-Object FullName |
            ForEach-Object {
                [ordered]@{
                    path = $_.FullName.
                        Substring($outputDirectory.Length + 1).
                        Replace('\', '/')
                    bytes = $_.Length
                    sha256 = (
                        Get-FileHash `
                            -LiteralPath $_.FullName `
                            -Algorithm SHA256
                    ).Hash.ToLowerInvariant()
                }
            }
    )

    $derivedManifest = [ordered]@{
        algorithm         = 'SHA-256'
        schema_version    = 1
        transform_version = $TransformVersion
        run_id            = $runId
        created_utc       = [datetimeoffset]::UtcNow.ToString('o')
        files             = $derivedManifestEntries
    }

    $derivedManifestPath = Join-Path $outputDirectory 'sha256-manifest.json'
    Write-Utf8NoBom `
        -Path $derivedManifestPath `
        -Content ($derivedManifest | ConvertTo-Json -Depth 6)

    Get-ChildItem -LiteralPath $outputDirectory -File -Recurse |
        ForEach-Object { $_.IsReadOnly = $true }

    Write-Output "output_path=$outputDirectory"
    Write-Output "run_id=$runId"
    Write-Output "transform_version=$TransformVersion"
    Write-Output "source_log_file_count=$($rawLogFiles.Count)"
    Write-Output "output_log_file_count=$($outputSummaries.Count)"
    Write-Output "record_count=$totalRecordCount"
    Write-Output "missing_timestamp_count=$missingTimestampCount"
    Write-Output 'derived_status=sealed-read-only'
}
catch {
    $originalError = $_

    if (Test-Path -LiteralPath $outputDirectory) {
        try {
            $invalidRoot = Join-Path $resolvedOutputRoot '_invalid'
            New-Item -ItemType Directory -Path $invalidRoot -Force |
                Out-Null

            Get-ChildItem `
                -LiteralPath $outputDirectory `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue |
                ForEach-Object { $_.IsReadOnly = $false }

            $failureRecord = [ordered]@{
                schema_version   = 1
                transform_version = $TransformVersion
                run_id           = $runId
                status           = 'invalid'
                failed_utc       = [datetimeoffset]::UtcNow.ToString('o')
                error            = $originalError.Exception.Message
            }

            Write-Utf8NoBom `
                -Path (Join-Path $outputDirectory 'transform-error.json') `
                -Content ($failureRecord | ConvertTo-Json -Depth 4)

            Get-ChildItem -LiteralPath $outputDirectory -File -Recurse |
                ForEach-Object { $_.IsReadOnly = $true }

            $invalidName = '{0}-{1}-failed-{2}' -f `
                $runId, `
                $TransformVersion, `
                ([datetimeoffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))

            $invalidDirectory = Join-Path $invalidRoot $invalidName
            Move-Item `
                -LiteralPath $outputDirectory `
                -Destination $invalidDirectory

            Write-Warning "Partial derived output preserved as invalid: $invalidDirectory"
        }
        catch {
            Write-Warning "Could not finalize invalid derived output: $($_.Exception.Message)"
            Write-Warning "Partial files remain at: $outputDirectory"
        }
    }

    throw $originalError
}
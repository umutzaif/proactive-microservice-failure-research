[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$RunId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$')]
    [string]$StartUtc,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$')]
    [string]$EndUtc,

    [string]$ArtifactRoot,

    [string]$ScientificRunMetadataPath
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

function Invoke-VerificationStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string]$PathParameter,

        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $arguments = @(
        '-NoProfile',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        $ScriptPath,
        "-$PathParameter",
        $Value
    )
    $output = & powershell @arguments 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "$Name verification failed: $($output -join ' | ')"
    }

    return @($output | ForEach-Object { [string]$_ })
}

function Read-JsonFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw "Required JSON file is missing: $Path"
    }

    return Get-Content -LiteralPath $Path -Raw |
        ConvertFrom-Json
}

function Get-NormalizedUtc {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $true)]
        [string]$Name
    )

    try {
        return [datetimeoffset]::Parse(
            $Value,
            [System.Globalization.CultureInfo]::InvariantCulture,
            (
                [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )
        ).ToUniversalTime().ToString(
            'yyyy-MM-ddTHH:mm:ss.fffZ',
            [System.Globalization.CultureInfo]::InvariantCulture
        )
    }
    catch {
        throw "$Name is not a valid UTC value: $Value"
    }
}

if ([string]::IsNullOrWhiteSpace($ArtifactRoot)) {
    $resolvedArtifactRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot '..\artifacts')
    )
}
else {
    $resolvedArtifactRoot = [System.IO.Path]::GetFullPath($ArtifactRoot)
}

$rawArchive = Join-Path $resolvedArtifactRoot "runs\$RunId"
$derivedArchive = Join-Path $resolvedArtifactRoot "derived\$RunId"
$telemetryArchive = Join-Path $resolvedArtifactRoot "telemetry\$RunId"
$finalizedRoot = Join-Path $resolvedArtifactRoot 'finalized'
$receiptDirectory = Join-Path $finalizedRoot $RunId

if (Test-Path -LiteralPath $receiptDirectory) {
    throw "Finalization receipt already exists and will not be overwritten: $receiptDirectory"
}

$startNormalized = Get-NormalizedUtc -Value $StartUtc -Name 'StartUtc'
$endNormalized = Get-NormalizedUtc -Value $EndUtc -Name 'EndUtc'

if (
    [datetimeoffset]::Parse($startNormalized) -ge
    [datetimeoffset]::Parse($endNormalized)
) {
    throw 'StartUtc must be earlier than EndUtc.'
}

$rawVerification = Invoke-VerificationStep `
    -Name 'raw log archive' `
    -ScriptPath (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') `
    -PathParameter 'ArchivePath' `
    -Value $rawArchive

$derivedVerification = Invoke-VerificationStep `
    -Name 'enriched logs' `
    -ScriptPath (Join-Path $PSScriptRoot 'verify-enriched-logs.ps1') `
    -PathParameter 'DerivedPath' `
    -Value $derivedArchive

$telemetryVerification = Invoke-VerificationStep `
    -Name 'run telemetry' `
    -ScriptPath (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') `
    -PathParameter 'TelemetryPath' `
    -Value $telemetryArchive

$rawMetadataPath = Join-Path $rawArchive 'metadata.json'
$rawManifestPath = Join-Path $rawArchive 'sha256-manifest.json'
$derivedMetadataPath = Join-Path $derivedArchive 'metadata.json'
$derivedManifestPath = Join-Path $derivedArchive 'sha256-manifest.json'
$telemetryMetadataPath = Join-Path $telemetryArchive 'metadata.json'
$telemetryManifestPath = Join-Path $telemetryArchive 'sha256-manifest.json'

$rawMetadata = Read-JsonFile -Path $rawMetadataPath
$rawManifest = Read-JsonFile -Path $rawManifestPath
$derivedMetadata = Read-JsonFile -Path $derivedMetadataPath
$derivedManifest = Read-JsonFile -Path $derivedManifestPath
$telemetryMetadata = Read-JsonFile -Path $telemetryMetadataPath
$telemetryManifest = Read-JsonFile -Path $telemetryManifestPath

$observedRunIds = @(
    @(
        [string]$rawMetadata.run_id
        [string]$rawManifest.run_id
        [string]$derivedMetadata.run_id
        [string]$derivedManifest.run_id
        [string]$telemetryMetadata.run_id
        [string]$telemetryManifest.run_id
    ) |
        Sort-Object -Unique
)

if ($observedRunIds.Count -ne 1 -or $observedRunIds[0] -ne $RunId) {
    throw "Run ID alignment failed: $($observedRunIds -join ', ')"
}

$rawStart = Get-NormalizedUtc `
    -Value ([string]$rawMetadata.since_utc) `
    -Name 'raw metadata since_utc'
$rawEnd = Get-NormalizedUtc `
    -Value ([string]$rawMetadata.until_utc) `
    -Name 'raw metadata until_utc'
$telemetryStart = Get-NormalizedUtc `
    -Value ([string]$telemetryMetadata.start_utc) `
    -Name 'telemetry metadata start_utc'
$telemetryEnd = Get-NormalizedUtc `
    -Value ([string]$telemetryMetadata.end_utc) `
    -Name 'telemetry metadata end_utc'

if (
    $rawStart -ne $startNormalized -or
    $rawEnd -ne $endNormalized -or
    $telemetryStart -ne $startNormalized -or
    $telemetryEnd -ne $endNormalized
) {
    throw (
        'Cross-modality time alignment failed: requested={0}/{1}; raw={2}/{3}; telemetry={4}/{5}' -f
        $startNormalized,
        $endNormalized,
        $rawStart,
        $rawEnd,
        $telemetryStart,
        $telemetryEnd
    )
}

$sourceManifestHashes = [ordered]@{
    raw_logs = (
        Get-FileHash -LiteralPath $rawManifestPath -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    enriched_logs = (
        Get-FileHash -LiteralPath $derivedManifestPath -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    telemetry = (
        Get-FileHash -LiteralPath $telemetryManifestPath -Algorithm SHA256
    ).Hash.ToLowerInvariant()
}

$scientificMetadata = $null
$scientificMetadataVerification = @()
$resolvedScientificMetadataPath = $null
$resolvedWorkloadProfilePath = $null

if (-not [string]::IsNullOrWhiteSpace($ScientificRunMetadataPath)) {
    $resolvedScientificMetadataPath = (
        Resolve-Path -LiteralPath $ScientificRunMetadataPath
    ).Path
    $scientificMetadataVerification = @(
        & powershell `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File (Join-Path $PSScriptRoot 'verify-scientific-run-metadata.ps1') `
            -MetadataPath $resolvedScientificMetadataPath `
            -ExpectedRunId $RunId `
            -ExpectedStartUtc $StartUtc `
            -ExpectedEndUtc $EndUtc 2>&1
    )

    if ($LASTEXITCODE -ne 0) {
        throw (
            'Scientific run metadata verification failed: {0}' -f
            ($scientificMetadataVerification -join ' | ')
        )
    }

    $scientificMetadata = Read-JsonFile `
        -Path $resolvedScientificMetadataPath
    $repositoryRootForProfile = (
        Resolve-Path (Join-Path $PSScriptRoot '..\..')
    ).Path
    $resolvedWorkloadProfilePath = [System.IO.Path]::GetFullPath(
        (Join-Path `
            $repositoryRootForProfile `
            ([string]$scientificMetadata.workload_profile_path))
    )
}

New-Item -ItemType Directory -Path $receiptDirectory -Force |
    Out-Null

try {
    $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $codeRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw 'Could not determine Git code revision.'
    }

    $scientificMetadataHash = $null
    $workloadProfileHash = $null

    if ($null -ne $scientificMetadata) {
        $scientificMetadataCopy = Join-Path `
            $receiptDirectory `
            'scientific-run-metadata.json'
        $workloadProfileCopy = Join-Path `
            $receiptDirectory `
            'workload-profile.json'
        Copy-Item `
            -LiteralPath $resolvedScientificMetadataPath `
            -Destination $scientificMetadataCopy
        Copy-Item `
            -LiteralPath $resolvedWorkloadProfilePath `
            -Destination $workloadProfileCopy
        $scientificMetadataHash = (
            Get-FileHash `
                -LiteralPath $scientificMetadataCopy `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        $workloadProfileHash = (
            Get-FileHash `
                -LiteralPath $workloadProfileCopy `
                -Algorithm SHA256
        ).Hash.ToLowerInvariant()
    }

    $receipt = [ordered]@{
        schema_version          = 1
        run_id                  = $RunId
        status                  = 'finalized'
        valid_for_modeling      = $true
        start_utc               = $startNormalized
        end_utc                 = $endNormalized
        finalized_utc           = [datetimeoffset]::UtcNow.ToString('o')
        code_revision           = $codeRevision
        raw_log_archive         = $rawArchive
        enriched_log_archive    = $derivedArchive
        telemetry_archive       = $telemetryArchive
        source_manifest_sha256  = $sourceManifestHashes
        verification            = [ordered]@{
            raw_logs = $rawVerification
            enriched_logs = $derivedVerification
            telemetry = $telemetryVerification
            scientific_run_metadata = $scientificMetadataVerification
        }
        scientific_run_metadata = if ($null -ne $scientificMetadata) {
            [ordered]@{
                path = 'scientific-run-metadata.json'
                sha256 = $scientificMetadataHash
                experiment_id = [string]$scientificMetadata.experiment_id
                run_kind = [string]$scientificMetadata.run_kind
                workload_profile_id = [string]$scientificMetadata.workload_profile_id
                random_seed = [int]$scientificMetadata.random_seed
            }
        }
        else {
            $null
        }
        workload_profile = if ($null -ne $scientificMetadata) {
            [ordered]@{
                path = 'workload-profile.json'
                sha256 = $workloadProfileHash
            }
        }
        else {
            $null
        }
        metric_series_count     = [int]$telemetryMetadata.metric_series_count
        metric_sample_count     = [int64]$telemetryMetadata.metric_sample_count
        telemetry_schema_version = [int]$telemetryMetadata.schema_version
        trace_query_chunk_seconds = if (
            [int]$telemetryMetadata.schema_version -ge 3
        ) {
            [int]$telemetryMetadata.trace_query_chunk_seconds
        }
        else {
            $null
        }
        trace_chunk_count       = if (
            [int]$telemetryMetadata.schema_version -ge 3
        ) {
            [int]$telemetryMetadata.trace_chunk_count
        }
        else {
            $null
        }
        unique_trace_count      = [int]$telemetryMetadata.unique_trace_count
        trace_response_count    = [int64]$telemetryMetadata.trace_response_count
        enriched_record_count   = [int64]$derivedMetadata.total_record_count
        overwrite_policy        = 'deny'
        protection              = 'SHA-256 source-manifest references plus Windows read-only attribute'
    }

    $receiptPath = Join-Path $receiptDirectory 'receipt.json'
    Write-Utf8NoBom `
        -Path $receiptPath `
        -Content ($receipt | ConvertTo-Json -Depth 10)

    $receiptManifestEntries = @(
        Get-ChildItem -LiteralPath $receiptDirectory -File |
            Sort-Object FullName |
            ForEach-Object {
                [ordered]@{
                    path = $_.Name
                    bytes = $_.Length
                    sha256 = (
                        Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
                    ).Hash.ToLowerInvariant()
                }
            }
    )

    $receiptManifest = [ordered]@{
        algorithm      = 'SHA-256'
        schema_version = 1
        run_id         = $RunId
        created_utc    = [datetimeoffset]::UtcNow.ToString('o')
        files          = $receiptManifestEntries
    }

    $receiptManifestPath = Join-Path `
        $receiptDirectory `
        'sha256-manifest.json'
    Write-Utf8NoBom `
        -Path $receiptManifestPath `
        -Content ($receiptManifest | ConvertTo-Json -Depth 6)

    Get-ChildItem -LiteralPath $receiptDirectory -File |
        ForEach-Object { $_.IsReadOnly = $true }

    Write-Output "receipt_path=$receiptDirectory"
    Write-Output "run_id=$RunId"
    Write-Output "start_utc=$startNormalized"
    Write-Output "end_utc=$endNormalized"
    Write-Output "metric_sample_count=$($telemetryMetadata.metric_sample_count)"
    Write-Output "telemetry_schema_version=$($telemetryMetadata.schema_version)"
    if ([int]$telemetryMetadata.schema_version -ge 3) {
        Write-Output "trace_query_chunk_seconds=$($telemetryMetadata.trace_query_chunk_seconds)"
        Write-Output "trace_chunk_count=$($telemetryMetadata.trace_chunk_count)"
    }
    Write-Output "unique_trace_count=$($telemetryMetadata.unique_trace_count)"
    Write-Output "enriched_record_count=$($derivedMetadata.total_record_count)"
    if ($null -ne $scientificMetadata) {
        Write-Output "workload_profile_id=$($scientificMetadata.workload_profile_id)"
        Write-Output "random_seed=$($scientificMetadata.random_seed)"
        Write-Output 'scientific_run_metadata=verified-and-sealed'
    }
    Write-Output 'run_finalization=passed'
}
catch {
    $originalError = $_

    if (Test-Path -LiteralPath $receiptDirectory) {
        try {
            $invalidRoot = Join-Path $finalizedRoot '_invalid'
            New-Item -ItemType Directory -Path $invalidRoot -Force |
                Out-Null

            Get-ChildItem `
                -LiteralPath $receiptDirectory `
                -File `
                -ErrorAction SilentlyContinue |
                ForEach-Object { $_.IsReadOnly = $false }

            $failureRecord = [ordered]@{
                schema_version = 1
                run_id         = $RunId
                status         = 'invalid'
                failed_utc     = [datetimeoffset]::UtcNow.ToString('o')
                error          = $originalError.Exception.Message
            }

            Write-Utf8NoBom `
                -Path (Join-Path $receiptDirectory 'finalization-error.json') `
                -Content ($failureRecord | ConvertTo-Json -Depth 4)

            Get-ChildItem -LiteralPath $receiptDirectory -File |
                ForEach-Object { $_.IsReadOnly = $true }

            $invalidName = '{0}-finalization-failed-{1}' -f `
                $RunId, `
                ([datetimeoffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
            $invalidDirectory = Join-Path $invalidRoot $invalidName

            Move-Item `
                -LiteralPath $receiptDirectory `
                -Destination $invalidDirectory

            Write-Warning "Failed finalization receipt preserved as invalid: $invalidDirectory"
        }
        catch {
            Write-Warning "Could not preserve failed finalization receipt: $($_.Exception.Message)"
        }
    }

    throw $originalError
}

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$ReceiptPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

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
}

$resolvedReceipt = (Resolve-Path -LiteralPath $ReceiptPath).Path
$receiptFile = Join-Path $resolvedReceipt 'receipt.json'
$manifestFile = Join-Path $resolvedReceipt 'sha256-manifest.json'

foreach ($requiredPath in @($receiptFile, $manifestFile)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required finalization file is missing: $requiredPath"
    }
}

$receipt = Get-Content -LiteralPath $receiptFile -Raw |
    ConvertFrom-Json
$manifest = Get-Content -LiteralPath $manifestFile -Raw |
    ConvertFrom-Json
$failures = New-Object System.Collections.Generic.List[string]
$verifiedManifestFileCount = 0

if ([string]$manifest.algorithm -ne 'SHA-256') {
    $failures.Add("unsupported_checksum_algorithm:$($manifest.algorithm)")
}

if ([string]$receipt.run_id -ne [string]$manifest.run_id) {
    $failures.Add('receipt_manifest_run_id_mismatch')
}

if ([string]$receipt.status -ne 'finalized') {
    $failures.Add("receipt_status_invalid:$($receipt.status)")
}

if ([bool]$receipt.valid_for_modeling -ne $true) {
    $failures.Add('receipt_not_valid_for_modeling')
}

$receiptPrefix = $resolvedReceipt.TrimEnd('\') + '\'
$manifestRelativePaths = @(
    $manifest.files |
        ForEach-Object { ([string]$_.path).Replace('\', '/') }
)

foreach ($entry in $manifest.files) {
    $relativePath = ([string]$entry.path).Replace('\', '/')

    if ([System.IO.Path]::IsPathRooted($relativePath)) {
        $failures.Add("absolute_path_not_allowed:$relativePath")
        continue
    }

    $candidatePath = [System.IO.Path]::GetFullPath(
        (Join-Path $resolvedReceipt $relativePath)
    )

    if (-not $candidatePath.StartsWith(
        $receiptPrefix,
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
    Get-ChildItem -LiteralPath $resolvedReceipt -File
)
$readOnlyFiles = @(
    $allFiles | Where-Object { $_.IsReadOnly }
)

foreach ($actualFile in $allFiles) {
    if ($actualFile.FullName -eq $manifestFile) {
        continue
    }

    if ($manifestRelativePaths -notcontains $actualFile.Name) {
        $failures.Add("unexpected_unmanifested_file:$($actualFile.Name)")
    }
}

if ($readOnlyFiles.Count -ne $allFiles.Count) {
    $failures.Add(
        "readonly_mismatch:expected=$($allFiles.Count),actual=$($readOnlyFiles.Count)"
    )
}

$sourceArchives = [ordered]@{
    raw_logs = [string]$receipt.raw_log_archive
    enriched_logs = [string]$receipt.enriched_log_archive
    telemetry = [string]$receipt.telemetry_archive
}

foreach ($sourceName in $sourceArchives.Keys) {
    $sourceArchive = $sourceArchives[$sourceName]
    $sourceManifest = Join-Path $sourceArchive 'sha256-manifest.json'

    if (-not (Test-Path -LiteralPath $sourceManifest -PathType Leaf)) {
        $failures.Add("source_manifest_missing:$sourceName")
        continue
    }

    $actualHash = (
        Get-FileHash -LiteralPath $sourceManifest -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    $expectedHash = (
        [string]$receipt.source_manifest_sha256.$sourceName
    ).ToLowerInvariant()

    if ($actualHash -ne $expectedHash) {
        $failures.Add("source_manifest_checksum_mismatch:$sourceName")
    }
}

$telemetryMetadataPath = Join-Path `
    $sourceArchives.telemetry `
    'metadata.json'

if (Test-Path -LiteralPath $telemetryMetadataPath -PathType Leaf) {
    $telemetryMetadata = Get-Content `
        -LiteralPath $telemetryMetadataPath `
        -Raw |
        ConvertFrom-Json

    if (
        $receipt.PSObject.Properties.Name -contains
        'telemetry_schema_version' -and
        [int]$receipt.telemetry_schema_version -ne
        [int]$telemetryMetadata.schema_version
    ) {
        $failures.Add('telemetry_schema_version_mismatch')
    }

    if ([int]$telemetryMetadata.schema_version -ge 3) {
        if (
            $receipt.PSObject.Properties.Name -notcontains
            'trace_query_chunk_seconds' -or
            [int]$receipt.trace_query_chunk_seconds -ne
            [int]$telemetryMetadata.trace_query_chunk_seconds
        ) {
            $failures.Add('trace_query_chunk_seconds_mismatch')
        }

        if (
            $receipt.PSObject.Properties.Name -notcontains
            'trace_chunk_count' -or
            [int]$receipt.trace_chunk_count -ne
            [int]$telemetryMetadata.trace_chunk_count
        ) {
            $failures.Add('trace_chunk_count_mismatch')
        }
    }
}

if ($failures.Count -eq 0) {
    Invoke-VerificationStep `
        -Name 'raw log archive' `
        -ScriptPath (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') `
        -PathParameter 'ArchivePath' `
        -Value $sourceArchives.raw_logs

    Invoke-VerificationStep `
        -Name 'enriched logs' `
        -ScriptPath (Join-Path $PSScriptRoot 'verify-enriched-logs.ps1') `
        -PathParameter 'DerivedPath' `
        -Value $sourceArchives.enriched_logs

    Invoke-VerificationStep `
        -Name 'run telemetry' `
        -ScriptPath (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') `
        -PathParameter 'TelemetryPath' `
        -Value $sourceArchives.telemetry
}

Write-Output "receipt_path=$resolvedReceipt"
Write-Output "run_id=$($receipt.run_id)"
Write-Output "manifest_file_count=$($manifest.files.Count)"
Write-Output "verified_manifest_file_count=$verifiedManifestFileCount"
Write-Output "readonly_file_count=$($readOnlyFiles.Count)"
Write-Output "metric_sample_count=$($receipt.metric_sample_count)"
if ($receipt.PSObject.Properties.Name -contains 'telemetry_schema_version') {
    Write-Output "telemetry_schema_version=$($receipt.telemetry_schema_version)"
}
if (
    $receipt.PSObject.Properties.Name -contains 'trace_query_chunk_seconds' -and
    $null -ne $receipt.trace_query_chunk_seconds
) {
    Write-Output "trace_query_chunk_seconds=$($receipt.trace_query_chunk_seconds)"
}
if (
    $receipt.PSObject.Properties.Name -contains 'trace_chunk_count' -and
    $null -ne $receipt.trace_chunk_count
) {
    Write-Output "trace_chunk_count=$($receipt.trace_chunk_count)"
}
Write-Output "unique_trace_count=$($receipt.unique_trace_count)"
Write-Output "enriched_record_count=$($receipt.enriched_record_count)"
Write-Output "failure_count=$($failures.Count)"

if ($failures.Count -gt 0) {
    $failures |
        ForEach-Object { Write-Output "failure=$_" }

    throw 'Finalized run verification failed.'
}

Write-Output 'finalized_run_verification=passed'

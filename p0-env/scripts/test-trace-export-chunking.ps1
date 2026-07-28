[CmdletBinding()]
param()

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

$runId = 'ob-trace-chunk-test-001'
$startUtc = '2026-01-01T00:00:00.000Z'
$endUtc = '2026-01-01T00:10:00.000Z'
$testRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\state\tests\trace-export-chunking')
)
$mockBin = Join-Path $testRoot 'mock-bin'
$outputRoot = Join-Path $testRoot 'telemetry'
$limitOutputRoot = Join-Path $testRoot 'limit-telemetry'
$validArchive = Join-Path $outputRoot $runId
$invalidArchive = Join-Path $testRoot 'invalid-gap'
$originalPath = $env:Path

if (Test-Path -LiteralPath $testRoot) {
    Remove-Item -LiteralPath $testRoot -Recurse -Force
}

New-Item -ItemType Directory -Path $mockBin -Force | Out-Null

$mockMinikube = @'
$ErrorActionPreference = 'Stop'
$runId = 'ob-trace-chunk-test-001'
$baseMicroseconds = [int64]1767225600000000

function New-Trace {
    param(
        [string]$TraceId,
        [int64]$StartMicroseconds
    )

    return [ordered]@{
        traceID = $TraceId
        spans = @(
            [ordered]@{
                traceID = $TraceId
                spanID = "span-$TraceId"
                operationName = 'synthetic'
                references = @()
                startTime = $StartMicroseconds
                duration = 1000
                tags = @()
                logs = @()
                processID = 'p1'
                warnings = $null
            }
        )
        processes = [ordered]@{
            p1 = [ordered]@{
                serviceName = 'synthetic-service'
                tags = @(
                    [ordered]@{
                        key = 'experiment.run_id'
                        type = 'string'
                        value = $runId
                    }
                )
            }
        }
        warnings = $null
    }
}

if ($args.Count -gt 0 -and $args[0] -eq 'status') {
    Write-Output 'host: Running'
    Write-Output 'kubelet: Running'
    Write-Output 'apiserver: Running'
    exit 0
}

$joined = $args -join ' '

if ($joined -match 'get deployments -o json') {
    [ordered]@{
        items = @(
            [ordered]@{
                spec = [ordered]@{
                    template = [ordered]@{
                        spec = [ordered]@{
                            containers = @(
                                [ordered]@{
                                    env = @(
                                        [ordered]@{
                                            name = 'EXPERIMENT_RUN_ID'
                                            value = $runId
                                        }
                                    )
                                }
                            )
                        }
                    }
                }
            }
        )
    } | ConvertTo-Json -Depth 10 -Compress
    exit 0
}

if ($joined -notmatch 'get --raw') {
    Write-Error "Unexpected mock minikube arguments: $joined"
    exit 1
}

$requestPath = [string]$args[-1]

if ($requestPath -match '/api/v1/query_range\?') {
    [ordered]@{
        status = 'success'
        data = [ordered]@{
            resultType = 'matrix'
            result = @(
                [ordered]@{
                    metric = [ordered]@{
                        __name__ = 'synthetic_metric'
                        experiment_run_id = $runId
                    }
                    values = @(
                        @([double]1767225600, '1'),
                        @([double]1767225900, '2')
                    )
                }
            )
        }
    } | ConvertTo-Json -Depth 10 -Compress
    exit 0
}

if ($requestPath -match '/api/services$') {
    [ordered]@{
        data = @('checkoutservice', 'frontend')
        total = 2
        limit = 0
        offset = 0
        errors = $null
    } | ConvertTo-Json -Depth 6 -Compress
    exit 0
}

if ($requestPath -match '/api/traces\?') {
    $serviceMatch = [regex]::Match(
        $requestPath,
        '[?&]service=([^&]+)'
    )
    $startMatch = [regex]::Match(
        $requestPath,
        '[?&]start=(\d+)'
    )

    if (-not $serviceMatch.Success -or -not $startMatch.Success) {
        Write-Error "Malformed trace request: $requestPath"
        exit 1
    }

    $service = [uri]::UnescapeDataString($serviceMatch.Groups[1].Value)
    $chunkStart = [int64]$startMatch.Groups[1].Value
    $chunkIndex = if ($chunkStart -eq $baseMicroseconds) { 0 } else { 1 }
    $traceStart = $chunkStart + 1000
    $traces = @()

    if ($service -eq 'frontend' -and $chunkIndex -eq 0) {
        $traces = @(New-Trace -TraceId 'trace-a' -StartMicroseconds $traceStart)
    }
    elseif ($service -eq 'frontend' -and $chunkIndex -eq 1) {
        $traces = @(New-Trace -TraceId 'trace-b' -StartMicroseconds $traceStart)
    }
    elseif ($service -eq 'checkoutservice' -and $chunkIndex -eq 0) {
        $traces = @(New-Trace -TraceId 'trace-a' -StartMicroseconds $traceStart)
    }
    else {
        $traces = @(New-Trace -TraceId 'trace-c' -StartMicroseconds $traceStart)
    }

    [ordered]@{
        data = $traces
        total = $traces.Count
        limit = 100
        offset = 0
        errors = $null
    } | ConvertTo-Json -Depth 20 -Compress
    exit 0
}

Write-Error "Unexpected mock request path: $requestPath"
exit 1
'@

Write-Utf8NoBom `
    -Path (Join-Path $mockBin 'minikube.ps1') `
    -Content ($mockMinikube.TrimEnd() + "`n")

try {
    $env:Path = "$mockBin;$originalPath"

    $archiveOutput = & powershell `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') `
        -RunId $runId `
        -StartUtc $startUtc `
        -EndUtc $endUtc `
        -TraceLimitPerService 100 `
        -TraceQueryChunkSeconds 300 `
        -OutputRoot $outputRoot 2>&1
    $archiveExitCode = $LASTEXITCODE

    if ($archiveExitCode -ne 0) {
        throw "Synthetic archive failed: $($archiveOutput -join ' | ')"
    }

    $verifyOutput = & powershell `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') `
        -TelemetryPath $validArchive 2>&1
    $verifyExitCode = $LASTEXITCODE

    if ($verifyExitCode -ne 0) {
        throw "Synthetic verification failed: $($verifyOutput -join ' | ')"
    }

    $metadataPath = Join-Path $validArchive 'metadata.json'
    $metadata = Get-Content -LiteralPath $metadataPath -Raw |
        ConvertFrom-Json

    if ([int]$metadata.schema_version -ne 3) {
        throw 'Synthetic archive did not use telemetry schema version 3.'
    }

    if ([int]$metadata.trace_chunk_count -ne 4) {
        throw "Expected 4 trace chunks; found $($metadata.trace_chunk_count)."
    }

    if ([int]$metadata.raw_unique_trace_count -ne 3) {
        throw (
            'Cross-service/chunk trace-ID deduplication failed: ' +
            "expected 3, found $($metadata.raw_unique_trace_count)."
        )
    }

    Copy-Item -LiteralPath $validArchive -Destination $invalidArchive -Recurse
    Get-ChildItem -LiteralPath $invalidArchive -File -Recurse |
        ForEach-Object { $_.IsReadOnly = $false }

    $invalidMetadataPath = Join-Path $invalidArchive 'metadata.json'
    $invalidMetadata = Get-Content -LiteralPath $invalidMetadataPath -Raw |
        ConvertFrom-Json
    $invalidMetadata.trace_files[0].start_microseconds = (
        [int64]$invalidMetadata.trace_files[0].start_microseconds + 1
    )
    Write-Utf8NoBom `
        -Path $invalidMetadataPath `
        -Content ($invalidMetadata | ConvertTo-Json -Depth 12)

    $invalidManifestPath = Join-Path `
        $invalidArchive `
        'sha256-manifest.json'
    $invalidManifest = Get-Content -LiteralPath $invalidManifestPath -Raw |
        ConvertFrom-Json
    $metadataManifestEntry = $invalidManifest.files |
        Where-Object { [string]$_.path -eq 'metadata.json' }
    $metadataManifestEntry.bytes = (
        Get-Item -LiteralPath $invalidMetadataPath
    ).Length
    $metadataManifestEntry.sha256 = (
        Get-FileHash -LiteralPath $invalidMetadataPath -Algorithm SHA256
    ).Hash.ToLowerInvariant()
    Write-Utf8NoBom `
        -Path $invalidManifestPath `
        -Content ($invalidManifest | ConvertTo-Json -Depth 12)
    Get-ChildItem -LiteralPath $invalidArchive -File -Recurse |
        ForEach-Object { $_.IsReadOnly = $true }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        $negativeOutput = & powershell `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') `
            -TelemetryPath $invalidArchive 2>&1
        $negativeExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($negativeExitCode -eq 0) {
        throw 'Verifier accepted a trace chunk coverage gap.'
    }

    if (($negativeOutput -join "`n") -notmatch 'trace_chunk_time_gap') {
        throw (
            'Verifier rejected the invalid fixture without reporting ' +
            'trace_chunk_time_gap.'
        )
    }

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        $limitOutput = & powershell `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') `
            -RunId $runId `
            -StartUtc $startUtc `
            -EndUtc $endUtc `
            -TraceLimitPerService 1 `
            -TraceQueryChunkSeconds 300 `
            -OutputRoot $limitOutputRoot 2>&1
        $limitExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    if ($limitExitCode -eq 0) {
        throw 'Exporter accepted a trace chunk at the configured limit.'
    }

    if (($limitOutput -join "`n") -notmatch 'reduce TraceQueryChunkSeconds') {
        throw 'Trace-limit failure did not report the chunk-size remedy.'
    }

    $preservedLimitFailures = @(
        Get-ChildItem `
            -LiteralPath (Join-Path $limitOutputRoot '_invalid') `
            -Directory `
            -ErrorAction SilentlyContinue
    )

    if ($preservedLimitFailures.Count -ne 1) {
        throw 'Trace-limit failure was not preserved exactly once.'
    }

    Write-Output 'schema_v3_fixture_verification=passed'
    Write-Output 'cross_chunk_trace_id_deduplication=passed'
    Write-Output 'chunk_gap_negative_test=passed'
    Write-Output 'chunk_limit_negative_test=passed'
    Write-Output 'invalid_limit_archive_preservation=passed'
    Write-Output 'trace_export_chunking_tests=passed'
}
finally {
    $env:Path = $originalPath

    if (Test-Path -LiteralPath $testRoot) {
        Get-ChildItem -LiteralPath $testRoot -File -Recurse |
            ForEach-Object { $_.IsReadOnly = $false }
        Remove-Item -LiteralPath $testRoot -Recurse -Force
    }
}

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$TelemetryPath
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$resolvedTelemetry = (Resolve-Path -LiteralPath $TelemetryPath).Path
$metadataPath = Join-Path $resolvedTelemetry 'metadata.json'
$manifestPath = Join-Path $resolvedTelemetry 'sha256-manifest.json'
$metricPath = Join-Path `
    $resolvedTelemetry `
    'raw\metrics\prometheus-query-range.json'
$traceDirectory = Join-Path $resolvedTelemetry 'raw\traces'
$servicesPath = Join-Path $traceDirectory 'jaeger-services.json'
$selectedTracePath = Join-Path $resolvedTelemetry 'selected\traces.ndjson'

foreach ($requiredPath in @(
    $metadataPath,
    $manifestPath,
    $metricPath,
    $servicesPath
)) {
    if (-not (Test-Path -LiteralPath $requiredPath -PathType Leaf)) {
        throw "Required telemetry file is missing: $requiredPath"
    }
}

if (-not (Test-Path -LiteralPath $traceDirectory -PathType Container)) {
    throw "Trace directory is missing: $traceDirectory"
}

$metadata = Get-Content -LiteralPath $metadataPath -Raw |
    ConvertFrom-Json
$manifest = Get-Content -LiteralPath $manifestPath -Raw |
    ConvertFrom-Json
$schemaVersion = [int]$metadata.schema_version

if ($schemaVersion -notin @(1, 2, 3)) {
    throw "Unsupported telemetry schema version: $schemaVersion"
}

if (
    $schemaVersion -ge 2 -and
    -not (Test-Path -LiteralPath $selectedTracePath -PathType Leaf)
) {
    throw "Selected trace file is missing: $selectedTracePath"
}

$failures = New-Object System.Collections.Generic.List[string]
$verifiedManifestFileCount = 0

$runId = [string]$metadata.run_id

if ([string]::IsNullOrWhiteSpace($runId)) {
    $failures.Add('metadata_run_id_missing')
}

if ([string]$manifest.run_id -ne $runId) {
    $failures.Add('manifest_run_id_mismatch')
}

if ([string]$manifest.algorithm -ne 'SHA-256') {
    $failures.Add("unsupported_checksum_algorithm:$($manifest.algorithm)")
}

try {
    $startValue = [datetimeoffset]::Parse(
        [string]$metadata.start_utc,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal
    ).ToUniversalTime()
    $endValue = [datetimeoffset]::Parse(
        [string]$metadata.end_utc,
        [System.Globalization.CultureInfo]::InvariantCulture,
        [System.Globalization.DateTimeStyles]::AssumeUniversal
    ).ToUniversalTime()
}
catch {
    $failures.Add('metadata_time_parse_failure')
    $startValue = [datetimeoffset]::MinValue
    $endValue = [datetimeoffset]::MaxValue
}

if ($startValue -ge $endValue) {
    $failures.Add('metadata_time_order_invalid')
}

$telemetryPrefix = $resolvedTelemetry.TrimEnd('\') + '\'
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
        (Join-Path $resolvedTelemetry $relativePath)
    )

    if (-not $candidatePath.StartsWith(
        $telemetryPrefix,
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
    Get-ChildItem -LiteralPath $resolvedTelemetry -File -Recurse
)
$readOnlyFiles = @(
    $allFiles | Where-Object { $_.IsReadOnly }
)

foreach ($actualFile in $allFiles) {
    if ($actualFile.FullName -eq $manifestPath) {
        continue
    }

    $relativePath = $actualFile.FullName.
        Substring($resolvedTelemetry.Length + 1).
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

$prometheusResponse = Get-Content -LiteralPath $metricPath -Raw |
    ConvertFrom-Json
$metricSeries = @($prometheusResponse.data.result)
$metricSampleCount = [int64]0
$metricRunIdMismatchCount = [int64]0
$metricTimeFailureCount = [int64]0

if ([string]$prometheusResponse.status -ne 'success') {
    $failures.Add('prometheus_status_not_success')
}

if ([string]$prometheusResponse.data.resultType -ne 'matrix') {
    $failures.Add(
        "prometheus_result_type_invalid:$($prometheusResponse.data.resultType)"
    )
}

foreach ($series in $metricSeries) {
    if ([string]$series.metric.experiment_run_id -ne $runId) {
        $metricRunIdMismatchCount++
    }

    foreach ($sample in @($series.values)) {
        $metricSampleCount++
        $sampleSeconds = [double]$sample[0]
        $sampleTime = [datetimeoffset]::FromUnixTimeMilliseconds(
            [int64][math]::Round($sampleSeconds * 1000)
        )

        if ($sampleTime -lt $startValue -or $sampleTime -gt $endValue) {
            $metricTimeFailureCount++
        }
    }
}

if ($metricSeries.Count -eq 0 -or $metricSampleCount -eq 0) {
    $failures.Add('metric_samples_missing')
}

if ($metricRunIdMismatchCount -gt 0) {
    $failures.Add("metric_run_id_mismatch_count:$metricRunIdMismatchCount")
}

if ($metricTimeFailureCount -gt 0) {
    $failures.Add("metric_time_failure_count:$metricTimeFailureCount")
}

if ($metricSeries.Count -ne [int]$metadata.metric_series_count) {
    $failures.Add(
        "metric_series_count_mismatch:metadata=$($metadata.metric_series_count):actual=$($metricSeries.Count)"
    )
}

if ($metricSampleCount -ne [int64]$metadata.metric_sample_count) {
    $failures.Add(
        "metric_sample_count_mismatch:metadata=$($metadata.metric_sample_count):actual=$metricSampleCount"
    )
}

$servicesResponse = Get-Content -LiteralPath $servicesPath -Raw |
    ConvertFrom-Json
$services = @($servicesResponse.data | Sort-Object -Unique)
$traceFiles = @(
    Get-ChildItem `
        -LiteralPath $traceDirectory `
        -Filter 'service-*.json' `
        -File |
        Sort-Object Name
)
$expectedTraceFiles = @($metadata.trace_files)
$rawUniqueTraces = @{}
$traceResponseCount = [int64]0
$traceSummaryByPath = @{}
$startMicroseconds = [int64]($startValue.ToUnixTimeMilliseconds() * 1000)
$endMicroseconds = [int64]($endValue.ToUnixTimeMilliseconds() * 1000)

if ($services.Count -ne [int]$metadata.jaeger_service_count) {
    $failures.Add(
        "jaeger_service_count_mismatch:metadata=$($metadata.jaeger_service_count):actual=$($services.Count)"
    )
}

if ($traceFiles.Count -ne $expectedTraceFiles.Count) {
    $failures.Add(
        "trace_file_count_mismatch:metadata=$($expectedTraceFiles.Count):actual=$($traceFiles.Count)"
    )
}

$expectedTracePaths = @(
    $expectedTraceFiles |
        ForEach-Object { ([string]$_.path).Replace('\', '/') }
)

foreach ($summary in $expectedTraceFiles) {
    $summaryPath = ([string]$summary.path).Replace('\', '/')
    $summaryService = [string]$summary.service

    if ($traceSummaryByPath.ContainsKey($summaryPath)) {
        $failures.Add("duplicate_trace_summary_path:$summaryPath")
        continue
    }

    if ($services -notcontains $summaryService) {
        $failures.Add(
            "unexpected_trace_summary_service:$summaryService"
        )
    }

    $traceSummaryByPath[$summaryPath] = $summary
}

foreach ($traceFile in $traceFiles) {
    $relativePath = $traceFile.FullName.
        Substring($resolvedTelemetry.Length + 1).
        Replace('\', '/')

    if ($expectedTracePaths -notcontains $relativePath) {
        $failures.Add("unexpected_trace_file:$relativePath")
    }

    $traceResponse = Get-Content -LiteralPath $traceFile.FullName -Raw |
        ConvertFrom-Json
    $traces = @($traceResponse.data)
    $traceResponseCount += $traces.Count

    if (
        $traceSummaryByPath.ContainsKey($relativePath) -and
        $traces.Count -ne
        [int]$traceSummaryByPath[$relativePath].returned_trace_count
    ) {
        $failures.Add(
            "trace_file_count_summary_mismatch:$relativePath"
        )
    }

    foreach ($trace in $traces) {
        $traceId = [string]$trace.traceID

        if ([string]::IsNullOrWhiteSpace($traceId)) {
            $failures.Add("trace_id_missing:$relativePath")
            continue
        }

        if (-not $rawUniqueTraces.ContainsKey($traceId)) {
            $rawUniqueTraces[$traceId] = $trace
        }
    }
}

$traceChunkCoverageFailureCount = [int64]0

if ($schemaVersion -eq 3) {
    $chunkSeconds = [int64]$metadata.trace_query_chunk_seconds
    $chunkLimitMicroseconds = $chunkSeconds * 1000000

    if ($chunkSeconds -lt 30 -or $chunkSeconds -gt 3600) {
        $failures.Add("trace_query_chunk_seconds_invalid:$chunkSeconds")
    }

    if ($expectedTraceFiles.Count -ne [int]$metadata.trace_chunk_count) {
        $failures.Add(
            "trace_chunk_count_mismatch:metadata=$($metadata.trace_chunk_count):actual=$($expectedTraceFiles.Count)"
        )
    }

    foreach ($service in $services) {
        $serviceName = [string]$service
        $serviceChunks = @(
            $expectedTraceFiles |
                Where-Object { [string]$_.service -eq $serviceName } |
                Sort-Object { [int]$_.chunk_index }
        )

        if ($serviceChunks.Count -eq 0) {
            $failures.Add("trace_chunks_missing_for_service:$serviceName")
            $traceChunkCoverageFailureCount++
            continue
        }

        $expectedChunkStart = $startMicroseconds
        $expectedChunkIndex = 0

        foreach ($chunk in $serviceChunks) {
            $chunkIndex = [int]$chunk.chunk_index
            $chunkStart = [int64]$chunk.start_microseconds
            $chunkEnd = [int64]$chunk.end_microseconds
            $chunkWidth = $chunkEnd - $chunkStart + 1

            if ($chunkIndex -ne $expectedChunkIndex) {
                $failures.Add(
                    "trace_chunk_index_gap:$serviceName:expected=$expectedChunkIndex:actual=$chunkIndex"
                )
                $traceChunkCoverageFailureCount++
            }

            if ($chunkStart -ne $expectedChunkStart) {
                $failures.Add(
                    "trace_chunk_time_gap:$serviceName:expected=$expectedChunkStart:actual=$chunkStart"
                )
                $traceChunkCoverageFailureCount++
            }

            if (
                $chunkEnd -lt $chunkStart -or
                $chunkEnd -gt $endMicroseconds -or
                $chunkWidth -gt ($chunkLimitMicroseconds + 1)
            ) {
                $failures.Add(
                    "trace_chunk_bounds_invalid:$serviceName:index=$chunkIndex"
                )
                $traceChunkCoverageFailureCount++
            }

            if (
                [int]$chunk.returned_trace_count -ge
                [int]$metadata.trace_limit_per_service
            ) {
                $failures.Add(
                    "trace_chunk_limit_reached:$serviceName:index=$chunkIndex"
                )
            }

            $expectedChunkStart = $chunkEnd + 1
            $expectedChunkIndex++
        }

        if ($expectedChunkStart -ne $endMicroseconds + 1) {
            $failures.Add(
                "trace_chunk_coverage_incomplete:$serviceName"
            )
            $traceChunkCoverageFailureCount++
        }
    }
}

$traceRunIdMismatchCount = [int64]0
$rawBoundaryExcludedTraceCount = [int64]0

foreach ($traceId in $rawUniqueTraces.Keys) {
    $trace = $rawUniqueTraces[$traceId]
    $traceCrossesBoundary = $false

    foreach ($processProperty in $trace.processes.PSObject.Properties) {
        $process = $processProperty.Value
        $runTag = @(
            $process.tags |
                Where-Object { [string]$_.key -eq 'experiment.run_id' }
        )

        if (
            $runTag.Count -ne 1 -or
            [string]$runTag[0].value -ne $runId
        ) {
            $traceRunIdMismatchCount++
        }
    }

    foreach ($span in @($trace.spans)) {
        $spanStartMicroseconds = [int64]$span.startTime
        $spanEndMicroseconds = (
            $spanStartMicroseconds + [int64]$span.duration
        )

        if (
            $spanStartMicroseconds -lt $startMicroseconds -or
            $spanEndMicroseconds -gt $endMicroseconds
        ) {
            $traceCrossesBoundary = $true
            break
        }
    }

    if ($traceCrossesBoundary) {
        $rawBoundaryExcludedTraceCount++
    }
}

$selectedTraceIds = @{}
$selectedTraceCount = [int64]0
$selectedSpanCount = [int64]0
$selectedTraceJsonFailureCount = [int64]0
$traceTimeFailureCount = [int64]0

if ($schemaVersion -ge 2) {
    $reader = New-Object System.IO.StreamReader(
        $selectedTracePath,
        [System.Text.Encoding]::UTF8,
        $true
    )

    try {
        while (($line = $reader.ReadLine()) -ne $null) {
            $trace = $null

            try {
                $trace = $line | ConvertFrom-Json
            }
            catch {
                $selectedTraceJsonFailureCount++
                continue
            }

            $traceId = [string]$trace.traceID

            if ([string]::IsNullOrWhiteSpace($traceId)) {
                $failures.Add('selected_trace_id_missing')
                continue
            }

            if ($selectedTraceIds.ContainsKey($traceId)) {
                $failures.Add("selected_trace_id_duplicate:$traceId")
                continue
            }

            $selectedTraceIds[$traceId] = $true
            $selectedTraceCount++

            foreach ($processProperty in $trace.processes.PSObject.Properties) {
                $process = $processProperty.Value
                $runTag = @(
                    $process.tags |
                        Where-Object {
                            [string]$_.key -eq 'experiment.run_id'
                        }
                )

                if (
                    $runTag.Count -ne 1 -or
                    [string]$runTag[0].value -ne $runId
                ) {
                    $traceRunIdMismatchCount++
                }
            }

            foreach ($span in @($trace.spans)) {
                $selectedSpanCount++
                $spanStartMicroseconds = [int64]$span.startTime
                $spanEndMicroseconds = (
                    $spanStartMicroseconds + [int64]$span.duration
                )

                if (
                    $spanStartMicroseconds -lt $startMicroseconds -or
                    $spanEndMicroseconds -gt $endMicroseconds
                ) {
                    $traceTimeFailureCount++
                }
            }
        }
    }
    finally {
        $reader.Dispose()
    }
}
else {
    foreach ($traceId in $rawUniqueTraces.Keys) {
        $trace = $rawUniqueTraces[$traceId]
        $selectedTraceIds[$traceId] = $true
        $selectedTraceCount++

        foreach ($processProperty in $trace.processes.PSObject.Properties) {
            $process = $processProperty.Value
            $runTag = @(
                $process.tags |
                    Where-Object { [string]$_.key -eq 'experiment.run_id' }
            )

            if (
                $runTag.Count -ne 1 -or
                [string]$runTag[0].value -ne $runId
            ) {
                $traceRunIdMismatchCount++
            }
        }

        foreach ($span in @($trace.spans)) {
            $selectedSpanCount++
            $spanStartMicroseconds = [int64]$span.startTime
            $spanEndMicroseconds = (
                $spanStartMicroseconds + [int64]$span.duration
            )

            if (
                $spanStartMicroseconds -lt $startMicroseconds -or
                $spanEndMicroseconds -gt $endMicroseconds
            ) {
                $traceTimeFailureCount++
            }
        }
    }
}

if ($rawUniqueTraces.Count -eq 0) {
    $failures.Add('trace_data_missing')
}

if ($selectedTraceCount -eq 0 -or $selectedSpanCount -eq 0) {
    $failures.Add('selected_trace_data_missing')
}

if ($selectedTraceJsonFailureCount -gt 0) {
    $failures.Add(
        "selected_trace_json_failure_count:$selectedTraceJsonFailureCount"
    )
}

if ($traceRunIdMismatchCount -gt 0) {
    $failures.Add("trace_run_id_mismatch_count:$traceRunIdMismatchCount")
}

if ($traceTimeFailureCount -gt 0) {
    $failures.Add("trace_time_failure_count:$traceTimeFailureCount")
}

if ($traceResponseCount -ne [int64]$metadata.trace_response_count) {
    $failures.Add(
        "trace_response_count_mismatch:metadata=$($metadata.trace_response_count):actual=$traceResponseCount"
    )
}

if ($selectedTraceCount -ne [int]$metadata.unique_trace_count) {
    $failures.Add(
        "unique_trace_count_mismatch:metadata=$($metadata.unique_trace_count):actual=$selectedTraceCount"
    )
}

if ($schemaVersion -ge 2) {
    if ($rawUniqueTraces.Count -ne [int]$metadata.raw_unique_trace_count) {
        $failures.Add(
            "raw_unique_trace_count_mismatch:metadata=$($metadata.raw_unique_trace_count):actual=$($rawUniqueTraces.Count)"
        )
    }

    if ($selectedSpanCount -ne [int64]$metadata.selected_span_count) {
        $failures.Add(
            "selected_span_count_mismatch:metadata=$($metadata.selected_span_count):actual=$selectedSpanCount"
        )
    }

    if (
        $rawBoundaryExcludedTraceCount -ne
        [int64]$metadata.boundary_excluded_trace_count
    ) {
        $failures.Add(
            "boundary_excluded_trace_count_mismatch:metadata=$($metadata.boundary_excluded_trace_count):actual=$rawBoundaryExcludedTraceCount"
        )
    }
}

Write-Output "telemetry_path=$resolvedTelemetry"
Write-Output "run_id=$runId"
Write-Output "schema_version=$schemaVersion"
Write-Output "manifest_file_count=$($manifest.files.Count)"
Write-Output "verified_manifest_file_count=$verifiedManifestFileCount"
Write-Output "readonly_file_count=$($readOnlyFiles.Count)"
Write-Output "metric_series_count=$($metricSeries.Count)"
Write-Output "metric_sample_count=$metricSampleCount"
Write-Output "metric_run_id_mismatch_count=$metricRunIdMismatchCount"
Write-Output "metric_time_failure_count=$metricTimeFailureCount"
Write-Output "jaeger_service_count=$($services.Count)"
Write-Output "trace_file_count=$($traceFiles.Count)"
if ($schemaVersion -eq 3) {
    Write-Output "trace_query_chunk_seconds=$($metadata.trace_query_chunk_seconds)"
    Write-Output "trace_chunk_count=$($expectedTraceFiles.Count)"
}
Write-Output "trace_response_count=$traceResponseCount"
Write-Output "raw_unique_trace_count=$($rawUniqueTraces.Count)"
Write-Output "unique_trace_count=$selectedTraceCount"
Write-Output "span_count=$selectedSpanCount"
Write-Output "boundary_excluded_trace_count=$rawBoundaryExcludedTraceCount"
Write-Output "selected_trace_json_failure_count=$selectedTraceJsonFailureCount"
Write-Output "trace_run_id_mismatch_count=$traceRunIdMismatchCount"
Write-Output "trace_time_failure_count=$traceTimeFailureCount"
Write-Output "trace_chunk_coverage_failure_count=$traceChunkCoverageFailureCount"
Write-Output "failure_count=$($failures.Count)"

if ($failures.Count -gt 0) {
    $failures |
        Select-Object -First 100 |
        ForEach-Object { Write-Output "failure=$_" }

    if ($failures.Count -gt 100) {
        Write-Output "failure=truncated:$($failures.Count - 100)_additional"
    }

    throw 'Run telemetry verification failed.'
}

Write-Output 'run_telemetry_verification=passed'

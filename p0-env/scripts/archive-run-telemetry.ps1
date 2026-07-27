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

    [ValidateRange(1, 60)]
    [int]$MetricStepSeconds = 5,

    [ValidateRange(1, 10000)]
    [int]$TraceLimitPerService = 5000,

    [string]$Namespace = 'online-boutique',

    [string]$Profile = 'p0-online-boutique',

    [string]$OutputRoot
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'env.ps1')

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

function Convert-ToUtcValue {
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
        )
    }
    catch {
        throw "$Name must be a valid UTC ISO-8601 value ending in Z: $Value"
    }
}

function Invoke-KubernetesRaw {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RequestPath
    )

    $response = & minikube kubectl --profile $Profile -- `
        get --raw $RequestPath 2>&1

    if ($LASTEXITCODE -ne 0) {
        throw "Kubernetes service-proxy request failed: $RequestPath :: $($response -join ' | ')"
    }

    return ($response | Out-String).TrimEnd("`r", "`n")
}

function Get-SafeFileName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    $safe = $Value -replace '[^a-zA-Z0-9._-]', '_'

    if ([string]::IsNullOrWhiteSpace($safe)) {
        throw "Could not derive a safe filename from: $Value"
    }

    return $safe
}

if ([string]::IsNullOrWhiteSpace($OutputRoot)) {
    $resolvedOutputRoot = [System.IO.Path]::GetFullPath(
        (Join-Path $PSScriptRoot '..\artifacts\telemetry')
    )
}
else {
    $resolvedOutputRoot = [System.IO.Path]::GetFullPath($OutputRoot)
}

$outputDirectory = Join-Path $resolvedOutputRoot $RunId
$metricDirectory = Join-Path $outputDirectory 'raw\metrics'
$traceDirectory = Join-Path $outputDirectory 'raw\traces'
$selectedTraceDirectory = Join-Path $outputDirectory 'selected'

if (Test-Path -LiteralPath $outputDirectory) {
    throw "Telemetry archive already exists and will not be overwritten: $outputDirectory"
}

$startValue = Convert-ToUtcValue -Value $StartUtc -Name 'StartUtc'
$endValue = Convert-ToUtcValue -Value $EndUtc -Name 'EndUtc'
$captureStartedUtc = [datetimeoffset]::UtcNow

if ($startValue -ge $endValue) {
    throw 'StartUtc must be earlier than EndUtc.'
}

if ($endValue -gt $captureStartedUtc) {
    throw 'EndUtc cannot be in the future.'
}

$startNormalized = $startValue.ToString(
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [System.Globalization.CultureInfo]::InvariantCulture
)
$endNormalized = $endValue.ToString(
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [System.Globalization.CultureInfo]::InvariantCulture
)

$clusterStatus = (& minikube status --profile $Profile 2>&1 | Out-String).Trim()

if ($LASTEXITCODE -ne 0 -or $clusterStatus -notmatch 'host:\s+Running') {
    throw "Minikube profile is not running: $Profile"
}

$deploymentsJson = & minikube kubectl --profile $Profile -- `
    -n $Namespace get deployments -o json

if ($LASTEXITCODE -ne 0) {
    throw 'Could not inspect deployment run IDs.'
}

$deployments = $deploymentsJson | ConvertFrom-Json
$configuredRunIds = @(
    foreach ($deployment in $deployments.items) {
        foreach ($container in $deployment.spec.template.spec.containers) {
            if ($container.PSObject.Properties.Name -notcontains 'env') {
                continue
            }

            $runIdVariable = $container.env |
                Where-Object { $_.name -eq 'EXPERIMENT_RUN_ID' }

            if ($null -ne $runIdVariable -and $null -ne $runIdVariable.value) {
                [string]$runIdVariable.value
            }
        }
    }
)

$uniqueConfiguredRunIds = @(
    $configuredRunIds |
        Where-Object { -not [string]::IsNullOrWhiteSpace($_) } |
        Sort-Object -Unique
)

if ($uniqueConfiguredRunIds.Count -ne 1) {
    throw "Expected exactly one configured experiment run ID; found: $($uniqueConfiguredRunIds -join ', ')"
}

if ($uniqueConfiguredRunIds[0] -ne $RunId) {
    throw "Requested run ID '$RunId' does not match deployed run ID '$($uniqueConfiguredRunIds[0])'."
}

New-Item -ItemType Directory -Path $metricDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $traceDirectory -Force | Out-Null
New-Item -ItemType Directory -Path $selectedTraceDirectory -Force | Out-Null

try {
    $prometheusQuery = '{experiment_run_id="' + $RunId + '"}'
    $prometheusPath = (
        '/api/v1/namespaces/{0}/services/http:prometheus:9090/proxy/api/v1/query_range' -f
        $Namespace
    )
    $prometheusPath += '?query=' + [uri]::EscapeDataString($prometheusQuery)
    $prometheusPath += '&start=' + [uri]::EscapeDataString($startNormalized)
    $prometheusPath += '&end=' + [uri]::EscapeDataString($endNormalized)
    $prometheusPath += '&step=' + $MetricStepSeconds

    $prometheusRaw = Invoke-KubernetesRaw -RequestPath $prometheusPath
    $prometheusResponse = $prometheusRaw | ConvertFrom-Json

    if ([string]$prometheusResponse.status -ne 'success') {
        throw 'Prometheus query_range response was not successful.'
    }

    if ([string]$prometheusResponse.data.resultType -ne 'matrix') {
        throw "Unexpected Prometheus result type: $($prometheusResponse.data.resultType)"
    }

    $metricSeries = @($prometheusResponse.data.result)
    $metricSampleCount = [int64]0

    foreach ($series in $metricSeries) {
        if ([string]$series.metric.experiment_run_id -ne $RunId) {
            throw 'Prometheus response contains a mismatched experiment_run_id.'
        }

        $metricSampleCount += @($series.values).Count
    }

    if ($metricSeries.Count -eq 0 -or $metricSampleCount -eq 0) {
        throw 'Prometheus response does not contain run-scoped metric samples.'
    }

    $prometheusFile = Join-Path $metricDirectory 'prometheus-query-range.json'
    Write-Utf8NoBom -Path $prometheusFile -Content $prometheusRaw

    $jaegerBasePath = (
        '/api/v1/namespaces/{0}/services/http:jaeger:16686/proxy' -f
        $Namespace
    )
    $servicesRaw = Invoke-KubernetesRaw -RequestPath "$jaegerBasePath/api/services"
    $servicesResponse = $servicesRaw | ConvertFrom-Json

    if ($servicesResponse.PSObject.Properties.Name -notcontains 'data') {
        throw 'Jaeger services response does not contain data.'
    }

    $services = @(
        $servicesResponse.data |
            Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } |
            Sort-Object -Unique
    )

    if ($services.Count -eq 0) {
        throw 'Jaeger does not contain any services.'
    }

    $servicesFile = Join-Path $traceDirectory 'jaeger-services.json'
    Write-Utf8NoBom -Path $servicesFile -Content $servicesRaw

    $startMicroseconds = [int64](
        $startValue.ToUnixTimeMilliseconds() * 1000
    )
    $endMicroseconds = [int64](
        $endValue.ToUnixTimeMilliseconds() * 1000
    )
    $traceTags = [ordered]@{
        'experiment.run_id' = $RunId
    } | ConvertTo-Json -Compress

    $traceFileSummaries = New-Object System.Collections.Generic.List[object]
    $uniqueTraceIds = @{}
    $uniqueTraces = @{}
    $totalReturnedTraceCount = [int64]0

    foreach ($service in $services) {
        $serviceName = [string]$service
        $tracePath = "$jaegerBasePath/api/traces"
        $tracePath += '?service=' + [uri]::EscapeDataString($serviceName)
        $tracePath += '&start=' + $startMicroseconds
        $tracePath += '&end=' + $endMicroseconds
        $tracePath += '&limit=' + $TraceLimitPerService
        $tracePath += '&tags=' + [uri]::EscapeDataString($traceTags)

        $traceRaw = Invoke-KubernetesRaw -RequestPath $tracePath
        $traceResponse = $traceRaw | ConvertFrom-Json
        $traces = @($traceResponse.data)

        if ($traces.Count -ge $TraceLimitPerService) {
            throw "Jaeger trace limit reached for service '$serviceName'; archive would be truncated."
        }

        foreach ($trace in $traces) {
            $traceId = [string]$trace.traceID

            if ([string]::IsNullOrWhiteSpace($traceId)) {
                throw "Jaeger returned a trace without traceID for service '$serviceName'."
            }

            $uniqueTraceIds[$traceId] = $true

            if (-not $uniqueTraces.ContainsKey($traceId)) {
                $uniqueTraces[$traceId] = $trace
            }
        }

        $totalReturnedTraceCount += $traces.Count
        $safeServiceName = Get-SafeFileName -Value $serviceName
        $relativePath = "raw/traces/service-$safeServiceName.json"
        $traceFile = Join-Path $outputDirectory $relativePath
        Write-Utf8NoBom -Path $traceFile -Content $traceRaw

        $traceFileSummaries.Add(
            [ordered]@{
                service              = $serviceName
                path                 = $relativePath
                returned_trace_count = $traces.Count
            }
        )
    }

    if ($uniqueTraceIds.Count -eq 0) {
        throw 'Jaeger responses do not contain run-scoped traces.'
    }

    $selectedTracePath = Join-Path `
        $selectedTraceDirectory `
        'traces.ndjson'
    $selectedTraceWriter = New-Object System.IO.StreamWriter(
        $selectedTracePath,
        $false,
        (New-Object System.Text.UTF8Encoding($false))
    )
    $selectedTraceCount = [int64]0
    $selectedSpanCount = [int64]0
    $boundaryExcludedTraceCount = [int64]0

    try {
        foreach ($traceId in ($uniqueTraces.Keys | Sort-Object)) {
            $trace = $uniqueTraces[$traceId]
            $traceCrossesBoundary = $false

            foreach ($processProperty in $trace.processes.PSObject.Properties) {
                $process = $processProperty.Value
                $runTags = @(
                    $process.tags |
                        Where-Object {
                            [string]$_.key -eq 'experiment.run_id'
                        }
                )

                if (
                    $runTags.Count -ne 1 -or
                    [string]$runTags[0].value -ne $RunId
                ) {
                    throw "Trace process run ID mismatch: $traceId"
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
                $boundaryExcludedTraceCount++
                continue
            }

            $selectedTraceWriter.WriteLine(
                ($trace | ConvertTo-Json -Compress -Depth 100)
            )
            $selectedTraceCount++
            $selectedSpanCount += @($trace.spans).Count
        }
    }
    finally {
        $selectedTraceWriter.Dispose()
    }

    if ($selectedTraceCount -eq 0 -or $selectedSpanCount -eq 0) {
        throw 'No complete in-window traces remain after boundary filtering.'
    }

    $captureCompletedUtc = [datetimeoffset]::UtcNow
    $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $codeRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw 'Could not determine Git code revision.'
    }

    $configRoot = Join-Path $PSScriptRoot '..\config'
    $configFiles = Get-ChildItem -LiteralPath $configRoot -File -Recurse |
        Sort-Object FullName

    $configHashes = @(
        foreach ($file in $configFiles) {
            [ordered]@{
                path = $file.FullName.
                    Substring($repositoryRoot.Length + 1).
                    Replace('\', '/')
                sha256 = (
                    Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256
                ).Hash.ToLowerInvariant()
            }
        }
    )

    $metadata = [ordered]@{
        schema_version             = 2
        run_id                     = $RunId
        system                     = 'online-boutique'
        namespace                  = $Namespace
        minikube_profile           = $Profile
        code_revision              = $codeRevision
        start_utc                  = $startNormalized
        end_utc                    = $endNormalized
        capture_started_utc        = $captureStartedUtc.ToString('o')
        capture_completed_utc      = $captureCompletedUtc.ToString('o')
        prometheus_query           = $prometheusQuery
        metric_step_seconds        = $MetricStepSeconds
        metric_series_count        = $metricSeries.Count
        metric_sample_count        = $metricSampleCount
        trace_limit_per_service    = $TraceLimitPerService
        jaeger_service_count       = $services.Count
        trace_response_count       = $totalReturnedTraceCount
        raw_unique_trace_count     = $uniqueTraceIds.Count
        unique_trace_count         = $selectedTraceCount
        selected_span_count        = $selectedSpanCount
        boundary_excluded_trace_count = $boundaryExcludedTraceCount
        trace_selection_policy     = 'retain only complete traces whose every span is inside [start_utc, end_utc]'
        selected_trace_file        = 'selected/traces.ndjson'
        trace_files                = $traceFileSummaries.ToArray()
        overwrite_policy           = 'deny'
        protection                 = 'SHA-256 manifest plus Windows read-only attribute'
        config_files               = $configHashes
    }

    $metadataPath = Join-Path $outputDirectory 'metadata.json'
    Write-Utf8NoBom `
        -Path $metadataPath `
        -Content ($metadata | ConvertTo-Json -Depth 10)

    $manifestEntries = @(
        Get-ChildItem -LiteralPath $outputDirectory -File -Recurse |
            Sort-Object FullName |
            ForEach-Object {
                [ordered]@{
                    path = $_.FullName.
                        Substring($outputDirectory.Length + 1).
                        Replace('\', '/')
                    bytes = $_.Length
                    sha256 = (
                        Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256
                    ).Hash.ToLowerInvariant()
                }
            }
    )

    $manifest = [ordered]@{
        algorithm      = 'SHA-256'
        schema_version = 2
        run_id         = $RunId
        created_utc    = [datetimeoffset]::UtcNow.ToString('o')
        files          = $manifestEntries
    }

    $manifestPath = Join-Path $outputDirectory 'sha256-manifest.json'
    Write-Utf8NoBom `
        -Path $manifestPath `
        -Content ($manifest | ConvertTo-Json -Depth 6)

    Get-ChildItem -LiteralPath $outputDirectory -File -Recurse |
        ForEach-Object { $_.IsReadOnly = $true }

    Write-Output "telemetry_path=$outputDirectory"
    Write-Output "run_id=$RunId"
    Write-Output "metric_series_count=$($metricSeries.Count)"
    Write-Output "metric_sample_count=$metricSampleCount"
    Write-Output "jaeger_service_count=$($services.Count)"
    Write-Output "raw_unique_trace_count=$($uniqueTraceIds.Count)"
    Write-Output "unique_trace_count=$selectedTraceCount"
    Write-Output "selected_span_count=$selectedSpanCount"
    Write-Output "boundary_excluded_trace_count=$boundaryExcludedTraceCount"
    Write-Output "manifest_file_count=$($manifestEntries.Count)"
    Write-Output 'telemetry_archive_status=sealed-read-only'
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
                schema_version = 1
                run_id         = $RunId
                status         = 'invalid'
                failed_utc     = [datetimeoffset]::UtcNow.ToString('o')
                error          = $originalError.Exception.Message
            }

            Write-Utf8NoBom `
                -Path (Join-Path $outputDirectory 'capture-error.json') `
                -Content ($failureRecord | ConvertTo-Json -Depth 4)

            Get-ChildItem -LiteralPath $outputDirectory -File -Recurse |
                ForEach-Object { $_.IsReadOnly = $true }

            $invalidName = '{0}-telemetry-capture-failed-{1}' -f `
                $RunId, `
                ([datetimeoffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
            $invalidDirectory = Join-Path $invalidRoot $invalidName

            Move-Item `
                -LiteralPath $outputDirectory `
                -Destination $invalidDirectory

            Write-Warning "Partial telemetry archive preserved as invalid: $invalidDirectory"
        }
        catch {
            Write-Warning "Could not finalize invalid telemetry archive: $($_.Exception.Message)"
            Write-Warning "Partial files remain at: $outputDirectory"
        }
    }

    throw $originalError
}

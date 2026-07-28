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

    [ValidateRange(1, 10000)]
    [int]$TraceLimitPerService = 5000,

    [ValidateRange(30, 3600)]
    [int]$TraceQueryChunkSeconds = 300
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-RunStep {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$ScriptPath,

        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    Write-Output "step_started=$Name"

    $previousErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'

    try {
        $output = & powershell `
            -NoProfile `
            -ExecutionPolicy Bypass `
            -File $ScriptPath `
            @Arguments 2>&1
        $stepExitCode = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = $previousErrorActionPreference
    }

    $output | ForEach-Object { Write-Output ([string]$_) }

    if ($stepExitCode -ne 0) {
        $invalidRoot = Join-Path $artifactRoot 'finalized\_invalid'
        New-Item -ItemType Directory -Path $invalidRoot -Force |
            Out-Null

        $invalidName = '{0}-close-failed-{1}' -f `
            $RunId, `
            ([datetimeoffset]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))
        $invalidDirectory = Join-Path $invalidRoot $invalidName
        New-Item -ItemType Directory -Path $invalidDirectory -Force |
            Out-Null

        $failureRecord = [ordered]@{
            schema_version = 1
            run_id         = $RunId
            status         = 'invalid'
            failed_step    = $Name
            failed_utc     = [datetimeoffset]::UtcNow.ToString('o')
            start_utc      = $StartUtc
            end_utc        = $EndUtc
            trace_limit_per_service = $TraceLimitPerService
            trace_query_chunk_seconds = $TraceQueryChunkSeconds
            child_exit_code = $stepExitCode
            child_output   = @(
                $output |
                    Select-Object -Last 100 |
                    ForEach-Object { [string]$_ }
            )
            existing_outputs = [ordered]@{
                raw_logs = Test-Path -LiteralPath $rawArchive
                enriched_logs = Test-Path -LiteralPath $derivedArchive
                telemetry = Test-Path -LiteralPath $telemetryArchive
                finalized_receipt = Test-Path -LiteralPath $receiptDirectory
            }
        }

        $failurePath = Join-Path `
            $invalidDirectory `
            'close-run-error.json'
        [System.IO.File]::WriteAllText(
            $failurePath,
            ($failureRecord | ConvertTo-Json -Depth 8),
            (New-Object System.Text.UTF8Encoding($false))
        )
        (Get-Item -LiteralPath $failurePath).IsReadOnly = $true

        Write-Warning "Failed run close receipt preserved as invalid: $invalidDirectory"
        throw "Run close step failed: $Name"
    }

    Write-Output "step_passed=$Name"
}

$artifactRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\artifacts')
)
$rawArchive = Join-Path $artifactRoot "runs\$RunId"
$derivedArchive = Join-Path $artifactRoot "derived\$RunId"
$telemetryArchive = Join-Path $artifactRoot "telemetry\$RunId"
$receiptDirectory = Join-Path $artifactRoot "finalized\$RunId"

foreach ($path in @(
    $rawArchive,
    $derivedArchive,
    $telemetryArchive,
    $receiptDirectory
)) {
    if (Test-Path -LiteralPath $path) {
        throw "Run close requires fresh output paths; already exists: $path"
    }
}

Invoke-RunStep `
    -Name 'archive_raw_logs' `
    -ScriptPath (Join-Path $PSScriptRoot 'archive-raw-logs.ps1') `
    -Arguments @(
        '-RunId', $RunId,
        '-SinceUtc', $StartUtc,
        '-UntilUtc', $EndUtc
    )

Invoke-RunStep `
    -Name 'verify_raw_logs' `
    -ScriptPath (Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1') `
    -Arguments @(
        '-ArchivePath', $rawArchive
    )

Invoke-RunStep `
    -Name 'enrich_logs' `
    -ScriptPath (Join-Path $PSScriptRoot 'enrich-log-run-id.ps1') `
    -Arguments @(
        '-ArchivePath', $rawArchive
    )

Invoke-RunStep `
    -Name 'verify_enriched_logs' `
    -ScriptPath (Join-Path $PSScriptRoot 'verify-enriched-logs.ps1') `
    -Arguments @(
        '-DerivedPath', $derivedArchive
    )

Invoke-RunStep `
    -Name 'archive_metrics_and_traces' `
    -ScriptPath (Join-Path $PSScriptRoot 'archive-run-telemetry.ps1') `
    -Arguments @(
        '-RunId', $RunId,
        '-StartUtc', $StartUtc,
        '-EndUtc', $EndUtc,
        '-TraceLimitPerService', $TraceLimitPerService,
        '-TraceQueryChunkSeconds', $TraceQueryChunkSeconds
    )

Invoke-RunStep `
    -Name 'verify_metrics_and_traces' `
    -ScriptPath (Join-Path $PSScriptRoot 'verify-run-telemetry.ps1') `
    -Arguments @(
        '-TelemetryPath', $telemetryArchive
    )

Invoke-RunStep `
    -Name 'finalize_receipt' `
    -ScriptPath (Join-Path $PSScriptRoot 'finalize-run-artifacts.ps1') `
    -Arguments @(
        '-RunId', $RunId,
        '-StartUtc', $StartUtc,
        '-EndUtc', $EndUtc
    )

Invoke-RunStep `
    -Name 'verify_finalized_run' `
    -ScriptPath (Join-Path $PSScriptRoot 'verify-finalized-run.ps1') `
    -Arguments @(
        '-ReceiptPath', $receiptDirectory
    )

Write-Output "run_id=$RunId"
Write-Output "start_utc=$StartUtc"
Write-Output "end_utc=$EndUtc"
Write-Output "trace_limit_per_service=$TraceLimitPerService"
Write-Output "trace_query_chunk_seconds=$TraceQueryChunkSeconds"
Write-Output 'close_run=passed'

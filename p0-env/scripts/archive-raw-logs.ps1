[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$RunId,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$')]
    [string]$SinceUtc,

    [ValidatePattern('^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$')]
    [string]$UntilUtc,

    [string]$Namespace = 'online-boutique',

    [string]$Profile = 'p0-online-boutique'
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

    $encoding = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $encoding)
}

$artifactRoot = [System.IO.Path]::GetFullPath(
    (Join-Path $PSScriptRoot '..\artifacts\runs')
)
$runDirectory = Join-Path $artifactRoot $RunId
$rawLogDirectory = Join-Path $runDirectory 'raw\logs'

if (Test-Path -LiteralPath $runDirectory) {
    throw "Archive already exists and will not be overwritten: $runDirectory"
}

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


$captureStartedUtc = [datetimeoffset]::UtcNow

try {
    $sinceUtcValue = [datetimeoffset]::Parse(
        $SinceUtc,
        [System.Globalization.CultureInfo]::InvariantCulture,
        (
            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
            [System.Globalization.DateTimeStyles]::AdjustToUniversal
        )
    )
}
catch {
    throw "SinceUtc must be a valid UTC ISO-8601 value ending in Z: $SinceUtc"
}

if ($sinceUtcValue -gt $captureStartedUtc) {
    throw "SinceUtc cannot be in the future: $SinceUtc"
}

$sinceUtcNormalized = $sinceUtcValue.ToString(
    'yyyy-MM-ddTHH:mm:ss.fffZ',
    [System.Globalization.CultureInfo]::InvariantCulture
)

$untilUtcValue = $null
$untilUtcNormalized = $null

if (-not [string]::IsNullOrWhiteSpace($UntilUtc)) {
    try {
        $untilUtcValue = [datetimeoffset]::Parse(
            $UntilUtc,
            [System.Globalization.CultureInfo]::InvariantCulture,
            (
                [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                [System.Globalization.DateTimeStyles]::AdjustToUniversal
            )
        )
    }
    catch {
        throw "UntilUtc must be a valid UTC ISO-8601 value ending in Z: $UntilUtc"
    }

    if ($untilUtcValue -le $sinceUtcValue) {
        throw 'UntilUtc must be later than SinceUtc.'
    }

    if ($untilUtcValue -gt $captureStartedUtc) {
        throw 'UntilUtc cannot be in the future.'
    }

    $untilUtcNormalized = $untilUtcValue.ToString(
        'yyyy-MM-ddTHH:mm:ss.fffZ',
        [System.Globalization.CultureInfo]::InvariantCulture
    )
}

New-Item -ItemType Directory -Path $rawLogDirectory -Force | Out-Null

try {
    $podsJson = & minikube kubectl --profile $Profile -- `
        -n $Namespace get pods -o json

    if ($LASTEXITCODE -ne 0) {
        throw 'Could not list Kubernetes pods.'
    }

    $pods = $podsJson | ConvertFrom-Json

    foreach ($pod in ($pods.items | Sort-Object { $_.metadata.name })) {
        foreach ($container in ($pod.spec.containers | Sort-Object name)) {
            $podName = [string]$pod.metadata.name
            $containerName = [string]$container.name
            $safeFileName = '{0}__{1}.log' -f $podName, $containerName
            $logPath = Join-Path $rawLogDirectory $safeFileName

            $logOutput = & minikube kubectl --profile $Profile -- `
                -n $Namespace logs $podName `
                -c $containerName `
                --timestamps=true `
                --since-time=$sinceUtcNormalized 2>&1

            if ($LASTEXITCODE -ne 0) {
                throw "Log collection failed for $podName/$containerName"
            }

            $logLines = @(
                $logOutput |
                    ForEach-Object { [string]$_ }
            )

            if ($null -ne $untilUtcValue) {
                $filteredLogLines = New-Object System.Collections.Generic.List[string]

                foreach ($logLine in $logLines) {
                    if ($logLine -notmatch '^(?<timestamp>\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,9})?Z)(?:\s|$)') {
                        throw "Log line does not contain a Kubernetes UTC prefix: $podName/$containerName"
                    }

                    $lineTimestamp = [datetimeoffset]::Parse(
                        [string]$Matches.timestamp,
                        [System.Globalization.CultureInfo]::InvariantCulture,
                        (
                            [System.Globalization.DateTimeStyles]::AssumeUniversal -bor
                            [System.Globalization.DateTimeStyles]::AdjustToUniversal
                        )
                    )

                    if (
                        $lineTimestamp -ge $sinceUtcValue -and
                        $lineTimestamp -le $untilUtcValue
                    ) {
                        $filteredLogLines.Add($logLine)
                    }
                }

                $logLines = $filteredLogLines.ToArray()
            }

            $logText = ($logLines -join [Environment]::NewLine).
                TrimEnd("`r", "`n")

            if ([string]::IsNullOrEmpty($logText)) {
                $logContent = ''
            }
            else {
                $logContent = $logText + [Environment]::NewLine
            }

            Write-Utf8NoBom `
                -Path $logPath `
                -Content $logContent
	    }
    }

    $captureCompletedUtc = [datetime]::UtcNow
    $repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
    $codeRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()

    if ($LASTEXITCODE -ne 0) {
        throw 'Could not determine Git code revision.'
    }

    $configRoot = Join-Path $PSScriptRoot '..\config'
    $configFiles = Get-ChildItem -LiteralPath $configRoot -File -Recurse |
        Sort-Object FullName

    $configHashes = foreach ($file in $configFiles) {
        [ordered]@{
            path   = $file.FullName.Substring($repositoryRoot.Length + 1).Replace('\', '/')
            sha256 = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    }

    $deploymentRevisionInput = ($configHashes |
        ForEach-Object { '{0}:{1}' -f $_.path, $_.sha256 }) -join "`n"

    $deploymentRevisionBytes = [System.Text.Encoding]::UTF8.GetBytes(
        $deploymentRevisionInput
    )
    $sha256 = [System.Security.Cryptography.SHA256]::Create()

    try {
        $deploymentRevision = (
            $sha256.ComputeHash($deploymentRevisionBytes) |
            ForEach-Object { $_.ToString('x2') }
        ) -join ''
    }
    finally {
        $sha256.Dispose()
    }

    $metadata = [ordered]@{
        schema_version        = 1
        run_id                = $RunId
        system                = 'online-boutique'
        namespace             = $Namespace
        minikube_profile      = $Profile
        code_revision         = $codeRevision
        deployment_revision   = $deploymentRevision
        since_utc             = $sinceUtcNormalized
        until_utc             = $untilUtcNormalized
        time_window_policy    = if ($null -ne $untilUtcValue) {
            'closed interval [since_utc, until_utc]'
        }
        else {
            'kubectl --since-time lower bound; no explicit upper bound'
        }
        capture_started_utc   = $captureStartedUtc.ToString('o')
        capture_completed_utc = $captureCompletedUtc.ToString('o')
        log_format            = 'raw kubectl logs with Kubernetes timestamps'
        overwrite_policy      = 'deny'
        protection            = 'SHA-256 manifest plus Windows read-only attribute'
        config_files          = @($configHashes)
    }

    $metadataPath = Join-Path $runDirectory 'metadata.json'
    Write-Utf8NoBom `
        -Path $metadataPath `
        -Content ($metadata | ConvertTo-Json -Depth 8)

    $manifestEntries = Get-ChildItem -LiteralPath $runDirectory -File -Recurse |
        Sort-Object FullName |
        ForEach-Object {
            [ordered]@{
                path   = $_.FullName.Substring($runDirectory.Length + 1).Replace('\', '/')
                bytes  = $_.Length
                sha256 = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
            }
        }

    $manifest = [ordered]@{
        algorithm = 'SHA-256'
        run_id     = $RunId
        created_utc = [datetime]::UtcNow.ToString('o')
        files      = @($manifestEntries)
    }

    $manifestPath = Join-Path $runDirectory 'sha256-manifest.json'
    Write-Utf8NoBom `
        -Path $manifestPath `
        -Content ($manifest | ConvertTo-Json -Depth 6)

    Get-ChildItem -LiteralPath $runDirectory -File -Recurse |
        ForEach-Object { $_.IsReadOnly = $true }

    Write-Output "archive_path=$runDirectory"
    Write-Output "run_id=$RunId"
    $rawLogCount = @(Get-ChildItem -LiteralPath $rawLogDirectory -File).Count
    Write-Output "raw_log_file_count=$rawLogCount"
    Write-Output "manifest_file_count=$($manifestEntries.Count)"
    Write-Output 'archive_status=sealed-read-only'
}
catch {
    $originalError = $_

    if (Test-Path -LiteralPath $runDirectory) {
        try {
            $invalidRoot = Join-Path $artifactRoot '_invalid'
            New-Item -ItemType Directory -Path $invalidRoot -Force | Out-Null

            Get-ChildItem `
                -LiteralPath $runDirectory `
                -File `
                -Recurse `
                -ErrorAction SilentlyContinue |
                ForEach-Object { $_.IsReadOnly = $false }

            $failureRecord = [ordered]@{
                schema_version = 1
                run_id         = $RunId
                status         = 'invalid'
                failed_utc     = [datetime]::UtcNow.ToString('o')
                error          = $originalError.Exception.Message
            }

            Write-Utf8NoBom `
                -Path (Join-Path $runDirectory 'capture-error.json') `
                -Content ($failureRecord | ConvertTo-Json -Depth 4)

            Get-ChildItem -LiteralPath $runDirectory -File -Recurse |
                ForEach-Object { $_.IsReadOnly = $true }

            $invalidName = '{0}-capture-failed-{1}' -f `
                $RunId, `
                ([datetime]::UtcNow.ToString('yyyyMMddTHHmmssfffZ'))

            $invalidDirectory = Join-Path $invalidRoot $invalidName
            Move-Item `
                -LiteralPath $runDirectory `
                -Destination $invalidDirectory

            Write-Warning "Partial archive preserved as invalid: $invalidDirectory"
        }
        catch {
            Write-Warning "Could not finalize invalid archive: $($_.Exception.Message)"
            Write-Warning "Partial files remain at: $runDirectory"
        }
    }

    throw $originalError
}

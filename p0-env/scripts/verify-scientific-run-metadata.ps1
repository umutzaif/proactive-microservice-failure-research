[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MetadataPath,

    [string]$ExpectedRunId,

    [string]$ExpectedStartUtc,

    [string]$ExpectedEndUtc
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Add-Failure {
    param([Parameter(Mandatory = $true)][string]$Message)
    $script:failures.Add($Message)
}

function Convert-ToUtc {
    param(
        [Parameter(Mandatory = $true)][AllowEmptyString()][string]$Value,
        [Parameter(Mandatory = $true)][string]$Name
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        Add-Failure "missing_utc:$Name"
        return $null
    }

    if ($Value -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$') {
        Add-Failure "invalid_utc:$Name=$Value"
        return $null
    }

    try {
        return [datetimeoffset]::Parse(
            $Value,
            [System.Globalization.CultureInfo]::InvariantCulture,
            [System.Globalization.DateTimeStyles]::AdjustToUniversal
        ).ToUniversalTime()
    }
    catch {
        Add-Failure "invalid_utc:$Name=$Value"
        return $null
    }
}

function Require-Property {
    param(
        [Parameter(Mandatory = $true)][object]$Object,
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$Context
    )

    if ($Object.PSObject.Properties.Name -notcontains $Name) {
        Add-Failure "missing_property:$Context.$Name"
        return $false
    }

    return $true
}

$resolvedMetadata = (Resolve-Path -LiteralPath $MetadataPath).Path
$metadata = Get-Content -LiteralPath $resolvedMetadata -Raw | ConvertFrom-Json
$failures = New-Object System.Collections.Generic.List[string]
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path

foreach ($property in @(
    'schema_version',
    'run_id',
    'experiment_id',
    'run_kind',
    'system',
    'code_revision',
    'deployment_revision',
    'fault_class',
    'target_service',
    'fault_profile',
    'workload_profile_id',
    'workload_profile_path',
    'workload_profile_sha256',
    'random_seed',
    'phases',
    'host_health',
    'valid_run'
)) {
    [void](Require-Property -Object $metadata -Name $property -Context 'metadata')
}

if ([int]$metadata.schema_version -ne 1) {
    Add-Failure "unsupported_metadata_schema:$($metadata.schema_version)"
}

if ([string]$metadata.run_id -notmatch '^[a-z0-9][a-z0-9-]{2,63}$') {
    Add-Failure "invalid_run_id:$($metadata.run_id)"
}

if (
    -not [string]::IsNullOrWhiteSpace($ExpectedRunId) -and
    [string]$metadata.run_id -ne $ExpectedRunId
) {
    Add-Failure "expected_run_id_mismatch:expected=$ExpectedRunId,actual=$($metadata.run_id)"
}

if ([string]$metadata.experiment_id -ne 'P1-CPU-001') {
    Add-Failure "unexpected_experiment_id:$($metadata.experiment_id)"
}

if ([string]$metadata.run_kind -ne 'normal_baseline') {
    Add-Failure "unexpected_run_kind:$($metadata.run_kind)"
}

if ([string]$metadata.system -ne 'online-boutique') {
    Add-Failure "unexpected_system:$($metadata.system)"
}

if ([string]$metadata.fault_class -ne 'normal') {
    Add-Failure "normal_run_fault_class_invalid:$($metadata.fault_class)"
}

if ($null -ne $metadata.target_service) {
    Add-Failure 'normal_run_target_service_must_be_null'
}

if ([string]$metadata.fault_profile -ne 'none') {
    Add-Failure "normal_run_fault_profile_invalid:$($metadata.fault_profile)"
}

if ([int]$metadata.random_seed -le 0) {
    Add-Failure "invalid_random_seed:$($metadata.random_seed)"
}

$profileRelativePath = ([string]$metadata.workload_profile_path).Replace('/', '\')
if ([System.IO.Path]::IsPathRooted($profileRelativePath)) {
    Add-Failure 'workload_profile_path_must_be_repository_relative'
    $profilePath = $null
}
else {
    $profilePath = [System.IO.Path]::GetFullPath(
        (Join-Path $repositoryRoot $profileRelativePath)
    )
    $repositoryPrefix = $repositoryRoot.TrimEnd('\') + '\'

    if (-not $profilePath.StartsWith(
        $repositoryPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
        Add-Failure 'workload_profile_path_escape'
        $profilePath = $null
    }
}

if ($null -ne $profilePath) {
    if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) {
        Add-Failure "workload_profile_missing:$profileRelativePath"
    }
    else {
        $actualProfileHash = (
            Get-FileHash -LiteralPath $profilePath -Algorithm SHA256
        ).Hash.ToLowerInvariant()
        $expectedProfileHash = (
            [string]$metadata.workload_profile_sha256
        ).ToLowerInvariant()

        if ($actualProfileHash -ne $expectedProfileHash) {
            Add-Failure 'workload_profile_checksum_mismatch'
        }

        $profile = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json

        if ([string]$profile.profile_id -ne [string]$metadata.workload_profile_id) {
            Add-Failure 'workload_profile_id_mismatch'
        }

        if ([int]$profile.loadgenerator.random_seed -ne [int]$metadata.random_seed) {
            Add-Failure 'workload_profile_random_seed_mismatch'
        }

        $expectedLocustFile = Join-Path `
            $repositoryRoot `
            'p0-env\source\microservices-demo\src\loadgenerator\locustfile.py'
        $actualLocustHash = (
            Get-FileHash -LiteralPath $expectedLocustFile -Algorithm SHA256
        ).Hash.ToLowerInvariant()

        if (
            $actualLocustHash -ne
            ([string]$profile.loadgenerator.locustfile_sha256).ToLowerInvariant()
        ) {
            Add-Failure 'locustfile_checksum_mismatch'
        }
    }
}

$actualCodeRevision = (& git -C $repositoryRoot rev-parse HEAD).Trim()
if ($LASTEXITCODE -ne 0) {
    Add-Failure 'git_revision_unavailable'
}
elseif ([string]$metadata.code_revision -ne $actualCodeRevision) {
    Add-Failure "code_revision_mismatch:expected=$actualCodeRevision,actual=$($metadata.code_revision)"
}

$phaseNames = @(
    'reset_health_check_utc',
    'warmup_start_utc',
    'warmup_end_utc',
    'normal_baseline_start_utc',
    'normal_baseline_end_utc'
)
$phaseTimes = @{}

foreach ($phaseName in $phaseNames) {
    if (Require-Property -Object $metadata.phases -Name $phaseName -Context 'metadata.phases') {
        $phaseTimes[$phaseName] = Convert-ToUtc `
            -Value ([string]$metadata.phases.$phaseName) `
            -Name $phaseName
    }
}

for ($index = 1; $index -lt $phaseNames.Count; $index++) {
    $previous = $phaseTimes[$phaseNames[$index - 1]]
    $current = $phaseTimes[$phaseNames[$index]]

    if ($null -ne $previous -and $null -ne $current -and $previous -gt $current) {
        Add-Failure "phase_order_invalid:$($phaseNames[$index - 1])>$($phaseNames[$index])"
    }
}

if (
    $null -ne $phaseTimes.warmup_start_utc -and
    $null -ne $phaseTimes.warmup_end_utc
) {
    $warmupSeconds = (
        $phaseTimes.warmup_end_utc - $phaseTimes.warmup_start_utc
    ).TotalSeconds

    if ($warmupSeconds -lt 300) {
        Add-Failure "warmup_too_short_seconds:$warmupSeconds"
    }
}

if (
    $null -ne $phaseTimes.normal_baseline_start_utc -and
    $null -ne $phaseTimes.normal_baseline_end_utc
) {
    $baselineSeconds = (
        $phaseTimes.normal_baseline_end_utc -
        $phaseTimes.normal_baseline_start_utc
    ).TotalSeconds

    if ($baselineSeconds -lt 300) {
        Add-Failure "normal_baseline_too_short_seconds:$baselineSeconds"
    }
}

if (
    -not [string]::IsNullOrWhiteSpace($ExpectedStartUtc) -and
    $null -ne $phaseTimes.warmup_start_utc
) {
    $expectedStart = Convert-ToUtc -Value $ExpectedStartUtc -Name 'ExpectedStartUtc'
    if ($null -ne $expectedStart -and $phaseTimes.warmup_start_utc -ne $expectedStart) {
        Add-Failure 'metadata_start_utc_mismatch'
    }
}

if (
    -not [string]::IsNullOrWhiteSpace($ExpectedEndUtc) -and
    $null -ne $phaseTimes.normal_baseline_end_utc
) {
    $expectedEnd = Convert-ToUtc -Value $ExpectedEndUtc -Name 'ExpectedEndUtc'
    if ($null -ne $expectedEnd -and $phaseTimes.normal_baseline_end_utc -ne $expectedEnd) {
        Add-Failure 'metadata_end_utc_mismatch'
    }
}

foreach ($hostProperty in @(
    'whea_event_17_before',
    'whea_event_17_after',
    'whea_event_17_delta',
    'kernel_power_41_before',
    'kernel_power_41_after',
    'kernel_power_41_delta',
    'bugcheck_before',
    'bugcheck_after',
    'bugcheck_delta'
)) {
    [void](Require-Property `
        -Object $metadata.host_health `
        -Name $hostProperty `
        -Context 'metadata.host_health')
}

foreach ($deltaProperty in @(
    'whea_event_17_delta',
    'kernel_power_41_delta',
    'bugcheck_delta'
)) {
    if ([int]$metadata.host_health.$deltaProperty -ne 0) {
        Add-Failure "host_health_delta_nonzero:$deltaProperty=$($metadata.host_health.$deltaProperty)"
    }
}

if ([bool]$metadata.valid_run -ne $true) {
    Add-Failure 'metadata_not_marked_valid'
}

Write-Output "metadata_path=$resolvedMetadata"
Write-Output "run_id=$($metadata.run_id)"
Write-Output "workload_profile_id=$($metadata.workload_profile_id)"
Write-Output "random_seed=$($metadata.random_seed)"
Write-Output "failure_count=$($failures.Count)"

foreach ($failure in $failures) {
    Write-Output "failure=$failure"
}

if ($failures.Count -gt 0) {
    throw "Scientific run metadata verification failed with $($failures.Count) failure(s)."
}

Write-Output 'scientific_run_metadata_verification=passed'

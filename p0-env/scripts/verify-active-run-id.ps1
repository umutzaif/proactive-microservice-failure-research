[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[a-z0-9][a-z0-9-]{2,63}$')]
    [string]$ExpectedRunId,

    [string]$Profile = 'p0-online-boutique',

    [string]$Namespace = 'online-boutique',

    [ValidateRange(15, 300)]
    [int]$MetricWaitSeconds = 90
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'env.ps1')

function Invoke-KubectlJson {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments,

        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    $output = & minikube kubectl --profile $Profile -- @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed with exit code $LASTEXITCODE."
    }

    return ($output | Out-String | ConvertFrom-Json)
}

function Get-TemplateRunId {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Deployment
    )

    $annotations = $Deployment.spec.template.metadata.annotations
    if (
        $null -eq $annotations -or
        $annotations.PSObject.Properties.Name -notcontains 'experiment.run-id'
    ) {
        return $null
    }

    return [string]$annotations.'experiment.run-id'
}

$status = (& minikube status --profile $Profile 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $status -notmatch 'host:\s+Running') {
    throw "Minikube profile is not ready: $Profile"
}

$collectorConfig = Invoke-KubectlJson `
    -Arguments @(
        '-n', $Namespace,
        'get', 'configmap', 'otel-collector-config', '-o', 'json'
    ) `
    -Operation 'Collector ConfigMap read'
$prometheusConfig = Invoke-KubectlJson `
    -Arguments @(
        '-n', $Namespace,
        'get', 'configmap', 'prometheus-config', '-o', 'json'
    ) `
    -Operation 'Prometheus ConfigMap read'

if ([string]$collectorConfig.data.'config.yaml' -notmatch (
    'value:\s+"?' + [regex]::Escape($ExpectedRunId) + '"?'
)) {
    throw 'Collector ConfigMap does not contain the expected run ID.'
}

if ([string]$prometheusConfig.data.'prometheus.yml' -notmatch (
    'replacement:\s+"?' + [regex]::Escape($ExpectedRunId) + '"?'
)) {
    throw 'Prometheus ConfigMap does not contain the expected run ID.'
}

foreach ($component in @('opentelemetrycollector', 'prometheus')) {
    $deployment = Invoke-KubectlJson `
        -Arguments @(
            '-n', $Namespace,
            'get', "deployment/$component", '-o', 'json'
        ) `
        -Operation "$component deployment read"
    $templateRunId = Get-TemplateRunId -Deployment $deployment

    if ($templateRunId -ne $ExpectedRunId) {
        throw (
            "$component template run ID mismatch: " +
            "expected=$ExpectedRunId actual=$templateRunId"
        )
    }

    $pods = Invoke-KubectlJson `
        -Arguments @(
            '-n', $Namespace,
            'get', 'pods', '-l', "app=$component", '-o', 'json'
        ) `
        -Operation "$component pod read"

    if (@($pods.items).Count -ne 1) {
        throw "$component must have exactly one live pod."
    }

    $pod = @($pods.items)[0]
    $podRunId = [string]$pod.metadata.annotations.'experiment.run-id'
    $ready = @(
        $pod.status.conditions |
            Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }
    ).Count -eq 1

    if ($podRunId -ne $ExpectedRunId) {
        throw (
            "$component pod run ID mismatch: " +
            "expected=$ExpectedRunId actual=$podRunId"
        )
    }

    if (-not $ready) {
        throw "$component pod is not Ready."
    }
}

$runtimePath = (
    '/api/v1/namespaces/{0}/services/http:prometheus:9090/proxy/' +
    'api/v1/status/config'
) -f $Namespace
$runtimeResponse = Invoke-KubectlJson `
    -Arguments @('get', '--raw', $runtimePath) `
    -Operation 'Prometheus runtime config read'

if ([string]$runtimeResponse.status -ne 'success') {
    throw 'Prometheus runtime config API did not return success.'
}

if ([string]$runtimeResponse.data.yaml -notmatch (
    'replacement:\s+"?' + [regex]::Escape($ExpectedRunId) + '"?'
)) {
    throw 'Prometheus runtime config does not contain the expected run ID.'
}

$query = [uri]::EscapeDataString(
    'count({experiment_run_id="' + $ExpectedRunId + '"})'
)
$queryPath = (
    '/api/v1/namespaces/{0}/services/http:prometheus:9090/proxy/' +
    'api/v1/query?query={1}'
) -f $Namespace, $query
$deadline = [datetimeoffset]::UtcNow.AddSeconds($MetricWaitSeconds)
$metricCount = 0

do {
    $queryResponse = Invoke-KubectlJson `
        -Arguments @('get', '--raw', $queryPath) `
        -Operation 'Prometheus run-scoped metric query'

    if (
        [string]$queryResponse.status -eq 'success' -and
        @($queryResponse.data.result).Count -gt 0
    ) {
        $metricCount = [double]$queryResponse.data.result[0].value[1]
    }

    if ($metricCount -gt 0) {
        break
    }

    Start-Sleep -Seconds 5
}
while ([datetimeoffset]::UtcNow -lt $deadline)

if ($metricCount -le 0) {
    throw (
        "Prometheus produced no run-scoped metric series within " +
        "$MetricWaitSeconds seconds."
    )
}

Write-Output "expected_run_id=$ExpectedRunId"
Write-Output "prometheus_run_scoped_series_count=$metricCount"
Write-Output 'collector_configmap_run_id=passed'
Write-Output 'collector_pod_rollout_run_id=passed'
Write-Output 'prometheus_configmap_run_id=passed'
Write-Output 'prometheus_runtime_run_id=passed'
Write-Output 'active_run_id_verification=passed'

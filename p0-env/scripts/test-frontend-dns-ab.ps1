[CmdletBinding()]
param(
    [string]$Profile = 'p0-online-boutique',
    [string]$Namespace = 'online-boutique',
    [string]$ControlImage = 'us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo/frontend:v0.10.6',
    [string]$TreatmentImage = 'makale/frontend:v0.10.6-env-platform-v1',
    [ValidateRange(5, 100)][int]$RequestCount = 12,
    [ValidateRange(1, 20)][int]$WarmupRequestCount = 5,
    [ValidateRange(2, 60)][int]$RequestTimeoutSeconds = 10,
    [string]$OutputPath = 'p0-env/artifacts/P1-FRONTEND-DNS-AB-001/ab-result.json'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'env.ps1')

function Assert-NativeSuccess {
    param([Parameter(Mandatory = $true)][string]$Operation)
    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed with exit code $LASTEXITCODE."
    }
}

function Invoke-Kubectl {
    param([Parameter(Mandatory = $true)][string[]]$Arguments)
    & minikube kubectl --profile $Profile -- @Arguments
    Assert-NativeSuccess -Operation ($Arguments -join ' ')
}

function Set-FrontendVariant {
    param([Parameter(Mandatory = $true)][string]$Image)
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'set', 'image', 'deployment/frontend', "server=$Image"
    )
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'set', 'env', 'deployment/frontend', 'ENV_PLATFORM=local'
    )
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'rollout', 'status', 'deployment/frontend', '--timeout=5m'
    )
}

function Measure-Frontend {
    param([Parameter(Mandatory = $true)][string]$Label)

    $python = @'
import json, statistics, sys, time, urllib.request
count = int(sys.argv[1])
timeout = float(sys.argv[2])
warmup_count = int(sys.argv[3])
url = "http://frontend:80/"
def request_once():
    started = time.perf_counter()
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            response.read()
            status = response.status
        return {"status": status, "error": None, "duration_ms": (time.perf_counter() - started) * 1000}
    except Exception as error:
        return {"status": None, "error": type(error).__name__, "duration_ms": (time.perf_counter() - started) * 1000}
warmup_samples = [request_once() for _ in range(warmup_count)]
samples = [request_once() for _ in range(count)]
durations = sorted(item["duration_ms"] for item in samples)
rank95 = durations[max(0, -(-95 * len(durations) // 100) - 1)]
print(json.dumps({
    "request_count": count,
    "warmup_request_count": warmup_count,
    "warmup_samples": warmup_samples,
    "request_timeout_seconds": timeout,
    "success_count": sum(1 for item in samples if item["status"] == 200),
    "timeout_count": sum(1 for item in samples if item["error"] == "TimeoutError"),
    "error_count": sum(1 for item in samples if item["error"] is not None),
    "samples": samples,
    "latency_ms": {
        "mean": statistics.mean(durations),
        "median": statistics.median(durations),
        "p95_nearest_rank": rank95,
        "max": max(durations)
    }
}, separators=(",", ":")))
'@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($python))
    $command = "import base64;exec(base64.b64decode('$encoded'))"
    $json = & minikube kubectl --profile $Profile -- `
        -n $Namespace exec pod/frontend-ab-client -- `
        python -c $command $RequestCount $RequestTimeoutSeconds $WarmupRequestCount
    Assert-NativeSuccess -Operation "frontend measurement $Label"
    return ($json | ConvertFrom-Json)
}

$startedUtc = [datetimeoffset]::UtcNow
$resolvedOutput = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
$outputDirectory = Split-Path -Parent $resolvedOutput
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
if (Test-Path -LiteralPath $resolvedOutput) {
    throw "Output already exists; refusing overwrite: $resolvedOutput"
}

$originalImage = (& minikube kubectl --profile $Profile -- `
    -n $Namespace get deployment/frontend `
    -o 'jsonpath={.spec.template.spec.containers[0].image}')
Assert-NativeSuccess -Operation 'read original frontend image'
$originalLoadgeneratorReplicas = (& minikube kubectl --profile $Profile -- `
    -n $Namespace get deployment/loadgenerator `
    -o 'jsonpath={.spec.replicas}')
Assert-NativeSuccess -Operation 'read original loadgenerator replicas'

$controlA = $null
$treatment = $null
$controlB = $null
$cleanupErrors = [Collections.Generic.List[string]]::new()

try {
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'scale', 'deployment/loadgenerator', '--replicas=0'
    )
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'run', 'frontend-ab-client',
        '--image=us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo/loadgenerator:v0.10.6',
        '--restart=Never', '--command', '--', 'sleep', '1800'
    )
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'wait', '--for=condition=Ready',
        'pod/frontend-ab-client', '--timeout=5m'
    )

    Set-FrontendVariant -Image $ControlImage
    $controlA = Measure-Frontend -Label 'control-a'

    Set-FrontendVariant -Image $TreatmentImage
    $treatment = Measure-Frontend -Label 'treatment'

    Set-FrontendVariant -Image $ControlImage
    $controlB = Measure-Frontend -Label 'control-b'
}
finally {
    try {
        Invoke-Kubectl -Arguments @(
            '-n', $Namespace, 'set', 'image', 'deployment/frontend', "server=$originalImage"
        )
        Invoke-Kubectl -Arguments @(
            '-n', $Namespace, 'set', 'env', 'deployment/frontend', 'ENV_PLATFORM-'
        )
        Invoke-Kubectl -Arguments @(
            '-n', $Namespace, 'rollout', 'status', 'deployment/frontend', '--timeout=5m'
        )
    }
    catch {
        $cleanupErrors.Add("frontend_restore: $($_.Exception.Message)")
    }
    try {
        & minikube kubectl --profile $Profile -- `
            -n $Namespace delete pod/frontend-ab-client --ignore-not-found=true --wait=true
        Assert-NativeSuccess -Operation 'delete A/B client pod'
    }
    catch {
        $cleanupErrors.Add("client_cleanup: $($_.Exception.Message)")
    }
    try {
        Invoke-Kubectl -Arguments @(
            '-n', $Namespace, 'scale', 'deployment/loadgenerator',
            "--replicas=$originalLoadgeneratorReplicas"
        )
    }
    catch {
        $cleanupErrors.Add("loadgenerator_restore: $($_.Exception.Message)")
    }
}

if ($null -eq $controlA -or $null -eq $treatment -or $null -eq $controlB) {
    throw 'A/B/A measurement did not produce all three result groups.'
}
if ($cleanupErrors.Count -gt 0) {
    throw "A/B/A cleanup failed: $($cleanupErrors -join '; ')"
}

$result = [ordered]@{
    schema_version = 1
    experiment_id = 'P1-FRONTEND-DNS-AB-001'
    evidence_class = 'tooling-smoke-not-scientific-dataset'
    started_utc = $startedUtc.ToString('o')
    ended_utc = [datetimeoffset]::UtcNow.ToString('o')
    request_count_per_variant = $RequestCount
    warmup_request_count_per_variant = $WarmupRequestCount
    request_timeout_seconds = $RequestTimeoutSeconds
    control_image = $ControlImage
    treatment_image = $TreatmentImage
    explicit_env_platform = 'local'
    sequence = @('control-a', 'treatment', 'control-b')
    control_a = $controlA
    treatment = $treatment
    control_b = $controlB
    restored_image = $originalImage
    restored_loadgenerator_replicas = [int]$originalLoadgeneratorReplicas
    cleanup_status = 'passed'
    scientific_dataset_inclusion = $false
    fault_injection = $false
}
$result | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $resolvedOutput -Encoding UTF8
Write-Output "output_path=$resolvedOutput"
Write-Output "control_a_median_ms=$($controlA.latency_ms.median)"
Write-Output "treatment_median_ms=$($treatment.latency_ms.median)"
Write-Output "control_b_median_ms=$($controlB.latency_ms.median)"
Write-Output 'ab_cleanup=passed'
Write-Output 'ab_execution=passed'

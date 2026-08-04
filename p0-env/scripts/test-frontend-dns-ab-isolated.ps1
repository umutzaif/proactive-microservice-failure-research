[CmdletBinding()]
param(
    [string]$Profile = 'p0-online-boutique',
    [string]$Namespace = 'online-boutique',
    [ValidateRange(2, 20)][int]$Rounds = 6,
    [ValidateRange(2, 50)][int]$ConcurrentUsers = 10,
    [ValidateRange(2, 60)][int]$RequestTimeoutSeconds = 15,
    [ValidateRange(0, 60)][int]$CooldownSeconds = 10,
    [int]$OrderSeed = 20260803,
    [string]$OutputPath = 'p0-env/artifacts/P1-FRONTEND-DNS-AB-002/ab-result.json'
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

function Invoke-ConcurrentBatch {
    param(
        [Parameter(Mandatory = $true)][string]$Variant,
        [Parameter(Mandatory = $true)][string]$Service,
        [Parameter(Mandatory = $true)][int]$Round
    )

    $python = @'
import concurrent.futures, json, math, statistics, sys, time, urllib.request
url = sys.argv[1]
count = int(sys.argv[2])
timeout = float(sys.argv[3])
def request_once(index):
    started = time.perf_counter()
    try:
        with urllib.request.urlopen(url, timeout=timeout) as response:
            response.read()
            status = response.status
        return {"index": index, "status": status, "error": None, "duration_ms": (time.perf_counter() - started) * 1000}
    except Exception as error:
        return {"index": index, "status": None, "error": type(error).__name__, "duration_ms": (time.perf_counter() - started) * 1000}
with concurrent.futures.ThreadPoolExecutor(max_workers=count) as executor:
    samples = list(executor.map(request_once, range(count)))
durations = sorted(item["duration_ms"] for item in samples)
def nearest_rank(fraction):
    return durations[min(len(durations) - 1, math.ceil(fraction * len(durations)) - 1)]
print(json.dumps({
    "request_count": count,
    "success_count": sum(1 for item in samples if item["status"] == 200),
    "error_count": sum(1 for item in samples if item["error"] is not None),
    "samples": samples,
    "latency_ms": {
        "mean": statistics.mean(durations),
        "median": statistics.median(durations),
        "p95_nearest_rank": nearest_rank(0.95),
        "max": max(durations)
    }
}, separators=(",", ":")))
'@
    $encoded = [Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($python))
    $command = "import base64;exec(base64.b64decode('$encoded'))"
    $url = "http://${Service}:80/"
    $json = & minikube kubectl --profile $Profile -- `
        -n $Namespace exec pod/frontend-dns-ab-client -- `
        python -c $command $url $ConcurrentUsers $RequestTimeoutSeconds
    Assert-NativeSuccess -Operation "round $Round variant $Variant"
    $measurement = $json | ConvertFrom-Json
    return [ordered]@{
        round = $Round
        variant = $Variant
        service = $Service
        measured_utc = [datetimeoffset]::UtcNow.ToString('o')
        result = $measurement
    }
}

$manifest = (Resolve-Path (Join-Path $PSScriptRoot '..\config\frontend-dns-ab\paired-deployments.yaml')).Path
$resolvedOutput = [IO.Path]::GetFullPath((Join-Path (Get-Location) $OutputPath))
$outputDirectory = Split-Path -Parent $resolvedOutput
[IO.Directory]::CreateDirectory($outputDirectory) | Out-Null
if (Test-Path -LiteralPath $resolvedOutput) {
    throw "Output already exists; refusing overwrite: $resolvedOutput"
}

foreach ($resource in @('deployment/frontend-dns-ab-control', 'deployment/frontend-dns-ab-treatment', 'pod/frontend-dns-ab-client')) {
    $existing = & minikube kubectl --profile $Profile -- -n $Namespace get $resource --ignore-not-found -o name
    Assert-NativeSuccess -Operation "preflight $resource"
    if (-not [string]::IsNullOrWhiteSpace(($existing -join ''))) {
        throw "Pre-existing A/B resource found: $resource"
    }
}

$originalLoadgeneratorReplicas = (& minikube kubectl --profile $Profile -- `
    -n $Namespace get deployment/loadgenerator -o 'jsonpath={.spec.replicas}')
Assert-NativeSuccess -Operation 'read original loadgenerator replicas'

$startedUtc = [datetimeoffset]::UtcNow
$measurements = [Collections.Generic.List[object]]::new()
$orders = [Collections.Generic.List[object]]::new()
$cleanupErrors = [Collections.Generic.List[string]]::new()
$rng = [Random]::new($OrderSeed)

try {
    Invoke-Kubectl -Arguments @('-n', $Namespace, 'scale', 'deployment/loadgenerator', '--replicas=0')
    Invoke-Kubectl -Arguments @('apply', '-f', $manifest)
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'wait', '--for=condition=Available',
        'deployment/frontend-dns-ab-control', 'deployment/frontend-dns-ab-treatment', '--timeout=5m'
    )
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'run', 'frontend-dns-ab-client',
        '--image=us-central1-docker.pkg.dev/online-boutique-ci/microservices-demo/loadgenerator:v0.10.6',
        '--restart=Never', '--command', '--', 'sleep', '1800'
    )
    Invoke-Kubectl -Arguments @(
        '-n', $Namespace, 'wait', '--for=condition=Ready',
        'pod/frontend-dns-ab-client', '--timeout=5m'
    )

    # One excluded concurrent warm-up batch for each independent frontend pod.
    $null = Invoke-ConcurrentBatch -Variant 'control-warmup' -Service 'frontend-dns-ab-control' -Round 0
    $null = Invoke-ConcurrentBatch -Variant 'treatment-warmup' -Service 'frontend-dns-ab-treatment' -Round 0

    for ($round = 1; $round -le $Rounds; $round++) {
        $order = if ($rng.Next(0, 2) -eq 0) {
            @('control', 'treatment')
        }
        else {
            @('treatment', 'control')
        }
        $orders.Add([ordered]@{ round = $round; order = $order })

        foreach ($variant in $order) {
            $service = "frontend-dns-ab-$variant"
            $measurements.Add((Invoke-ConcurrentBatch -Variant $variant -Service $service -Round $round))
        }
        if ($round -lt $Rounds -and $CooldownSeconds -gt 0) {
            Start-Sleep -Seconds $CooldownSeconds
        }
    }
}
finally {
    try {
        & minikube kubectl --profile $Profile -- delete -f $manifest --ignore-not-found=true --wait=true
        Assert-NativeSuccess -Operation 'delete paired A/B resources'
    }
    catch {
        $cleanupErrors.Add("paired_resource_cleanup: $($_.Exception.Message)")
    }
    try {
        & minikube kubectl --profile $Profile -- `
            -n $Namespace delete pod/frontend-dns-ab-client --ignore-not-found=true --wait=true
        Assert-NativeSuccess -Operation 'delete isolated A/B client'
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

if ($measurements.Count -ne (2 * $Rounds)) {
    throw "Expected $($Rounds * 2) measurements, found $($measurements.Count)."
}
if ($cleanupErrors.Count -gt 0) {
    throw "Cleanup failed: $($cleanupErrors -join '; ')"
}

$pairedRatios = [Collections.Generic.List[double]]::new()
$allHttp200 = $true
$allTreatmentLower = $true
for ($round = 1; $round -le $Rounds; $round++) {
    $control = $measurements | Where-Object { $_.round -eq $round -and $_.variant -eq 'control' }
    $treatment = $measurements | Where-Object { $_.round -eq $round -and $_.variant -eq 'treatment' }
    $controlMedian = [double]$control.result.latency_ms.median
    $treatmentMedian = [double]$treatment.result.latency_ms.median
    $pairedRatios.Add($treatmentMedian / $controlMedian)
    if ($treatmentMedian -ge $controlMedian) { $allTreatmentLower = $false }
    if ($control.result.success_count -ne $ConcurrentUsers -or $treatment.result.success_count -ne $ConcurrentUsers) {
        $allHttp200 = $false
    }
}

$maxPairedMedianRatio = ($pairedRatios | Measure-Object -Maximum).Maximum
$accepted = $allTreatmentLower -and $allHttp200 -and $maxPairedMedianRatio -le 0.25
$result = [ordered]@{
    schema_version = 1
    experiment_id = 'P1-FRONTEND-DNS-AB-002'
    evidence_class = 'tooling-causal-test-not-scientific-dataset'
    started_utc = $startedUtc.ToString('o')
    ended_utc = [datetimeoffset]::UtcNow.ToString('o')
    design = [ordered]@{
        independent_simultaneous_frontend_pods = $true
        rounds = $Rounds
        concurrent_users_per_batch = $ConcurrentUsers
        request_timeout_seconds = $RequestTimeoutSeconds
        cooldown_seconds = $CooldownSeconds
        randomized_order_seed = $OrderSeed
        excluded_warmup_batches_per_variant = 1
    }
    preregistered_acceptance = [ordered]@{
        treatment_median_lower_in_every_round = $true
        maximum_paired_median_ratio = 0.25
        required_http_200_rate = 1.0
        cleanup_required = $true
        host_health_delta_zero_required = $true
    }
    orders = $orders
    measurements = $measurements
    paired_treatment_control_median_ratios = $pairedRatios
    observed_max_paired_median_ratio = $maxPairedMedianRatio
    treatment_lower_in_every_round = $allTreatmentLower
    all_requests_http_200 = $allHttp200
    acceptance_before_host_health = $accepted
    cleanup_status = 'passed'
    scientific_dataset_inclusion = $false
    fault_injection = $false
}
$result | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $resolvedOutput -Encoding UTF8
Write-Output "output_path=$resolvedOutput"
Write-Output "max_paired_median_ratio=$maxPairedMedianRatio"
Write-Output "treatment_lower_every_round=$allTreatmentLower"
Write-Output "all_http_200=$allHttp200"
Write-Output "acceptance_before_host_health=$accepted"
Write-Output 'isolated_ab_cleanup=passed'
Write-Output 'isolated_ab_execution=passed'

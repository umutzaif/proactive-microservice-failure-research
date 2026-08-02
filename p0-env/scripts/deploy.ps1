[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'env.ps1')

function Assert-NativeSuccess {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Operation
    )

    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed with exit code $LASTEXITCODE."
    }
}

$profile = 'p0-online-boutique'
$namespace = 'online-boutique'
$configPath = Join-Path $PSScriptRoot '..\config\online-boutique'
$sourcePath = Join-Path $PSScriptRoot '..\source\microservices-demo'

if (-not (Test-Path -LiteralPath $sourcePath -PathType Container)) {
    throw (
        'Online Boutique source is missing. Run ' +
        'p0-env\scripts\fetch-online-boutique.ps1 first.'
    )
}

& minikube start `
    --profile $profile `
    --driver docker `
    --kubernetes-version v1.34.0 `
    --cpus 4 `
    --memory 6144mb `
    --disk-size 32g `
    --container-runtime containerd
Assert-NativeSuccess -Operation 'Minikube start'

& minikube kubectl --profile $profile -- `
    apply -k $configPath
Assert-NativeSuccess -Operation 'Kustomize apply'

# Bu iki bileşen ConfigMap içeriğini yalnızca başlangıçta okur.
# Run ID değişikliklerinin belleğe alınması için yeniden başlatılmaları zorunludur.
& minikube kubectl --profile $profile -- `
    -n $namespace rollout restart `
    deployment/opentelemetrycollector `
    deployment/prometheus
Assert-NativeSuccess -Operation 'Observability rollout restart'

& minikube kubectl --profile $profile -- `
    -n $namespace wait `
    --for=condition=Available `
    deployment `
    --all `
    --timeout=15m
Assert-NativeSuccess -Operation 'Deployment availability wait'

& minikube kubectl --profile $profile -- `
    -n $namespace rollout status `
    deployment/opentelemetrycollector `
    --timeout=5m
Assert-NativeSuccess -Operation 'OpenTelemetry Collector rollout'

& minikube kubectl --profile $profile -- `
    -n $namespace rollout status `
    deployment/prometheus `
    --timeout=5m
Assert-NativeSuccess -Operation 'Prometheus rollout'

& powershell `
    -NoProfile `
    -ExecutionPolicy Bypass `
    -File (Join-Path $PSScriptRoot 'verify-active-run-id.ps1') `
    -ExpectedRunId ((
        Get-Content `
            -LiteralPath (Join-Path $configPath 'observability.yaml') `
            -Raw
    ) | Select-String `
        -Pattern 'experiment\.run-id:\s+"([a-z0-9-]+)"' `
        -AllMatches).Matches[0].Groups[1].Value
Assert-NativeSuccess -Operation 'Active run ID verification'

Write-Output "profile=$profile"
Write-Output "namespace=$namespace"
Write-Output 'observability_restart=passed'
Write-Output 'active_run_id_gate=passed'
Write-Output 'deployment_status=passed'

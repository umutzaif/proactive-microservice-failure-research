[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)][string]$ExpectedProfileRelative,
    [string]$Profile = 'p0-online-boutique',
    [string]$Namespace = 'online-boutique',
    [switch]$StaticOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$profilePath = [IO.Path]::GetFullPath((Join-Path $repo ($ExpectedProfileRelative.Replace('/', '\'))))
if (-not $profilePath.StartsWith($repo, [StringComparison]::OrdinalIgnoreCase)) { throw 'workload_profile_path_escape' }
if (-not (Test-Path -LiteralPath $profilePath -PathType Leaf)) { throw 'workload_profile_missing' }
$expected = Get-Content -LiteralPath $profilePath -Raw | ConvertFrom-Json
$expectedValues = [ordered]@{
    USERS = [string]$expected.loadgenerator.users
    RATE = [string]$expected.loadgenerator.spawn_rate_per_second
    WORKLOAD_PROFILE_ID = [string]$expected.profile_id
    WORKLOAD_RANDOM_SEED = [string]$expected.loadgenerator.random_seed
}

$kustomization = Get-Content -LiteralPath (Join-Path $repo 'p0-env\config\online-boutique\kustomization.yaml') -Raw
foreach ($value in @($expectedValues.USERS, $expectedValues.RATE, $expectedValues.WORKLOAD_PROFILE_ID, $expectedValues.WORKLOAD_RANDOM_SEED)) {
    if ($kustomization -notmatch ('value:\s+"' + [regex]::Escape($value) + '"')) {
        throw "static_workload_binding_missing:$value"
    }
}
Write-Output 'static_workload_profile_binding=passed'
if ($StaticOnly) { return }

function KubectlJson([string[]]$Arguments, [string]$Operation) {
    $raw = & minikube kubectl --profile $Profile -- @Arguments 2>&1
    if ($LASTEXITCODE -ne 0) { throw "$Operation failed:$($raw -join ' | ')" }
    return (($raw -join "`n") | ConvertFrom-Json)
}
function EnvironmentMap([object]$Container) {
    $map = @{}
    foreach ($entry in @($Container.env)) {
        if ($entry.PSObject.Properties.Name -contains 'value') { $map[[string]$entry.name] = [string]$entry.value }
    }
    return $map
}
function VerifyContainer([object]$Container, [string]$Context) {
    $actual = EnvironmentMap $Container
    foreach ($name in $expectedValues.Keys) {
        if (-not $actual.ContainsKey($name) -or [string]$actual[$name] -ne [string]$expectedValues[$name]) {
            throw "active_workload_mismatch:$Context.$name expected=$($expectedValues[$name]) actual=$($actual[$name])"
        }
    }
}

$status = (& minikube status --profile $Profile 2>&1 | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $status -notmatch 'host:\s+Running') { throw 'minikube_not_ready' }
$deployment = KubectlJson @('-n',$Namespace,'get','deployment/loadgenerator','-o','json') 'loadgenerator_deployment_read'
VerifyContainer @($deployment.spec.template.spec.containers)[0] 'deployment'
$pods = KubectlJson @('-n',$Namespace,'get','pods','-l','app=loadgenerator','-o','json') 'loadgenerator_pod_read'
if (@($pods.items).Count -ne 1) { throw "loadgenerator_pod_count_invalid:$(@($pods.items).Count)" }
$pod = @($pods.items)[0]
$ready = @($pod.status.conditions | Where-Object { $_.type -eq 'Ready' -and $_.status -eq 'True' }).Count -eq 1
if (-not $ready) { throw 'loadgenerator_pod_not_ready' }
VerifyContainer @($pod.spec.containers)[0] 'pod'

Write-Output "active_workload_profile_id=$($expectedValues.WORKLOAD_PROFILE_ID)"
Write-Output "active_workload_users=$($expectedValues.USERS)"
Write-Output "active_workload_spawn_rate=$($expectedValues.RATE)"
Write-Output "active_workload_seed=$($expectedValues.WORKLOAD_RANDOM_SEED)"
Write-Output 'active_workload_profile_verification=passed'

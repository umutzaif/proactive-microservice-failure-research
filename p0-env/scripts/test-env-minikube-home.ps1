$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$envScript = Join-Path $PSScriptRoot 'env.ps1'
$original = $env:MINIKUBE_HOME
try {
    $explicit = Join-Path ([IO.Path]::GetTempPath()) 'explicit-minikube-home'
    $env:MINIKUBE_HOME = $explicit
    . $envScript
    if ($env:MINIKUBE_HOME -ne $explicit) {
        throw 'explicit_minikube_home_was_overwritten'
    }

    $env:MINIKUBE_HOME = ''
    . $envScript
    $expectedDefault = Join-Path $PSScriptRoot '..\state\minikube'
    if ($env:MINIKUBE_HOME -ne $expectedDefault) {
        throw 'default_minikube_home_not_applied'
    }

    Write-Output 'env_minikube_home_tests=passed'
}
finally {
    $env:MINIKUBE_HOME = $original
}

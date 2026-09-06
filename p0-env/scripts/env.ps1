$env:Path += ';C:\Program Files\Docker\Docker\resources\bin;C:\ProgramData\chocolatey\bin'
if ([string]::IsNullOrWhiteSpace($env:MINIKUBE_HOME)) {
    $env:MINIKUBE_HOME = Join-Path $PSScriptRoot '..\state\minikube'
}

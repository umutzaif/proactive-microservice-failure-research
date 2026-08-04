$env:Path += ';C:\Program Files\Docker\Docker\resources\bin;C:\ProgramData\chocolatey\bin'
$env:MINIKUBE_HOME = Join-Path $PSScriptRoot '..\state\minikube'

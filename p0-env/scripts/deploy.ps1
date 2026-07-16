. (Join-Path $PSScriptRoot 'env.ps1')
$sourcePath = Join-Path $PSScriptRoot '..\source\microservices-demo'
if (-not (Test-Path -LiteralPath $sourcePath)) {
    throw 'Online Boutique source is missing. Run p0-env\scripts\fetch-online-boutique.ps1 first.'
}
minikube start --profile p0-online-boutique --driver=docker --kubernetes-version=v1.34.0 --cpus=4 --memory=6144mb --disk-size=32g --container-runtime=containerd
minikube kubectl --profile p0-online-boutique -- apply -k (Join-Path $PSScriptRoot '..\config\online-boutique')
minikube kubectl --profile p0-online-boutique -- -n online-boutique wait --for=condition=Available deployment --all --timeout=15m

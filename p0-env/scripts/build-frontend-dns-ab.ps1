[CmdletBinding()]
param(
    [string]$Image = 'makale/frontend:v0.10.6-env-platform-v1'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'env.ps1')

$p0Root = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$dockerfile = Join-Path $p0Root 'config\frontend-dns-ab\Dockerfile'

& docker build --provenance=false --file $dockerfile --tag $Image $p0Root
if ($LASTEXITCODE -ne 0) {
    throw "Frontend A/B image build failed with exit code $LASTEXITCODE."
}

$imageId = & docker image inspect $Image --format '{{.Id}}'
if ($LASTEXITCODE -ne 0) {
    throw "Built image inspection failed with exit code $LASTEXITCODE."
}

Write-Output "image=$Image"
Write-Output "image_id=$imageId"
Write-Output 'build_status=passed'

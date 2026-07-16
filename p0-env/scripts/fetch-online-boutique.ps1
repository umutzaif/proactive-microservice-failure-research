$ErrorActionPreference = 'Stop'

$expectedTag = 'v0.10.6'
$expectedCommit = '5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb'
$sourceRoot = Join-Path $PSScriptRoot '..\source'
$target = Join-Path $sourceRoot 'microservices-demo'

if (Test-Path -LiteralPath $target) {
    $actualCommit = (git -C $target rev-parse HEAD).Trim()
    if ($actualCommit -ne $expectedCommit) {
        throw "Online Boutique source exists at an unexpected revision: $actualCommit"
    }

    Write-Host "Online Boutique is already present at $expectedCommit"
    exit 0
}

New-Item -ItemType Directory -Path $sourceRoot -Force | Out-Null
git clone --depth 1 --branch $expectedTag https://github.com/GoogleCloudPlatform/microservices-demo.git $target

$actualCommit = (git -C $target rev-parse HEAD).Trim()
if ($actualCommit -ne $expectedCommit) {
    throw "Revision verification failed. Expected $expectedCommit, received $actualCommit"
}

Write-Host "Online Boutique $expectedTag prepared at $expectedCommit"


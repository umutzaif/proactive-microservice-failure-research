$ErrorActionPreference='Stop'
$verifier=Join-Path $PSScriptRoot 'verify-network-resource-compat-design.ps1'
& pwsh -NoProfile -File $verifier
if($LASTEXITCODE){throw'positive_design_fixture_failed'}
$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path
$fixture=Join-Path ([IO.Path]::GetTempPath())("network-resource-design-fixture-"+[guid]::NewGuid().ToString('N'))
function ResetFixture{
    New-Item -ItemType Directory -Force -Path(Join-Path $fixture 'p0-env\config\network-delay-resource-compatibility')|Out-Null
    New-Item -ItemType Directory -Force -Path(Join-Path $fixture 'p0-env\artifacts\P2-NETWORK-DELAY-RESOURCE-COMPAT-DESIGN-001')|Out-Null
    Copy-Item -LiteralPath(Join-Path $repo 'p0-env\config\network-delay-resource-compatibility\kustomization.yaml')-Destination(Join-Path $fixture 'p0-env\config\network-delay-resource-compatibility\kustomization.yaml')-Force
    Copy-Item -LiteralPath(Join-Path $repo 'p0-env\artifacts\P2-NETWORK-DELAY-RESOURCE-COMPAT-DESIGN-001\report.md')-Destination(Join-Path $fixture 'p0-env\artifacts\P2-NETWORK-DELAY-RESOURCE-COMPAT-DESIGN-001\report.md')-Force
}
function ExpectFailure([object]$Patch,[string]$Expected){
    $path=Join-Path $fixture 'p0-env\config\network-delay-resource-compatibility\recommendation-server-cpu-limit.json'
    [IO.File]::WriteAllText($path,($Patch|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
    $output=@(& pwsh -NoProfile -File $verifier -RepoRoot $fixture 2>&1);if($LASTEXITCODE-eq0-or($output-join' ')-notlike"*$Expected*"){throw"negative_fixture_not_rejected:$Expected"}
}
try{
    ResetFixture
    ExpectFailure @([ordered]@{op='replace';path='/spec/template/spec/containers/0/livenessProbe/timeoutSeconds';value=2}) 'unexpected_resource_patch'
    ExpectFailure @([ordered]@{op='replace';path='/spec/template/spec/containers/0/resources/limits/cpu';value='500m'},[ordered]@{op='replace';path='/spec/template/spec/containers/0/resources/requests/cpu';value='200m'}) 'patch_must_have_exactly_one_operation'
}finally{
    $resolved=[IO.Path]::GetFullPath($fixture);$tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath());if($resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase)-and(Test-Path -LiteralPath $resolved)){Remove-Item -LiteralPath $resolved -Recurse -Force}
}
Write-Output 'network_resource_compat_design_contract=passed positive=1 negative=2'

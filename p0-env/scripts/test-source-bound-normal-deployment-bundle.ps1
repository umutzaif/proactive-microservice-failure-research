$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

. (Join-Path $PSScriptRoot 'source-bound-normal-deployment-bundle.ps1')

$kubectl = (Get-Command kubectl.exe -ErrorAction Stop).Source
$fixture = Join-Path ([IO.Path]::GetTempPath()) ('source-bound-bundle-test-'+[guid]::NewGuid().ToString('N'))
$parentJunction = "$fixture-parent-junction"
$bundle = $null
function WriteUtf8([string]$Path,[string]$Value) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText($Path,$Value,[Text.UTF8Encoding]::new($false))
}
function ExpectFailure([string]$Expected,[scriptblock]$Action) {
    try { & $Action; throw "expected_failure_missing:$Expected" }
    catch { if ($_.Exception.Message -notlike "*$Expected*") { throw } }
}

try {
    $repo = Join-Path $fixture 'repo'
    $source = Join-Path $fixture 'source'
    WriteUtf8 (Join-Path $source 'kustomize\base\kustomization.yaml') @'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - configmap.yaml
'@
    WriteUtf8 (Join-Path $source 'kustomize\base\configmap.yaml') @'
apiVersion: v1
kind: ConfigMap
metadata:
  name: upstream
'@
    & git -C $source init --quiet
    & git -C $source add .
    & git -C $source -c user.name=fixture -c user.email=fixture@example.invalid commit --quiet -m fixture
    $revision = (& git -C $source rev-parse HEAD).Trim()

    WriteUtf8 (Join-Path $repo 'p0-env\config\online-boutique\kustomization.yaml') @'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../../source/microservices-demo/kustomize/base
  - local.yaml
'@
    WriteUtf8 (Join-Path $repo 'p0-env\config\online-boutique\local.yaml') @'
apiVersion: v1
kind: ConfigMap
metadata:
  name: local
'@
    WriteUtf8 (Join-Path $repo 'p0-env\config\network-delay-design\kustomization.yaml') @'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../online-boutique
  - proxy.yaml
'@
    WriteUtf8 (Join-Path $repo 'p0-env\config\network-delay-design\proxy.yaml') @'
apiVersion: v1
kind: ConfigMap
metadata:
  name: proxy
'@
    WriteUtf8 (Join-Path $repo 'p0-env\config\network-delay-resource-compatibility\kustomization.yaml') @'
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization
resources:
  - ../network-delay-design
  - resource.yaml
'@
    WriteUtf8 (Join-Path $repo 'p0-env\config\network-delay-resource-compatibility\resource.yaml') @'
apiVersion: v1
kind: ConfigMap
metadata:
  name: resource
'@

    $bundle = New-NetworkDelayNormalDeploymentBundle -RepoRoot $repo -OnlineBoutiqueSourceRoot $source -ExpectedSourceRevision $revision -KubectlPath $kubectl
    if (-not $bundle.passed -or $bundle.source_revision -ne $revision -or $bundle.source_root_reparse_point) { throw 'positive_bundle_contract_failed' }
    if ($bundle.base_render_line_count -lt 1 -or $bundle.overlay_render_line_count -lt $bundle.base_render_line_count) { throw 'positive_bundle_render_failed' }
    if (-not (Assert-NetworkDelayNormalDeploymentBundle -Bundle $bundle -KubectlPath $kubectl)) { throw 'positive_bundle_replay_failed' }

    Add-Content -LiteralPath (Join-Path $bundle.root 'online-boutique\local.yaml') -Value '# tamper'
    ExpectFailure 'deployment_bundle_content_mismatch' { Assert-NetworkDelayNormalDeploymentBundle -Bundle $bundle -KubectlPath $kubectl }
    Remove-NetworkDelayNormalDeploymentBundle -Bundle $bundle
    if (Test-Path -LiteralPath $bundle.root) { throw 'bundle_cleanup_failed' }
    $bundle = $null

    ExpectFailure 'online_boutique_source_revision_mismatch' { New-NetworkDelayNormalDeploymentBundle -RepoRoot $repo -OnlineBoutiqueSourceRoot $source -ExpectedSourceRevision ('0'*40) -KubectlPath $kubectl }
    WriteUtf8 (Join-Path $source 'dirty.txt') 'dirty'
    ExpectFailure 'online_boutique_source_not_clean' { New-NetworkDelayNormalDeploymentBundle -RepoRoot $repo -OnlineBoutiqueSourceRoot $source -ExpectedSourceRevision $revision -KubectlPath $kubectl }
    Remove-Item -LiteralPath (Join-Path $source 'dirty.txt') -Force

    $junction = Join-Path $fixture 'source-junction'
    New-Item -ItemType Junction -Path $junction -Target $source | Out-Null
    ExpectFailure 'online_boutique_source_reparse_point_forbidden' { New-NetworkDelayNormalDeploymentBundle -RepoRoot $repo -OnlineBoutiqueSourceRoot $junction -ExpectedSourceRevision $revision -KubectlPath $kubectl }
    New-Item -ItemType Junction -Path $parentJunction -Target $fixture | Out-Null
    ExpectFailure 'online_boutique_source_reparse_point_forbidden' { New-NetworkDelayNormalDeploymentBundle -RepoRoot $repo -OnlineBoutiqueSourceRoot (Join-Path $parentJunction 'source') -ExpectedSourceRevision $revision -KubectlPath $kubectl }

    $baseKustomization = Join-Path $repo 'p0-env\config\online-boutique\kustomization.yaml'
    Add-Content -LiteralPath $baseKustomization -Value "`n# ../../source/microservices-demo/kustomize/base"
    ExpectFailure 'base_overlay_source_reference_contract_mismatch' { New-NetworkDelayNormalDeploymentBundle -RepoRoot $repo -OnlineBoutiqueSourceRoot $source -ExpectedSourceRevision $revision -KubectlPath $kubectl }
    Write-Output 'source_bound_normal_bundle=passed positive=1 negative=6 runtime=none'
}
finally {
    if ($null -ne $bundle) { try { Remove-NetworkDelayNormalDeploymentBundle -Bundle $bundle } catch {} }
    if (Test-Path -LiteralPath $parentJunction) { [IO.Directory]::Delete($parentJunction) }
    if (Test-Path -LiteralPath $fixture) { Remove-Item -LiteralPath $fixture -Recurse -Force }
}

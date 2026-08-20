[CmdletBinding()]
param(
    [string]$RepoRoot=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$VerifyRender,
    [string]$Profile='p0-online-boutique'
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$overlay=Join-Path $RepoRoot 'p0-env\config\network-delay-resource-compatibility'
$kustomization=Get-Content -LiteralPath(Join-Path $overlay 'kustomization.yaml')-Raw
$patch=@(Get-Content -LiteralPath(Join-Path $overlay 'recommendation-server-cpu-limit.json')-Raw|ConvertFrom-Json)
$report=Get-Content -LiteralPath(Join-Path $RepoRoot 'p0-env\artifacts\P2-NETWORK-DELAY-RESOURCE-COMPAT-DESIGN-001\report.md')-Raw
if(-not$kustomization.Contains('../network-delay-design')){throw'base_overlay_not_bound'}
if(-not$kustomization.Contains('name: recommendationservice')){throw'target_deployment_not_bound'}
if($patch.Count-ne1){throw'patch_must_have_exactly_one_operation'}
if([string]$patch[0].op-ne'replace'-or[string]$patch[0].path-ne'/spec/template/spec/containers/0/resources/limits/cpu'-or[string]$patch[0].value-ne'500m'){throw'unexpected_resource_patch'}
foreach($required in @('ob-network-resource-compat-001','ob-second-15u-1r-v1','120 sn / 5 sn','180 sn / 5 sn','13/13','175 sn','<0,50','<10,635359 sn','0/0/0','toxic/fault: yasak')){if(-not$report.Contains($required)){throw"prereg_contract_missing:$required"}}
foreach($forbidden in @('/livenessProbe','/readinessProbe','/resources/requests','memory')){if([string]$patch[0].path-like"*$forbidden*"){throw"forbidden_patch_scope:$forbidden"}}
if($VerifyRender){
    . (Join-Path $PSScriptRoot 'env.ps1')
    $relative='p0-env/config/network-delay-resource-compatibility'
    $raw=@(& minikube kubectl --profile $Profile -- kustomize $relative 2>&1);if($LASTEXITCODE){throw"kustomize_render_failed:$($raw-join' | ')"}
    $docs=($raw-join"`n")-split'(?m)^---\s*$';$deployment=@($docs|Where-Object{$_-match'(?m)^kind: Deployment\s*$'-and$_-match'(?m)^  name: recommendationservice\s*$'})
    if($deployment.Count-ne1){throw"rendered_recommendation_count:$($deployment.Count)"};$rendered=$deployment[0]
    if($rendered-notmatch'(?s)name: server.*?limits:\s*\n\s*cpu: 500m\s*\n\s*memory: 450Mi.*?requests:\s*\n\s*cpu: 100m\s*\n\s*memory: 220Mi'){throw'rendered_server_resource_contract_failed'}
    if($rendered-notmatch'(?s)livenessProbe:.*?grpc:\s*\n\s*port: 8080.*?periodSeconds: 5'){throw'rendered_liveness_contract_failed'}
    if($rendered-notmatch'(?s)name: network-delay-proxy.*?limits:\s*\n\s*cpu: 100m\s*\n\s*memory: 64Mi.*?requests:\s*\n\s*cpu: 10m\s*\n\s*memory: 16Mi'){throw'rendered_proxy_resource_contract_failed'}
    Write-Output 'network_resource_compat_render=passed recommendation_deployments=1'
}
Write-Output 'network_resource_compat_design=passed operations=1 cpu_limit=500m'

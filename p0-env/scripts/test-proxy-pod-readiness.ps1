$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'proxy-pod-readiness.ps1')

function Pod([string]$Name,[bool]$ServerReady=$true,[bool]$ProxyReady=$true,[string]$PodReady='True'){
    [pscustomobject]@{metadata=[pscustomobject]@{name=$Name};status=[pscustomobject]@{
        containerStatuses=@(
            [pscustomobject]@{name='server';ready=$ServerReady},
            [pscustomobject]@{name='network-delay-proxy';ready=$ProxyReady}
        )
        conditions=@([pscustomobject]@{type='Ready';status=$PodReady})
    }}
}

if(-not(Test-SingleReadyProxyPod -Items @((Pod 'new')))){throw 'single_ready_positive_failed'}
if(Test-SingleReadyProxyPod -Items @((Pod 'old'),(Pod 'new'))){throw 'multiple_pod_negative_failed'}
if(Test-SingleReadyProxyPod -Items @((Pod 'new' -ProxyReady $false))){throw 'container_not_ready_negative_failed'}
if(Test-SingleReadyProxyPod -Items @((Pod 'new' -PodReady 'False'))){throw 'pod_not_ready_negative_failed'}
if(Test-SingleReadyProxyPod -Items @()){throw 'zero_pod_negative_failed'}
Write-Output 'proxy_single_ready_pod_fixtures=passed'

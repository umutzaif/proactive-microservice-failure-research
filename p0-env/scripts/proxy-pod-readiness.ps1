Set-StrictMode -Version Latest

function Test-SingleReadyProxyPod {
    [CmdletBinding()]
    param([Parameter(Mandatory=$true)][AllowEmptyCollection()][object[]]$Items)

    if($Items.Count-ne 1){return $false}
    $pod=$Items[0]
    $statuses=@($pod.status.containerStatuses)
    $names=@($statuses.name|Sort-Object)
    $allContainersReady=($statuses.Count-eq 2-and@($statuses|Where-Object{-not[bool]$_.ready}).Count-eq 0)
    $podReady=@($pod.status.conditions|Where-Object{$_.type-eq'Ready'-and$_.status-eq'True'}).Count-eq 1
    return($names.Count-eq 2-and($names-join',')-eq'network-delay-proxy,server'-and$allContainersReady-and$podReady)
}

Set-StrictMode -Version Latest
function Get-KubernetesOptionalProperty([object]$Object,[string]$Name){
    if($null-ne$Object-and$Object.PSObject.Properties.Name-contains$Name){return $Object.$Name}
    return $null
}

function ConvertTo-KubernetesPodView([object]$Pod){
    $metadata=Get-KubernetesOptionalProperty $Pod 'metadata'
    $status=Get-KubernetesOptionalProperty $Pod 'status'
    $conditions=@(@(Get-KubernetesOptionalProperty $status 'conditions')|Where-Object{$null-ne$_}|ForEach-Object{
        [ordered]@{type=[string](Get-KubernetesOptionalProperty $_ 'type');status=[string](Get-KubernetesOptionalProperty $_ 'status');reason=(Get-KubernetesOptionalProperty $_ 'reason');message=(Get-KubernetesOptionalProperty $_ 'message')}
    })
    $containers=@(@(Get-KubernetesOptionalProperty $status 'containerStatuses')|Where-Object{$null-ne$_}|ForEach-Object{
        [ordered]@{name=[string](Get-KubernetesOptionalProperty $_ 'name');ready=[bool](Get-KubernetesOptionalProperty $_ 'ready');started=(Get-KubernetesOptionalProperty $_ 'started');restart_count=[int](Get-KubernetesOptionalProperty $_ 'restartCount');container_id=(Get-KubernetesOptionalProperty $_ 'containerID');state=(Get-KubernetesOptionalProperty $_ 'state');last_state=(Get-KubernetesOptionalProperty $_ 'lastState')}
    })
    [ordered]@{name=[string](Get-KubernetesOptionalProperty $metadata 'name');uid=[string](Get-KubernetesOptionalProperty $metadata 'uid');deletion_timestamp=(Get-KubernetesOptionalProperty $metadata 'deletionTimestamp');phase=[string](Get-KubernetesOptionalProperty $status 'phase');conditions=$conditions;containers=$containers}
}

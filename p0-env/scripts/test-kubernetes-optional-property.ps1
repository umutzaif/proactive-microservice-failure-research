$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'kubernetes-optional-property.ps1')
$condition=[pscustomobject]@{type='Ready';status='False'}
if($null-ne(Get-KubernetesOptionalProperty $condition 'reason')){throw 'missing_optional_property_not_null'}
$condition|Add-Member -NotePropertyName reason -NotePropertyValue 'ContainersNotReady'
if((Get-KubernetesOptionalProperty $condition 'reason')-ne'ContainersNotReady'){throw 'present_optional_property_lost'}
$pending=[pscustomobject]@{metadata=[pscustomobject]@{name='recommendation-pending';uid='uid-pending'};status=[pscustomobject]@{phase='Pending'}}
$pendingView=ConvertTo-KubernetesPodView $pending
if($pendingView.phase-ne'Pending'-or@($pendingView.conditions).Count-ne0-or@($pendingView.containers).Count-ne0){throw 'pending_pod_optional_collections_failed'}
$starting=[pscustomobject]@{metadata=[pscustomobject]@{name='recommendation-starting';uid='uid-starting'};status=[pscustomobject]@{phase='Running';containerStatuses=@([pscustomobject]@{name='server';ready=$false;restartCount=0;state=[pscustomobject]@{waiting=[pscustomobject]@{reason='ContainerCreating'}}})}}
$startingView=ConvertTo-KubernetesPodView $starting
if(@($startingView.containers).Count-ne1-or$null-ne$startingView.containers[0].container_id-or$startingView.containers[0].ready-ne$false){throw 'missing_container_id_fixture_failed'}
Write-Output 'kubernetes_optional_property_fixture=passed'

$ErrorActionPreference='Stop'
. (Join-Path $PSScriptRoot 'kubernetes-optional-property.ps1')
$condition=[pscustomobject]@{type='Ready';status='False'}
if($null-ne(Get-KubernetesOptionalProperty $condition 'reason')){throw 'missing_optional_property_not_null'}
$condition|Add-Member -NotePropertyName reason -NotePropertyValue 'ContainersNotReady'
if((Get-KubernetesOptionalProperty $condition 'reason')-ne'ContainersNotReady'){throw 'present_optional_property_lost'}
Write-Output 'kubernetes_optional_property_fixture=passed'

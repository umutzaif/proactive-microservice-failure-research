Set-StrictMode -Version Latest
function Get-KubernetesOptionalProperty([object]$Object,[string]$Name){
    if($null-ne$Object-and$Object.PSObject.Properties.Name-contains$Name){return $Object.$Name}
    return $null
}

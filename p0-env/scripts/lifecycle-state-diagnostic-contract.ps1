Set-StrictMode -Version Latest

function Get-LifecycleStateAssessment {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Deployment,
        [Parameter(Mandatory)][AllowEmptyCollection()][object[]]$Pods
    )

    if ([string]$Deployment.metadata.name -ne 'recommendationservice') {
        throw 'recommendation_deployment_identity_mismatch'
    }
    $generation = [long]$Deployment.metadata.generation
    $statusProperty = $Deployment.PSObject.Properties['status']
    $observedProperty = if ($null -eq $statusProperty -or $null -eq $statusProperty.Value) {
        $null
    } else {
        $statusProperty.Value.PSObject.Properties['observedGeneration']
    }
    $observedGeneration = if ($null -eq $observedProperty) { 0L } else { [long]$observedProperty.Value }
    $targetPods = @($Pods | Where-Object {
        $name = [string]$_.metadata.name
        $labelsProperty = $_.metadata.PSObject.Properties['labels']
        $labelProperty = if ($null -eq $labelsProperty -or $null -eq $labelsProperty.Value) {
            $null
        } else {
            $labelsProperty.Value.PSObject.Properties['app']
        }
        $label = if ($null -eq $labelProperty) { '' } else { [string]$labelProperty.Value }
        $name.StartsWith('recommendationservice-', [StringComparison]::Ordinal) -or
            $label -eq 'recommendationservice'
    })
    $terminatingPods = @($targetPods | Where-Object {
        $property = $_.metadata.PSObject.Properties['deletionTimestamp']
        $null -ne $property -and -not [string]::IsNullOrWhiteSpace([string]$property.Value)
    })
    $controllerLag = $generation -gt $observedGeneration
    $classification = if ($terminatingPods.Count -gt 0 -or $controllerLag) {
        'stale_lifecycle_state_observed'
    } else {
        'lifecycle_state_not_reproduced'
    }

    [ordered]@{
        schema_version = 1
        classification = $classification
        deployment_generation = $generation
        observed_generation = $observedGeneration
        controller_generation_lag = $controllerLag
        recommendation_pod_count = $targetPods.Count
        terminating_pod_count = $terminatingPods.Count
        terminating_pods = @($terminatingPods | ForEach-Object {
            [ordered]@{
                name = [string]$_.metadata.name
                uid = [string]$_.metadata.uid
                deletion_timestamp = [string]$_.metadata.deletionTimestamp
                phase = [string]$_.status.phase
            }
        })
    }
}

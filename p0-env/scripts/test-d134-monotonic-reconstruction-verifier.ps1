[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')
$verifier = Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1'
$id = 'ob-k8s-clean-reconstruction-002'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('d134-verifier-' + [guid]::NewGuid().ToString('N'))
$artifact = Join-Path $temp $id
New-Item -ItemType Directory -Path $artifact -Force | Out-Null

function Write-FixtureJson([string]$Name, [object]$Value) {
    [IO.File]::WriteAllText(
        (Join-Path $artifact $Name),
        ($Value | ConvertTo-Json -Depth 30),
        [Text.UTF8Encoding]::new($false)
    )
}

try {
    $plan = New-MonotonicReconstructionObservationPlan `
        -DurationSeconds 180 -CadenceSeconds 5 -CompletionTimeoutSeconds 210 `
        -MaximumLatenessMilliseconds 5000
    $observations = @()
    for ($index = 0; $index -lt $plan.target_count; $index++) {
        $target = [long]$plan.target_elapsed_ms[$index]
        $observations += ,[ordered]@{
            target_index=$index;target_elapsed_ms=$target
            sample_started_elapsed_ms=[double]($target + 100)
            sample_completed_elapsed_ms=[double]($target + 900)
            lateness_ms=100;observed_utc='2026-10-13T00:00:00.0000000Z'
            exit_code=0;host='Running';kubelet='Running';apiserver='Running';kubeconfig='Configured'
        }
    }
    $manifest = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-002';reconstruction_id=$id
        preregistration_decision='D-134';predecessor_decision='D-133'
        predecessor_manifest_sha256='bc97ddb3ee38077de9cb2ec3f031ac78b9fb07f0a3265151de28b883b11417d9'
        runtime_state_root='C:\fixture\state';backup_root='D:\fixture\backup-002'
        backup_contains_sensitive_runtime_credentials=$true;backup_must_remain_outside_repository=$true
        backup_acl_verified=$true;backup_acl_inheritance_protected=$true
        backup_acl_allowed_principals=@('current_user','SYSTEM','Administrators');backup_acl_rule_count=3
        application_manifest_applied=$false;workload_started=$false;toxic_created=$false
        scientific_fault_started=$false;scientific_window_started=$false;dataset_inclusion=$false
        headroom_decision_inclusion=$false;successor_authorized=$false
    }
    $assessment = [ordered]@{
        classification='fresh_kubernetes_reconstruction_supported';sampling_contract='monotonic_target_time'
        target_count=36;sample_count=36;stable_sample_count=36;maximum_lateness_ms=100
        causal_conclusion=$false;repair_cause_proven=$false;successor_authorized=$false
        dataset_inclusion=$false;headroom_decision_inclusion=$false
    }
    Write-FixtureJson 'reconstruction-manifest.json' $manifest
    Write-FixtureJson 'assessment.json' $assessment
    Write-FixtureJson 'host-after.json' ([ordered]@{passed=$true;counts=[ordered]@{whea_event_17=0;kernel_power_41_count=0;kernel_power_41=0;bugcheck=0}})
    Write-FixtureJson 'final-profile-status-capture.json' ([ordered]@{exit_code=7;stdout='{"Host":"Stopped","Kubelet":"Stopped","APIServer":"Stopped","Kubeconfig":"Stopped"}'})
    Write-FixtureJson 'backup-verification.json' ([ordered]@{passed=$true})
    Write-FixtureJson 'delete-verification.json' ([ordered]@{passed=$true;container_exists=$false;volume_exists=$false})
    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$observations})
    & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null

    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=@($observations | Select-Object -First 35)})
    try { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null; throw 'expected_missing_target_negative_missing' }
    catch { if ($_.Exception.Message -eq 'expected_missing_target_negative_missing') { throw } }

    $wrongTarget = @($observations | ForEach-Object { [pscustomobject]$_ | Select-Object * })
    $wrongTarget[10].target_elapsed_ms = 12345
    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$wrongTarget})
    try { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null; throw 'expected_target_identity_negative_missing' }
    catch { if ($_.Exception.Message -eq 'expected_target_identity_negative_missing') { throw } }

    $lateTarget = @($observations | ForEach-Object { [pscustomobject]$_ | Select-Object * })
    $lateTarget[18].sample_started_elapsed_ms = $lateTarget[18].target_elapsed_ms + 5000
    $lateTarget[18].sample_completed_elapsed_ms = $lateTarget[18].target_elapsed_ms + 5900
    $lateTarget[18].lateness_ms = 5000
    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$lateTarget})
    try { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null; throw 'expected_lateness_limit_negative_missing' }
    catch { if ($_.Exception.Message -eq 'expected_lateness_limit_negative_missing') { throw } }

    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$observations})
    $assessment.sample_count = 35
    Write-FixtureJson 'assessment.json' $assessment
    try { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null; throw 'expected_assessment_negative_missing' }
    catch { if ($_.Exception.Message -eq 'expected_assessment_negative_missing') { throw } }
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}

Write-Output 'd134_monotonic_reconstruction_verifier_tests=passed positive=1 negative=4 runtime=none'

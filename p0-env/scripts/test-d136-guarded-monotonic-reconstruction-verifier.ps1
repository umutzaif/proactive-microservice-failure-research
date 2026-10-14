[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')
$verifier = Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1'
$id = 'ob-k8s-clean-reconstruction-003'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('d136-verifier-' + [guid]::NewGuid().ToString('N'))
$artifact = Join-Path $temp $id
New-Item -ItemType Directory -Path $artifact -Force | Out-Null

function Write-FixtureJson([string]$Name, [object]$Value) {
    [IO.File]::WriteAllText(
        (Join-Path $artifact $Name),
        ($Value | ConvertTo-Json -Depth 30),
        [Text.UTF8Encoding]::new($false)
    )
}
function Expect-Rejection([scriptblock]$Action, [string]$Name) {
    try { & $Action; throw "expected_rejection_missing:$Name" }
    catch { if ($_.Exception.Message -eq "expected_rejection_missing:$Name") { throw } }
}

try {
    $plan = New-MonotonicReconstructionObservationPlan `
        -DurationSeconds 180 -CadenceSeconds 5 -CompletionTimeoutSeconds 210 `
        -MaximumLatenessMilliseconds 5000 -WaitStrategy 'guarded_recheck'
    $observations = @()
    for ($index = 0; $index -lt $plan.target_count; $index++) {
        $target = [long]$plan.target_elapsed_ms[$index]
        $observations += ,[ordered]@{
            target_index=$index;target_elapsed_ms=$target
            sample_started_elapsed_ms=[double]($target + 100)
            sample_completed_elapsed_ms=[double]($target + 900);lateness_ms=100
            wait_strategy='guarded_recheck';wait_guard_satisfied=$true;wait_recheck_count=1
            observed_utc='2026-10-14T00:00:00.0000000Z';exit_code=0
            host='Running';kubelet='Running';apiserver='Running';kubeconfig='Configured'
        }
    }
    $manifest = [ordered]@{
        gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-003';reconstruction_id=$id
        preregistration_decision='D-136';predecessor_decision='D-135'
        predecessor_manifest_sha256='9a4b1cf5f854051656bef5e101137982a2ddc06862223d8a6010d5657d75c67e'
        runtime_state_root='C:\fixture\state';backup_root='D:\fixture\backup-003'
        backup_contains_sensitive_runtime_credentials=$true;backup_must_remain_outside_repository=$true
        backup_acl_verified=$true;backup_acl_inheritance_protected=$true
        backup_acl_allowed_principals=@('current_user','SYSTEM','Administrators');backup_acl_rule_count=3
        application_manifest_applied=$false;workload_started=$false;toxic_created=$false
        scientific_fault_started=$false;scientific_window_started=$false;dataset_inclusion=$false
        headroom_decision_inclusion=$false;successor_authorized=$false
    }
    $assessment = [ordered]@{
        classification='fresh_kubernetes_reconstruction_supported'
        sampling_contract='guarded_monotonic_target_time';target_count=36;sample_count=36
        stable_sample_count=36;maximum_lateness_ms=100;causal_conclusion=$false
        repair_cause_proven=$false;successor_authorized=$false;dataset_inclusion=$false
        headroom_decision_inclusion=$false
    }
    Write-FixtureJson 'reconstruction-manifest.json' $manifest
    Write-FixtureJson 'assessment.json' $assessment
    Write-FixtureJson 'host-after.json' ([ordered]@{passed=$true;counts=[ordered]@{whea_event_17=0;kernel_power_41=0;bugcheck=0}})
    Write-FixtureJson 'final-profile-status-capture.json' ([ordered]@{stdout='{"Host":"Stopped","Kubelet":"Stopped","APIServer":"Stopped","Kubeconfig":"Stopped"}'})
    Write-FixtureJson 'backup-verification.json' ([ordered]@{passed=$true})
    Write-FixtureJson 'delete-verification.json' ([ordered]@{passed=$true;container_exists=$false;volume_exists=$false})
    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$observations})
    & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null

    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=@($observations | Select-Object -First 35)})
    Expect-Rejection { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null } 'missing_target'

    $early = @($observations | ForEach-Object { [pscustomobject]$_ | Select-Object * })
    $early[10].sample_started_elapsed_ms = $early[10].target_elapsed_ms - 0.5
    $early[10].sample_completed_elapsed_ms = $early[10].target_elapsed_ms + 900
    $early[10].lateness_ms = 0
    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$early})
    Expect-Rejection { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null } 'early_target'

    $unguarded = @($observations | ForEach-Object { [pscustomobject]$_ | Select-Object * })
    $unguarded[20].wait_guard_satisfied = $false
    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$unguarded})
    Expect-Rejection { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null } 'missing_guard_evidence'

    Write-FixtureJson 'bootstrap-observations.json' ([ordered]@{schema_version=2;schedule=$plan;observations=$observations})
    $assessment.sampling_contract = 'monotonic_target_time'
    Write-FixtureJson 'assessment.json' $assessment
    Expect-Rejection { & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null } 'assessment_contract'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}

Write-Output 'd136_guarded_monotonic_reconstruction_verifier_tests=passed positive=1 negative=4 runtime=none'

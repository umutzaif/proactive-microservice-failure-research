[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'monotonic-reconstruction-observation.ps1')
$verifier = Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1'
$id = 'ob-k8s-clean-reconstruction-006'
$temp = Join-Path ([IO.Path]::GetTempPath()) ('d143-verifier-' + [guid]::NewGuid().ToString('N'))
$artifact = Join-Path $temp $id
New-Item -ItemType Directory -Path $artifact -Force | Out-Null

function Write-FixtureJson([string]$Name, [object]$Value) {
    [IO.File]::WriteAllText(
        (Join-Path $artifact $Name),
        ($Value | ConvertTo-Json -Depth 100),
        [Text.UTF8Encoding]::new($false)
    )
}
function Copy-Fixture([object]$Value) {
    $Value | ConvertTo-Json -Depth 100 | ConvertFrom-Json
}
function Expect-Rejection([scriptblock]$Action, [string]$Expected) {
    try {
        & $Action
        throw "expected_d143_rejection_missing:$Expected"
    }
    catch {
        if ($_.Exception.Message -notlike "*$Expected*") { throw }
    }
}

try {
    $frequency = [long]10000000
    $plan = New-MonotonicReconstructionTickPlan -StopwatchFrequency $frequency
    $observations = @()
    for ($index = 0; $index -lt [int]$plan.target_count; $index++) {
        $target = [long]$plan.target_elapsed_ms[$index]
        $targetTicks = [long]($target * 10000)
        $startedTicks = [long]($targetTicks + 1001250)
        $completedTicks = [long]($startedTicks + 625)
        $observations += ,[ordered]@{
            target_index=$index;target_elapsed_ms=$target;stopwatch_frequency_hz=$frequency
            sample_started_ticks=$startedTicks;sample_completed_ticks=$completedTicks
            sample_started_elapsed_ms_display=(Convert-StopwatchTicksToDisplayMilliseconds `
                -ElapsedTicks $startedTicks -StopwatchFrequency $frequency)
            sample_completed_elapsed_ms_display=(Convert-StopwatchTicksToDisplayMilliseconds `
                -ElapsedTicks $completedTicks -StopwatchFrequency $frequency)
            wait_strategy='guarded_tick_rational_ceiling';wait_guard_satisfied=$true
            wait_recheck_count=1;observed_utc='2026-10-15T00:00:00.0000000Z';exit_code=0
            host='Running';kubelet='Running';apiserver='Running';kubeconfig='Configured'
        }
    }
    $summary = Assert-MonotonicReconstructionTickObservations `
        -Plan $plan -Observations $observations
    $manifest = [ordered]@{
        schema_version=2;gate_id='P2-KUBERNETES-CLEAN-RECONSTRUCTION-006'
        reconstruction_id=$id;preregistration_decision='D-143';representation_decision='D-142'
        predecessor_decision='D-141'
        predecessor_manifest_sha256='f02c370c2a4582b995c47871ac42f8ce696f05cab6ca15ec1bdd1f794f4abaf7'
        runtime_state_root='C:\fixture\state';backup_root='D:\fixture\backup-006'
        backup_contains_sensitive_runtime_credentials=$true;backup_must_remain_outside_repository=$true
        backup_acl_verified=$true;backup_acl_inheritance_protected=$true
        backup_acl_allowed_principals=@('current_user','SYSTEM','Administrators');backup_acl_rule_count=3
        application_manifest_applied=$false;workload_started=$false;toxic_created=$false
        scientific_fault_started=$false;scientific_window_started=$false;dataset_inclusion=$false
        headroom_decision_inclusion=$false;successor_authorized=$false
    }
    $assessment = [ordered]@{
        schema_version=2;classification='fresh_kubernetes_reconstruction_supported'
        sampling_contract='portable_integer_tick_monotonic_target_time'
        target_count=36;sample_count=36;stable_sample_count=36
        stopwatch_frequency_hz=[long]$summary.stopwatch_frequency_hz
        maximum_lateness_numerator=[long]$summary.maximum_lateness_numerator
        maximum_lateness_ms_display=[string]$summary.maximum_lateness_ms_display
        completed_elapsed_ticks=[long]$summary.completed_elapsed_ticks
        completed_elapsed_ms_display=[string]$summary.completed_elapsed_ms_display
        display_values_authoritative=$false
        causal_conclusion=$false;repair_cause_proven=$false;successor_authorized=$false
        dataset_inclusion=$false;headroom_decision_inclusion=$false
    }
    $bootstrap = [ordered]@{schema_version=3;schedule=$plan;observations=$observations;assessment=$summary}

    Write-FixtureJson 'reconstruction-manifest.json' $manifest
    Write-FixtureJson 'assessment.json' $assessment

    Write-FixtureJson 'host-after.json' ([ordered]@{passed=$true;counts=[ordered]@{whea_event_17=0;kernel_power_41=0;bugcheck=0}})
    Write-FixtureJson 'final-profile-status-capture.json' ([ordered]@{stdout='{"Host":"Stopped","Kubelet":"Stopped","APIServer":"Stopped","Kubeconfig":"Stopped"}'})
    Write-FixtureJson 'backup-verification.json' ([ordered]@{passed=$true})
    Write-FixtureJson 'delete-verification.json' ([ordered]@{passed=$true;container_exists=$false;volume_exists=$false})
    Write-FixtureJson 'bootstrap-observations.json' $bootstrap
    & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null

    $floatingCount = Copy-Fixture $assessment
    $floatingCount.sample_count = [double]36.0
    Write-FixtureJson 'assessment.json' $floatingCount
    Expect-Rejection {
        & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
    } 'monotonic_tick_json_integer_required:assessment.sample_count'
    Write-FixtureJson 'assessment.json' $assessment

    $wrongNumerator = Copy-Fixture $assessment
    $wrongNumerator.maximum_lateness_numerator = [long]($wrongNumerator.maximum_lateness_numerator + 1)
    Write-FixtureJson 'assessment.json' $wrongNumerator
    Expect-Rejection {
        & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
    } 'monotonic_tick_reconstruction_assessment_mismatch'
    Write-FixtureJson 'assessment.json' $assessment

    $wrongFrequency = Copy-Fixture $bootstrap
    $wrongFrequency.observations[9].stopwatch_frequency_hz = [long]9999999
    Write-FixtureJson 'bootstrap-observations.json' $wrongFrequency
    Expect-Rejection {
        & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
    } 'monotonic_tick_frequency_mismatch'

    $atLimit = Copy-Fixture $bootstrap
    $atLimit.observations[10].sample_started_ticks = [long](
        $atLimit.observations[10].target_elapsed_ms * 10000 + 50000000
    )
    $atLimit.observations[10].sample_completed_ticks = [long](
        $atLimit.observations[10].sample_started_ticks + 625
    )
    Write-FixtureJson 'bootstrap-observations.json' $atLimit
    Expect-Rejection {
        & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
    } 'monotonic_tick_lateness_limit_exceeded'
    Write-FixtureJson 'bootstrap-observations.json' $bootstrap

    $wrongRepresentation = Copy-Fixture $manifest
    $wrongRepresentation.representation_decision = 'D-140'
    Write-FixtureJson 'reconstruction-manifest.json' $wrongRepresentation
    Expect-Rejection {
        & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
    } 'reconstruction_representation_identity_mismatch'
    Write-FixtureJson 'reconstruction-manifest.json' $manifest

    $wrongDisplay = Copy-Fixture $assessment
    $wrongDisplay.maximum_lateness_ms_display = '0'
    Write-FixtureJson 'assessment.json' $wrongDisplay
    Expect-Rejection {
        & $verifier -ArtifactRoot $artifact -ExpectedReconstructionId $id | Out-Null
    } 'monotonic_tick_reconstruction_display_mismatch'
}
finally {
    Remove-Item -LiteralPath $temp -Recurse -Force
}

Write-Output (
    'd143_tick_reconstruction_verifier=passed positive=1 negative=6 schema=3 ' +
    'integer_authoritative=true display_authoritative=false runtime=none d067=3/6'
)

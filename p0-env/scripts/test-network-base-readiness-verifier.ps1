$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$root=Join-Path ([IO.Path]::GetTempPath()) ('base-readiness-verifier-'+[guid]::NewGuid().ToString('N'))
$id='ob-network-base-readiness-009'
function WriteJson([string]$Name,[object]$Value){[IO.File]::WriteAllText((Join-Path $root $Name),($Value|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))}
try{
 New-Item -ItemType Directory -Path $root|Out-Null
 $runtimeRoot=[IO.Path]::GetFullPath((Join-Path $root 'runtime-state'));$sourceRoot=[IO.Path]::GetFullPath((Join-Path $root 'source'))
 WriteJson 'diagnostic-manifest.json' ([ordered]@{diagnostic_id=$id;gate_id='P2-NETWORK-DELAY-BASE-READINESS-DIAG-001';predecessor_decision='D-097';predecessor_diagnostic_id='ob-network-base-readiness-008';predecessor_merge_revision='63dc70aed38ec0a39dbccb9cede99cf9c3da347d';runtime_state_root_resolved=$runtimeRoot;source_root_resolved=$sourceRoot;ssh_public_key_sha256_expected='86bf057eb0bf9488079879a62c297157bd9e0b2a835b9097dc9d61b79d7e02b1';ssh_public_key_fingerprint_expected='SHA256:E8X6DYnpxGPJpp3lUOnbtLCow0oNNLC9HomdrrWBEOs';dataset_inclusion=$false;headroom_decision_inclusion=$false;scientific_fault_started=$false;scientific_window_started=$false;base_config='p0-env/config/online-boutique';workload_profile_id='ob-default-10u-1r-v1';online_boutique_source_revision_expected='5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb';proxy_overlay_applied=$false;toxic_created=$false})
 WriteJson 'preflight-provenance.json' ([ordered]@{passed=$true;predecessor_decision='D-094';predecessor_diagnostic_id='ob-docker-disk-recovery-001';predecessor_merge_revision='09bf0e077f291318df561f16e48d38cc805ebcd7';runtime_state_root_resolved=$runtimeRoot;source_root_resolved=$sourceRoot;profile='p0-online-boutique';driver='docker';kubernetes_version='v1.34.0';cpus=4;memory_mib=6144;disk_mib=32768;container_runtime='containerd';container_status='exited';container_exit_code=130;container_oom_killed=$false;volume_present=$true;ssh_key_provenance=[ordered]@{passed=$true;exact_host_public_key_present=$true;host_public_key_sha256='86bf057eb0bf9488079879a62c297157bd9e0b2a835b9097dc9d61b79d7e02b1';host_public_key_fingerprint='SHA256:E8X6DYnpxGPJpp3lUOnbtLCow0oNNLC9HomdrrWBEOs'}})
 WriteJson 'readiness-observations.json' ([ordered]@{convergence_timeout_seconds=900;stability_duration_seconds=180;poll_seconds=5})
 WriteJson 'assessment.json' ([ordered]@{diagnostic_id=$id;classification='fresh_base_stability_supported';dataset_inclusion=$false;headroom_decision_inclusion=$false;causal_conclusion=$false})
 WriteJson 'host-after.json' ([ordered]@{passed=$true;counts=[ordered]@{whea_event_17=0;kernel_power_41=0;bugcheck=0}})
 $leaf=Join-Path (Split-Path -Parent $root) $id
 Move-Item -LiteralPath $root -Destination $leaf;$root=$leaf
 $output=@(& (Join-Path $PSScriptRoot 'verify-network-base-readiness-diagnostic.ps1') -ArtifactRoot $root -ExpectedDiagnosticId $id 2>&1)
 if(($output-join"`n")-notmatch'network_base_readiness_verification=passed'){throw 'verifier_fixture_success_marker_missing'}
 Write-Output 'network_base_readiness_verifier_fixture=passed'
}finally{if(Test-Path -LiteralPath $root){Remove-Item -LiteralPath $root -Recurse -Force}}

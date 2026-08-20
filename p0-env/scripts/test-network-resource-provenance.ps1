$ErrorActionPreference = 'Stop'
$verifier = Join-Path $PSScriptRoot 'verify-network-resource-compatibility.ps1'
$parent = Join-Path ([IO.Path]::GetTempPath()) "resource-provenance-$([guid]::NewGuid().ToString('N'))"
$runId = 'ob-network-resource-compat-fixture'
$root = Join-Path $parent $runId
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    $manifest = [ordered]@{schema_version=1;run_id=$runId;telemetry_run_id='ob-netdelay-15u-005';workload_profile_id='ob-second-15u-1r-v1';server_cpu_limit='500m';server_cpu_request='100m';scientific_fault_started=$false}
    [IO.File]::WriteAllText((Join-Path $root 'run-manifest.json'),($manifest|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
    $wrongRoot = @(& pwsh -NoProfile -File $verifier -ArtifactRoot $root -ExpectedRunId 'wrong-run-id' 2>&1)|ForEach-Object{[string]$_}
    if(($wrongRoot -join "`n") -notmatch 'artifact_root_run_id_mismatch'){throw 'artifact_root_negative_fixture_failed'}
    $manifest.run_id = 'wrong-manifest-id'
    [IO.File]::WriteAllText((Join-Path $root 'run-manifest.json'),($manifest|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
    $wrongManifest = @(& pwsh -NoProfile -File $verifier -ArtifactRoot $root -ExpectedRunId $runId 2>&1)|ForEach-Object{[string]$_}
    if(($wrongManifest -join "`n") -notmatch 'run_manifest_id_mismatch'){throw 'manifest_negative_fixture_failed'}
    $manifest.run_id = $runId
    [IO.File]::WriteAllText((Join-Path $root 'run-manifest.json'),($manifest|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
    $positive = @(& pwsh -NoProfile -File $verifier -ArtifactRoot $root -ExpectedRunId $runId 2>&1)|ForEach-Object{[string]$_}
    if(($positive -join "`n") -notmatch 'missing_artifact:host-after.json'){throw 'provenance_positive_fixture_failed'}
    Write-Output 'network_resource_provenance_gate=passed positive=1 negative=2'
}
finally { Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue }

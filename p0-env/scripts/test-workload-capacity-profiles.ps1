$ErrorActionPreference = 'Stop'
$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$profiles = @(
    'p0-env/config/workloads/ob-default-10u-1r-v1.json',
    'p0-env/config/workloads/ob-capacity-15u-1r-v1.json',
    'p0-env/config/workloads/ob-capacity-20u-1r-v1.json'
)
foreach ($relative in $profiles) {
    $profile = Get-Content (Join-Path $repo ($relative.Replace('/', '\'))) -Raw | ConvertFrom-Json
    $seconds = if ($profile.phases.PSObject.Properties.Name -contains 'measurement_seconds') {
        [int]$profile.phases.measurement_seconds
    } elseif ($profile.phases.PSObject.Properties.Name -contains 'normal_baseline_seconds') {
        [int]$profile.phases.normal_baseline_seconds
    } else { throw "measurement_phase_missing:$relative" }
    if ([int]$profile.phases.warmup_seconds -ne 300 -or $seconds -ne 300) { throw "capacity_phase_contract_mismatch:$relative" }
    if ([int]$profile.loadgenerator.random_seed -ne 1 -or [int]$profile.loadgenerator.spawn_rate_per_second -ne 1) { throw "capacity_fixed_input_mismatch:$relative" }
    Write-Output "capacity_profile_fixture=passed profile=$($profile.profile_id)"
}

$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$runner=Join-Path $PSScriptRoot 'run-network-delay-headroom-normal.ps1'
$shell=(Get-Process -Id $PID).Path
$tokens=$null;$errors=$null
[void][Management.Automation.Language.Parser]::ParseFile($runner,[ref]$tokens,[ref]$errors)
if($errors.Count){throw 'runner_parse_failed'}
foreach($case in @(
    @{id='ob-netdelay-500m-normal-10u-005';transport='ethernet';error='closed_run_id'},
    @{id='ob-netdelay-500m-normal-10u-006';transport='wifi';error='closed_run_id'},
    @{id='ob-netdelay-500m-normal-10u-006';transport='ethernet';error='closed_run_id'}
)) {
    $old=$ErrorActionPreference;$ErrorActionPreference='Continue'
    try { $out=@(& $shell -NoProfile -File $runner -RunId $case.id -NetworkTransport $case.transport -WorkloadProfileRelative 'p0-env/config/workloads/ob-default-10u-1r-v1.json' -PythonPath unused -ExecutionApproved 2>&1);$code=$LASTEXITCODE } finally {$ErrorActionPreference=$old}
    if($code -eq 0 -or ($out -join "`n") -notmatch $case.error){throw "gate_not_rejected:$($case.error)"}
}
$source=Get-Content $runner -Raw
foreach($token in @('verify-mentor-feedback-policy.ps1','manual_single_run_no_retry','run_start_utc','run_end_utc','background_load_note','node_state','observed_pod_evidence','anomalies','environment-note.json')) {if(-not $source.Contains($token)){throw "environment_note_contract_missing:$token"}}
if($source.IndexOf('background_load_note_required') -gt $source.IndexOf('New-Item -ItemType Directory -Path $artifactRoot')){throw 'note_gate_after_artifact'}
Write-Output 'd113_preregistration=passed negative=3 environment_note_contract=passed runtime=none'

[CmdletBinding()]
param([Parameter(Mandatory=$true)][string]$MetadataPath,[string]$ExpectedRunId,[string]$ExpectedStartUtc,[string]$ExpectedEndUtc)
$ErrorActionPreference='Stop';$repo=(Resolve-Path(Join-Path $PSScriptRoot '..\..')).Path;$m=Get-Content $MetadataPath -Raw|ConvertFrom-Json
if($ExpectedRunId-and$m.run_id-ne$ExpectedRunId){throw'expected_run_id_mismatch'}
if($ExpectedStartUtc-and$m.phases.warmup_start_utc-ne$ExpectedStartUtc){throw'expected_start_utc_mismatch'}
if($ExpectedEndUtc-and$m.phases.normal_baseline_end_utc-ne$ExpectedEndUtc){throw'expected_end_utc_mismatch'}
$python=if($env:P0_PYTHON_PATH){$env:P0_PYTHON_PATH}else{(Get-Command python -ErrorAction Stop).Source}
& $python (Join-Path $PSScriptRoot 'verify-network-delay-headroom-normal-metadata.py') --repo-root $repo --metadata $MetadataPath
exit $LASTEXITCODE

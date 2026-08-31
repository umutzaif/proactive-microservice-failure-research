$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'bootstrap-state-consistency-runtime.ps1')
$good=[pscustomobject]@{exit_code=0;stdout='[{"State":{"Status":"running"}}]';stderr=''}
if((Resolve-DockerInspectState -Capture $good)-ne'running'){throw 'inspect_positive_fixture_failed'}
$failed=$false;try{Resolve-DockerInspectState -Capture ([pscustomobject]@{exit_code=0;stdout='[{"Id":"x"}]';stderr=''})|Out-Null}catch{$failed=$_.Exception.Message-eq'docker_inspect_state_missing'}
if(-not$failed){throw 'inspect_missing_state_not_failed_closed'}
$paths=@('/a','/b');Assert-BootstrapStateCapture -Capture ([pscustomobject]@{exit_code=0;stdout="PRESENT|/a|regular file|1|2`nMISSING|/b`n";stderr=''}) -ExpectedPaths $paths
$failed=$false;try{Assert-BootstrapStateCapture -Capture ([pscustomobject]@{exit_code=2;stdout='';stderr='bad loop'}) -ExpectedPaths $paths}catch{$failed=$_.Exception.Message-eq'bootstrap_state_capture_exit_nonzero'};if(-not$failed){throw 'state_capture_nonzero_not_failed_closed'}
$tmp=Join-Path ([IO.Path]::GetTempPath())("bootstrap-process-"+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $tmp|Out-Null
try{$out=Join-Path $tmp 'out.txt';$err=Join-Path $tmp 'err.txt';$fixture=Join-Path $tmp 'fixture.ps1';[IO.File]::WriteAllText($fixture,'[Console]::Error.WriteLine("fixture");exit 7',[Text.UTF8Encoding]::new($false));$p=Start-Process -FilePath (Get-Command pwsh).Source -ArgumentList @('-NoProfile','-File',$fixture) -RedirectStandardOutput $out -RedirectStandardError $err -PassThru;$exit=Complete-RedirectedProcess -Process $p;if($exit-ne7){throw "redirected_process_exit_fixture_failed:$exit"};Move-Item -LiteralPath $err -Destination(Join-Path $tmp 'moved.txt');if(-not(Test-Path(Join-Path $tmp 'moved.txt'))){throw 'redirected_process_handle_not_released'}}finally{Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue}
Write-Output 'bootstrap_state_consistency_runtime_tests=passed'

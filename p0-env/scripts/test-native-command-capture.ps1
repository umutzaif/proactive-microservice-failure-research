$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'native-command-capture.ps1')
$pwsh=(Get-Command pwsh -CommandType Application|Select-Object -First 1).Source
$fixture=Join-Path([IO.Path]::GetTempPath())"native-capture-fixture-$([guid]::NewGuid().ToString('N')).ps1"
try{
 [IO.File]::WriteAllText($fixture,"param([int]`$ExitCode,[string]`$Out='',[string]`$Err='')`n[Console]::Out.Write(`$Out);[Console]::Error.Write(`$Err);exit `$ExitCode",[Text.UTF8Encoding]::new($false))
 $ok=Invoke-NativeCommandCapture -FilePath $pwsh -ArgumentList @('-NoProfile','-File',$fixture,'-ExitCode','0','-Out','payload','-Err','diagnostic')
 if($ok.exit_code-ne0-or$ok.stdout-ne'payload'-or$ok.stderr-ne'diagnostic'){throw 'native_capture_success_fixture_failed'}
 $bad=Invoke-NativeCommandCapture -FilePath $pwsh -ArgumentList @('-NoProfile','-File',$fixture,'-ExitCode','9','-Err','engine-offline')
 if($bad.exit_code-ne9-or$bad.stdout-or$bad.stderr-ne'engine-offline'){throw 'native_capture_failure_fixture_failed'}
 Write-Output 'native_command_capture_tests=passed'
}
finally{Remove-Item -LiteralPath $fixture -Force -ErrorAction SilentlyContinue}

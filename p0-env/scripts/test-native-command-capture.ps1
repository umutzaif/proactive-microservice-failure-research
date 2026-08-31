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
 $argumentFixture=Join-Path([IO.Path]::GetTempPath())"native-arguments-fixture-$([guid]::NewGuid().ToString('N')).ps1"
 [IO.File]::WriteAllText($argumentFixture,'param([Parameter(ValueFromRemainingArguments=$true)][string[]]$Values);[Console]::Out.Write(($Values|ConvertTo-Json -Compress))',[Text.UTF8Encoding]::new($false))
 $complex='for p in /a /b; do printf "PRESENT|%s" "$p"; done';$captured=Invoke-NativeCommandCapture -FilePath $pwsh -ArgumentList @('-NoProfile','-File',$argumentFixture,$complex,'C:\path with space\','a"b','')
 $parsed=$captured.stdout|ConvertFrom-Json;$values=@($parsed|ForEach-Object{$_});if($captured.exit_code-ne0-or$values.Count-ne4-or$values[0]-ne$complex-or$values[1]-ne'C:\path with space\'-or$values[2]-ne'a"b'-or$values[3]-ne''){throw "native_capture_argument_boundary_fixture_failed:exit=$($captured.exit_code):stdout=$($captured.stdout):stderr=$($captured.stderr)"}
 $before=@(Get-ChildItem -LiteralPath([IO.Path]::GetTempPath()) -Filter 'tmp*.tmp'|ForEach-Object{$_.FullName})
 function Start-Process{param($FilePath,$ArgumentList,[switch]$Wait,[switch]$PassThru,$WindowStyle,$RedirectStandardOutput,$RedirectStandardError);[IO.File]::WriteAllText($RedirectStandardOutput,'dry-payload');[IO.File]::WriteAllText($RedirectStandardError,'');[pscustomobject]@{ExitCode=0}}
 $savedWhatIf=$WhatIfPreference;$WhatIfPreference=$true
 try{$dry=Invoke-NativeCommandCapture -FilePath 'mock-read-only-command' -ArgumentList @('mock')}
 finally{$WhatIfPreference=$savedWhatIf}
 if($dry.exit_code-ne0-or$dry.stdout-ne'dry-payload'){throw 'native_capture_whatif_fixture_failed'}
 $after=@(Get-ChildItem -LiteralPath([IO.Path]::GetTempPath()) -Filter 'tmp*.tmp'|ForEach-Object{$_.FullName})
 if(@($after|Where-Object{$_-notin$before}).Count){throw 'native_capture_whatif_temp_cleanup_failed'}
 Write-Output 'native_command_capture_tests=passed'
}
finally{Remove-Item -LiteralPath $fixture,$argumentFixture -Force -WhatIf:$false -Confirm:$false -ErrorAction SilentlyContinue}

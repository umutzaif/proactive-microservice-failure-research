$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'native-json-command.ps1')
$diagnosticPath = Join-Path ([IO.Path]::GetTempPath()) "native-json-test-$([guid]::NewGuid().ToString('N')).log"
try {
    $payload = Invoke-NativeJsonCommand -FilePath (Get-Command pwsh).Source -ArgumentList @('-NoProfile', '-Command', '[Console]::Out.Write(''{"value":7}'');[Console]::Error.Write(''diagnostic-only'')') -Operation 'fixture_success' -DiagnosticPath $diagnosticPath
    if ($payload.value -ne 7) { throw 'stdout_json_payload_failed' }
    if ((Get-Content -LiteralPath $diagnosticPath -Raw) -notmatch 'diagnostic-only') { throw 'stderr_diagnostic_preservation_failed' }
    $failedClosed = $false
    try { Invoke-NativeJsonCommand -FilePath (Get-Command pwsh).Source -ArgumentList @('-NoProfile', '-Command', '[Console]::Error.Write(''native-failure'');exit 9') -Operation 'fixture_failure' | Out-Null }
    catch { $failedClosed = $_.Exception.Message -match 'exit=9' -and $_.Exception.Message -match 'native-failure' }
    if (-not $failedClosed) { throw 'native_nonzero_fail_closed_test_failed' }
    Write-Output 'native_json_stdout_stderr_isolation=passed'
}
finally { Remove-Item -LiteralPath $diagnosticPath -Force -ErrorAction SilentlyContinue }

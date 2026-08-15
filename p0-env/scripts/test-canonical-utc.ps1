$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'canonical-utc.ps1')

$typed = ('{"utc":"2026-08-15T12:26:40.445Z"}' | ConvertFrom-Json).utc
$normalized = ConvertTo-CanonicalUtcString -Value $typed
if ($normalized -ne '2026-08-15T12:26:40.4450000Z') { throw "typed_json_utc_not_preserved:$normalized" }
$string = ConvertTo-CanonicalUtcString -Value '2026-08-15T12:26:40.445Z'
if ($string -ne '2026-08-15T12:26:40.445Z') { throw "string_utc_not_preserved:$string" }
try { ConvertTo-CanonicalUtcString -Value '08/15/2026 12:26:40' | Out-Null; throw 'locale_string_was_accepted' } catch { if ($_.Exception.Message -eq 'locale_string_was_accepted') { throw } }
Write-Output 'canonical_utc_typed_json_fixture=passed'
Write-Output 'canonical_utc_locale_negative_fixture=passed'

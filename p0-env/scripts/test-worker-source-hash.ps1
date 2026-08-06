[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'worker-source-hash.ps1')

$testRoot = Join-Path $PSScriptRoot '..\state\tests\worker-source-hash'
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$lfPath = Join-Path $testRoot 'lf.py'
$crlfPath = Join-Path $testRoot 'crlf.py'
$changedPath = Join-Path $testRoot 'changed.py'
$utf8 = New-Object System.Text.UTF8Encoding($false)
[System.IO.File]::WriteAllBytes($lfPath, $utf8.GetBytes("print('same')`n"))
[System.IO.File]::WriteAllBytes($crlfPath, $utf8.GetBytes("print('same')`r`n"))
[System.IO.File]::WriteAllBytes($changedPath, $utf8.GetBytes("print('changed')`n"))

$lfRaw = Get-WorkerSourceSha256 -Path $lfPath -Normalization raw-bytes
$crlfRaw = Get-WorkerSourceSha256 -Path $crlfPath -Normalization raw-bytes
if ($lfRaw -eq $crlfRaw) { throw 'raw_hash_failed_to_detect_line_ending_difference' }

$lfCanonical = Get-WorkerSourceSha256 -Path $lfPath -Normalization utf8-lf
$crlfCanonical = Get-WorkerSourceSha256 -Path $crlfPath -Normalization utf8-lf
if ($lfCanonical -ne $crlfCanonical) { throw 'canonical_hash_is_not_line_ending_independent' }
$changedCanonical = Get-WorkerSourceSha256 -Path $changedPath -Normalization utf8-lf
if ($lfCanonical -eq $changedCanonical) { throw 'canonical_hash_accepted_changed_source' }

Write-Output 'worker_source_raw_line_ending_difference_fixture=passed'
Write-Output 'worker_source_utf8_lf_equivalence_fixture=passed'
Write-Output 'worker_source_changed_content_negative_fixture=passed'

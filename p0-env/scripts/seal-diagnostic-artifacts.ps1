[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ArtifactRoot,
    [ValidateSet('Create','Verify')][string]$Mode='Verify'
)
$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$resolved=(Resolve-Path -LiteralPath $ArtifactRoot).Path;$manifestPath=Join-Path $resolved 'sha256-manifest.json';$receiptPath=Join-Path $resolved 'offline-verification.txt'
if($Mode-eq'Create'){
    if(Test-Path -LiteralPath $manifestPath){throw'manifest_already_exists'}
    $files=@(Get-ChildItem -LiteralPath $resolved -File -Recurse|Where-Object{$_.FullName-notin@($manifestPath,$receiptPath)}|Sort-Object FullName)
    $entries=@($files|ForEach-Object{[ordered]@{path=$_.FullName.Substring($resolved.Length+1).Replace('\','/');bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}})
    $manifest=[ordered]@{schema_version=1;artifact_root=(Split-Path $resolved -Leaf);created_utc=[datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ');file_count=$entries.Count;files=$entries}
    [IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 8),[Text.UTF8Encoding]::new($false))
}
if(-not(Test-Path -LiteralPath $manifestPath)){throw'manifest_missing'};$saved=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
foreach($entry in @($saved.files)){$path=Join-Path $resolved ([string]$entry.path).Replace('/','\');if(-not(Test-Path -LiteralPath $path)){throw"sealed_file_missing:$($entry.path)"};$hash=(Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant();if($hash-ne[string]$entry.sha256){throw"sealed_hash_mismatch:$($entry.path)"};if((Get-Item -LiteralPath $path).Length-ne[long]$entry.bytes){throw"sealed_size_mismatch:$($entry.path)"}}
$actual=@(Get-ChildItem -LiteralPath $resolved -File -Recurse|Where-Object{$_.FullName-notin@($manifestPath,$receiptPath)}).Count;if($actual-ne[int]$saved.file_count){throw'sealed_file_count_mismatch'}
$line="diagnostic_offline_verification=passed files=$actual manifest_sha256=$((Get-FileHash -LiteralPath $manifestPath -Algorithm SHA256).Hash.ToLowerInvariant())"
[IO.File]::WriteAllText($receiptPath,$line+"`n",[Text.UTF8Encoding]::new($false));Write-Output $line

[CmdletBinding()]
param(
    [string]$PowerShell7Path = 'pwsh'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$verifier = Join-Path $PSScriptRoot 'verify-raw-log-archive.ps1'
$tempRoot = Join-Path ([System.IO.Path]::GetTempPath()) ("raw-utc-portability-" + [guid]::NewGuid().ToString('N'))

function New-Fixture {
    param(
        [Parameter(Mandatory = $true)][string]$Name,
        [Parameter(Mandatory = $true)][string]$LogTimestamp
    )

    $root = Join-Path $tempRoot $Name
    $logRoot = Join-Path $root 'raw\logs'
    New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
    $logPath = Join-Path $logRoot 'service.log'
    $metadataPath = Join-Path $root 'metadata.json'
    $manifestPath = Join-Path $root 'sha256-manifest.json'

    [System.IO.File]::WriteAllText(
        $logPath,
        "$LogTimestamp fixture`n",
        (New-Object System.Text.UTF8Encoding($false))
    )
    [System.IO.File]::WriteAllText(
        $metadataPath,
        "{`n  `"run_id`": `"utc-portability-fixture`",`n  `"since_utc`": `"2026-08-20T18:36:00.000Z`",`n  `"until_utc`": `"2026-08-20T18:36:04.674Z`"`n}`n",
        (New-Object System.Text.UTF8Encoding($false))
    )

    $entries = @($metadataPath, $logPath) | ForEach-Object {
        $relative = $_.Substring($root.Length + 1).Replace('\', '/')
        [ordered]@{
            path = $relative
            sha256 = (Get-FileHash -LiteralPath $_ -Algorithm SHA256).Hash.ToLowerInvariant()
            size_bytes = (Get-Item -LiteralPath $_).Length
        }
    }
    $manifest = [ordered]@{
        algorithm = 'SHA-256'
        run_id = 'utc-portability-fixture'
        files = $entries
    } | ConvertTo-Json -Depth 5
    [System.IO.File]::WriteAllText(
        $manifestPath,
        $manifest + "`n",
        (New-Object System.Text.UTF8Encoding($false))
    )

    Get-ChildItem -LiteralPath $root -File -Recurse | ForEach-Object { $_.IsReadOnly = $true }
    return $root
}

function Invoke-Case {
    param(
        [Parameter(Mandatory = $true)][string]$Runtime,
        [Parameter(Mandatory = $true)][string]$Fixture,
        [Parameter(Mandatory = $true)][bool]$ShouldPass
    )

    $output = & $Runtime -NoProfile -ExecutionPolicy Bypass -File $verifier -ArchivePath $Fixture 2>&1
    $passed = $LASTEXITCODE -eq 0
    if ($passed -ne $ShouldPass) {
        throw "utc_portability_case_failed:runtime=$Runtime fixture=$Fixture expected=$ShouldPass output=$($output -join ' | ')"
    }
    if ($ShouldPass -and ($output -join "`n") -notmatch 'timestamp_after_end_count=0') {
        throw "utc_portability_expected_zero_after_end:runtime=$Runtime"
    }
    if (-not $ShouldPass -and ($output -join "`n") -notmatch 'timestamp_after_end_count=1') {
        throw "utc_portability_expected_one_after_end:runtime=$Runtime"
    }
}

try {
    $positive = New-Fixture -Name 'positive' -LogTimestamp '2026-08-20T18:36:04.6265920Z'
    $negative = New-Fixture -Name 'negative' -LogTimestamp '2026-08-20T18:36:04.6740001Z'
    $windowsPowerShell = "$env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe"

    foreach ($runtime in @($windowsPowerShell, $PowerShell7Path)) {
        Invoke-Case -Runtime $runtime -Fixture $positive -ShouldPass $true
        Invoke-Case -Runtime $runtime -Fixture $negative -ShouldPass $false
    }

    Write-Output 'raw_log_utc_portability=passed runtimes=2 positive_boundary=passed negative_boundary=failed_closed'
}
finally {
    if (Test-Path -LiteralPath $tempRoot) {
        Get-ChildItem -LiteralPath $tempRoot -File -Recurse -ErrorAction SilentlyContinue |
            ForEach-Object { $_.IsReadOnly = $false }
        Remove-Item -LiteralPath $tempRoot -Recurse -Force
    }
}

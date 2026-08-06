Set-StrictMode -Version Latest

function Get-WorkerSourceSha256 {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [ValidateSet('raw-bytes','utf8-lf')][string]$Normalization = 'raw-bytes'
    )

    if ($Normalization -eq 'raw-bytes') {
        return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash.ToLowerInvariant()
    }

    $text = [System.IO.File]::ReadAllText($Path)
    $canonicalText = $text.Replace("`r`n", "`n").Replace("`r", "`n")
    $bytes = (New-Object System.Text.UTF8Encoding($false)).GetBytes($canonicalText)
    $algorithm = [System.Security.Cryptography.SHA256]::Create()
    try {
        return ([System.BitConverter]::ToString($algorithm.ComputeHash($bytes))).Replace('-', '').ToLowerInvariant()
    }
    finally { $algorithm.Dispose() }
}

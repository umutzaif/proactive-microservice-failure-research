function Invoke-NativeJsonCommand {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$FilePath,
        [Parameter(Mandatory = $true)][string[]]$ArgumentList,
        [Parameter(Mandatory = $true)][string]$Operation,
        [string]$DiagnosticPath
    )
    $stdoutPath = [IO.Path]::GetTempFileName()
    $stderrPath = [IO.Path]::GetTempFileName()
    try {
        & $FilePath @ArgumentList 1> $stdoutPath 2> $stderrPath
        $exitCode = $LASTEXITCODE
        $stdout = [IO.File]::ReadAllText($stdoutPath)
        $stderr = [IO.File]::ReadAllText($stderrPath)
        if ($DiagnosticPath -and $stderr.Length) {
            [IO.File]::AppendAllText($DiagnosticPath, "[$Operation]`r`n$stderr`r`n", [Text.UTF8Encoding]::new($false))
        }
        if ($exitCode -ne 0) { throw "$Operation exit=$exitCode stderr=$($stderr.Trim())" }
        if (-not $stdout.Trim()) { throw "$Operation empty_stdout" }
        return $stdout | ConvertFrom-Json
    }
    finally { Remove-Item -LiteralPath $stdoutPath, $stderrPath -Force -ErrorAction SilentlyContinue }
}

function Invoke-NativeCommandCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][string[]]$ArgumentList
    )
    $stdoutPath=[IO.Path]::GetTempFileName();$stderrPath=[IO.Path]::GetTempFileName()
    try{
        $process=Start-Process -FilePath $FilePath -ArgumentList $ArgumentList -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $exitCode=$process.ExitCode
        $stdout=[IO.File]::ReadAllText($stdoutPath);$stderr=[IO.File]::ReadAllText($stderrPath)
        [pscustomobject]@{exit_code=[int]$exitCode;stdout=$stdout;stderr=$stderr}
    }
    finally{Remove-Item -LiteralPath $stdoutPath,$stderrPath -Force -ErrorAction SilentlyContinue}
}

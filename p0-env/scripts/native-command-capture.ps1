function ConvertTo-NativeProcessArgument {
    [CmdletBinding()]
    param([AllowEmptyString()][string]$Value)
    if ($Value.Length -gt 0 -and $Value -notmatch '[\s"]') { return $Value }
    $builder=[Text.StringBuilder]::new();[void]$builder.Append('"');$slashes=0
    foreach($character in $Value.ToCharArray()){
        if($character-eq'\'){$slashes++;continue}
        if($character-eq'"'){
            [void]$builder.Append(('\' * (($slashes*2)+1)));[void]$builder.Append('"');$slashes=0;continue
        }
        if($slashes){[void]$builder.Append(('\' * $slashes));$slashes=0}
        [void]$builder.Append($character)
    }
    if($slashes){[void]$builder.Append(('\' * ($slashes*2)))};[void]$builder.Append('"');$builder.ToString()
}

function Invoke-NativeCommandCapture {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$FilePath,
        [Parameter(Mandatory)][AllowEmptyCollection()][AllowEmptyString()][string[]]$ArgumentList
    )
    $stdoutPath=[IO.Path]::GetTempFileName();$stderrPath=[IO.Path]::GetTempFileName()
    try{
        $escapedArguments=@($ArgumentList|ForEach-Object{ConvertTo-NativeProcessArgument -Value $_})
        $process=Start-Process -FilePath $FilePath -ArgumentList $escapedArguments -Wait -PassThru -WindowStyle Hidden -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        $exitCode=$process.ExitCode
        $stdout=[IO.File]::ReadAllText($stdoutPath);$stderr=[IO.File]::ReadAllText($stderrPath)
        [pscustomobject]@{exit_code=[int]$exitCode;stdout=$stdout;stderr=$stderr}
    }
    finally{Remove-Item -LiteralPath $stdoutPath,$stderrPath -Force -WhatIf:$false -Confirm:$false -ErrorAction SilentlyContinue}
}

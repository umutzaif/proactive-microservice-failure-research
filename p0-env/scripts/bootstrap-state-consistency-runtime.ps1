Set-StrictMode -Version Latest

function Resolve-DockerInspectState {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Capture)
    if ([int]$Capture.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace([string]$Capture.stdout)) {
        throw 'docker_inspect_capture_failed'
    }
    try { $parsed = $Capture.stdout | ConvertFrom-Json } catch { throw 'docker_inspect_json_invalid' }
    $items = @($parsed)
    if ($items.Count -ne 1) { throw 'docker_inspect_item_count_invalid' }
    $stateProperty = $items[0].PSObject.Properties['State']
    if ($null -eq $stateProperty -or $null -eq $stateProperty.Value) { throw 'docker_inspect_state_missing' }
    $statusProperty = $stateProperty.Value.PSObject.Properties['Status']
    if ($null -eq $statusProperty -or [string]::IsNullOrWhiteSpace([string]$statusProperty.Value)) { throw 'docker_inspect_status_missing' }
    [string]$statusProperty.Value
}

function Complete-RedirectedProcess {
    [CmdletBinding()]
    param([Parameter(Mandatory)][System.Diagnostics.Process]$Process,[switch]$Force)
    try {
        if ($Force -and -not $Process.HasExited) { Stop-Process -Id $Process.Id -Force }
        $Process.WaitForExit();$Process.Refresh()
        if ($null -eq $Process.ExitCode) { throw 'start_exit_code_unavailable' }
        [int]$Process.ExitCode
    }
    finally { $Process.Dispose() }
}

function Assert-BootstrapStateCapture {
    [CmdletBinding()]
    param([Parameter(Mandatory)][object]$Capture,[Parameter(Mandatory)][string[]]$ExpectedPaths)
    if([int]$Capture.exit_code-ne0){throw 'bootstrap_state_capture_exit_nonzero'}
    if([string]::IsNullOrWhiteSpace([string]$Capture.stdout)){throw 'bootstrap_state_capture_stdout_empty'}
    foreach($path in $ExpectedPaths){
        $pattern='(?m)^(?:PRESENT|MISSING)\|'+[regex]::Escape($path)+'(?:\||$)'
        if([string]$Capture.stdout-notmatch$pattern){throw "bootstrap_state_path_missing:$path"}
    }
}

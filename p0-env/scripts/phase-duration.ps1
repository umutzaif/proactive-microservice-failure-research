Set-StrictMode -Version Latest

function Wait-UntilMinimumUtcDuration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$StartUtc,
        [Parameter(Mandatory = $true)][ValidateRange(0.001, 3600)][double]$MinimumSeconds
    )

    if ($StartUtc -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$') {
        throw 'phase_start_utc_must_be_canonical_z'
    }
    $start = [datetimeoffset]::Parse(
        $StartUtc,
        [Globalization.CultureInfo]::InvariantCulture,
        [Globalization.DateTimeStyles]::AssumeUniversal
    ).ToUniversalTime()
    $deadline = $start.AddSeconds($MinimumSeconds)

    while ([datetimeoffset]::UtcNow -lt $deadline) {
        $remainingMilliseconds = ($deadline - [datetimeoffset]::UtcNow).TotalMilliseconds
        if ($remainingMilliseconds -le 0) { break }
        Start-Sleep -Milliseconds ([int][Math]::Max(1, [Math]::Ceiling($remainingMilliseconds)))
    }

    [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ')
}

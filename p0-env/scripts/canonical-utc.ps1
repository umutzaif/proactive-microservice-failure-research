Set-StrictMode -Version Latest

function ConvertTo-CanonicalUtcString {
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][object]$Value)

    if ($Value -is [datetime]) {
        return ([datetime]$Value).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ',[Globalization.CultureInfo]::InvariantCulture)
    }
    if ($Value -is [datetimeoffset]) {
        return ([datetimeoffset]$Value).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ',[Globalization.CultureInfo]::InvariantCulture)
    }
    $text = [string]$Value
    if ($text -notmatch '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d{1,7})?Z$') { throw 'utc_value_must_be_canonical_z_or_typed_utc' }
    return $text
}

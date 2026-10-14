[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [ValidateSet('create', 'verify', 'test')]
    [string]$Mode,

    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$RemainingArguments
)

$ErrorActionPreference = 'Stop'
$repositoryRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$scriptNames = @{
    create = 'create-agent-handoff.py'
    verify = 'verify-agent-handoff.py'
    test = 'test-agent-handoff.py'
}

$pythonCommand = Get-Command python.exe -ErrorAction SilentlyContinue
if ($null -ne $pythonCommand) {
    & $pythonCommand.Source (Join-Path $PSScriptRoot $scriptNames[$Mode]) @RemainingArguments
    exit $LASTEXITCODE
}

$pyLauncher = Get-Command py.exe -ErrorAction SilentlyContinue
if ($null -ne $pyLauncher) {
    & $pyLauncher.Source -3 (Join-Path $PSScriptRoot $scriptNames[$Mode]) @RemainingArguments
    exit $LASTEXITCODE
}

$profileCandidates = @([Environment]::GetFolderPath('UserProfile'))
if ($repositoryRoot -match '^(?<profile>[A-Za-z]:\\Users\\[^\\]+)\\') {
    $profileCandidates += $Matches.profile
}
foreach ($profileCandidate in ($profileCandidates | Select-Object -Unique)) {
    $bundledPython = Join-Path $profileCandidate '.cache\codex-runtimes\codex-primary-runtime\dependencies\python\python.exe'
    if (Test-Path -LiteralPath $bundledPython -PathType Leaf) {
        & $bundledPython (Join-Path $PSScriptRoot $scriptNames[$Mode]) @RemainingArguments
        exit $LASTEXITCODE
    }
}

throw 'python_runtime_not_found: install Python, enable py.exe, or load the Codex workspace runtime'

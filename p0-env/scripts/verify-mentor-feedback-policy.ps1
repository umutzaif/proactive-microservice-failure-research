[CmdletBinding()]
param(
    [string]$RepoRoot = ''
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $RepoRoot = (Resolve-Path (Join-Path $scriptDirectory '..\..')).Path
}

$required = [ordered]@{
    'AGENTS.md' = @('2026-09-19', 'nine valid narrowed-screening runs', 'Internship scope is capped')
    'research_decisions.md' = @('## D-112', '`2026-09-19`', 'confirmatory 60 pozitif/60 normal')
    'experiment_protocol.md' = @('`2026-09-19`', 'Invalid attempt', 'D-109')
    'dataset_card.md' = @('`2026-09-19`', '60 pozitif/60 normal confirmatory')
    'pilot_experiment_plan.md' = @('## D-112', 'no-retry')
    'docs/researcher-datasheets/01-project-architecture.md' = @('### D-112 narrowed screen and scope boundary', 'nine-valid-run gate')
}

$forbiddenActive = [ordered]@{
    'AGENTS.md' = @('Calendar stop gate: if the ladder screen has not produced')
}

$failures = [System.Collections.Generic.List[string]]::new()
foreach ($entry in $required.GetEnumerator()) {
    $path = Join-Path $RepoRoot $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) {
        $failures.Add("missing_file:$($entry.Key)")
        continue
    }
    $text = [IO.File]::ReadAllText($path)
    foreach ($token in $entry.Value) {
        if (-not $text.Contains($token)) { $failures.Add("missing_policy:$($entry.Key):$token") }
    }
}
foreach ($entry in $forbiddenActive.GetEnumerator()) {
    $path = Join-Path $RepoRoot $entry.Key
    if (-not (Test-Path -LiteralPath $path -PathType Leaf)) { continue }
    $text = [IO.File]::ReadAllText($path)
    foreach ($token in $entry.Value) {
        if ($text.Contains($token)) { $failures.Add("superseded_policy_active:$($entry.Key):$token") }
    }
}

if ($failures.Count -gt 0) {
    $failures | ForEach-Object { Write-Error $_ }
    throw 'mentor_feedback_policy_verification_failed'
}

Write-Output 'mentor_feedback_policy_verification=passed'
Write-Output 'preparation_gate=2026-09-19'
Write-Output 'screening_plan=3_delay_x_1_workload_x_3_valid_runs'
Write-Output 'runtime_authorized=false'

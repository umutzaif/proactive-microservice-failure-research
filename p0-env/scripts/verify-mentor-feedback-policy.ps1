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
    'AGENTS.md' = @('Preparation gate (D-116/D-121): no calendar deadline.', 'operator-reported oral provenance', 'six valid new 500m normal baselines', 'sealed quantitative headroom analysis', 'versioned health-path isolation proof', 'nine valid narrowed-screening runs', 'at least 15 seconds positive lead time in at least 2 of its 3 valid repeats', 'separate runtime authorization', 'Internship scope is capped', 'D-149 prospective Ethernet-only transport policy', 'only active transport for every new project runtime')
    'research_decisions.md' = @('## D-116', '## D-121', 'operator-reported oral confirmation', 'no replacement', 'confirmatory 60 pozitif/60 normal', '## D-149 - Prospective Ethernet-only transport policy', 'historical tethering evidence')
    'experiment_protocol.md' = @('# D-116 active preparation policy', '# D-121 mentor-confirmed schedule provenance', 'operator-reported oral confirmation', 'No calendar deadline', 'Invalid attempt', 'D-109', '# D-149 prospective Ethernet-only transport policy', 'NetworkTransport=ethernet')
    'dataset_card.md' = @('### D-116 active schedule boundary', '### D-121 schedule-authority provenance', 'oral authority provenance', 'No calendar deadline', '60 pozitif/60 normal confirmatory', '### D-149 prospective transport boundary', 'not a Dataset relabeling operation')
    'pilot_experiment_plan.md' = @('## D-116 active preparation plan', '## D-121 active schedule authority', 'oral operator provenance only', 'no calendar deadline', 'no-retry', '## D-149 Ethernet-only preparation rule', 'Historical D-115 through D-145 transport')
    'docs/researcher-datasheets/01-project-architecture.md' = @('### D-116 preparation policy flow', '### D-121 schedule-authority provenance edge', 'operator-reported mentor extension', 'no calendar deadline', 'nine-valid-run gate', '### D-149 Ethernet-only transport edge', 'there is no post-hoc')
}

$forbiddenActive = [ordered]@{
    'AGENTS.md' = @('Calendar stop gate: if the ladder screen has not produced', 'Preparation gate: by', '2026-09-19')
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
Write-Output 'preparation_gate=evidence_based_no_calendar_deadline'
Write-Output 'schedule_authority=d121_operator_reported_oral_mentor_confirmation'
Write-Output 'preparation_requirements=six_valid_500m_normals+sealed_headroom+health_path_isolation'
Write-Output 'screening_plan=3_delay_x_1_workload_x_3_valid_runs'
Write-Output 'prospective_transport=ethernet_only_d149'
Write-Output 'historical_tethering=replay_only_no_relabel'
Write-Output 'runtime_authorized=false'

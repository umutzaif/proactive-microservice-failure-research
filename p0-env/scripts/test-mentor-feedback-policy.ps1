$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$repo=Split-Path -Parent $PSScriptRoot
$repo=Split-Path -Parent $repo
$verifier=Join-Path $PSScriptRoot 'verify-mentor-feedback-policy.ps1'
$fixture=Join-Path ([IO.Path]::GetTempPath()) ('d121-policy-'+[guid]::NewGuid().ToString('N'))
$files=@('AGENTS.md','research_decisions.md','experiment_protocol.md','dataset_card.md','pilot_experiment_plan.md','docs/researcher-datasheets/01-project-architecture.md')
try {
    foreach($relative in $files) {
        $target=Join-Path $fixture $relative
        [void][IO.Directory]::CreateDirectory((Split-Path $target -Parent))
        [IO.File]::Copy((Join-Path $repo $relative),$target)
    }
    & $verifier -RepoRoot $fixture | Out-Null
    $agents=Join-Path $fixture 'AGENTS.md'
    $original=[IO.File]::ReadAllText($agents)
    $cases=@(
        'Preparation gate (D-116/D-121): no calendar deadline.',
        'operator-reported oral provenance',
        'six valid new 500m normal baselines',
        'sealed quantitative headroom analysis',
        'versioned health-path isolation proof',
        'nine valid narrowed-screening runs',
        'at least 15 seconds positive lead time in at least 2 of its 3 valid repeats',
        'separate runtime authorization'
    )
    foreach($token in $cases) {
        [IO.File]::WriteAllText($agents,$original.Replace($token,'REMOVED'))
        $rejected=$false
        try { & $verifier -RepoRoot $fixture | Out-Null } catch {$rejected=$true}
        if(-not $rejected){throw "policy_mutation_accepted:$token"}
    }
    [IO.File]::WriteAllText($agents,$original+"`nPreparation gate: by 2026-09-19`n")
    $rejected=$false
    try { & $verifier -RepoRoot $fixture | Out-Null } catch {$rejected=$true}
    if(-not $rejected){throw 'active_deadline_accepted'}
    [IO.File]::WriteAllText($agents,$original)
    Remove-Item -LiteralPath (Join-Path $fixture 'experiment_protocol.md')
    $rejected=$false
    try { & $verifier -RepoRoot $fixture | Out-Null } catch {$rejected=$true}
    if(-not $rejected){throw 'missing_canonical_document_accepted'}
    Write-Output 'mentor_policy_fixtures=passed positive=1 negative=10 runtime=none'
} finally {
    $resolved=[IO.Path]::GetFullPath($fixture)
    $tempRoot=[IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if(-not $resolved.StartsWith($tempRoot,[StringComparison]::OrdinalIgnoreCase) -or (Split-Path $resolved -Leaf) -notlike 'd121-policy-*'){throw 'fixture_cleanup_path_invalid'}
    if(Test-Path -LiteralPath $resolved){Remove-Item -LiteralPath $resolved -Recurse -Force}
}

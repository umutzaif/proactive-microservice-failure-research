[CmdletBinding()]
param(
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path,
    [switch]$RequireReceiptReplay
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Invoke-GitText {
    param([Parameter(Mandatory)][string[]]$Arguments)

    $output = @(& git -C $RepoRoot @Arguments 2>&1)
    if ($LASTEXITCODE -ne 0) {
        throw "git_failed:$($Arguments -join ' '):$($output -join ' | ')"
    }
    return ($output -join "`n")
}

function Read-GitJson {
    param([Parameter(Mandatory)][string]$Path)

    return (Invoke-GitText -Arguments @('show', "HEAD:$Path")) | ConvertFrom-Json
}

$registryPath = Join-Path $RepoRoot 'results_registry.md'
$rows = @()
foreach ($line in (Get-Content -LiteralPath $registryPath -Encoding utf8)) {
    if ($line -notmatch '^\| P1-CPU-001 / ') { continue }
    $parts = $line.Split('|')
    $rows += [pscustomobject]@{
        id = (($parts[1].Trim()) -replace '^P1-CPU-001 / ', '')
        status = $parts[3].Trim()
        report = $parts[8].Trim().Trim('`')
    }
}

$valid = @($rows | Where-Object status -eq 'completed')
$invalid = @($rows | Where-Object status -eq 'invalid')
$validNormal = @($valid | Where-Object id -match 'normal')
$validFault = @($valid | Where-Object id -notmatch 'normal')
$invalidNormal = @($invalid | Where-Object id -match 'normal')
$invalidFault = @($invalid | Where-Object id -notmatch 'normal')

$tree = @((Invoke-GitText -Arguments @('ls-tree', '-r', '--name-only', 'HEAD')) -split "`n")
$treeSet = [Collections.Generic.HashSet[string]]::new([StringComparer]::Ordinal)
foreach ($path in $tree) {
    if ($path) { [void]$treeSet.Add($path) }
}

$failures = [Collections.Generic.List[string]]::new()
$expectedCounts = [ordered]@{
    attempts = 35
    valid = 21
    invalid = 14
    valid_normal = 6
    valid_fault = 15
    invalid_normal = 2
    invalid_fault = 12
}
$actualCounts = [ordered]@{
    attempts = $rows.Count
    valid = $valid.Count
    invalid = $invalid.Count
    valid_normal = $validNormal.Count
    valid_fault = $validFault.Count
    invalid_normal = $invalidNormal.Count
    invalid_fault = $invalidFault.Count
}
foreach ($name in $expectedCounts.Keys) {
    if ($actualCounts[$name] -ne $expectedCounts[$name]) {
        $failures.Add("count_mismatch:${name}:$($actualCounts[$name]):$($expectedCounts[$name])")
    }
}
if (@($rows.id | Sort-Object -Unique).Count -ne 35) {
    $failures.Add('run_id_uniqueness_failed')
}

$missingReports = [Collections.Generic.List[string]]::new()
$reportIdentityFailures = [Collections.Generic.List[string]]::new()
foreach ($row in $rows) {
    if (-not $treeSet.Contains($row.report)) {
        $missingReports.Add($row.id)
        continue
    }
    $reportText = Invoke-GitText -Arguments @('show', "HEAD:$($row.report)")
    if ($reportText -notmatch [regex]::Escape($row.id)) {
        $reportIdentityFailures.Add($row.id)
    }
}
if ($missingReports.Count) { $failures.Add('cpu_run_reports_missing') }
if ($reportIdentityFailures.Count) { $failures.Add('cpu_run_report_identity_mismatch') }

$records = @()
foreach ($row in $validFault) {
    $base = "p0-env/artifacts/P1-CPU-001/$($row.id)"
    $required = @(
        'draft-metadata.json',
        'injector-evidence.json',
        'injector-execution.json',
        'manifestation-evidence.json',
        'run-assessment.json'
    )
    $missing = @($required | Where-Object { -not $treeSet.Contains("$base/$_") })
    if ($missing.Count) {
        $failures.Add("tracked_fault_evidence_missing:$($row.id):$($missing -join ',')")
        continue
    }

    $draft = Read-GitJson -Path "$base/draft-metadata.json"
    $injector = Read-GitJson -Path "$base/injector-evidence.json"
    $manifestation = Read-GitJson -Path "$base/manifestation-evidence.json"
    $assessment = Read-GitJson -Path "$base/run-assessment.json"
    $contractPassed = (
        $draft.run_id -eq $row.id -and
        $injector.run_id -eq $row.id -and
        $manifestation.run_id -eq $row.id -and
        $assessment.run_id -eq $row.id -and
        $injector.physical_effect_verified -eq $true -and
        $injector.physical_effect_verification_status -eq 'passed' -and
        $assessment.valid_run -eq $true -and
        $assessment.physical_effect_verified -eq $true -and
        $assessment.pod_lifecycle_stable -eq $true -and
        [int]$assessment.host_health.whea_event_17_delta -eq 0 -and
        [int]$assessment.host_health.kernel_power_41_delta -eq 0 -and
        [int]$assessment.host_health.bugcheck_delta -eq 0 -and
        $manifestation.slo_id -eq 'p1-cpu-001-slo-v1' -and
        $null -eq $manifestation.failure_manifestation -and
        $null -eq $manifestation.manifestation_trigger
    )
    if (-not $contractPassed) {
        $failures.Add("tracked_fault_contract_failed:$($row.id)")
    }

    $workload = if ($row.id -like 'ob-cpu-15u-*') { '15u' } else { '10u' }
    $severity = if ($row.id -match '-(low|medium|high)-') { $Matches[1] } else { 'unknown' }
    $records += [pscustomobject]@{
        id = $row.id
        workload = $workload
        severity = $severity
        profile = $injector.fault_profile_id
        increase_m = [double]$injector.physical_effect.steady_minus_baseline_mean_millicores
        complete_windows = [int]$manifestation.complete_window_count
    }
}

$expectedAggregates = [ordered]@{
    '10u, low' = '3|50.349|3.576'
    '10u, medium' = '3|99.649|4.947'
    '10u, high' = '3|146.941|2.254'
    '15u, low' = '2|51.098|5.384'
    '15u, medium' = '2|93.987|0.704'
    '15u, high' = '2|140.435|5.312'
}
$aggregates = @()
foreach ($group in ($records | Group-Object workload, severity | Sort-Object Name)) {
    $values = @($group.Group.increase_m)
    $mean = ($values | Measure-Object -Average).Average
    $sampleSd = [Math]::Sqrt(
        (($values | ForEach-Object { [Math]::Pow($_ - $mean, 2) } | Measure-Object -Sum).Sum) /
        ($values.Count - 1)
    )
    $aggregate = [pscustomobject]@{
        cell = $group.Name
        n = $values.Count
        mean_m = [Math]::Round($mean, 3)
        sample_sd_m = [Math]::Round($sampleSd, 3)
        cv_percent = [Math]::Round(100 * $sampleSd / $mean, 3)
    }
    $aggregates += $aggregate
    $actual = "$($aggregate.n)|$($aggregate.mean_m)|$($aggregate.cv_percent)"
    if (-not $expectedAggregates.Contains($group.Name) -or
        $actual -ne $expectedAggregates[$group.Name]) {
        $failures.Add("aggregate_mismatch:$($group.Name):$actual")
    }
}

$receiptReady = @()
$receiptMissing = @()
foreach ($row in $valid) {
    $receiptRoot = Join-Path $RepoRoot "p0-env/artifacts/finalized/$($row.id)"
    $hasReceipt = Test-Path -LiteralPath (Join-Path $receiptRoot 'receipt.json') -PathType Leaf
    $hasManifest = Test-Path -LiteralPath (Join-Path $receiptRoot 'sha256-manifest.json') -PathType Leaf
    if ($hasReceipt -and $hasManifest) { $receiptReady += $row.id } else { $receiptMissing += $row.id }
}

$summary = [ordered]@{
    schema_version = 1
    audit_id = 'D148-WEEK2-CPU-EVIDENCE-AUDIT-001'
    head = Invoke-GitText -Arguments @('rev-parse', 'HEAD')
    tracked_evidence_passed = ($failures.Count -eq 0)
    counts = $actualCounts
    unique_run_ids = @($rows.id | Sort-Object -Unique).Count
    reports_present = $rows.Count - $missingReports.Count
    valid_fault_tracked_contracts = $records.Count
    valid_fault_null_manifestations = @($records).Count
    aggregates = $aggregates
    receipt_replay_ready = ($receiptReady.Count -eq $valid.Count)
    receipt_ready_count = $receiptReady.Count
    receipt_missing_count = $receiptMissing.Count
    receipt_missing_run_ids = $receiptMissing
    failures = @($failures)
}
$summary | ConvertTo-Json -Depth 6

if ($failures.Count) {
    throw "d148_cpu_publication_evidence_audit_failed:$($failures -join ',')"
}
Write-Output 'd148_cpu_tracked_evidence_audit=passed attempts=35 valid=21 invalid=14 reports=35 fault_contracts=15 manifestations=0/15'
Write-Output "d148_cpu_receipt_replay_ready=$($summary.receipt_replay_ready.ToString().ToLowerInvariant()) ready=$($receiptReady.Count) missing=$($receiptMissing.Count)"
if ($RequireReceiptReplay -and -not $summary.receipt_replay_ready) {
    throw 'd148_cpu_receipt_replay_not_ready'
}

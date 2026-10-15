Set-StrictMode -Version Latest

function New-MonotonicReconstructionObservationPlan {
    [CmdletBinding()]
    param(
        [int]$DurationSeconds = 180,
        [int]$CadenceSeconds = 5,
        [int]$CompletionTimeoutSeconds = 210,
        [int]$MaximumLatenessMilliseconds = 5000,
        [ValidateSet('single_delay','guarded_recheck','guarded_branch_then_ceiling')]
        [string]$WaitStrategy = 'single_delay'
    )
    if ($DurationSeconds -le 0 -or $CadenceSeconds -le 0 -or
        $DurationSeconds % $CadenceSeconds -ne 0) {
        throw 'monotonic_schedule_invalid_duration_or_cadence'
    }
    if ($CompletionTimeoutSeconds -le $DurationSeconds) {
        throw 'monotonic_schedule_completion_timeout_not_greater_than_window'
    }
    if ($MaximumLatenessMilliseconds -le 0 -or
        $MaximumLatenessMilliseconds -gt ($CadenceSeconds * 1000)) {
        throw 'monotonic_schedule_lateness_limit_invalid'
    }
    $count = [int]($DurationSeconds / $CadenceSeconds)
    [pscustomobject]@{
        schema_version = 1
        mode = 'monotonic_target_time'
        clock = 'System.Diagnostics.Stopwatch'
        window_semantics = 'half_open_[0,duration)'
        duration_seconds = $DurationSeconds
        cadence_seconds = $CadenceSeconds
        completion_timeout_seconds = $CompletionTimeoutSeconds
        maximum_lateness_ms_exclusive = $MaximumLatenessMilliseconds
        wait_strategy = $WaitStrategy
        target_count = $count
        target_elapsed_ms = @(0..($count - 1) | ForEach-Object { [long]($_ * $CadenceSeconds * 1000) })
    }
}

function Wait-MonotonicReconstructionTarget {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$TargetElapsedMilliseconds,
        [Parameter(Mandatory)][scriptblock]$GetElapsedMilliseconds,
        [Parameter(Mandatory)][scriptblock]$SleepMilliseconds,
        [int]$MaximumRechecks = 1000
    )
    if ($TargetElapsedMilliseconds -lt 0) { throw 'monotonic_wait_negative_target' }
    if ($MaximumRechecks -le 0) { throw 'monotonic_wait_invalid_recheck_limit' }
    $rechecks = 0
    while ($true) {
        $elapsed = [double](& $GetElapsedMilliseconds)
        if ($elapsed -ge $TargetElapsedMilliseconds) {
            return [pscustomobject]@{
                target_elapsed_ms = $TargetElapsedMilliseconds
                reached_elapsed_ms = $elapsed
                recheck_count = $rechecks
                target_reached = $true
            }
        }
        if ($rechecks -ge $MaximumRechecks) { throw 'monotonic_wait_recheck_limit_exceeded' }
        $delayMs = Get-MonotonicReconstructionDelayMilliseconds `
            -TargetElapsedMilliseconds $TargetElapsedMilliseconds `
            -CurrentElapsedMilliseconds $elapsed
        if ($delayMs -le 0) { throw 'monotonic_wait_nonpositive_delay_before_target' }
        & $SleepMilliseconds $delayMs
        $rechecks++
    }
}

function Get-MonotonicReconstructionDelayMilliseconds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$TargetElapsedMilliseconds,
        [Parameter(Mandatory)][double]$CurrentElapsedMilliseconds
    )
    $remainingMilliseconds = [double]$TargetElapsedMilliseconds - $CurrentElapsedMilliseconds
    if ($remainingMilliseconds -le 0) { return 0 }
    [int][Math]::Ceiling($remainingMilliseconds)
}

function Assert-MonotonicReconstructionObservations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Plan,
        [Parameter(Mandatory)][object[]]$Observations
    )
    if (@($Plan.target_elapsed_ms).Count -ne [int]$Plan.target_count) {
        throw 'monotonic_schedule_plan_target_count_mismatch'
    }
    for ($index = 0; $index -lt [int]$Plan.target_count; $index++) {
        if ([long]$Plan.target_elapsed_ms[$index] -ne [long]($index * [int]$Plan.cadence_seconds * 1000)) {
            throw 'monotonic_schedule_plan_target_sequence_mismatch'
        }
    }
    foreach ($observation in $Observations) {
        if ([double]$observation.sample_completed_elapsed_ms -gt
            ([int]$Plan.completion_timeout_seconds * 1000)) {
            throw 'monotonic_schedule_completion_timeout_exceeded'
        }
    }
    if ($Observations.Count -ne [int]$Plan.target_count) {
        throw 'monotonic_schedule_target_count_not_completed'
    }
    for ($index = 0; $index -lt $Observations.Count; $index++) {
        $observation = $Observations[$index]
        if ([int]$observation.target_index -ne $index -or
            [long]$observation.target_elapsed_ms -ne [long]$Plan.target_elapsed_ms[$index]) {
            throw 'monotonic_schedule_target_identity_mismatch'
        }
        if ([double]$observation.sample_started_elapsed_ms -lt [long]$observation.target_elapsed_ms) {
            throw 'monotonic_schedule_sample_started_before_target'
        }
        if ([double]$observation.sample_completed_elapsed_ms -lt [double]$observation.sample_started_elapsed_ms) {
            throw 'monotonic_schedule_sample_completion_invalid'
        }
        $expectedLateness = [double]$observation.sample_started_elapsed_ms -
            [double]$observation.target_elapsed_ms
        if ([double]$observation.lateness_ms -ne $expectedLateness) {
            throw 'monotonic_schedule_lateness_mismatch'
        }
        if ($expectedLateness -ge [int]$Plan.maximum_lateness_ms_exclusive) {
            throw 'monotonic_schedule_lateness_limit_exceeded'
        }
        if ([int]$observation.exit_code -ne 0 -or $observation.host -ne 'Running' -or
            $observation.kubelet -ne 'Running' -or $observation.apiserver -ne 'Running' -or
            $observation.kubeconfig -ne 'Configured') {
            throw 'monotonic_schedule_unstable_observation'
        }
    }
    $last = $Observations[$Observations.Count - 1]
    $latenessValues = @($Observations | ForEach-Object { [double]$_.lateness_ms })
    [pscustomobject]@{
        target_count = [int]$Plan.target_count
        completed_count = $Observations.Count
        stable_count = $Observations.Count
        maximum_lateness_ms = [double](($latenessValues | Measure-Object -Maximum).Maximum)
        completed_elapsed_ms = [double]$last.sample_completed_elapsed_ms
    }
}

function ConvertTo-JsonSafeInt64 {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Value,
        [Parameter(Mandatory)][string]$FieldName
    )
    $integerTypes = @(
        [byte], [sbyte], [int16], [uint16], [int32], [uint32], [int64], [uint64]
    )
    if ($null -eq $Value -or $integerTypes -notcontains $Value.GetType()) {
        throw "monotonic_tick_json_integer_required:$FieldName"
    }
    $asBigInteger = [System.Numerics.BigInteger]$Value
    $jsonSafeMaximum = [System.Numerics.BigInteger]9007199254740991
    if ($asBigInteger -lt [System.Numerics.BigInteger]0 -or
        $asBigInteger -gt $jsonSafeMaximum) {
        throw "monotonic_tick_json_safe_integer_exceeded:$FieldName"
    }
    [long]$asBigInteger
}

function Get-CheckedInt64Product {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$Left,
        [Parameter(Mandatory)][long]$Right,
        [Parameter(Mandatory)][string]$FieldName
    )
    if ($Left -lt 0 -or $Right -lt 0) {
        throw "monotonic_tick_negative_product_operand:$FieldName"
    }
    $product = ([System.Numerics.BigInteger]$Left) * ([System.Numerics.BigInteger]$Right)
    if ($product -gt [System.Numerics.BigInteger][long]::MaxValue) {
        throw "monotonic_tick_int64_overflow:$FieldName"
    }
    [long]$product
}

function Get-MonotonicReconstructionLatenessNumerator {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$SampleStartedTicks,
        [Parameter(Mandatory)][long]$TargetElapsedMilliseconds,
        [Parameter(Mandatory)][long]$StopwatchFrequency
    )
    $sampleTerm = Get-CheckedInt64Product `
        -Left $SampleStartedTicks -Right 1000 -FieldName 'sample_started_ticks_x_1000'
    $targetTerm = Get-CheckedInt64Product `
        -Left $TargetElapsedMilliseconds -Right $StopwatchFrequency `
        -FieldName 'target_elapsed_ms_x_frequency'
    $numerator = ([System.Numerics.BigInteger]$sampleTerm) - ([System.Numerics.BigInteger]$targetTerm)
    if ($numerator -lt [System.Numerics.BigInteger][long]::MinValue -or
        $numerator -gt [System.Numerics.BigInteger][long]::MaxValue) {
        throw 'monotonic_tick_int64_overflow:lateness_numerator'
    }
    [long]$numerator
}

function Get-MonotonicReconstructionDelayMillisecondsFromTicks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$TargetElapsedMilliseconds,
        [Parameter(Mandatory)][long]$CurrentElapsedTicks,
        [Parameter(Mandatory)][long]$StopwatchFrequency
    )
    if ($StopwatchFrequency -le 0) { throw 'monotonic_tick_frequency_invalid' }
    if ($TargetElapsedMilliseconds -lt 0 -or $CurrentElapsedTicks -lt 0) {
        throw 'monotonic_tick_wait_value_negative'
    }
    $latenessNumerator = Get-MonotonicReconstructionLatenessNumerator `
        -SampleStartedTicks $CurrentElapsedTicks `
        -TargetElapsedMilliseconds $TargetElapsedMilliseconds `
        -StopwatchFrequency $StopwatchFrequency
    if ($latenessNumerator -ge 0) { return 0 }
    $remainingNumerator = [long](-$latenessNumerator)
    $remainder = [long]0
    $quotient = [Math]::DivRem($remainingNumerator, $StopwatchFrequency, [ref]$remainder)
    if ($remainder -gt 0) { $quotient++ }
    if ($quotient -gt [int]::MaxValue) { throw 'monotonic_tick_wait_milliseconds_overflow' }
    [int]$quotient
}

function Wait-MonotonicReconstructionTargetTicks {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$TargetElapsedMilliseconds,
        [Parameter(Mandatory)][long]$StopwatchFrequency,
        [Parameter(Mandatory)][scriptblock]$GetElapsedTicks,
        [Parameter(Mandatory)][scriptblock]$SleepMilliseconds,
        [int]$MaximumRechecks = 1000
    )
    if ($StopwatchFrequency -le 0) { throw 'monotonic_tick_frequency_invalid' }
    if ($TargetElapsedMilliseconds -lt 0) { throw 'monotonic_tick_wait_negative_target' }
    if ($MaximumRechecks -le 0) { throw 'monotonic_tick_wait_invalid_recheck_limit' }
    $rechecks = 0
    while ($true) {
        $elapsedTicks = ConvertTo-JsonSafeInt64 `
            -Value (& $GetElapsedTicks) -FieldName 'current_elapsed_ticks'
        $latenessNumerator = Get-MonotonicReconstructionLatenessNumerator `
            -SampleStartedTicks $elapsedTicks `
            -TargetElapsedMilliseconds $TargetElapsedMilliseconds `
            -StopwatchFrequency $StopwatchFrequency
        if ($latenessNumerator -ge 0) {
            return [pscustomobject]@{
                target_elapsed_ms = $TargetElapsedMilliseconds
                reached_elapsed_ticks = $elapsedTicks
                stopwatch_frequency_hz = $StopwatchFrequency
                recheck_count = $rechecks
                target_reached = $true
            }
        }
        if ($rechecks -ge $MaximumRechecks) { throw 'monotonic_tick_wait_recheck_limit_exceeded' }
        $delayMs = Get-MonotonicReconstructionDelayMillisecondsFromTicks `
            -TargetElapsedMilliseconds $TargetElapsedMilliseconds `
            -CurrentElapsedTicks $elapsedTicks `
            -StopwatchFrequency $StopwatchFrequency
        if ($delayMs -le 0) { throw 'monotonic_tick_wait_nonpositive_delay_before_target' }
        & $SleepMilliseconds $delayMs
        $rechecks++
    }
}

function Convert-StopwatchTicksToDisplayMilliseconds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$ElapsedTicks,
        [Parameter(Mandatory)][long]$StopwatchFrequency
    )
    if ($ElapsedTicks -lt 0 -or $StopwatchFrequency -le 0) {
        throw 'monotonic_tick_display_value_invalid'
    }
    $displayValue = ([decimal]$ElapsedTicks * [decimal]1000) / [decimal]$StopwatchFrequency
    $displayValue.ToString('G29', [Globalization.CultureInfo]::InvariantCulture)
}

function Convert-LatenessNumeratorToDisplayMilliseconds {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$LatenessNumerator,
        [Parameter(Mandatory)][long]$StopwatchFrequency
    )
    if ($LatenessNumerator -lt 0 -or $StopwatchFrequency -le 0) {
        throw 'monotonic_tick_display_value_invalid'
    }
    $displayValue = [decimal]$LatenessNumerator / [decimal]$StopwatchFrequency
    $displayValue.ToString('G29', [Globalization.CultureInfo]::InvariantCulture)
}

function New-MonotonicReconstructionTickPlan {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][long]$StopwatchFrequency,
        [int]$DurationSeconds = 180,
        [int]$CadenceSeconds = 5,
        [int]$CompletionTimeoutSeconds = 210,
        [int]$MaximumLatenessMilliseconds = 5000,
        [string]$WaitStrategy = 'guarded_tick_rational_ceiling'
    )
    $legacyShape = New-MonotonicReconstructionObservationPlan `
        -DurationSeconds $DurationSeconds -CadenceSeconds $CadenceSeconds `
        -CompletionTimeoutSeconds $CompletionTimeoutSeconds `
        -MaximumLatenessMilliseconds $MaximumLatenessMilliseconds `
        -WaitStrategy 'guarded_branch_then_ceiling'
    $validatedFrequency = ConvertTo-JsonSafeInt64 `
        -Value $StopwatchFrequency -FieldName 'stopwatch_frequency_hz'
    if ($validatedFrequency -le 0) { throw 'monotonic_tick_frequency_invalid' }
    [pscustomobject]@{
        schema_version = 2
        mode = 'monotonic_target_time'
        clock = 'System.Diagnostics.Stopwatch'
        timing_representation = 'elapsed_ticks_with_recorded_frequency'
        authoritative_numeric_type = 'json_safe_int64'
        display_milliseconds_authoritative = $false
        stopwatch_frequency_hz = $validatedFrequency
        window_semantics = $legacyShape.window_semantics
        duration_seconds = $DurationSeconds
        cadence_seconds = $CadenceSeconds
        completion_timeout_seconds = $CompletionTimeoutSeconds
        maximum_lateness_ms_exclusive = $MaximumLatenessMilliseconds
        wait_strategy = $WaitStrategy
        target_count = $legacyShape.target_count
        target_elapsed_ms = @($legacyShape.target_elapsed_ms)
    }
}

function Assert-MonotonicReconstructionTickObservations {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object]$Plan,
        [Parameter(Mandatory)][object[]]$Observations
    )
    $schemaVersion = ConvertTo-JsonSafeInt64 -Value $Plan.schema_version -FieldName 'schema_version'
    if ($schemaVersion -ne 2 -or
        $Plan.mode -ne 'monotonic_target_time' -or
        $Plan.clock -ne 'System.Diagnostics.Stopwatch' -or
        $Plan.timing_representation -ne 'elapsed_ticks_with_recorded_frequency' -or
        $Plan.authoritative_numeric_type -ne 'json_safe_int64' -or
        [bool]$Plan.display_milliseconds_authoritative -or
        $Plan.window_semantics -ne 'half_open_[0,duration)' -or
        $Plan.wait_strategy -ne 'guarded_tick_rational_ceiling') {
        throw 'monotonic_tick_plan_representation_mismatch'
    }
    $frequency = ConvertTo-JsonSafeInt64 `
        -Value $Plan.stopwatch_frequency_hz -FieldName 'stopwatch_frequency_hz'
    if ($frequency -le 0) { throw 'monotonic_tick_frequency_invalid' }
    $targetCount = ConvertTo-JsonSafeInt64 -Value $Plan.target_count -FieldName 'target_count'
    $durationSeconds = ConvertTo-JsonSafeInt64 -Value $Plan.duration_seconds -FieldName 'duration_seconds'
    $cadenceSeconds = ConvertTo-JsonSafeInt64 -Value $Plan.cadence_seconds -FieldName 'cadence_seconds'
    $maximumLatenessMilliseconds = ConvertTo-JsonSafeInt64 `
        -Value $Plan.maximum_lateness_ms_exclusive -FieldName 'maximum_lateness_ms_exclusive'
    $completionTimeoutSeconds = ConvertTo-JsonSafeInt64 `
        -Value $Plan.completion_timeout_seconds -FieldName 'completion_timeout_seconds'
    if ($durationSeconds -ne 180 -or $cadenceSeconds -ne 5 -or
        $completionTimeoutSeconds -ne 210 -or $maximumLatenessMilliseconds -ne 5000 -or
        $targetCount -ne 36) {
        throw 'monotonic_tick_frozen_plan_mismatch'
    }
    if (@($Plan.target_elapsed_ms).Count -ne $targetCount) {
        throw 'monotonic_tick_plan_target_count_mismatch'
    }
    for ($index = 0; $index -lt $targetCount; $index++) {
        $target = ConvertTo-JsonSafeInt64 `
            -Value $Plan.target_elapsed_ms[$index] -FieldName "target_elapsed_ms[$index]"
        $expectedTarget = Get-CheckedInt64Product `
            -Left ([long]$index) -Right $cadenceSeconds -FieldName "target_seconds[$index]"
        $expectedTarget = Get-CheckedInt64Product `
            -Left $expectedTarget -Right 1000 -FieldName "target_elapsed_ms[$index]"
        if ($target -ne $expectedTarget) {
            throw 'monotonic_tick_plan_target_sequence_mismatch'
        }
    }
    if ($Observations.Count -ne $targetCount) {
        throw 'monotonic_tick_target_count_not_completed'
    }
    $latenessLimitNumerator = Get-CheckedInt64Product `
        -Left $maximumLatenessMilliseconds -Right $frequency `
        -FieldName 'maximum_lateness_ms_x_frequency'
    $completionLimitTicks = Get-CheckedInt64Product `
        -Left $completionTimeoutSeconds -Right $frequency `
        -FieldName 'completion_timeout_seconds_x_frequency'
    $maximumLatenessNumerator = [long]0
    for ($index = 0; $index -lt $Observations.Count; $index++) {
        $observation = $Observations[$index]
        $target = ConvertTo-JsonSafeInt64 `
            -Value $observation.target_elapsed_ms -FieldName "observations[$index].target_elapsed_ms"
        $started = ConvertTo-JsonSafeInt64 `
            -Value $observation.sample_started_ticks -FieldName "observations[$index].sample_started_ticks"
        $completed = ConvertTo-JsonSafeInt64 `
            -Value $observation.sample_completed_ticks -FieldName "observations[$index].sample_completed_ticks"
        $observationIndex = ConvertTo-JsonSafeInt64 `
            -Value $observation.target_index -FieldName "observations[$index].target_index"
        $observationFrequency = ConvertTo-JsonSafeInt64 `
            -Value $observation.stopwatch_frequency_hz `
            -FieldName "observations[$index].stopwatch_frequency_hz"
        if ($observationFrequency -ne $frequency) {
            throw 'monotonic_tick_frequency_mismatch'
        }
        if ($observationIndex -ne $index -or
            $target -ne [long]$Plan.target_elapsed_ms[$index]) {
            throw 'monotonic_tick_target_identity_mismatch'
        }
        if ($completed -lt $started) { throw 'monotonic_tick_sample_completion_invalid' }
        if ($completed -gt $completionLimitTicks) {
            throw 'monotonic_tick_completion_timeout_exceeded'
        }
        $latenessNumerator = Get-MonotonicReconstructionLatenessNumerator `
            -SampleStartedTicks $started -TargetElapsedMilliseconds $target `
            -StopwatchFrequency $frequency
        if ($latenessNumerator -lt 0) { throw 'monotonic_tick_sample_started_before_target' }
        if ($latenessNumerator -ge $latenessLimitNumerator) {
            throw 'monotonic_tick_lateness_limit_exceeded'
        }
        if ($latenessNumerator -gt $maximumLatenessNumerator) {
            $maximumLatenessNumerator = $latenessNumerator
        }
        $waitRecheckCount = ConvertTo-JsonSafeInt64 `
            -Value $observation.wait_recheck_count `
            -FieldName "observations[$index].wait_recheck_count"
        $exitCode = ConvertTo-JsonSafeInt64 `
            -Value $observation.exit_code -FieldName "observations[$index].exit_code"
        if ($observation.wait_strategy -ne $Plan.wait_strategy -or
            -not [bool]$observation.wait_guard_satisfied -or
            $waitRecheckCount -lt 0) {
            throw 'monotonic_tick_wait_evidence_missing'
        }
        if ($exitCode -ne 0 -or $observation.host -ne 'Running' -or
            $observation.kubelet -ne 'Running' -or $observation.apiserver -ne 'Running' -or
            $observation.kubeconfig -ne 'Configured') {
            throw 'monotonic_tick_unstable_observation'
        }
    }
    $last = $Observations[$Observations.Count - 1]
    [pscustomobject]@{
        target_count = [int]$targetCount
        completed_count = $Observations.Count
        stable_count = $Observations.Count
        stopwatch_frequency_hz = $frequency
        maximum_lateness_numerator = $maximumLatenessNumerator
        maximum_lateness_ms_display = Convert-LatenessNumeratorToDisplayMilliseconds `
            -LatenessNumerator $maximumLatenessNumerator -StopwatchFrequency $frequency
        completed_elapsed_ticks = [long]$last.sample_completed_ticks
        completed_elapsed_ms_display = Convert-StopwatchTicksToDisplayMilliseconds `
            -ElapsedTicks ([long]$last.sample_completed_ticks) -StopwatchFrequency $frequency
        display_values_authoritative = $false
    }
}

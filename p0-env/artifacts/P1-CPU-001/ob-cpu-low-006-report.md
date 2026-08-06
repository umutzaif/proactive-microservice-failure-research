# P1-CPU-001 / ob-cpu-low-006 Invalid Low CPU Repeat Run

## Disposition

The second independent repeat completed its bounded worker, physical-effect,
pod-continuity, host-health and schema-v3 telemetry gates, but scientific
metadata finalization rejected the lifecycle duration. The run remains invalid,
is excluded from the scientific dataset and will not be rerun under the same
run ID. All partial evidence is preserved.

## Lifecycle and integrity

- Code revision: `f000418e3969d19c6ae25d067ec108a65d029bf5`
- Warm-up start: `2026-08-06T10:56:13.0712366Z`
- Normal-baseline start: `2026-08-06T11:01:13.4666186Z`
- Injector outer start/end: `2026-08-06T11:06:23.5722758Z` / `2026-08-06T11:13:28.8850314Z`
- Cooldown end: `2026-08-06T11:18:29.7901185Z`
- Worker: 1 started, 84 heartbeat, 1 completed; monotonic elapsed `420.000233s`
- Pod UID/restart continuity: passed
- Host deltas: WHEA 17 = 0, Kernel-Power 41 = 0, bugcheck = 0
- Raw logs: 15 files; verification passed
- Enriched logs: 43,328 records; verification passed
- Metrics: 4,118 series / 1,093,337 samples; verification passed
- Schema-v3 traces: 6,622 selected traces / 69,839 spans; run-ID, time,
  boundary and chunk failures = 0; 3 boundary-crossing traces excluded
- Failure manifestation: null across 207 complete five-second windows

## Physical CPU effect

- Baseline / steady intervals: `60 / 60` (required: at least `48` each)
- Baseline mean: `12.784m`
- Steady mean: `61.684m`
- Increase: `48.899m` (required: at least `25m`)
- Throttling series present; mean equivalent: `12.489m`

## Finalization failure

The worker's own monotonic evidence shows the preregistered 420-second total
duration. The outer `kubectl exec` wall-clock interval was `425.313s`; after the
fixed 120-second ramp, metadata therefore represented a `305.313s` steady phase.
The verifier requires 300 seconds within a five-second tolerance and correctly
reported `steady_duration_mismatch`. No final receipt was produced.

The tolerance is not relaxed after observing the result. A new run requires an
explicit decision on whether lifecycle UTC must come from worker-emitted UTC
events rather than transport-inclusive outer process timestamps.

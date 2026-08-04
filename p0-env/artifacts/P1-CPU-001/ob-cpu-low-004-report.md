# P1-CPU-001 / ob-cpu-low-004 Valid Low CPU Calibration Run

## Disposition

The complete `cpu-recommendation-low-v2` lifecycle passed physical-effect,
pod-continuity, host-health, immutable log/metric/schema-v3 trace, scientific
metadata, final receipt and offline receipt verification gates. The run is the
first valid low CPU-stress calibration candidate and may be included in the
pilot scientific dataset under its recorded labels.

## Lifecycle and integrity

- Code revision: `0643c7b51d606db3fc8bc3fa810828f3b5db4946`
- Warm-up start: `2026-08-04T15:00:51.7669100Z`
- Normal-baseline start: `2026-08-04T15:05:51.7794186Z`
- Injection start/end: `2026-08-04T15:10:53.1827978Z` / `2026-08-04T15:17:58.1772235Z`
- Cooldown end: `2026-08-04T15:22:58.7680870Z`
- Worker: 1 started, 84 heartbeat, 1 completed; bounded verification passed
- Pod UID/restart continuity: passed
- Host deltas: WHEA 17 = 0, Kernel-Power 41 = 0, bugcheck = 0
- Raw logs: 15 files; verification passed
- Enriched logs: 43,658 records; verification passed
- Metrics: 4,810 series / 1,111,199 samples; verification passed
- Schema-v3 traces: 6,690 selected traces / 70,112 spans; run-ID, time,
  boundary and chunk failures = 0; 3 boundary-crossing traces excluded
- Final receipt and offline verification: passed

## Physical CPU effect

- Baseline / steady intervals: `59 / 60` (required: at least `48` each)
- Baseline mean: `9.551m`
- Steady mean: `58.014m`
- Increase: `48.463m` (required: at least `25m`)
- Throttling series present; mean equivalent: `4.333m`

## Manifestation result

The fixed-grid detector evaluated 205 complete five-second windows. Neither the
product-latency nor global-error condition completed the required three-window
streak, so `failure_manifestation` is null. This is a valid negative
manifestation result at low severity; it does not authorize post-hoc SLO changes
or prove that higher severities will behave similarly.

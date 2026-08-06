# P1-CPU-001 / ob-cpu-low-005 Valid Low CPU Repeat Run

## Disposition

The first independent repeat of `ob-cpu-low-004` passed the unchanged
`cpu-recommendation-low-v2` physical-effect, pod-continuity, host-health,
immutable telemetry, scientific metadata, final receipt and offline receipt
verification gates. It is a valid low CPU-stress calibration candidate.

## Lifecycle and integrity

- Code revision: `8f2e3d426204db0b99f4784ae9a16ec4012f5cc1`
- Warm-up start: `2026-08-06T10:09:09.5301289Z`
- Normal-baseline start: `2026-08-06T10:14:09.5482484Z`
- Injection start/end: `2026-08-06T10:19:11.5526681Z` / `2026-08-06T10:26:16.1146966Z`
- Cooldown end: `2026-08-06T10:31:17.2348082Z`
- Worker: 1 started, 84 heartbeat, 1 completed; bounded verification passed
- Pod UID/restart continuity: passed
- Host deltas: WHEA 17 = 0, Kernel-Power 41 = 0, bugcheck = 0
- Raw logs: 15 files; verification passed
- Enriched logs: 43,803 records; verification passed
- Metrics: 4,680 series / 1,110,047 samples; verification passed
- Schema-v3 traces: 6,688 selected traces / 70,643 spans; run-ID, time,
  boundary and chunk failures = 0; 5 boundary-crossing traces excluded
- Final receipt and offline verification: passed

## Physical CPU effect

- Baseline / steady intervals: `59 / 60` (required: at least `48` each)
- Baseline mean: `11.300m`
- Steady mean: `63.351m`
- Increase: `52.050m` (required: at least `25m`)
- Throttling series present; mean equivalent: `6.508m`

## Manifestation result

The fixed-grid detector evaluated 205 complete five-second windows and produced
`failure_manifestation = null`. This independently repeats the valid null result
from `ob-cpu-low-004`, but two valid runs are still insufficient to freeze a
variance claim or change severity/SLO. The preregistered `ob-cpu-low-006` repeat
remains required.

# P1-CPU-001 / ob-cpu-low-002 Invalid Calibration Run

## Disposition

The complete lifecycle and immutable telemetry capture succeeded, but the run
failed one preregistered physical-effect gate and remains invalid. It is not
included in the scientific dataset and is not retroactively reclassified.

## Lifecycle and integrity

- Warm-up start: `2026-08-04T10:23:55.1965599Z`
- Normal-baseline start: `2026-08-04T10:28:55.2054043Z`
- Injection start/end: `2026-08-04T10:33:56.6959892Z` / `2026-08-04T10:41:02.8746100Z`
- Worker: 1 started, 84 heartbeat, 1 completed event; bounded verification passed
- Pod UID/restart continuity: passed
- Host deltas: WHEA 17 = 0, Kernel-Power 41 = 0, bugcheck = 0
- Raw logs: 15 files; verification passed
- Enriched logs: 43,805 records; verification passed
- Metrics: 4,170 series / 1,064,015 samples; verification passed
- Schema-v3 traces: 6,694 selected traces / 70,726 spans; run-ID, time,
  boundary and chunk failures = 0
- Failure manifestation: null; neither frozen latency nor error streak completed

## Physical CPU effect

- Baseline mean: `11.173m`
- Steady mean: `61.764m`
- Increase: `50.591m` (required magnitude: at least `25m`)
- Throttling series present; mean equivalent: `6.419m`
- Baseline / steady CPU-rate intervals: `59 / 60`
- Preregistered minimum per phase: `240`

The magnitude criterion passed but the interval-count criterion failed. The
archived target CPU series has 266 samples and 265 intervals; every timestamp
delta is exactly five seconds. Therefore a 300-second phase can provide about
60 observed rate intervals, not 300. The configured Prometheus query step of one
second does not interpolate new scrape samples.

## Evidence hashes

- Injector/physical-effect evidence: `9acbf071324091dd3ca7cd8a173feda50fda51f87ad06005069fdd5beec310ab`
- Manifestation evidence: `3341fb110573649f1d596f1e3266d2dbef8c1b89454e83386858689ded557039`
- Run assessment: `53b1322ef9dc204c2b78d16610ab8f58ab582fa452a1bb2273876e93581115d6`

No final valid receipt was produced. Any correction to the sampling-coverage
gate applies only to a new run ID and requires an explicit research decision.

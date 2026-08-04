# P1-CPU-001 / ob-cpu-low-003 Invalid Calibration Run

## Disposition

The full lifecycle, physical-effect analysis and telemetry verification completed,
but final receipt creation failed in the scientific metadata verifier. The run
remains invalid, is excluded from the scientific dataset and will not be rerun
under the same run ID. All partial evidence is preserved.

## Lifecycle and integrity

- Code revision: `843a006d2d4ab82797a7c6deafeda752d71381e5`
- Warm-up start: `2026-08-04T13:01:39.1004953Z`
- Normal-baseline start: `2026-08-04T13:06:39.1115058Z`
- Injection start/end: `2026-08-04T13:11:40.5762957+00:00` / `2026-08-04T13:18:48.3683179+00:00`
- Cooldown end: `2026-08-04T13:23:48.8641038Z`
- Worker: 1 started, 84 heartbeat, 1 completed; bounded verification passed
- Pod UID/restart continuity: passed
- Host deltas: WHEA 17 = 0, Kernel-Power 41 = 0, bugcheck = 0
- Raw logs: 15 files; verification passed
- Enriched logs: 44,631 records; verification passed
- Metrics: 4,124 series / 1,087,174 samples; verification passed
- Schema-v3 traces: 6,802 selected traces / 72,171 spans; run-ID, time,
  boundary and chunk failures = 0
- Failure manifestation: null

## Physical CPU effect

- Baseline / steady intervals: `59 / 60` (required: at least `48` each)
- Baseline mean: `12.075m`
- Steady mean: `60.965m`
- Increase: `48.890m` (required: at least `25m`)
- Throttling series present; mean equivalent: `5.064m`

The v2 physical-effect contract passed. This does not make the run valid because
the immutable final receipt and offline verification gates did not complete.

## Finalization failure

The injector serialized UTC as `+00:00`, while the canonical metadata verifier
requires a trailing `Z`. The verifier also leaked the return value of its failure
list insertion, producing an `op_Subtraction` type error instead of a clean
`invalid_utc` rejection. No final valid receipt was produced. The producer and
verifier must be corrected and independently tested before a new run ID is used.

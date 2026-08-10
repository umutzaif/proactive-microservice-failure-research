# P1-WORKLOAD-CAPACITY-001 Preregistration

## Purpose and scope

This fault-free tooling study selects a second workload level for P3 without
using fault outcomes. Its output is decision evidence, not scientific dataset
input. The 10-user reference and 15/20-user candidates keep image, replica,
spawn rate (`1/s`), wait distribution, task weights, seed (`1`), tracing and
phase durations unchanged.

## Candidate order and lifecycle

- Randomization seed: `20260810`
- Frozen order: `20 users -> 10 users -> 15 users`
- Each candidate: independent cluster start, active run-ID gate, 300-second
  warm-up, 300-second measurement, telemetry archive/verification, controlled
  cluster stop and host-health comparison.
- Run IDs: `ob-capacity-20u-001`, `ob-capacity-10u-001`,
  `ob-capacity-15u-001`.

## Candidate validity gates

A candidate is evaluable only if:

1. active run-ID verification passes;
2. all 15 deployment pod UIDs and restart totals remain stable during the
   measurement window;
3. schema-v3 metric/trace archive verification passes with zero run-ID, time or
   chunk-coverage failures;
4. WHEA Event 17, Kernel-Power 41 and bugcheck deltas are all zero;
5. the frozen SLO produces no three-consecutive-window manifestation.

Invalid evidence is retained and the same run ID is not reused.

## Selection rule frozen before results

The highest-user candidate is selected only when it passes all validity gates,
has frontend user-server-span rate at least `1.30x` the measured 10-user
reference, and recommendationservice mean CPU is at most `25m`. The CPU limit
is `200m`; this gate preserves at least `25m` nominal mean headroom after the
existing `+150m` high request. CPU p95 and throttling are reported but are not
post-hoc replacement gates.

Selection order is `20`, then `15`. If neither passes, no second workload is
selected and thresholds are not relaxed.

## Downstream preregistration if a candidate passes

- Collect three valid fault-free scientific normal baselines at the selected
  workload before its fault runs.
- Collect two valid runs for each existing low/medium/high profile at the
  selected workload; invalid runs remain recorded and are replaced with new
  run IDs under unchanged conditions.
- Fault-run randomization seed: `20260810`.
- Frozen six-run order:
  `medium-2, low-2, high-1, high-2, low-1, medium-1`.
- Existing 10-user calibration runs remain provenance evidence; the six new
  second-workload runs form the workload challenge block. No model training,
  LLM validation, GAT execution, SLO change or target-service change is
  authorized by this preregistration.

## Falsification

Independent reviewers can rerun the analyzer from sealed schema-v3 telemetry,
the frozen SLO and versioned workload profiles. A different result under the
same inputs, a failed checksum, or any gate failure falsifies selection.

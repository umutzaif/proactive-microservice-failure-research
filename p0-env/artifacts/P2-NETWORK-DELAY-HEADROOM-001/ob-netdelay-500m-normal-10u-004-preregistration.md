# ob-netdelay-500m-normal-10u-004 preregistration

## Purpose and status

This planned no-fault run replaces only the invalid D-067 `10u-002` collection slot.
It is repository preparation, not runtime authorization. The invalid evidence remains
immutable and `10u-003` remains the final frozen 10u slot.

## Frozen contract

- Workload: `ob-default-10u-1r-v1` (10 users, rate 1, seed 1).
- Topology: no-toxic proxy overlay; no toxic and no fault.
- Resources: recommendationservice server `500m/100m`, proxy `100m`.
- Lifecycle: 120-second stability, 300-second warm-up, 300-second baseline.
- Acceptance: 60 expected/48 minimum nonempty five-second windows, null frozen-SLO
  manifestation, stable pod lifecycle, schema-v3 telemetry, host, rollback, metadata,
  final-receipt and replay gates already bound by D-067.
- Thresholds, probes, topology, workload and scientific interpretation are unchanged.

## Fail-closed boundaries

The run must not start before a canonical merge and fresh explicit runtime approval.
Any failed gate preserves this ID as invalid/incomplete; it cannot be reused or repaired
after observing results. Success would raise 10u eligibility from `1/3` to `2/3` only.
It would not complete headroom, select a ladder severity, authorize fault injection, or
enter Dataset v1 by itself.

## Independent verification

The decision-input verifier and runner contract fixtures must pass in PowerShell 5.1 and
7. They must prove that the original randomized sequence is unchanged, `10u-002` is
invalid, only its effective slot is `10u-004`, `10u-003` remains last, and execution
authorization is false. Rendered manifests must bind `10u-004`, workload 10/1/1 and no toxic.

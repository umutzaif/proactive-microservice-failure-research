# ob-netdelay-500m-normal-10u-001 valid run report

## Scientific status

`ob-netdelay-500m-normal-10u-001` is the first valid 10u input for the D-067
500m normal-headroom design. It is a no-fault normal observation and does not select
or authorize a delay severity.

## Conditions and measurement

- Workload: `ob-default-10u-1r-v1` (10 users, spawn rate 1/s, seed 1).
- Topology/resources: no-toxic Toxiproxy overlay; server `500m/100m`, proxy `100m`.
- Timing: 300-second warm-up and 300-second baseline.
- Primary run summary: maximum nonempty product-detail five-second window-p95 latency
  during baseline = **612.248 ms**.
- Coverage: 60/60 complete and nonempty product-detail windows.
- Frozen failure manifestation: null.

The maximum exceeds the frozen `594.664 ms` latency threshold, but the SLO requires
three consecutive violating nonempty windows. A single run-level maximum therefore
does not establish manifestation and must not be relabeled as a fault.

## Validity evidence

Target stability passed 25 observations with zero restarts. Proxy clean state passed
before and after the window. Raw verification passed 17/17; enriched logs contained
20,340 verified records. Schema-v3 telemetry passed 25/25 manifest entries, 508,877
metric samples, 3,112 selected unique traces, and 33,165 spans. Pod lifecycle,
rollback, zero host-event deltas, metadata 15/15, finalization, and offline receipt
verification all passed.

## Interpretation boundary

This is only the first of three required 10u runs. It supplies matched normal-side
evidence and shows why the preregistered consecutive-window rule is distinct from an
extreme single-window statistic. It does not establish repeatability, the three-run
normal bound/range, population-tail coverage, fault causality, or an academic severity
decision.

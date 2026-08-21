# ob-netdelay-500m-normal-15u-002 valid run report

## Scientific status

`ob-netdelay-500m-normal-15u-002` is the second valid 15u input for the D-067
500m normal-headroom design. It is a no-fault normal observation and does not select
or authorize a network-delay severity.

## Conditions and measurement

- Workload: `ob-second-15u-1r-v1` (15 users, spawn rate 1/s, seed 1).
- Topology/resources: no-toxic Toxiproxy overlay; server `500m/100m`, proxy `100m`.
- Timing: 300-second warm-up and 300-second baseline.
- Primary run summary: maximum nonempty product-detail five-second window-p95 latency
  during baseline = **374.397 ms**.
- Coverage: 60/60 complete and nonempty product-detail windows; frozen failure
  manifestation remained null.

## Validity evidence

Target stability passed 25 observations with zero restarts. Proxy clean state passed
before and after the window. Raw verification passed 17/17; enriched logs contained
26,110 verified records. Schema-v3 telemetry passed 25/25 manifest entries, 505,206
metric samples, 3,750 selected unique traces, and 46,445 spans. Pod lifecycle,
rollback, zero host-event deltas, metadata 15/15, finalization, and offline receipt
verification all passed.

## Interpretation boundary

Together with `15u-006` (`539.155 ms`), this establishes two independently sealed
15u observations under matched conditions. The observed two-run spread is
`164.758 ms`, but D-067 defines the range and normal upper bound over **three** valid
runs. Therefore this interim spread is descriptive only and must not be used for the
headroom or candidate-margin calculation.

The result strengthens repeatability evidence but does not yet establish the required
15u sample size, a population-tail guarantee, fault manifestation, causality, or an
academic severity decision.

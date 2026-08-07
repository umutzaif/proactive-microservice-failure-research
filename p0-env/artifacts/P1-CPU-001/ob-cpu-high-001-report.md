# ob-cpu-high-001 Valid Run Report

- Status: `completed/valid`
- Scientific dataset inclusion: `true`
- Profile: `cpu-recommendation-high-v1`
- Workload/SLO/seed: `ob-default-10u-1r-v1` / `p1-cpu-001-slo-v1` / `1`
- Code revision: `4379851`
- Worker UTC: `2026-08-07T11:51:40.480469Z` to `2026-08-07T11:58:40.456173Z`
- Worker wall/monotonic duration: `419.975704` / `420.000295` seconds
- Baseline/steady CPU: `11.564m` / `158.153m`
- Steady minus baseline: `+146.589m` (required `>=75m`)
- Baseline/steady interval coverage: `59/59` (required `>=48` each)
- Throttling mean equivalent: `13.236m`; series present
- Complete SLO windows: `205`
- Product-latency violation windows: `1`; maximum product p95 `497.801 ms`; no three-window streak
- Global-error violation windows: `0`
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Pod lifecycle: all 15 tracked deployments stable

Immutable evidence closure passed for 15 raw log files, 44,415 enriched log
records, 1,088,907 metric samples, 35 schema-v3 trace chunks, 6,754 unique
selected traces and 71,670 spans. One lifecycle-boundary trace was excluded
under the preregistered policy. Chunk coverage, run-ID and time failures were
zero. Scientific metadata, final receipt and a second independent offline
finalized-run verification all passed.

This is the first valid high-severity CPU calibration candidate. It confirms a
strong physical CPU effect under the fixed workload, while the single latency
violation window did not satisfy the frozen three-window manifestation rule.
One run does not establish high-severity repeatability and does not authorize
post-hoc SLO changes, a different workload/service or model training.

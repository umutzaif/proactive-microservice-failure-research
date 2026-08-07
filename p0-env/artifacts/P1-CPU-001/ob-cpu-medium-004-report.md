# ob-cpu-medium-004 Valid Run Report

- Status: `completed/valid`
- Scientific dataset inclusion: `true`
- Profile: `cpu-recommendation-medium-v1`
- Workload/SLO/seed: `ob-default-10u-1r-v1` / `p1-cpu-001-slo-v1` / `1`
- Code revision: `59e1a8d`
- Worker UTC: `2026-08-07T10:50:17.690908Z` to `2026-08-07T10:57:17.655865Z`
- Worker wall/monotonic duration: `419.964957` / `420.000130` seconds
- Baseline/steady CPU: `16.867m` / `110.861m`
- Steady minus baseline: `+93.994m` (required `>=50m`)
- Baseline/steady interval coverage: `59/59` (required `>=48` each)
- Throttling mean equivalent: `9.386m`; series present
- Complete SLO windows: `205`
- Product-latency violation windows: `0`; maximum product p95 `334.953 ms`
- Global-error violation windows: `1` isolated window; no three-window streak
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Pod lifecycle: all 15 tracked deployments stable

Immutable evidence closure passed for 15 raw log files, 44,743 enriched log
records, 1,115,407 metric samples, 35 schema-v3 trace chunks, 6,732 unique
selected traces and 67,660 spans. Seven lifecycle-boundary traces were
excluded under the preregistered policy. Chunk coverage, run-ID and time
failures were zero. Scientific metadata, final receipt and a second independent
offline finalized-run verification all passed.

This is the third valid medium-severity candidate after
`ob-cpu-medium-001` and `ob-cpu-medium-003`. It completes the valid-run count
required for the D-025 descriptive medium repeatability summary. Invalid
`ob-cpu-medium-002` remains excluded.

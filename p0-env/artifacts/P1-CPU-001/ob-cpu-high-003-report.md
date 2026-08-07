# ob-cpu-high-003 Valid Run Report

- Status: `completed/valid`
- Scientific dataset inclusion: `true`
- Profile: `cpu-recommendation-high-v1`
- Workload/SLO/seed: `ob-default-10u-1r-v1` / `p1-cpu-001-slo-v1` / `1`
- Code revision: `8282adc`
- Worker UTC: `2026-08-07T14:14:40.193950Z` to `2026-08-07T14:21:40.171551Z`
- Worker wall/monotonic duration: `419.977601` / `420.000416` seconds
- Baseline/steady CPU: `13.299m` / `163.715m`
- Steady minus baseline: `+150.416m` (required `>=75m`)
- Baseline/steady interval coverage: `59/58` (required `>=48` each)
- Throttling mean equivalent: `47.804m`; series present
- Complete SLO windows: `206`
- Product-latency violation windows: `4`; maximum product p95 `3759.091 ms`; maximum streak `2`
- Global-error violation windows: `0`
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Pod lifecycle: all 15 tracked deployments stable

Immutable evidence closure passed for 15 raw log files, 43,770 enriched log
records, 1,088,320 metric samples, 35 schema-v3 trace chunks, 6,708 unique
selected traces and 70,411 spans. Eight lifecycle-boundary traces were excluded
under the preregistered policy. Chunk coverage, run-ID and time failures were
zero. Scientific metadata, final receipt and a second independent offline
finalized-run verification all passed.

This is the third valid high-severity CPU calibration candidate and the second
independent repeat of `ob-cpu-high-001`. Four latency violations included only
a two-window maximum streak and therefore did not meet the frozen three-window
manifestation rule. The run completes the preregistered three-valid-run
descriptive set; it does not authorize post-hoc SLO changes, a different
workload/service or model training.

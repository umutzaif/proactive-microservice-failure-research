# ob-cpu-high-002 Valid Run Report

- Status: `completed/valid`
- Scientific dataset inclusion: `true`
- Profile: `cpu-recommendation-high-v1`
- Workload/SLO/seed: `ob-default-10u-1r-v1` / `p1-cpu-001-slo-v1` / `1`
- Code revision: `04fafaf`
- Worker UTC: `2026-08-07T13:28:24.843751Z` to `2026-08-07T13:35:24.816463Z`
- Worker wall/monotonic duration: `419.972712` / `420.000245` seconds
- Baseline/steady CPU: `13.375m` / `157.193m`
- Steady minus baseline: `+143.819m` (required `>=75m`)
- Baseline/steady interval coverage: `59/59` (required `>=48` each)
- Throttling mean equivalent: `14.891m`; series present
- Complete SLO windows: `205`
- Product-latency violation windows: `0`; maximum product p95 `193.879 ms`
- Global-error violation windows: `0`
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Pod lifecycle: all 15 tracked deployments stable

Immutable evidence closure passed for 15 raw log files, 43,972 enriched log
records, 1,085,626 metric samples, 35 schema-v3 trace chunks, 6,716 unique
selected traces and 71,006 spans. Six lifecycle-boundary traces were excluded
under the preregistered policy. Chunk coverage, run-ID and time failures were
zero. Scientific metadata, final receipt and a second independent offline
finalized-run verification all passed.

This is the second valid high-severity CPU calibration candidate and the first
independent repeat of `ob-cpu-high-001`. It confirms a strong physical CPU
effect under the unchanged workload and has null manifestation under the frozen
SLO. Two runs do not complete the preregistered three-valid-run descriptive set
and do not authorize post-hoc SLO changes, a different workload/service or
model training.

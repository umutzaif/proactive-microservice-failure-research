# ob-cpu-low-009 Valid Run Report

- Status: `completed/valid`
- Scientific dataset inclusion: `true`
- Profile: `cpu-recommendation-low-v4`
- Workload/SLO/seed: `ob-default-10u-1r-v1` / `p1-cpu-001-slo-v1` / `1`
- Worker UTC: `2026-08-06T13:08:17.714219Z` to `2026-08-06T13:15:17.678732Z`
- Worker wall/monotonic duration: `419.964513` / `420.000154` seconds
- Baseline/steady CPU: `13.138m` / `63.672m`
- Steady minus baseline: `+50.534m` (required `>=25m`)
- Baseline/steady interval coverage: `59/59` (required `>=48` each)
- Throttling mean equivalent: `9.684m`; series present
- Complete SLO windows: `206`
- Product-latency violation windows: `0`; maximum product p95 `210.440 ms`
- Global-error violation windows: `1` isolated window; no three-window streak
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Pod lifecycle: all 15 tracked deployments stable

Immutable evidence closure passed for 15 raw log files, 44,303 enriched log
records, 1,118,724 metric samples, 35 schema-v3 trace chunks, 6,758 unique
selected traces and 71,550 spans. Chunk coverage, run-ID and time failures were
zero. Scientific metadata, final receipt and offline finalized-run verification
all passed.

This is the third valid low-severity CPU calibration candidate after
`ob-cpu-low-004` and `ob-cpu-low-005`. The null manifestation is a valid
negative result and does not authorize post-hoc SLO changes.

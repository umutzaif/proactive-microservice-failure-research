# ob-cpu-medium-003 Valid Run Report

- Status: `completed/valid`
- Scientific dataset inclusion: `true`
- Profile: `cpu-recommendation-medium-v1`
- Workload/SLO/seed: `ob-default-10u-1r-v1` / `p1-cpu-001-slo-v1` / `1`
- Code revision: `300341d`
- Worker UTC: `2026-08-06T17:10:09.938805Z` to `2026-08-06T17:17:09.920883Z`
- Worker wall/monotonic duration: `419.982078` / `420.000112` seconds
- Baseline/steady CPU: `11.517m` / `114.559m`
- Steady minus baseline: `+103.042m` (required `>=50m`)
- Baseline/steady interval coverage: `59/59` (required `>=48` each)
- Throttling mean equivalent: `8.671m`; series present
- Complete SLO windows: `205`
- Product-latency violation windows: `0`; maximum product p95 `256.896 ms`
- Global-error violation windows: `0`
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Pod lifecycle: all 15 tracked deployments stable

Immutable evidence closure passed for 15 raw log files, 44,558 enriched log
records, 1,084,208 metric samples, 35 schema-v3 trace chunks, 6,755 unique
selected traces and 72,535 spans. Three lifecycle-boundary traces were
excluded under the preregistered policy. Chunk coverage, run-ID and time
failures were zero. Scientific metadata, final receipt and a second independent
offline finalized-run verification all passed.

This is the second valid medium-severity candidate after
`ob-cpu-medium-001`. Both valid candidates have verified physical effect and
null manifestation, but two valid runs do not complete the D-025 three-run
repeatability set. Invalid `ob-cpu-medium-002` is excluded from that set.

# ob-cpu-medium-001 Valid Run Report

- Status: `completed/valid`
- Scientific dataset inclusion: `true`
- Profile: `cpu-recommendation-medium-v1`
- Workload/SLO/seed: `ob-default-10u-1r-v1` / `p1-cpu-001-slo-v1` / `1`
- Worker UTC: `2026-08-06T14:58:03.503056Z` to `2026-08-06T15:05:03.481432Z`
- Worker wall/monotonic duration: `419.978376` / `420.000151` seconds
- Baseline/steady CPU: `10.161m` / `112.071m`
- Steady minus baseline: `+101.910m` (required `>=50m`)
- Baseline/steady interval coverage: `59/59` (required `>=48` each)
- Throttling mean equivalent: `7.599m`; series present
- Complete SLO windows: `206`
- Product-latency violation windows: `0`; maximum product p95 `158.424 ms`
- Global-error violation windows: `0`
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Pod lifecycle: all 15 tracked deployments stable

Immutable evidence closure passed for 15 raw log files, 43,544 enriched log
records, 1,089,695 metric samples, 35 schema-v3 trace chunks, 6,663 unique
selected traces and 69,971 spans. Four traces crossing lifecycle boundaries
were excluded under the preregistered boundary policy. Chunk coverage, run-ID
and time failures were zero. Scientific metadata, final receipt and an
independent offline finalized-run verification all passed.

This is the first valid medium-severity CPU calibration candidate. Its
physical effect is verified, while manifestation remains null under the frozen
SLO. One run does not establish medium-severity repeatability and does not
authorize a high-severity profile or a post-hoc SLO change.

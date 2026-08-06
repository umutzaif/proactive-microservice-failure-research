# ob-cpu-medium-002 Invalid Run Report

- Status: `invalid/incomplete`
- Scientific dataset inclusion: `false`
- Profile: `cpu-recommendation-medium-v1`
- Code revision: `0ad19cd`
- Worker UTC: `2026-08-06T16:31:17.758766Z` to `2026-08-06T16:38:17.727630Z`
- Worker wall/monotonic duration: `419.968864` / `420.000181` seconds
- Worker heartbeats: `84`; bounded execution passed
- Original physical-effect result: baseline/steady intervals `0/0`; failed
- Pod lifecycle: stable; target restart count `1` before and after fault
- Complete SLO windows: `205`; latency violations `3`, no three-window streak
- Failure manifestation: `null`
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`
- Final receipt: not created because the scientific validity gate failed

Raw/enriched/schema-v3 telemetry closure passed before the validity rejection:
15 raw logs, 43,746 enriched records, 1,118,194 metric samples, 35 trace
chunks, 6,667 selected traces and 70,100 spans. Ten boundary-crossing traces
were excluded; run-ID, time and chunk failures were zero.

The archived Prometheus payload contained two cAdvisor CPU counter series for
the same pod/container: a stale 56-sample container series ending during
warm-up and an active 266-sample series covering the lifecycle. The original
analyzer retained the last matching series, so the stale series displaced the
active series and produced zero baseline/steady intervals. A read-only
diagnostic replay with lifecycle-aware selection found `59/59` intervals,
baseline `13.909m`, steady `114.737m` and `+100.828m`; this is diagnostic
evidence only and does not retroactively validate the run.

The run remains invalid, all evidence is preserved and the run ID will not be
reused. D-026 makes future analysis select exactly one series spanning both
measured phases and fail closed on zero or multiple eligible series.

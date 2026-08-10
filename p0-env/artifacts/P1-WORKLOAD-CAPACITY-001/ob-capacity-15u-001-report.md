# ob-capacity-15u-001 Valid but Non-selected Capacity Candidate

- Status: `valid_capacity_evidence`; dataset inclusion: `false`
- Workload: `ob-capacity-15u-1r-v1`; fault injection: none
- Frontend user-server span rate: `3.532528/s`
- Same-day 10-user reference rate: `2.492375/s`
- Request-intensity ratio: `1.417334x` (required `>=1.30x`): passed
- Recommendationservice CPU: mean `35.890m`, p95 `143.834m`, 59 intervals
- CPU gate: mean `<=25m`: failed
- Frozen SLO: manifestation `null`; latency/error maximum streak `1/0`
- All 15 pod UID/restart snapshots stable; host deltas WHEA/KP41/bugcheck `0/0/0`

Raw-log and schema-v3 telemetry verification passed with 482,048 metric
samples, 3,816 selected traces, 46,079 spans and 21 trace chunks. Two boundary
traces were excluded; run-ID, time and chunk-coverage failures were zero.

The run is valid capacity evidence but the 15-user workload is not selectable
under D-030 because it fails the preregistered CPU-headroom gate. The threshold
is not relaxed after observing the result.

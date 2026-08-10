# ob-capacity-20u-002 Valid but Non-selected Capacity Candidate

- Status: `valid_capacity_evidence`; dataset inclusion: `false`
- Workload: `ob-capacity-20u-1r-v1`; fault injection: none
- Frontend user-server span rate: `4.755222/s`
- Same-day 10-user reference rate: `2.492375/s`
- Request-intensity ratio: `1.907908x` (required `>=1.30x`): passed
- Recommendationservice CPU: mean `43.015m`, p95 `152.573m`, 59 intervals
- CPU gate: mean `<=25m`: failed
- Frozen SLO: manifestation `null`; latency/error maximum streak `1/0`
- All 15 pod UID/restart snapshots stable; host deltas WHEA/KP41/bugcheck `0/0/0`

Raw-log and schema-v3 telemetry verification passed with 482,381 metric
samples, 4,500 selected traces, 59,778 spans and 21 trace chunks. Fifteen
boundary traces were excluded; run-ID, time and chunk-coverage failures were
zero. An independent verifier replay passed after cluster shutdown.

The run is valid capacity evidence but the 20-user workload is not selectable
under D-030 because it fails the preregistered CPU-headroom gate. The threshold
is not relaxed after observing the result.

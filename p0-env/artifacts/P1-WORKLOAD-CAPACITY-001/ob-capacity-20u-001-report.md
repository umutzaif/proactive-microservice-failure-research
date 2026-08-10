# ob-capacity-20u-001 Invalid Capacity Attempt

- Status: `invalid`; dataset inclusion: `false`
- Workload: `ob-capacity-20u-1r-v1`; fault injection: none
- Active run-ID, raw logs and schema-v3 telemetry verification passed.
- Telemetry: 512,907 metric samples, 4,379 selected traces, 35,499 spans,
  18 trace chunks; run-ID/time/chunk failures were zero.
- Host deltas: WHEA Event 17 `0`, Kernel-Power 41 `0`, bugcheck `0`.
- Frozen-SLO manifestation: `null`; maximum latency streak `1`, error streak `0`.
- Pod lifecycle assessment: `false`, but before/after component snapshots were
  not serialized by the first capacity runner version and the failing component
  cannot be independently identified.
- Original CPU analysis is non-decisional: it combined more than one cAdvisor
  series and produced 89 intervals with an impossible-for-interpretation zero
  p95. It is retained as evidence and is not used for workload selection.

The attempt cannot be retroactively accepted. D-031 adds serialized pod
snapshots and fail-closed selection of exactly one measurement-covering CPU
series for subsequent new run IDs. D-030 users, thresholds, order and SLO are
unchanged.

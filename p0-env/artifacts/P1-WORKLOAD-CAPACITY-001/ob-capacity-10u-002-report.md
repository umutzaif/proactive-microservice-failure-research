# ob-capacity-10u-002 Valid Capacity Control

- Status: `valid_capacity_evidence`; dataset inclusion: `false`
- Workload: `ob-default-10u-1r-v1`; fault injection: none
- Lifecycle: 300-second warm-up and 300.517-second measurement
- Frontend user-server spans: `749`; rate `2.492375/s`
- Recommendationservice CPU: 59 intervals; mean `26.011m`; p95 `116.334m`
- Mean headroom to 200m limit: `173.989m`
- Frozen SLO: manifestation `null`; maximum latency streak `1`; error streak `0`
- Pod lifecycle: all 15 component UID/restart snapshots stable
- Host deltas: WHEA Event 17 `0`; Kernel-Power 41 `0`; bugcheck `0`

Raw-log and schema-v3 telemetry verification passed with 486,721 metric
samples, 2,976 unique selected traces, 30,919 spans and 21 trace chunks.
Four lifecycle-boundary traces were excluded under the existing policy;
run-ID, time and chunk-coverage failures were zero.

This same-day control is the frozen denominator for D-030 request-intensity
ratios. Its CPU value is descriptive; the `<=25m` gate applies to the candidate
workload, not retroactively to the control.

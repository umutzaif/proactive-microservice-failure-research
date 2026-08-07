# ob-cpu-high-001 Attempt Binding

`ob-cpu-high-001` is the first preregistered high-severity CPU calibration. It
targets `recommendationservice` with `cpu-recommendation-high-v1`: 150 mCPU
additional demand, 120 seconds ramp, 300 seconds steady and 300 seconds
cooldown. Workload `ob-default-10u-1r-v1`, seed `1`, frozen SLO
`p1-cpu-001-slo-v1`, target service, coverage, lifecycle UTC, host-health,
telemetry and receipt contracts remain unchanged from the valid medium runs.

Physical acceptance requires at least 75 mCPU steady-minus-baseline increase
and at least 48 real Prometheus CPU-rate intervals in each 300-second baseline
and steady phase. D-026 requires exactly one lifecycle-covering cAdvisor CPU
series and matching-cgroup throttling evidence. Command success is insufficient.
Null manifestation remains admissible.

The run cannot start until this profile and tooling are merged to canonical
main, its artifact paths are empty, deployment-time active run-ID and host
preflight gates pass, and separate execution approval is recorded. Invalid
evidence is preserved and the run ID is never reused. A valid result does not
authorize post-hoc SLO changes, a different workload/service or model training.

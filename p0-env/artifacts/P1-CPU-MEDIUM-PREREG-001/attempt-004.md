# ob-cpu-medium-004 Attempt Binding

`ob-cpu-medium-004` is the preregistered replacement candidate for invalid
`ob-cpu-medium-002` and is intended to complete the D-025 three-valid-run
medium repeat set. It uses the unchanged `cpu-recommendation-medium-v1`
profile: 100 mCPU additional demand against `recommendationservice`, 120
seconds ramp, 300 seconds steady and 300 seconds cooldown. Workload
`ob-default-10u-1r-v1`, seed `1`, frozen SLO `p1-cpu-001-slo-v1`, target,
lifecycle UTC, coverage, host-health, telemetry and receipt contracts remain
unchanged from valid `ob-cpu-medium-001` and `ob-cpu-medium-003`.

Physical acceptance requires at least 50 mCPU steady-minus-baseline increase
and at least 48 real Prometheus CPU-rate intervals in each 300-second baseline
and steady phase. D-026 requires exactly one cAdvisor CPU counter series that
contains samples in both measured phases; zero or multiple eligible series
fail closed, and throttling must match the selected cgroup ID. Command success
is insufficient. Null manifestation remains an admissible result.

The run requires canonical main containing this binding, an empty artifact
path, deployment-time active run-ID verification, clean host preflight and
separate explicit execution approval. Failure preserves all available evidence
as invalid and the run ID is never reused. A valid result may complete the
three-run descriptive medium repeat set, but does not authorize high severity,
a different workload, post-hoc SLO changes or model training.

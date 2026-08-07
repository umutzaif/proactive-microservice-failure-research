# ob-cpu-high-002 Attempt Binding

`ob-cpu-high-002` is the first independent repeat of valid
`ob-cpu-high-001`. It uses the unchanged `cpu-recommendation-high-v1` profile:
150 mCPU additional demand against `recommendationservice`, 120 seconds ramp,
300 seconds steady and 300 seconds cooldown. Workload
`ob-default-10u-1r-v1`, seed `1`, frozen SLO `p1-cpu-001-slo-v1`, target,
coverage, D-026 series selection, lifecycle UTC, host-health, telemetry and
receipt contracts remain unchanged.

Physical acceptance requires at least 75 mCPU steady-minus-baseline increase
and at least 48 real Prometheus CPU-rate intervals in each 300-second baseline
and steady phase. Exactly one cAdvisor CPU counter series must contain samples
in both phases; throttling must use the selected cgroup ID. Null manifestation
is admissible and command success is insufficient.

The run requires canonical main containing this binding, empty artifact paths,
deployment-time active run-ID verification and clean host preflight. Failure
preserves all evidence as invalid and the run ID is never reused. Completion
does not automatically authorize `ob-cpu-high-003`; that run has its own gates.

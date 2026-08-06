# ob-cpu-medium-002 Attempt Binding

`ob-cpu-medium-002` is the first independent repeat of the valid
`ob-cpu-medium-001` calibration. It uses the unchanged
`cpu-recommendation-medium-v1` profile: 100 mCPU additional demand against
`recommendationservice`, 120 seconds ramp, 300 seconds steady and 300 seconds
cooldown. Workload `ob-default-10u-1r-v1`, seed `1`, frozen SLO
`p1-cpu-001-slo-v1`, target service, lifecycle UTC, telemetry, host-health and
receipt contracts remain unchanged.

Physical acceptance requires at least 50 mCPU steady-minus-baseline increase
and at least 48 real Prometheus CPU-rate intervals in each 300-second baseline
and steady phase. Command success is insufficient and throttling must be
reported. Null manifestation is an admissible result.

The run requires a clean canonical main revision, an empty artifact path,
deployment-time active run-ID verification and separate explicit execution
approval after this preregistration is merged. Failure preserves all available
evidence as invalid and the run ID is never reused.

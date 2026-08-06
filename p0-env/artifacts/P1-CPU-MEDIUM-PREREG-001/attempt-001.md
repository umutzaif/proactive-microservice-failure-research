# ob-cpu-medium-001 Attempt Binding

`ob-cpu-medium-001` is the first preregistered medium-severity CPU calibration.
It targets `recommendationservice` with `cpu-recommendation-medium-v1`: 100 mCPU
additional demand, 120 seconds ramp, 300 seconds steady and 300 seconds
cooldown. The workload, seed, frozen SLO, target service, lifecycle UTC,
telemetry, host-health and receipt contracts remain unchanged from the valid
low-severity runs.

Physical acceptance requires at least 50 mCPU steady-minus-baseline increase and
at least 48 real Prometheus CPU-rate intervals in each 300-second baseline and
steady phase. Command success is insufficient. Throttling must be reported.

The run may produce null manifestation and must still be preserved if all
validity gates pass. It cannot start before this profile and tooling are merged
to canonical main, the deployment carries the new run ID, and all preflight
gates pass. The result does not automatically authorize high severity.

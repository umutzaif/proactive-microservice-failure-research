# ob-capacity-10u-001 Invalid/Incomplete Capacity Attempt

- Status: `invalid/incomplete`; dataset inclusion: `false`
- Workload: canonical `ob-default-10u-1r-v1`; fault injection: none
- Active run-ID passed and 300-second warm-up completed.
- Measurement and telemetry archive did not start.
- Failure: the first capacity runner expected only `phases.measurement_seconds`,
  while the established 10-user profile stores the same 300-second duration as
  `phases.normal_baseline_seconds`.
- Cluster stopped in `finally`; no result is used for comparison.

D-032 normalizes the two canonical field names to one internal measurement
duration and requires exactly 300 seconds. The run remains invalid, its ID is
not reused, and a new 10-user control is required.

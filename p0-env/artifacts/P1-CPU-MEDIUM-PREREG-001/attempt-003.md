# ob-cpu-medium-003 Attempt Binding

`ob-cpu-medium-003` is the second independent repeat of the valid
`ob-cpu-medium-001` calibration. It uses the same
`cpu-recommendation-medium-v1` profile, workload `ob-default-10u-1r-v1`, seed
`1`, frozen SLO `p1-cpu-001-slo-v1`, target service and lifecycle as
`ob-cpu-medium-001` and `ob-cpu-medium-002`.

Acceptance remains fail-closed: at least 50 mCPU steady-minus-baseline CPU
increase; at least 48 real Prometheus CPU-rate intervals in each 300-second
baseline and steady phase; stable pod lifecycle; zero new WHEA Event 17,
Kernel-Power 41 and bugcheck events; complete immutable log, metric and schema
v3 trace archives; and passing close-run plus independent offline receipt
verification. Null manifestation remains scientifically admissible.

This run cannot start merely because `ob-cpu-medium-002` finishes. Its own
canonical-main, empty-artifact, active run-ID, host-health and explicit
execution gates must pass. Invalid evidence is preserved and the run ID is
never reused.

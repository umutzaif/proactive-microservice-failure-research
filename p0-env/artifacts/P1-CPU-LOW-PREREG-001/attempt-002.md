# ob-cpu-low-002 Attempt Binding

`ob-cpu-low-002` repeats the already frozen `cpu-recommendation-low-v1` protocol
after `ob-cpu-low-001` failed before fault injection because of a PowerShell
common-parameter binding error.

No scientific condition changes:

- target: recommendationservice;
- additional CPU demand: approximately 50 millicores;
- ramp / steady: 120 / 300 seconds;
- workload: `ob-default-10u-1r-v1`, seed 1;
- SLO: `p1-cpu-001-slo-v1` with D-017 fixed window alignment;
- cooldown: 300 seconds;
- physical-effect and all integrity gates unchanged.

Only the unique run ID and the process-invocation implementation differ. The
invalid `ob-cpu-low-001` evidence remains preserved and excluded from the
scientific dataset.

# ob-cpu-low-005 Attempt Binding

`ob-cpu-low-005` is the first independent repeat of the valid
`ob-cpu-low-004` low-severity calibration. It uses the unchanged
`cpu-recommendation-low-v2` profile, `ob-default-10u-1r-v1` workload with seed
1, `p1-cpu-001-slo-v1`, five-minute warm-up, five-minute normal baseline,
120-second ramp, 300-second steady phase and five-minute cooldown.

Validity remains fail-closed: each baseline and steady phase requires at least
48 real CPU-rate intervals, steady-minus-baseline mean CPU must be at least
25m, pod identity/restarts and host WHEA 17/Kernel-Power 41/bugcheck deltas must
remain stable, schema-v3 telemetry must pass, and both final receipt and offline
verification must complete. A null manifestation is a valid observed outcome,
not a reason to change the frozen SLO.

The run may start only from a clean canonical revision after live collector and
Prometheus run-ID verification for `ob-cpu-low-005`.

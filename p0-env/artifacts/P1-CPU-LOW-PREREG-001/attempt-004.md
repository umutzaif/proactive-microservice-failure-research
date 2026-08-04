# ob-cpu-low-004 Attempt Binding

`ob-cpu-low-004` repeats the approved `cpu-recommendation-low-v2` scientific
conditions without changing target, severity, workload, seed, SLO, lifecycle,
coverage or physical-effect thresholds.

The only technical correction is canonical UTC handling: the injector writes
UTC timestamps with a trailing `Z`, and the metadata verifier reports invalid
timestamps without allowing null/array values into duration arithmetic.
`ob-cpu-low-003` remains invalid and is not retroactively finalized.

The new run may start only after the correction is merged to `main`, all positive
and negative metadata tests pass, the worktree is clean, and the live active
run-ID gate verifies `ob-cpu-low-004` in collector and Prometheus.

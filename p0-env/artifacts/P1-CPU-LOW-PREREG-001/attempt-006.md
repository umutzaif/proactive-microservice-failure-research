# ob-cpu-low-006 Attempt Binding

`ob-cpu-low-006` is the second independent repeat of the valid
`ob-cpu-low-004` low-severity calibration. Its profile, target, workload, seed,
SLO, lifecycle, physical-effect coverage and magnitude thresholds are identical
to `ob-cpu-low-005`.

It must not reuse the live cluster lifecycle, artifact paths or scientific
metadata of `ob-cpu-low-005`. Run 005 must first close as valid or invalid and
its evidence must be preserved. The active deployment identity will then move
to `ob-cpu-low-006` in a new clean canonical revision, followed by independent
host, live run-ID, telemetry, receipt and offline verification gates.

No result from run 005 may be used to alter run 006 severity or SLO.

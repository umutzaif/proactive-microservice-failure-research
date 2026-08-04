# P1-CPU-001 / ob-cpu-low-001 Invalid Attempt

The warm-up and pre-fault baseline completed, but CPU stress was never started.
The nested `powershell.exe -File` call could not bind the boolean `Confirm`
common parameter and failed before the target worker executed.

- Warm-up start: `2026-08-04T10:07:35.6504217Z`
- Normal-baseline start: `2026-08-04T10:12:35.6566991Z`
- Failure: `2026-08-04T10:17:37.6999379Z`
- Fault injected: no
- Manifestation: not observable / null
- Minikube cleanup: passed
- Post-cleanup host totals: WHEA 17 = 881, Kernel-Power 41 = 5, bugcheck = 1

No raw/enriched/metric/trace close-run archive was attempted because the
mandatory fault phase did not begin and the lifecycle was incomplete. The
evidence is retained as an invalid tooling attempt. The run ID is never reused.
The fix changes only PowerShell process invocation; fault profile, workload,
SLO, target and phase durations remain frozen.

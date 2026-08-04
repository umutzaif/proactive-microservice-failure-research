# ob-cpu-low-003 Attempt Binding

`ob-cpu-low-003` is preregistered against `cpu-recommendation-low-v2`.
The target, workload, SLO, seed, ramp, steady duration, cooldown, worker and
minimum CPU increase are unchanged from `v1`. The only methodological change is
the physical-effect coverage gate: each 300-second baseline and steady phase
must contain at least 48 real CPU-rate intervals. At the independently verified
5-second scrape cadence, 60 intervals are expected and 48 represents 80%
coverage.

`ob-cpu-low-002` remains invalid. Its 59/60 intervals and observed CPU increase
were used to diagnose the sampling contract, not to retroactively accept the
run or tune the CPU severity/SLO. The new run ID prevents evidence replacement.

The run may start only from a clean committed revision after the profile,
metadata verifier, synthetic coverage tests and active run-ID configuration all
pass independent checks. Any failure preserves evidence and keeps the run out
of the scientific dataset.

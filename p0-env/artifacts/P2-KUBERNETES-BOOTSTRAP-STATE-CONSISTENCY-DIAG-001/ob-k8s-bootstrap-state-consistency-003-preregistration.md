# ob-k8s-bootstrap-state-consistency-003 preregistration

This unique operational replacement keeps the D-081/D-082 scientific and machine conditions:
the preserved stopped `p0-online-boutique` profile, Docker driver, Kubernetes `v1.34.0`, 4 CPU,
6144 MiB memory, 32 GiB disk, containerd, 420-second start bound and 5-second polling. The profile
must not be deleted, reset or cleaned.

The runner must preserve raw Docker inspect before parsing, require exactly one nonempty
`State.Status`, close redirected process handles before stop/seal, and capture a non-null start
exit code. At first-live and final-live boundaries, each state capture must have exit code zero,
nonempty stdout and exactly one `PRESENT` or `MISSING` status line for every frozen path. The
independent verifier repeats these semantic assertions, rejects crictl help output, checks host
closure and is followed by SHA replay.

Any missing/failed/ambiguous capture, verifier failure, host-health failure, process-handle
failure or incomplete seal makes the diagnostic invalid/incomplete and closes this ID. Observed
state may narrow the bootstrap chain but cannot establish a unique root cause.

Application deployment, workload, proxy/toxic, fault injection, scientific windows, Dataset v1,
D-067 headroom/incident accounting, profile delete/reset and replacement normal runs are forbidden.
Canonical merge is not runtime authorization; live execution requires separate explicit approval.

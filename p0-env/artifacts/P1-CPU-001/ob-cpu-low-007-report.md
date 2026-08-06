# ob-cpu-low-007 Invalid Run Report

- Status: `invalid/incomplete`
- Scientific dataset inclusion: `false`
- Fault injected: `false`
- Warm-up start UTC: `2026-08-06T11:58:25.0809578Z`
- Normal baseline start UTC: `2026-08-06T12:03:25.0874572Z`
- Failure UTC: `2026-08-06T12:08:25.7502984Z`
- Failure: `Worker source checksum does not match the fault profile.`
- Profile worker SHA-256: `20cdfb9b360cf42c7b51e2a191eb3b3e04926f24b18e7179fa60ce85594337d4`
- Windows working-tree worker SHA-256: `503f826bc92672aa00657741f25c474c2567b897f2312933e58515bd98952898`
- Post-cleanup host totals: WHEA Event 17 `881`; Kernel-Power 41 `5`; bugcheck `1` (delta `0/0/0`).

The active run-ID gate passed and the complete five-minute warm-up and
five-minute normal-baseline phases elapsed. The injector rejected the worker
before execution because Git's Windows checkout converted LF line endings to
CRLF, changing the raw byte hash without changing source semantics. The
orchestrator stopped Minikube in `finally`; no CPU fault worker started.

The run ID will not be reused. The evidence is preserved and the profile hash
will not be edited retroactively. A new profile and run ID require an explicit,
platform-independent source-normalization contract plus independent tests.

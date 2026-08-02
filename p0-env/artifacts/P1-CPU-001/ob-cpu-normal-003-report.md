# P1-CPU-001 / ob-cpu-normal-003 Report

- Status: `completed`; scientific normal-baseline candidate
- Fault injection: none
- Workload: `ob-default-10u-1r-v1`; seed `1`
- Warm-up: `2026-08-02T13:42:34.4002648Z`–`2026-08-02T13:47:34.6741286Z` (300.2738638 s)
- Normal baseline: `2026-08-02T13:48:30.1627148Z`–`2026-08-02T13:53:30.4128274Z` (300.2501126 s)
- Clock evidence: `time.windows.com`; offsets +0.0369027, +0.0359933, +0.0358501 s
- Lifecycle: all 15 tracked deployments kept the same pod UID and restart count across the baseline window
- Active run-ID gate: passed before lifecycle and after baseline; 4,061 post-baseline run-scoped metric series
- Host health: WHEA Event 17 = 0, Kernel-Power 41 = 0, bugcheck = 0; post-shutdown check passed
- Logs: 15 raw files; 21,798 enriched records
- Metrics: 4,106 series; 538,304 samples
- Traces: schema v3; 21 chunks; 3,338 selected unique traces; 35,109 spans; 2 boundary-crossing traces excluded
- Integrity: run-ID/time/chunk failures = 0; close-run, final receipt and offline finalized-run verification passed
- Metadata SHA-256: `6e9a5b378993cf76b8f7b72d2a0e1124d709e8532359ff6f7a5bbf88fcebba65`

Decision: accept as a scientific normal-baseline candidate. This run does not authorize fault injection or freeze an SLO.

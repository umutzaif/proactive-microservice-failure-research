# P1-CPU-001 / ob-cpu-normal-004 Report

- Status: `completed`; scientific normal-baseline candidate
- Fault injection: none
- Workload: `ob-default-10u-1r-v1`; seed `1`
- Warm-up: `2026-08-02T14:06:13.5694864Z`–`2026-08-02T14:11:13.8291820Z` (300.2596956 s)
- Normal baseline: `2026-08-02T14:12:02.6366757Z`–`2026-08-02T14:17:02.8558175Z` (300.2191418 s)
- Clock evidence: `time.windows.com`; offsets +0.0389296, +0.0413729, +0.0404316 s
- Lifecycle: all 15 tracked deployments kept the same pod UID and restart count across the baseline window
- Active run-ID gate: passed before lifecycle and after baseline; 3,941 post-baseline run-scoped metric series
- Host health: WHEA Event 17 = 0, Kernel-Power 41 = 0, bugcheck = 0; post-shutdown check passed
- Logs: 15 raw files; 21,150 enriched records
- Metrics: 3,980 series; 513,784 samples
- Traces: schema v3; 21 chunks; 3,257 selected unique traces; 33,970 spans; 5 boundary-crossing traces excluded
- Integrity: run-ID/time/chunk failures = 0; close-run, final receipt and offline finalized-run verification passed
- Metadata SHA-256: `b163422c407a690f0cc7b292608b6fd7ddb4984e9d3d7de4aad9687cda6a77ba`

Decision: accept as a scientific normal-baseline candidate. This run does not authorize fault injection or freeze an SLO.

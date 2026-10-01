# 008 invalid/incomplete closure

Closed at the user's explicit request on 2026-10-01, from original 2026-09-30
evidence at revision 9fd93c406cb48aaecb2410c6176c4d9ca6ad5218.
The ID is consumed and must never be reused. No fault was injected.

Baseline, raw/enriched archives (17/17 each, 21,209 records) and telemetry
(25/25 files, 515,226 metric samples, 3,180 traces) passed during execution.
The partial upper-tail measurement was 118.893 ms. These intermediate results
cannot count as accepted headroom or a valid normal because complete closure failed.

Rollback failed: the observed command output reported Kubernetes OpenAPI TLS
handshake timeouts; run-error.json records rollback_apply_failed at
2026-09-30T18:55:45.4047541Z. Failure cleanup also failed rollback and stop returned
82. Docker API 500 errors were observed in command output. No root cause is claimed.
Original failure closure records profile Stopped, container exited/255/OOMKilled=false,
host event deltas 0/0/0 and USB network context present/stable. These historical
observations do not repair failed rollback/stop and are not current host status.

PostgreSQL, pgAdmin and Adminer remained running; the operator reported SQL queries
finished and possible coursework reporting/push activity. No causal link between
that background activity and the failure is established. Phone Wi-Fi/mobile-data-off
was operator-declared, not host-verified; retrospective continuity is not confirmed.

Original files are preserved and sealed in the sibling run directory. Raw/derived/
telemetry archives remain at their existing local paths and are not regenerated.
The report is outside the seal and records interpretation, not replacement evidence.
D-067 remains 10u 1/3, 15u 2/3 (3/6); Dataset inclusion is false. D-116 removes the
calendar deadline only; all evidence, safety and scientific stop gates remain.

Repository closure preserves these records, rejects 008 before runtime even without
local artifacts, and leaves its replacement slot null pending prospective preregistration.
No new run ID, runtime, reset, Docker restart or Engine-loss investigation is authorized.

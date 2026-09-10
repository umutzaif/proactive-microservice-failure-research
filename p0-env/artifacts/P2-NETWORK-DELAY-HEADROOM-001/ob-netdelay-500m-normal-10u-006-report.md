# ob-netdelay-500m-normal-10u-006 invalid/incomplete closure

## Status and execution

Separately authorized single manual no-fault runtime used canonical
`7627817d55218186fd7c7fe412ef1c000d96b55a` and the preregistered 44eb Minikube state root.
The environment note records 2026-09-09 17:26:39.9310347Z to 17:42:50.3905877Z and the
user's declaration of no significant background load. This declaration is not a process audit.
No run retry or fault was performed. The ID is consumed, closed and invalid/incomplete.

Mentor policy and Ethernet preflight passed. Proxy convergence reached one Ready pod on
its first observation. Target stability passed 25 observations with restart count 0.
The recorded baseline interval is 17:37:04.1115853Z to 17:42:04.1227884Z (300.0112031 s).
Before/after baseline pod-lifecycle summaries match; pre/post proxy evidence shows no toxics.
These partial successes do not establish scientific validity or a headroom statistic.

## Failure and evidence limits

The runner failed at `step_failed:archive_telemetry` at 17:42:36.0932099Z.
Raw and enriched log archives exist; each replayed 17/17 manifest entries on 2026-09-10.
There is no telemetry directory, scientific metadata or finalized receipt for this run.
No valid primary latency/headroom value or manifestation result can be claimed.

Best-effort rollback recorded `rollback_apply_failed`. Stop exit was 82; the original
failure closure could not read profile/container state because the Docker Engine pipe
was unavailable. The last original RecordId host deltas were 0/0/0 and Ethernet remained
stable. The exact initiating cause of Engine loss and the detailed telemetry exception
are not captured by the stored run-error; do not infer a disk, Wi-Fi or application cause.

When work resumed on 2026-09-10 the tool session was unavailable. This report is based
on stored artifacts and explicitly dated supplemental checks, not a recovered full stdout log.
Docker Desktop was opened for read-only closure verification. Once Engine access returned,
container state was exited/137/OOMKilled=false, with FinishedAt 2026-09-09T17:42:32.529570083Z;
the exact profile was Stopped/Stopped/Stopped (native status exit 7). These later observations
confirm current stopped state only; they do not repair the original failed stop or rollback.
No deploy, profile start, forced cleanup, reset or scientific re-execution was performed.

## Evidence locations and interpretation

Original and supplemental artifacts are under this run's `P2-NETWORK-DELAY-HEADROOM-001`
directory; the environment note remains unchanged. Supplemental engine/profile status and
archive-replay files carry their own timestamps. Raw logs are retained locally under
`p0-env/artifacts/runs/ob-netdelay-500m-normal-10u-006/`; enriched logs are under the
corresponding `derived/` directory. Neither archive is replaced or regenerated.
The run-directory seal includes partial and failure evidence; its replay proves integrity,
not a complete scientific receipt. This report is outside the sealed run directory.

D-067 stays 10u 1/3 and 15u 2/3; Dataset inclusion is false. The final 10u-003 slot,
D-109 Wi-Fi boundary and D-112 September 19 / nine-valid-run gates remain unchanged.
On 2026-09-10 the user declined further Engine-loss investigation and approved D-114
replacement preregistration and PR delivery. The cause remains unknown. This does not
authorize runtime or reset and does not establish recovery. This report lives beside
earlier run reports to preserve provenance; future fixes must not rewrite this outcome.
The unchanged seal replays 20 files; manifest SHA-256:
`8e1cd6aa12c340d50458aa0a65171297fbcd480e2b13e0aea4feb2f5f43ce897`.

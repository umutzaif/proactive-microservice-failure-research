# ob-netdelay-500m-normal-10u-004 invalid preflight report

## Status

`ob-netdelay-500m-normal-10u-004` is **invalid/incomplete preflight evidence**. It is
excluded from Dataset v1, the 10u repeat count, and every D-067 headroom calculation.
The run ID is closed and cannot be reused.

## Failure boundary

The canonical `2c8541409cea459328374afd19ef8999c53bc93c` runtime reached base deployment
but lost the Kubernetes API during the deployment-availability wait. The runner ended
with `step_failed:deploy_base`. Overlay validation, target stability, warm-up, baseline,
telemetry, manifestation analysis and scientific fault never started.

Docker Desktop concurrently reported a full disk and a read-only host check showed only
about 7.5 MB free on C:. This is strong diagnostic context for the engine/API loss, but
the three runner-produced files do not independently prove a unique root cause.

## Closure limitations

Best-effort rollback failed with `rollback_apply_failed`. Minikube stop timed out after
Docker inspect/API errors, so profile stop and container state are unknown. No host-after
boundary exists; host-health deltas cannot be claimed. The seal therefore preserves an
invalid/incomplete lifecycle, not a valid scientific or operational recovery result.

## Next-action boundary

Do not retry this ID or change thresholds, probes, resources, topology, workload or
timeouts. Preserve the evidence first. Disk inventory, deletion, Docker restart/profile
recovery and any new replacement ID remain separately approval-gated.

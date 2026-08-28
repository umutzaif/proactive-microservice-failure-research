# ob-netdelay-500m-normal-10u-002 invalid preflight report

## Status

`ob-netdelay-500m-normal-10u-002` is **invalid/incomplete preflight evidence**.
It is excluded from the dataset, the 10u repeat count, and every D-067 headroom
calculation. Its run ID must not be reused.

## Failure boundary

The base deployment availability gate timed out before overlay validation, target
stability, warm-up, baseline, telemetry collection, or any scientific fault. The
runner recorded `step_failed:deploy_base`. Its best-effort rollback rollout also timed
out, after which Minikube stopped.

A concurrent read-only Kubernetes observation showed recommendationservice at `0/1`,
`CrashLoopBackOff`, six restarts, and repeated one-second readiness/liveness probe
timeouts. Because the runner did not seal that observation, it is reported only as
diagnostic context and not as a definitive causal finding.

## Preserved evidence

The run-local diagnostic seal binds the host RecordId boundary, run error, rollback
error, invalid assessment, and post-stop host measurement. WHEA-17, Kernel-Power-41,
and BugCheck deltas were all zero. No raw, enriched, telemetry, manifestation, or valid
receipt artifacts exist because the scientific window never began.

## Next-action boundary

Do not retry by changing timeouts, probes, resources, topology, workload, or acceptance
criteria. First perform a separately identified no-fault readiness diagnosis or prove
fresh host/service stability. Any replacement must use a new run ID and the unchanged
D-067 scientific contract.

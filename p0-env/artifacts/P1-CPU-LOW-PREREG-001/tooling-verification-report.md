# P1-CPU-LOW-PREREG-001 Tooling Verification

## Scope

This milestone prepares, but does not execute, the first low CPU-stress
calibration. The profile and validity rules were frozen before fault data.

## Files and responsibilities

- `cpu-recommendation-low-v1.json`: single source of truth for target,
  50-millicore demand, 120-second ramp, 300-second steady phase, bounded runtime
  and physical-effect acceptance criteria. Change only through a new version and
  explicit research decision.
- `cpu-duty-worker.py`: dependency-free bounded worker executed in the existing
  target container. It cannot exceed the profile's 450-second safety maximum.
- `invoke-cpu-stress.ps1`: resolves exactly one target pod, verifies the worker
  hash, runs the worker and preserves execution evidence. It does not claim
  physical effect.
- `analyze-cpu-fault-effect.py`: compares archived baseline and steady CPU
  counter rates. It requires at least 240 intervals per phase and at least
  25 millicores mean increase.
- `verify-scientific-fault-run-metadata.ps1`: rejects mismatched hashes, phase
  durations, target/profile/SLO changes, restarts, missing physical effect and
  nonzero host-health deltas.
- `detect-fault-manifestation.py`: applies the frozen latency/error rule on one
  five-second grid anchored at normal-baseline start; phase changes never reset
  or realign the grid. Its output is sealed into metadata and final receipt.
- final receipt tooling: copies and hashes fault profile, SLO configuration and
  injector evidence for offline verification.
- `run-low-cpu-calibration.ps1`: fail-closed lifecycle orchestrator. It requires
  a clean committed tree and fresh artifact paths, records phase UTCs and pod
  snapshots, invokes the bounded worker, archives all modalities, runs physical
  effect and manifestation analysis, stops the cluster before the post-host
  gate, and finalizes only when every validity condition passes. Its `finally`
  block stops Minikube after failures while preserving partial evidence.

## Verification performed

- Python worker compilation: passed
- Two-second bounded worker execution: one start, heartbeat and completion
- PowerShell parser checks: passed
- CPU-effect positive fixture: passed
- Insufficient CPU-increase negative fixture: rejected as required
- Fault metadata positive fixture: passed
- Missing physical-effect negative fixture: rejected as required
- Fixed-grid manifestation, empty-window reset and third-window timestamp tests: passed

No cluster was started and no fault was injected during these tests.

## Remaining live gates

The committed tooling revision must be deployed with a clean working tree.
Docker/Minikube readiness, active run ID, deployment availability, target Python
runtime, pod UID/restart baseline, host events and Prometheus target-series
availability must pass before the scientific worker can start.

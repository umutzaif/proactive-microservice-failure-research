# 007 invalid/incomplete closure

Recorded on 2026-09-30 from the original 2026-09-12 artifacts. No new live run,
network reconfiguration or Engine-loss investigation was performed on resumption.
Canonical runtime revision: `6c6a7ac6914951a991b72da2cf82b2311d6d9ae7`.
Transport: USB -> phone -> Wi-Fi; phone uplink and background load were operator
declarations, not independently verified phone state.

## Outcome

`ob-netdelay-500m-normal-10u-007` is consumed, permanently closed and invalid/incomplete.
Run times: 2026-09-12T12:48:26.4949761Z to 2026-09-12T13:08:07.3970857Z.
Preflight, deployment, workload, convergence, 25 stability observations with zero
restarts, warm-up/baseline and pre/post no-toxic checks completed. Raw and enriched
archives each contain 17 manifest entries; enriched logs contain 21,170 records.

At 13:08:06.0769148Z, post-stop network capture failed because no IPv4 default route
(`0.0.0.0/0`) was returned. Failure closure independently recorded the same error.
Rollback verification passed at 13:07:37.9784289Z. Original closure records all profile
components Stopped, container exited/137/OOMKilled=false, and host deltas 0/0/0.
The failure-closure stop_exit_code is null; it must not be reinterpreted as a stored
zero exit code. These are historical observations, not current host status.

There is no scientific metadata or finalized receipt. Network continuity did not
pass. The precise cause and timing of route loss are unknown; this does not prove
phone Wi-Fi, USB hardware, mobile fallback or Docker caused it. No retrospective
operator continuity confirmation is available. Recovered stdout is not assumed.

## Partial measurements and exclusions

All 60 expected 5-second product-detail windows are nonempty (minimum 48).
Maximum window-p95 was 1013.642 ms; frozen three-consecutive-window manifestation
was null. A single high window is not the frozen manifestation rule.
The analyzer's local `valid_headroom_input=true` checks its input/window contract;
it does not override failed end-to-end network closure. Preserve that original file
unchanged but exclude 007 from accepted headroom, Dataset and normal counts.
D-067 remains 10u 1/3, 15u 2/3, total 3/6 in this checkout.

## Evidence and next boundary

This report lives beside prior run reports; original partial/failure files remain
inside the run directory and are sealed separately. Raw, enriched and telemetry
archives stay at their existing local paths; no collection or transformation is rerun.
Offline replay verifies bytes and archive semantics, not scientific validity.

On 2026-09-30 raw and enriched archive replay passed 17/17 each. Original closure
artifacts were sealed 20/20 with manifest SHA-256
`7004fd4fc2b4c2ba91f89ae3db1b5140376cb7fd5e47e37912b82b20dc27d8e8`.

Telemetry replay using explicit Windows PowerShell 5.1 (the original runtime) passed
25/25 manifest files with zero failures: 517,193 metric samples, 3,192 selected traces
and 35,189 spans. An initial replay in the execution tool's shell passed all hashes
but reported 4,128 metric-time, 51 trace-time and 28 chunk-coverage failures. The
explicit 5.1 replay did not reproduce those semantic failures. This demonstrates a
verification-environment discrepancy, not corrupt bytes; its exact cause is not
diagnosed or repaired here. Use the original runtime for reproducible replay and
do not confuse either replay result with the failed live network closure.

The 2026-09-19 preparation deadline has passed. Available canonical records do not
establish six valid normals, sealed quantitative headroom and health-path proof by
that date. Fault preparation is stopped under D-112; an alternative execution
environment must go to the mentor for decision. No silent date extension, replacement
run, cellular fallback or fault is authorized by this closure.

Subsequent prospective decision: D-116 (2026-09-30) removes the calendar stop for
future preparation at the user's direction. The preceding deadline assessment is
historical; 007 remains invalid and all evidence/validity requirements still apply.

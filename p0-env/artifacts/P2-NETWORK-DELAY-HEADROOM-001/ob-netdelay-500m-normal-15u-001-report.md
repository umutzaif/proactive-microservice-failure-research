# ob-netdelay-500m-normal-15u-001 invalid run report

## Status

`ob-netdelay-500m-normal-15u-001` is **invalid/incomplete** and is excluded from
the dataset and every D-067 headroom calculation. Its identifier must not be reused.

## What completed

- The run used the preregistered `ob-second-15u-1r-v1` workload and the no-toxic
  proxy-overlay normal topology.
- The 300-second warm-up and 300-second baseline completed without starting a
  scientific fault.
- Baseline coverage was 60/60 complete five-second windows and 60/60 nonempty
  product-detail windows; failure manifestation was null.
- Pod lifecycle, proxy post-clean, rollback, host-event deltas, and schema-v3
  collection completed successfully.
- The diagnostic run-level upper-tail output was `299.901 ms`.

## Why it is invalid

After evidence collection and rollback, the runner attempted to assign host-health
data to `$host`. PowerShell variable names are case-insensitive, so this collided
with the read-only built-in `$Host` variable. The runner therefore stopped before
scientific metadata verification and the valid-run final receipt.

This is an operational finalization failure, not a negative scientific result.
The otherwise complete diagnostic output cannot repair the missing close gate and
must not be promoted into a valid headroom input.

## Preservation and falsification

`invalid-assessment.json` explicitly records exclusion. The finalized-invalid
receipt hashes the raw, enriched, telemetry, and run-local JSON evidence using
canonical JSON SHA-256. Independently replay
`p0-env/scripts/verify-invalid-run-receipt.py` with this run ID; any changed or
missing source must make verification fail.

## Next action boundary

Fix only the PowerShell variable collision, add a regression check, and execute a
new preregistered replacement under a new run ID. Do not change topology, workload,
timing, coverage, manifestation, or headroom thresholds in response to this run.

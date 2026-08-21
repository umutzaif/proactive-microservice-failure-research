# ob-netdelay-500m-normal-15u-005 invalid run report

## Status

`ob-netdelay-500m-normal-15u-005` is **invalid/incomplete**, excluded from the
dataset and D-067 headroom calculation, and its ID cannot be reused.

## Completed evidence

The no-toxic 15u window, raw/enriched/schema-v3 archives, coverage, null
manifestation, pod lifecycle, rollback, zero host-event deltas, and independent
metadata verification (15/15) passed. The diagnostic maximum was `1082.282 ms`.

## Final receipt failure

The shared finalizer copied scientific metadata and the workload profile, then tried
to read `scientificMetadata.random_seed`. The normal-run metadata contract carries
the seed inside the hashed workload profile rather than as a top-level property.
PowerShell StrictMode rejected the missing property. The partial receipt directory
was preserved under `finalized/_invalid`; no valid receipt exists.

This run therefore demonstrates a finalizer integration gap, not an academic result.
The next replacement requires an end-to-end fixture that exercises the normal metadata
shape through finalization and offline receipt verification before any live window.

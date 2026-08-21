# ob-netdelay-500m-normal-15u-004 invalid run report

## Status

`ob-netdelay-500m-normal-15u-004` is **invalid/incomplete**. It is excluded from
the dataset and all D-067 calculations, and its identifier must not be reused.

## Completed evidence

The no-toxic 15u scientific window completed. Raw logs, enriched logs, schema-v3
telemetry, null manifestation, pod lifecycle, rollback, and zero host-event deltas
passed. The diagnostic run-level maximum was `605.978 ms`; an isolated maximum does
not itself satisfy the frozen three-consecutive-window manifestation rule.

## Close-gate failure

The runner correctly admitted the D-068 replacement ID, but the independent metadata
verifier contained a duplicated, older run-ID allowlist without `15u-004`. Its identity
check therefore failed after metadata construction and before valid final receipt
creation. Because the receipt is an independent mandatory gate, the run cannot be
repaired into a valid observation after execution.

The invalid receipt hashes the complete run-local JSON evidence, scientific metadata,
and raw/enriched/telemetry manifests. Replay the invalid receipt verifier to falsify
the preserved state. The next replacement must use a new ID and pass a cross-component
ID-contract regression before live execution.

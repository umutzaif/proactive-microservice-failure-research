# P1-SLO-ROUTE-CANDIDATE-001 Route-Specific SLI Decision Support

## Purpose and boundary

This analysis compares three user-visible frontend populations in the three
verified normal baselines. It reuses immutable schema-v3 selected traces and
does not run a deployment, inject a fault, or freeze an SLO.

The populations are:

- `global_user_routes`: every frontend user server span;
- `root_excluded_user_routes`: the same population except exact route `/`;
- `product_detail_family`: normalized paths beginning with `/product/`, so
  individual product identifiers do not fragment one user action.

## Combined result

| Population | Requests | Nonempty / all 5 s windows | Coverage | Window-p95 p95 | Window-p95 p99 | Maximum | Errors |
|---|---:|---:|---:|---:|---:|---:|---:|
| Global user routes | 2,219 | 180 / 180 | 100.00% | 4,081.168 ms | 4,279.712 ms | 4,764.157 ms | 0 |
| Root excluded | 1,983 | 180 / 180 | 100.00% | 165.049 ms | 345.992 ms | 451.162 ms | 0 |
| Product detail family | 1,066 | 179 / 180 | 99.44% | 124.563 ms | 345.992 ms | 451.162 ms | 0 |

## Product-family run stability

| Run | Requests | Nonempty / all windows | Window-p95 p95 | Window-p95 p99 | Maximum |
|---|---:|---:|---:|---:|---:|
| `ob-cpu-normal-002` | 354 | 59 / 60 | 63.617 ms | 117.555 ms | 117.555 ms |
| `ob-cpu-normal-003` | 349 | 60 / 60 | 71.747 ms | 345.992 ms | 345.992 ms |
| `ob-cpu-normal-004` | 363 | 60 / 60 | 208.765 ms | 451.162 ms | 451.162 ms |

The product population is dense enough for five-second monitoring and is more
closely aligned with the selected `recommendationservice` fault target than an
unscoped global frontend population. However, the upper tail differs materially
between runs. The combined normal p99 (`345.992 ms`) is therefore a candidate,
not an accepted threshold.

## Reproducibility and falsification

- Script: `p0-env/scripts/analyze-route-specific-slo-candidates.py`
- Source runs: `ob-cpu-normal-002`, `ob-cpu-normal-003`, `ob-cpu-normal-004`
- Window: complete, non-overlapping 5-second normal-baseline windows
- Output SHA-256: `886eff666099a4525f9510a98caca9d4d17cf8beb1db5fbf0b60d7ec48589bae`
- An independent replay produced the same SHA-256 byte for byte.
- Invalid or non-normal metadata is rejected by the analyzer.
- Empty route windows are reported and never assigned an invented latency.

## Decision boundary

This evidence supports considering `/product/{id}` as the primary latency SLI
population, with a separately retained frontend error-rate guard. Adopting that
population changes what counts as user-visible failure and therefore requires an
explicit research decision. No SLO is frozen and fault injection remains gated.

# P1-SLO-FREEZE-001

## Frozen manifestation rule

Before observing any fault run, `p1-cpu-001-slo-v1` freezes the following OR rule:

1. `/product/{id}` five-second window p95 latency is strictly greater than
   `345.992 ms` for three consecutive observed windows; or
2. global frontend user-request error rate is strictly greater than `0` for
   three consecutive observed windows.

The completion time of the first qualifying third window is
`failure_manifestation`. An empty window is unobserved and resets the relevant
streak; it is not assigned zero latency and is not counted as a healthy window.

## Rationale

The latency threshold is the nearest-rank p99 of the product-family window-p95
distribution in the three valid normal baselines. The product family is aligned
with the selected `recommendationservice` target and covered 179/180 normal
windows. The global error guard retains visibility of user-visible failures
outside that route. Requiring three consecutive windows reduces sensitivity to
one isolated normal-tail observation.

No fault observation, validation result, model output, LLM result or GAT result
was used to select the population, threshold or persistence rule.

## Normal-baseline falsification

| Run | Latency violating windows | Maximum latency streak | Maximum error streak | False manifestation |
|---|---:|---:|---:|---|
| `ob-cpu-normal-002` | 0 | 0 | 0 | No |
| `ob-cpu-normal-003` | 0 | 0 | 0 | No |
| `ob-cpu-normal-004` | 1 | 1 | 0 | No |

The verifier rejected no normal run and detected zero false manifestations.
This proves only compatibility with the three source normal baselines; it does
not prove that the rule is sensitive to CPU stress.

## Reproduction

Run `verify-frozen-slo-on-normal-baselines.py` with the route candidate evidence,
the versioned SLO JSON and an output path. Verify the output reports
`verification_passed=true`, then replay to a second path and compare SHA-256.

- SLO config SHA-256: `3645ccd7fbcc487725ff6f9480fd91b231f77c50b46b235bd53a1448d90baf42`
- Normal replay SHA-256: `8401381d7726d9363c906db968cd10e15dbfdf293994c1ce9c58b9f2e6eddd84`
- Independent replay: byte-identical
- Synthetic verifier tests: two violations rejected; three accepted; an empty
  window reset the streak; equality with the strict threshold did not violate.

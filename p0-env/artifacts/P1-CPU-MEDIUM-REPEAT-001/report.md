# P1-CPU-MEDIUM-REPEAT-001 Descriptive Repeatability Report

The preregistered valid medium set is `ob-cpu-medium-001`,
`ob-cpu-medium-003` and `ob-cpu-medium-004`. All three used
`cpu-recommendation-medium-v1`, workload `ob-default-10u-1r-v1`, seed `1`,
frozen SLO `p1-cpu-001-slo-v1`, the same target and the same lifecycle and
validity gates. Invalid `ob-cpu-medium-002` is preserved but excluded.

| Run | Baseline/steady intervals | CPU increase | Manifestation | Valid |
|---|---:|---:|---|---|
| `ob-cpu-medium-001` | 59/59 | 101.910m | null | yes |
| `ob-cpu-medium-003` | 59/59 | 103.042m | null | yes |
| `ob-cpu-medium-004` | 59/59 | 93.994m | null | yes |

- Mean CPU increase: `99.649m`
- Sample standard deviation: `4.930m`
- Coefficient of variation: `4.947%`
- Range: `93.994–103.042m`
- Physical-effect, pod, host, telemetry and receipt gates: passed in all three
- Failure manifestation: `null` in all three

Under the fixed local host, workload, seed and service configuration, the
medium profile produced a low-variance physical CPU actuation and a repeatable
null manifestation observation. This is descriptive calibration evidence. It
does not prove causal generalization, pre-failure predictability, high-severity
safety, workload generalization or model performance, and it does not authorize
post-hoc SLO changes.

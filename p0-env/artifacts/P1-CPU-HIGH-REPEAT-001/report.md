# P1-CPU-HIGH-REPEAT-001 Report

## Scope

This descriptive analysis covers the three valid high-severity CPU calibration
runs `ob-cpu-high-001`, `ob-cpu-high-002` and `ob-cpu-high-003`. All used the
unchanged `cpu-recommendation-high-v1`, workload `ob-default-10u-1r-v1`, seed
`1`, target `recommendationservice`, frozen SLO `p1-cpu-001-slo-v1` and the
same lifecycle and validity gates.

## Physical effect

| Run | Baseline mCPU | Steady mCPU | Increase mCPU | Coverage |
|---|---:|---:|---:|---:|
| `ob-cpu-high-001` | 11.564 | 158.153 | 146.589 | 59/59 |
| `ob-cpu-high-002` | 13.375 | 157.193 | 143.819 | 59/59 |
| `ob-cpu-high-003` | 13.299 | 163.715 | 150.416 | 59/58 |

- Mean increase: `146.941m`
- Sample standard deviation: `3.313m`
- Coefficient of variation: `2.254%`
- Range: `143.819m` to `150.416m`
- Required minimum increase: `75m`
- Required coverage: at least `48` intervals in each baseline and steady phase

All three runs passed the physical-effect, pod, host-health, telemetry, final
receipt and independent offline verification gates. All three had null failure
manifestation under the frozen three-consecutive-window SLO rule. The high-001,
high-002 and high-003 latency-violation counts were respectively `1`, `0` and
`4`; high-003 reached at most a two-window streak.

## Interpretation boundary

The low coefficient of variation supports repeatable physical CPU actuation for
this profile under this fixed local environment. This three-run descriptive
summary is not an inferential population estimate, does not prove pre-failure
predictability, does not validate a model, and does not authorize changing the
SLO, workload, target service or fault severity.

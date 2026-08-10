# P1-WORKLOAD-CAPACITY-001 Decision Report

## Outcome

D-030, `selected_users=null` sonucuyla tamamlandı. Hiçbir aday önceden
kaydedilmiş bütün kapıları sağlamadığı için ikinci workload profili aktive edilmedi.

| Evidence | 10-user control | 15-user candidate | 20-user candidate |
|---|---:|---:|---:|
| Valid capacity evidence | yes | yes | yes |
| Frontend span rate `/s` | 2.492375 | 3.532528 | 4.755222 |
| Ratio vs 10 users | 1.000000 | 1.417334 | 1.907908 |
| Request ratio `>=1.30x` | reference | pass | pass |
| Recommendation mean CPU m | 26.011 | 35.890 | 43.015 |
| Candidate CPU `<=25m` | not applied | fail | fail |
| CPU p95 m | 116.334 | 143.834 | 152.573 |
| SLO manifestation | null | null | null |
| Max latency/error streak | 1/0 | 1/0 | 1/0 |
| Pod and host gates | pass | pass | pass |

The selector output was replayed byte-identically and retained in
`selection-decision.json`. The 20-user sealed schema-v3 telemetry was also
independently reverified with zero failures.

## Interpretation

Both candidates create materially higher request intensity without normal-SLO
false manifestation or host/pod instability. They are rejected solely because
their observed recommendationservice mean CPU exceeds the preregistered 25m
headroom gate for combining the workload with the existing +150m high profile
under a 200m service limit.

The invalid `ob-capacity-20u-001` and incomplete `ob-capacity-10u-001` remain
excluded. Their replacements do not retroactively change those records.

## Downstream gate

The conditional plan for three normal baselines and six randomized second-load
fault runs is not activated because no workload was selected. Changing the CPU
headroom threshold, testing a smaller candidate such as 12 users, reducing the
high fault request, or changing the service CPU limit is a new academic decision
and requires a new preregistration. No model, LLM or GAT work is authorized.

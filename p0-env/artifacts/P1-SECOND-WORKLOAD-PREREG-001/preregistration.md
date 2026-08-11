# P1-SECOND-WORKLOAD-PREREG-001

## Status and decision boundary

This preregistration implements D-033 after explicit user approval on
2026-08-11. It is configuration and planning evidence, not scientific data.
No run or fault injection may start until this preregistration and its profiles
are merged into canonical `main`, the worktree is clean, and the ordinary
active-run-ID, pod, host, telemetry, close-run and offline receipt gates pass.

## Frozen second workload

- Workload profile: `ob-second-15u-1r-v1`.
- Users: `15`; spawn rate: `1/s`; random seed: `1`.
- Image, task weights, wait distribution, Locust/Faker versions, workload code
  hash, full trace sampling and telemetry chunk policy are unchanged from the
  10-user scientific workload.
- Capacity provenance: `ob-capacity-15u-001` produced `1.417334x` the same-day
  10-user request intensity, recommendationservice mean CPU `35.890m`, null
  SLO manifestation and passed pod/host/schema-v3 gates.
- Prospective D-033 gate: normal mean CPU `<=40m`, derived as a 5% (`10m`)
  nominal reserve under the unchanged `200m` limit and `+150m` high demand.
  This selects 15 users only for new work and does not retroactively alter the
  failed D-030 `<=25m` decision.

## Frozen matched fault profiles

- Low: `cpu-recommendation-low-15u-v1`, `+50m`, minimum observed increase `25m`.
- Medium: `cpu-recommendation-medium-15u-v1`, `+100m`, minimum increase `50m`.
- High: `cpu-recommendation-high-15u-v1`, `+150m`, minimum increase `75m`.
- All keep recommendationservice, `200m` limit, 120-second ramp, 300-second
  steady, 300-second cooldown, schema-v3 coverage, worker lifecycle/hash,
  frozen SLO and all fail-closed validity gates unchanged.
- The new profile IDs and workload binding prevent 10-user and 15-user
  provenance from being conflated. Tests require all other fault-physics fields
  to match their source profiles.

## Frozen run inventory and order

Three independent valid normal baselines must be completed first:

1. `ob-cpu-15u-normal-001`
2. `ob-cpu-15u-normal-002`
3. `ob-cpu-15u-normal-003`

Only after all three normal runs pass may fault runs start. D-030 randomization
seed `20260810` and its previously frozen order remain:

1. `ob-cpu-15u-medium-002`
2. `ob-cpu-15u-low-002`
3. `ob-cpu-15u-high-001`
4. `ob-cpu-15u-high-002`
5. `ob-cpu-15u-low-001`
6. `ob-cpu-15u-medium-001`

The numeric suffix denotes the preregistered replicate, not chronological
execution. Invalid runs remain immutable and are replaced by a new unique ID
under unchanged conditions; they are never deleted or relabelled valid.

## Validity and interpretation

Every run requires a unique run ID, canonical UTC lifecycle, active deployment
run-ID verification, stable 15-pod UID/restart snapshots, WHEA Event 17 /
Kernel-Power 41 / bugcheck deltas `0/0/0`, immutable raw and enriched logs,
schema-v3 metric/trace chunk and boundary policy, close-run, final receipt and
offline verification. Fault runs additionally require profile-specific physical
effect coverage and worker evidence. Null manifestation remains a valid result.

The three new normal runs are scientific controls; the earlier capacity run is
selection evidence only and cannot substitute for them. No model training, LLM
validation, GAT work, SLO change, target-service change or result-dependent
reordering is authorized.

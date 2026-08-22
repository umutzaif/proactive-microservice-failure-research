# ob-netdelay-500m-normal-15u-006 valid run report

## Scientific status

`ob-netdelay-500m-normal-15u-006` is the first valid 15u input for the D-067
500m normal-headroom design. It is a no-fault normal observation, not a network-delay
treatment and not an authorization or selection of a delay severity.

## What was done and measured

- Workload: `ob-second-15u-1r-v1` (15 users, spawn rate 1/s, seed 1).
- Topology/resources: no-toxic Toxiproxy overlay; recommendationservice server
  `500m/100m`, proxy `100m`.
- Timing: 300-second warm-up followed by a 300-second baseline.
- Primary run summary: maximum nonempty product-detail five-second window-p95 latency
  during baseline = **539.155 ms**.
- Coverage and symptom gate: 60/60 complete and nonempty product-detail windows;
  frozen failure manifestation remained null.

## Independent validity gates

Target stability passed 25 observations with zero restarts. Proxy clean state passed
before and after the window. Raw archive verification passed 17/17; enriched logs
contained 26,475 verified records. Schema-v3 telemetry passed 25/25 manifest entries,
514,271 metric samples, 3,803 selected unique traces, and 47,714 spans. Pod lifecycle,
rollback, and host deltas (WHEA-17, Kernel-Power-41, BugCheck) passed. Metadata passed
15/15, finalization succeeded, and the offline receipt verifier reported zero failures.

## Value to the core defense thesis

This run supplies one independently sealed estimate of the system's normal upper-tail
latency under the exact topology/resources planned for later network-delay treatment.
Its value is control-side comparability: a later latency change can be contrasted with
matched normal behavior instead of with a historical 200m or different-topology run.

It does **not** yet establish repeatability, a population bound, fault manifestation,
causality, or an academically defensible delay severity. D-067 requires three valid
15u runs and three valid 10u runs before the preregistered max/range headroom calculation.

## Falsification

Replay `verify-finalized-run.ps1` against the finalized receipt and replay the normal
metadata verifier. Any source hash, run ID, seed, time window, toxic state, lifecycle,
host, or telemetry mismatch must reject the run.

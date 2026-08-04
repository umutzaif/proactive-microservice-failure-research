# P1-SLO-CANDIDATE-001 Normal SLI Distribution Report

## Purpose

Describe latency and error-rate SLI candidates from the three valid normal
baselines without freezing an SLO or authorizing fault injection.

## Inputs and method

- Runs: `ob-cpu-normal-002`, `ob-cpu-normal-003`, `ob-cpu-normal-004`
- Source: immutable schema-v3 `selected/traces.ndjson` and verified scientific metadata
- Population: `frontend` server spans in each declared normal-baseline interval
- Exclusions: warm-up, partial final window, `/_healthz`, health-check and telemetry-export spans
- Window: 60 complete, non-overlapping 5-second windows per run
- Percentile method: nearest rank

## Results

| Run | Complete windows | User requests | Errors | Partial-tail spans excluded |
|---|---:|---:|---:|---:|
| `ob-cpu-normal-002` | 60 | 741 | 0 | 2 |
| `ob-cpu-normal-003` | 60 | 739 | 0 | 0 |
| `ob-cpu-normal-004` | 60 | 739 | 0 | 0 |

Across 180 complete windows, the distribution of per-window p95 latency was:

- p95: `4,081.168 ms`
- p99: `4,279.712 ms`
- maximum: `4,764.157 ms`

All 2,219 included requests completed without a trace-derived error. The normal
window error-rate p95, p99 and maximum were therefore all `0`.

The global latency distribution is dominated by the `/` route. Its per-request
p50 was approximately 4 seconds in every run, while most product/cart routes
were generally tens of milliseconds. This makes `4,279.712 ms for three
consecutive 5-second windows` a protocol-compatible empirical latency candidate,
but not yet an accepted objective: freezing it could normalize an unexplained
baseline bottleneck. Zero observed errors also cannot by itself justify a
non-zero fixed error-rate threshold.

## Verification and limitations

- Route totals equal window totals and reported request totals for every run.
- All 180 planned windows are non-empty.
- Re-running the analyzer produced byte-identical output SHA-256
  `83eaacb3820dc37f184f7b245a9652919d6cc30e9fb718eb94d35b9c7a110674`.
- Three same-host runs are pilot evidence, not a population guarantee.
- Trace latency is frontend server time, not client-side network latency.
- Endpoint mixing makes the global p95 sensitive to the versioned workload mix.

Decision: retain O-003 as open. Explain the normal `/` latency before accepting
the latency threshold; choose any fixed error-rate threshold as an explicit
research policy rather than presenting it as learned from zero errors.

Follow-up diagnostic: source, enriched-log and critical-path evidence identifies
the frontend handler's uninstrumented `metadata.google.internal.` DNS lookup as
the strongest explanation. It remains a causal hypothesis pending a controlled
A/B smoke. See `frontend-root-diagnostic-report.md`.

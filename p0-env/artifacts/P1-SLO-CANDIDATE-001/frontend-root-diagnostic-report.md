# Frontend `/` Latency Diagnostic

## Finding

Across the three valid normal runs, the frontend `/` route returned HTTP 200
without trace-derived errors but frequently took approximately four seconds:

| Run | `/` traces | p50 | p95 | max |
|---|---:|---:|---:|---:|
| `ob-cpu-normal-002` | 78 | 4,017.128 ms | 4,050.504 ms | 4,215.323 ms |
| `ob-cpu-normal-003` | 83 | 4,016.618 ms | 4,047.426 ms | 4,096.574 ms |
| `ob-cpu-normal-004` | 75 | 4,020.319 ms | 4,199.183 ms | 4,764.157 ms |

The longest instrumented non-root spans in the same traces were normally only
a few milliseconds. They do not explain the roughly four-second frontend span.
This localizes the wait to an uninstrumented frontend step rather than proving a
slow downstream microservice.

## Source and log evidence

`src/frontend/handlers.go` performs the following work for every home request:

1. reads `ENV_PLATFORM`, printing `env platform is either empty or invalid`
   when it is absent or invalid;
2. calls `net.LookupHost("metadata.google.internal.")` to autodetect GCP;
3. only then renders the response.

The v0.10.6 release manifest leaves `ENV_PLATFORM` commented out, and the local
overlay does not add it. Enriched frontend logs from all three runs repeatedly
contain the empty/invalid message for `/` requests. The DNS lookup has no child
span, matching the unexplained span gap.

## Interpretation

The strongest current hypothesis is that GCP metadata DNS autodetection in the
local Kubernetes environment incurs resolver retries/timeouts. This is a
source-, log-, and trace-supported inference, not causal proof.

## Falsification

A controlled A/B smoke can compare the current v0.10.6 frontend with a version
that skips GCP autodetection when `ENV_PLATFORM=local` is explicitly set. The
same fixed workload must be used and `/` latency must fall while downstream RPC
latencies remain comparable. Merely setting `ENV_PLATFORM=local` on the current
code is insufficient because the current handler performs `LookupHost`
unconditionally.

## Governance impact

A patched frontend changes the benchmark implementation and invalidates direct
pooling with the three existing normal baselines. Alternatively excluding `/`
or selecting a route-specific SLO changes the SLO population. Keeping the
current global threshold preserves the system but normalizes the unexplained
delay and reduces fault sensitivity. No alternative is selected in this report.

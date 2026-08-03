# P1-FRONTEND-DNS-AB-001 Report

## Status

`invalid/inconclusive` tooling experiment. No scientific dataset inclusion, no
fault injection and no accepted deployment change.

## Tested change

The patched v0.10.6 frontend skips `metadata.google.internal.` autodetection
when `ENV_PLATFORM=local` is explicitly valid. The image was built reproducibly
as `makale/frontend:v0.10.6-env-platform-v1`. The tested BuildKit manifest-list
ID was:

`sha256:56cdd59106159ccd58180581a0f157102f422adb54dfe900779b9e8499030390`

Its runtime manifest was
`sha256:a7256ddd088db164b7f924cd166e99c82cc52eb018bdf3a72b227203ae222edc`
and runtime config was
`sha256:324ad14610daed9fc6ac1001afa316013c77b0bac1d46f509f36294c4b0cb07c`.
The builder was later pinned to the already-resolved distroless digest and
provenance attestation was disabled so repeated local builds do not acquire a
new time-dependent manifest-list ID; runtime bytes remained unchanged.
Two consecutive cache-backed builds then both produced image ID
`sha256:a7256ddd088db164b7f924cd166e99c82cc52eb018bdf3a72b227203ae222edc`.

The upstream source checkout remained unmodified. The patch was applied only in
the Docker builder context.

## Attempts

### Attempt 001

The control request exceeded the original 15-second timeout and aborted before
a result file was written. Cleanup restored the deployment. This attempt showed
that timeout must be recorded as data rather than terminate the sequence.

### Attempt 002 — cold-start confounded

Five sequential requests per A/B/A variant, without a separate warm-up:

- control A median: 8,231.638 ms; 2/5 timeout;
- treatment median: 4,149.615 ms; 2/5 timeout;
- control B median: 8,157.061 ms; 2/5 timeout.

Within every newly rolled-out pod the first requests were slowest, so lazy gRPC
connection/cold-start cost was mixed with the image effect. Preserved SHA-256:
`c1cfcbbe6625bb53c2cd7d0d54fbfbc592d78220113bc11bd41029133e4bf0d9`.

### Attempt 003 — DNS-cache/sequence confounded

Five warm-up requests followed by five measured requests per A/B/A variant:

- control A median: 101.283 ms; p95 3,639.393 ms;
- treatment median: 200.923 ms; p95 227.792 ms;
- control B median: 4,030.807 ms; p95 4,059.204 ms.

The two identical A controls disagree materially. Individual control requests
transitioned from timeout/approximately four seconds to tens of milliseconds,
consistent with negative DNS-cache or other temporal carry-over. Therefore the
treatment effect cannot be separated reliably. Preserved SHA-256:
`73b33a281e78509d3af6582b41fdefcec02bd76fac4ea6741c21b26f6aad6c69`.

## Cleanup and host health

- Upstream frontend image restored.
- `ENV_PLATFORM` removed.
- Loadgenerator restored to one replica.
- Temporary A/B client pod deleted.
- Minikube stopped.
- WHEA Event 17: 881 → 881 (delta 0).
- Kernel-Power 41: 5 → 5 (delta 0).
- Bugcheck: 1 → 1 (delta 0).

## Conclusion

The patch is technically plausible and treatment became consistently fast only
after warm-up, but the A controls were not stationary. The A/B/A evidence is
therefore insufficient for causal acceptance. No SLO is frozen and the patched
image is not adopted. A future test would need isolated DNS/cache state and the
same concurrent workload shape as the scientific baseline, preferably with
randomized variant order and repeated independent pods.

# P1-FRONTEND-DNS-AB-002 Report

## Outcome

The isolated, simultaneous, randomized A/B test completed correctly but failed
its preregistered patch-acceptance rule. This is a valid negative tooling result,
not an invalid run and not scientific dataset material.

## Preregistered design

- Independent upstream control and patched treatment frontend pods
- Both variants configured with `ENV_PLATFORM=local`
- One excluded 10-concurrent-request warm-up batch per variant
- Six paired rounds, ten concurrent `/` requests per variant per round
- Variant order randomized with seed `20260803`
- Ten-second cooldown between rounds
- Acceptance frozen in commit `673e2c9`

## Results

| Round | Order | Control median | Treatment median | Treatment/control ratio |
|---:|---|---:|---:|---:|
| 1 | control → treatment | 12,963.847 ms | 9,364.946 ms | 0.722389 |
| 2 | treatment → control | 5,048.333 ms | 1,569.250 ms | 0.310845 |
| 3 | treatment → control | 5,883.404 ms | 1,073.140 ms | 0.182401 |
| 4 | treatment → control | 5,000.096 ms | 1,113.342 ms | 0.222664 |
| 5 | treatment → control | 5,073.475 ms | 1,183.428 ms | 0.233258 |
| 6 | treatment → control | 5,119.135 ms | 1,291.631 ms | 0.252314 |

All 120 measured requests returned HTTP 200. Treatment median latency was lower
in all six rounds. Nevertheless, the maximum paired median ratio was `0.722389`,
which exceeds the frozen `0.25` limit; round 6 also slightly exceeded the limit.

## Acceptance gates

| Gate | Result |
|---|---|
| HTTP 200 rate = 100% | Passed |
| Treatment median lower in every round | Passed |
| Maximum paired median ratio ≤ 0.25 | **Failed** |
| Cleanup | Passed |
| WHEA 17 / Kernel-Power 41 / bugcheck deltas = 0 | Passed |

Overall preregistered acceptance: **failed**.

## Integrity and cleanup

- Source result SHA-256: `6d8c3fe8f9028c83fa187f95243b3e0323f332bd10e3955683fad3e4b0c36b81`
- Control/treatment deployments and services removed
- A/B client pod removed
- Loadgenerator restored to one replica
- Minikube stopped
- WHEA Event 17: 881 → 881
- Kernel-Power 41: 5 → 5
- Bugcheck: 1 → 1

## Interpretation

The direction is consistently favorable to the patch, so DNS autodetection is
likely one contributor. The preregistered magnitude and stability requirement
was not met, meaning the patch does not sufficiently explain or remove the
latency under the tested concurrent condition. The threshold is not relaxed
post hoc. The patched image is not adopted, no SLO is frozen and fault injection
does not begin.

# P1-FRONTEND-DNS-AB-002 Preregistration

Status: method frozen before result collection. Tooling causal test; not a
scientific baseline and not eligible for the modeling dataset.

Question: does skipping unconditional GCP metadata DNS autodetection materially
reduce local frontend `/` latency after separating rollout, cold-start and
measurement-order effects?

Design:

- one upstream v0.10.6 control pod and one patched treatment pod run simultaneously;
- both receive `ENV_PLATFORM=local`; image code is the only intended difference;
- one excluded 10-concurrent-request warm-up batch per pod;
- six measured paired rounds;
- ten concurrent `/` requests per variant per round;
- A/B order randomized with seed `20260803`;
- ten-second cooldown between rounds;
- original loadgenerator scaled to zero during the test;
- paired resources and client removed afterward.

Acceptance criteria, frozen before execution:

1. all ten requests in every measured batch return HTTP 200;
2. treatment median latency is lower than paired control median in all six rounds;
3. the maximum treatment/control paired median ratio is at most `0.25`;
4. cleanup passes;
5. WHEA 17, Kernel-Power 41 and bugcheck deltas are all zero.

Failure or disagreement is preserved as invalid/inconclusive evidence. Passing
this tooling test supports causality but does not itself authorize the patched
image for scientific runs. Adoption would require an explicit research decision
and fresh normal baselines under a new deployment revision.

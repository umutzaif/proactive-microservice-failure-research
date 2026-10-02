# ob-netdelay-500m-normal-10u-010 preregistration (D-120)

## Identity and authority

The user approved repository preparation on 2026-10-01 for one prospective manual
replacement normal. `ob-netdelay-500m-normal-10u-010` replaces consumed invalid 009
at the original D-067 10u-002 slot; original randomization is unchanged and 10u-003
remains final. Preparation, tests, commit, push or PR do not authorize runtime. Live
execution requires a clean merged revision, the exact state root, fresh operator notes,
fresh preflight evidence and separate explicit approval. No queue, retry or fallback.

## Frozen scientific and transport conditions

- Experiment P2-NETWORK-DELAY-HEADROOM-001; workload ob-default-10u-1r-v1;
  users/spawn-rate/seed 10/1/1; no-toxic proxy overlay.
- Recommendation server CPU limit/request 500m/100m; proxy CPU limit 100m.
- Full-selector convergence <=120 s at 5 s cadence, then unchanged single-pod
  UID/container/restart stability for 120 s at 5 s cadence.
- Warm-up 300 s and baseline 300 s; 60 expected and >=48 nonempty five-second
  product-detail windows.
- Frozen SLO p2-network-delay-001-slo-v1: 594.664 ms and three consecutive
  violating windows; normal failure manifestation must remain null.
- Complete raw/enriched/schema-v3 telemetry, metadata, rollback, stopped state,
  host 0/0/0, stable network, final receipt and offline replay are mandatory.
- Transport remains PC -> physical USB -> phone -> phone Wi-Fi. Host physical Wi-Fi
  and non-tether physical Ethernet must be Disabled/absent. Phone cellular data must
  be disabled by operator declaration `wifi_only_cellular_disabled`.

## D-119 failure prevention

Before Python, artifact creation, preflight or infrastructure start, the runner must
verify that `kustomization.yaml` contains exactly three and `observability.yaml`
exactly four occurrences of 010, with no other network-delay normal identity in either
file. Any mismatch is artifact-free and does not consume 010. The repository binds
all seven fields to 010 prospectively. Live Kubernetes verification remains mandatory
after deployment; the static check does not substitute for it.

## Operational and research boundary

The exact existing stopped profile, clean pinned source, clean checkout, mentor-policy
pass, readable boot-covering System log, host 0/0/0, >=15 GiB free, Docker readiness,
unique USB/RNDIS route and fresh background-load note remain mandatory. No reset,
deletion, repair, driver change or Docker restart is authorized.

009 remains immutable and excluded. An artifact-producing 010 attempt consumes 010
even if invalid; never reuse it. Artifact-free rejection does not consume the ID.
D-067 remains 10u 1/3 and 15u 2/3 (3/6); only a fully valid 010 may advance 10u to
2/3. No Dataset inclusion, fault, ladder selection, model, LLM or graph work occurs.

## D-121 schedule-authority provenance

The operator reported on 2026-10-02 that the mentor granted additional time during the
week of 2026-09-28 and accepted evidence-milestone scheduling without a calendar target.
This is oral operator provenance, not an archived written mentor artifact, and it changes
no D-120 execution, scientific-validity or complete-closure gate.

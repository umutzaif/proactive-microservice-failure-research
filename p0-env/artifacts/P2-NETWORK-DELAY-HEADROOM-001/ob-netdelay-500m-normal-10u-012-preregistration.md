# ob-netdelay-500m-normal-10u-012 preregistration (D-127)

## Purpose and predecessor boundary

This unique manual no-fault 10-user normal prospectively replaces consumed
invalid/incomplete `ob-netdelay-500m-normal-10u-011` in the original randomized D-067
`10u-002` slot. `ob-netdelay-500m-normal-10u-003` remains the final slot. D-125 preserves
011 as invalid/incomplete; D-126 repairs only the source-to-deploy binding. Neither decision
turns prior deployment activity into scientific evidence or authorizes live execution.

Before this preregistration, the exact 012 identity had no working-tree, Git-history or artifact
match. It becomes reserved by D-127 and must never be reused after artifact/runtime entry.

## Frozen scientific contract

- workload: `ob-default-10u-1r-v1` (10 users, spawn rate 1/s, seed 1);
- topology: 500m recommendationservice server, 100m request and 100m no-toxic proxy;
- phases: 300 seconds warm-up and 300 seconds normal baseline;
- continuity: one stable server pod/container across 15 tracked deployments, with the existing
  120-second target-stability gate;
- SLO and headroom: unchanged `p2-network-delay-001-slo-v1`, schema-v3 telemetry, null normal
  manifestation, run-level maximum nonempty product-detail 5-second window-p95 input, rollback,
  host-health and final-receipt gates;
- provenance: D-126 explicit physical source root, pinned clean revision, no-reparse validation,
  one temporary source-bound bundle, content/render replay, same-bundle base/overlay/rollback,
  scientific-metadata path/hash binding and read-only receipt sealing;
- prohibited: toxic/fault injection, changed thresholds, post-hoc exclusions, automatic retry,
  queue execution and reuse of any consumed ID.

The accepted count remains 10u `1/3` plus 15u `2/3` (`3/6`). Only a completely valid sealed
012 result may fill the effective replacement slot scientifically and change 10u to `2/3`.
Preregistration changes the sequence entry, not the accepted count.

## Transport and environment gates

012 inherits the D-115/D-117/D-118/D-120/D-124 USB phone-Wi-Fi contract. The PC transport
must be recorded as `usb_tether_wifi` through the exact physical USB/RNDIS path. Physical host
Wi-Fi and every non-tether physical Ethernet adapter must be Disabled or absent. The operator
must freshly declare `wifi_only_cellular_disabled`, and a nonempty background-load note is
mandatory. Prior operator statements are provenance only; they do not replace current machine
evidence or before/after route and adapter stability checks.

## Prospective repository and runtime gates

Before artifacts, infrastructure start or application deployment:

1. use a clean checkout of the exact merged D-127 revision;
2. resolve the exact runtime state root and a separate absolute physical Online Boutique source
   root explicitly;
3. require the preserved profile to be stopped under Docker, Kubernetes v1.34.0, 4 CPU,
   6144 MiB, 32 GiB and containerd;
4. require upstream revision `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` to be clean and
   reject the source root or any ancestor that is a junction/reparse point;
5. reject closed IDs 002 and 004 through 011 and require every 012 output root to be absent;
6. pass `verify-mentor-feedback-policy.ps1` and the 3+4 static identity gate: exactly three 012
   occurrences in `kustomization.yaml` and four in `observability.yaml`, with no foreign normal ID;
7. build and replay the D-126 source-bound bundle before artifacts or Minikube start;
8. pass current USB/RNDIS route, adapter isolation, clean-boot host events, at least 15 GiB free
   space, Docker readiness and stopped-profile preflight;
9. launch only one manual run with no retry after fresh explicit runtime approval naming the
   merged revision, exact runtime state root, exact physical source root, transport declaration
   and background-load note.

An artifact-free rejection before the runner creates the 012 root leaves 012 unconsumed. Once
the artifact root or runtime lifecycle begins, every failure consumes and permanently closes
012; evidence must be preserved and sealed. Repository preparation, tests, PR or merge authorize
neither runtime nor fault execution. `execution_authorized` remains false.

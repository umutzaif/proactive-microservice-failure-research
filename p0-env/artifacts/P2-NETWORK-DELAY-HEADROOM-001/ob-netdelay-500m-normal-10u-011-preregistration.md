# ob-netdelay-500m-normal-10u-011 preregistration (D-124)

## Purpose and predecessor boundary

This unique manual no-fault 10-user normal replaces consumed invalid/incomplete
`ob-netdelay-500m-normal-10u-010` in the original randomized D-067 `10u-002` slot.
`ob-netdelay-500m-normal-10u-003` remains the final slot. D-123 validly observed bootstrap
success for the exact repaired preserved state, but neither D-123 nor this preparation proves
the unique cause of D-122 or authorizes live execution.

## Frozen scientific contract

- workload: `ob-default-10u-1r-v1` (10 users, spawn rate 1/s, seed 1);
- topology: 500m recommendationservice server, 100m request and 100m no-toxic proxy;
- phases: 300 seconds warm-up and 300 seconds normal baseline;
- continuity: one stable server pod/container across 15 tracked deployments, with the existing
  120-second target-stability gate;
- SLO and headroom: unchanged `p2-network-delay-001-slo-v1`, schema-v3 telemetry, null normal
  manifestation, run-level maximum nonempty product-detail 5-second window-p95 input, rollback,
  host-health and final-receipt gates;
- prohibited: toxic/fault injection, changed thresholds, post-hoc exclusions, automatic retry,
  queue execution and reuse of any consumed ID.

The current accepted count remains 10u `1/3` plus 15u `2/3` (`3/6`). Only a completely valid
sealed 011 result may fill the null replacement slot and change the 10u count to `2/3`.

## Transport and environment gates

011 inherits the D-115/D-117/D-118/D-120 USB phone-Wi-Fi contract. The PC transport must be
recorded as `usb_tether_wifi` through the exact physical USB/RNDIS path. Physical host Wi-Fi and
every non-tether physical Ethernet adapter must be Disabled or absent. The operator must freshly
declare `wifi_only_cellular_disabled`, and a nonempty background-load note is mandatory. The
2026-10-04 operator statement is provenance only; it does not replace current machine evidence,
the fresh declaration at invocation or before/after route and adapter stability checks.

## Prospective repository and runtime gates

Before artifacts, infrastructure start or application deployment:

1. use a clean checkout of the exact merged D-124 revision;
2. resolve the exact runtime state root explicitly and require the preserved profile to be
   stopped under Docker, Kubernetes v1.34.0, 4 CPU, 6144 MiB, 32 GiB and containerd;
3. keep upstream source revision `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` clean;
4. reject closed IDs 002 and 004 through 010 and require every 011 output root to be absent;
5. pass `verify-mentor-feedback-policy.ps1` and the 3+4 static identity gate: exactly three 011
   occurrences in `kustomization.yaml` and four in `observability.yaml`, with no foreign normal ID;
6. pass current USB/RNDIS route, adapter isolation, clean-boot host events, at least 15 GiB free
   space, Docker readiness and stopped-profile preflight;
7. launch only one manual run with no retry after a fresh explicit runtime approval naming the
   merged revision, exact runtime state root, source root, transport declaration and background
   load note.

An artifact-free rejection before the runner creates the 011 root leaves 011 unconsumed. Once
the artifact root or runtime lifecycle begins, every failure consumes and permanently closes 011;
the evidence must be preserved and sealed. Repository preparation, tests, PR or merge authorize
neither runtime nor fault execution.

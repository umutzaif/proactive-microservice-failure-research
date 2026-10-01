# ob-netdelay-500m-normal-10u-009 preregistration (D-118)

## Identity and authority

The user selected repository preparation on 2026-10-01 for one manual replacement
normal under USB -> phone -> Wi-Fi. 009 replaces consumed invalid/incomplete 008 at
the original D-067 10u-002 slot. Original randomization is unchanged and 10u-003
remains final. This document, its code, tests and a local commit do not authorize
runtime. Push/PR is deferred for joint delivery with the next body of work. A live
run requires a clean merged revision, exact state root, fresh operator notes and a
separate explicit runtime approval. No queue, retry or automatic replacement.

## Frozen scientific conditions

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
  Intermediate analysis never substitutes for complete closure.

## Transport and adapter isolation

Transport is usb_tether_wifi: PC -> physical USB -> phone -> phone Wi-Fi. It must
not be labeled Ethernet or host Wi-Fi. The exact active path is one physical Up USB
Remote NDIS based Internet Sharing Device with medium 0, a unique effective IPv4
default route, and stable adapter/driver identity before and after the run.

Before artifacts or infrastructure start, all host physical Wi-Fi adapters and all
host physical Ethernet adapters other than the medium-0 USB/RNDIS tether path must
be Disabled or absent. The preflight is read-only: it verifies this state but never
changes a driver or adapter. Any enabled/disconnected Wi-Fi or enabled physical
Ethernet adapter fails closed. The operator states that Ethernet and Wi-Fi drivers
were disabled; live acceptance still depends on the fresh machine-readable preflight.

Phone cellular data must be disabled. The operator supplies
PhoneUpstreamDeclaration=wifi_only_cellular_disabled and observes phone Wi-Fi through
closure. The host cannot independently prove the phone upstream; preserve the basis
as operator_declaration_not_host_verified. Any known fallback, route loss, change or
uncertainty prevents valid acceptance. No route/metric mutation or mobile fallback.

## Operational preflight and closure

Before artifacts/start require: clean checkout, mentor policy pass, enabled readable
System log covering boot, WHEA17/KernelPower41/BugCheck 0/0/0, >=15 GiB free, Docker
ready, clean pinned source 5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb, and exact
existing stopped p0-online-boutique profile. Candidate state root remains
`C:\Users\Asus-PC\.codex\worktrees\44eb\Makale\p0-env\state\minikube`; this is not
runtime authorization. No reset, delete, repair, Docker restart or Engine-loss
investigation is authorized.

008 remains immutable and excluded: its baseline/archive success and partial 118.893 ms
upper tail cannot repair failed rollback/stop. The 19-file seal remains unchanged.
An artifact-producing 009 attempt consumes 009 even if invalid; never reuse it.
Artifact-free preflight rejection does not consume the ID. Preserve every failure.

## Research boundary and verification

D-116 only removes the calendar deadline. Six valid fresh 500m normals, sealed
headroom and versioned health-path isolation remain mandatory before any fault.
D-067 stays 10u 1/3 and 15u 2/3; only a fully valid 009 could advance 10u to 2/3.
No Dataset inclusion, ladder-cell selection, fault, model, LLM or graph work occurs.

The existing runner gains only the 009 identity and the stricter host-Ethernet-disabled
preflight. Metadata retains closed IDs solely for replay. Offline tests must reject
wrong transport, phone declaration, missing background note, enabled Wi-Fi, enabled
physical Ethernet, sequence changes and final-slot changes. These tests do not prove
current host readiness or authorize live execution.

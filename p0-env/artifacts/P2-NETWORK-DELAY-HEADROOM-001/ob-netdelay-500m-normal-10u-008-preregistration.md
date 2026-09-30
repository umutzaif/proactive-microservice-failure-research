# ob-netdelay-500m-normal-10u-008 preregistration (D-117)

## Identity and authority

User-selected USB -> phone -> Wi-Fi preparation on 2026-09-30, based on canonical
`30bc019bcf0d80276c0492f21870bd50eae46b3b` (D-116 / PR #137).
008 replaces invalid 007 at the original D-067 10u-002 slot. Original randomization
and final 10u-003 slot are unchanged. One manually launched run, no queue, no retry,
no automatic replacement or mobile-data fallback. Canonical merge and separate
approval naming its revision and exact runtime state root are required.

## Frozen conditions

- Experiment P2-NETWORK-DELAY-HEADROOM-001; workload ob-default-10u-1r-v1,
  users/spawn-rate/seed 10/1/1; no-toxic proxy overlay, pre/post toxics empty.
- Recommendation server CPU limit/request 500m/100m; proxy CPU limit 100m.
- Full-selector convergence <=120 s at 5 s cadence, followed by unchanged single-pod
  UID/container/restart stability for 120 s at 5 s cadence; terminating pods count.
- Warm-up 300 s and baseline 300 s; 60 expected, >=48 nonempty 5 s product windows.
- Frozen SLO p2-network-delay-001-slo-v1: 594.664 ms and three consecutive violating
  windows; null manifestation required. No thresholds or topology changed.
- Complete raw/enriched logs and schema-v3 telemetry, metadata, verified rollback,
  stopped profile/container, host event deltas 0/0/0, stable network, final receipt
  and offline replay are required. Local analyzer success alone cannot validate a run.
- Seal supplemental evidence, including environment note, only after process exit.

## Transport and preflight

Transport is usb_tether_wifi, never labeled Ethernet or host Wi-Fi. Inherit D-115's
physical Up USB Remote NDIS based Internet Sharing Device, medium 0, unique effective
default route and stable adapter/driver identity. Unknown and virtual adapters fail.
No route filtering, metric adjustment, adapter mutation or relaxed post-stop check.
Host Wi-Fi must be Disabled/absent. Phone cellular data must be disabled; operator
supplies PhoneUpstreamDeclaration=wifi_only_cellular_disabled and a fresh BackgroundLoadNote.
Phone upstream is operator-declared, not host-verified; preserve that evidence basis.
Observe phone Wi-Fi through closure and report changes/loss/uncertainty. A known
violation prevents valid acceptance. No automatic fallback to mobile data.

Before artifacts/start require a clean checkout, policy pass, boot-covered enabled
System log with WHEA17/KernelPower41/BugCheck 0/0/0, >=15 GiB free, Docker ready,
clean pinned local source, and the exact existing stopped profile.
Profile p0-online-boutique: Docker, Kubernetes v1.34.0, 4 CPU, 6144 MiB memory,
32768 MiB disk, containerd. Candidate runtime state root:
`C:\Users\Asus-PC\.codex\worktrees\44eb\Makale\p0-env\state\minikube`.
Local source p0-env/source/microservices-demo must be clean at
`5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` with kustomize/base.
No reset, deletion, repair or Engine-loss investigation is authorized.

## Prior failure, policy and interpretation

007 is closed invalid/incomplete: post-stop default route was missing. Its original
20-file seal remains immutable. Cause and timing of route loss are unknown; this
preparation is not remediation evidence. The user selected another independent
attempt under the same transport rather than mobile data or physical Ethernet.
Failure may recur; preserve it and stop. Artifact-producing attempts consume 008;
artifact-free preflight rejection does not. Never repair or overwrite prior evidence.

D-116 removes the calendar deadline only. Six valid fresh normals, sealed quantitative
headroom and health-path isolation remain required before faults. Then preregister
exactly three delays from 25/50/100/250/500 ms and one workload with three valid
independent repeats each. After nine valid runs require manifestation and >=15 s
lead in 2/3 of at least one cell or stop with a negative conclusion. No cell is selected
here. Future 60-positive/60-control target and model/LLM/graph scope remain unchanged.
D-109 still blocks long host Wi-Fi runtime. Current D-067 counts are 10u 1/3, 15u 2/3;
valid 008 would advance 10u to 2/3 only. Transport covariates remain explicit; no
Ethernet equivalence or future KYK reliability claim. Material system effects require
a new comparison decision, not silent pooling of incompatible normals.

## Implementation and verification

Existing runner/config/sequence/metadata wiring is extended to 008. Legacy metadata
replay remains supported; 005/006/007 are rejected at invocation. D-117 appears in
the preflight and environment note. The inherited ethernet-preflight.json filename
is retained for compatibility, but its contents record the actual USB transport.
No new runtime dependency or execution stage. Test closed IDs, transport/declaration/
background-note rejection, sequence and metadata gates; render manifests offline;
replay 007's seal without changing it. Use original PowerShell 5.1 for telemetry replay.
This prospective document lives beside prior registrations for provenance; amendments
must be versioned before execution. The new invocation test lives beside the runner
and is maintained with future contract changes. No scientific result is created here.

Repository verification (2026-09-30): mentor policy passed; five D-117 invocation
cases passed on PowerShell 5.1 and 7; metadata fixtures passed four positive identities
and eight negative preflight cases; sequence/exclusion and runner checks passed.
Offline base/overlay renders bind 008. The 007 seal replays 20/20 unchanged; the 008
runtime output directory is absent. These checks do not establish live readiness.

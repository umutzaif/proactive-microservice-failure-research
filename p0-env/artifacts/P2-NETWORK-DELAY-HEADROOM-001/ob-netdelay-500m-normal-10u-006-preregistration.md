# ob-netdelay-500m-normal-10u-006 preregistration (D-113)

## Identity, scope and authority

Approved repository preparation on 2026-09-09, based on canonical
`f5e7cfa0b8ad76bc860d6b59acdece6e8c96e2db` (D-112 mentor policy, PR #133), after D-111
merge `a359ddb2f5cf51b35d54391ef8702cfe7e27fd75` (PR #132).
`ob-netdelay-500m-normal-10u-006` replaces consumed invalid `005` at the original D-067
`10u-002` slot. Original randomization is unchanged; `10u-003` remains the final slot.
This is one manually launched run, not a queue. No automatic retry, run-ID reuse, next-run
launch, cluster/application/workload startup or fault execution is authorized by this document.
Canonical merge and separate explicit runtime approval are required.

## Unchanged run contract and D-111 execution

- Experiment `P2-NETWORK-DELAY-HEADROOM-001`; `ob-default-10u-1r-v1`, users/rate/seed 10/1/1.
- No-toxic proxy overlay, pre/post `toxics=[]`; server limit/request 500m/100m, proxy limit 100m.
- D-111 full-selector convergence at most 120 seconds / 5-second cadence, then unchanged
  D-038 single-pod identity/restart stability 120/5. Terminating pods are not filtered.
- Warm-up 300 seconds; baseline 300 seconds; 60 expected / 48 minimum nonempty windows.
- Frozen SLO `p2-network-delay-001-slo-v1`, 594.664 ms / three consecutive windows;
  null manifestation, unchanged probes/resources/topology and complete validity gates.
- Raw/enriched logs, schema-v3 telemetry, metadata, rollback, stopped state, host/network,
  final receipt and offline replay must pass. Supplementary run artifacts including the
  environment note and convergence must be sealed after the runner finishes.
- Before artifacts/start: clean enabled System log covering boot with host 0/0/0,
  Ethernet unique effective route, wireless Disabled/absent, >=15 GiB, Docker ready,
  exact existing stopped profile, clean checkout and pinned checkout-local source.
- Profile `p0-online-boutique`, Docker/v1.34.0/4 CPU/6144 MiB/32768 MiB disk/containerd.
  Candidate state root remains `C:\Users\Asus-PC\.codex\worktrees\44eb\Makale\p0-env\state\minikube`;
  it must be freshly verified and explicitly named with the merged revision in runtime approval.
  No reset/delete or credential copy. D-108 explicit state-root propagation remains binding.
- Source `p0-env/source/microservices-demo` at `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`,
  clean and with `kustomize/base`; an external checkout alone cannot satisfy deploy/rollback.

## D-112 mentor-policy application

`verify-mentor-feedback-policy.ps1` must pass before material planning and execution.
The active preparation deadline is 2026-09-19, requiring six valid new 500m normals,
sealed quantitative headroom and health-path isolation proof. If missed, fault preparation
stops and an alternative execution environment goes to the mentor; no silent extension.
After these inputs, preregister exactly three levels from 25/50/100/250/500 ms and one
workload, three independent valid repeats per cell (nine valid screening runs). Continue
only if at least one selected cell has frozen manifestation and >=15 seconds lead-time
in 2/3 valid repeats; otherwise report the negative result. No delay/workload selection
is made here. This normal run supplies an input and does not establish fault feasibility.

D-109 long Wi-Fi prohibition remains. Historical 750 ms runs are exploratory, not screen
or confirmatory evidence. Confirmatory 60-positive/60-control targets are future scope;
feature engineering, model training, LLM verification and graph RCA are outside this
internship scope without a new explicit decision after the data gate.

## Mandatory environment note

The operator supplies `BackgroundLoadNote` before invocation, describing relevant known
background load (including uncertainty); no process command lines or private application
content are collected. Empty notes fail before artifacts. The runner writes
`environment-note.json` with run start/end UTC, this note, manual/no-retry launch mode,
Ethernet transport, observed node conditions and references to available pod-state evidence,
plus captured run errors and closure references. Node state is explicitly unavailable if
deployment fails before capture. Relevant additional operator-observed anomalies are recorded
in the closure report. These are covariates/audit context, never retrospective exclusion rules.
The note is finalized in `finally` and sealed after process exit, not rewritten after sealing.

## Failure, verification and interpretation

`005` remains immutable invalid/incomplete; D-111 does not prove its exact two-pod cause.
New failure observations and independent cleanup evidence are retained. Once artifacts/start
occur, a failed attempt is closed invalid/incomplete and the ID cannot be reused. There is no
automatic replacement. Artifact-free preflight failure does not create scientific evidence.

D-067 eligibility remains 10u 1/3 and 15u 2/3 until valid closure. Success would make 10u
2/3, not complete the six-normal gate or authorize screening, modeling or Dataset inclusion.
Verify policy, run-ID/workload binding, frozen sequence/invalid-ID exclusion, inherited
Ethernet preflight in runner and metadata, required background note, and offline base/overlay
render. Preserve the 005 eight-file seal. Tests exercise preparation only, never runtime.

This file is alongside prior run preregistrations to preserve chronology. It is the
prospective contract for 006, not an execution artifact. Amendments must be versioned before
execution; the operator later supplies the actual background-load note, not new criteria.

## Repository verification (2026-09-09)

Mentor policy passed at the updated canonical source. PowerShell 5.1/7 D-113 tests reject
closed 005, Wi-Fi for 006 and an empty background note; normal runner parse/no-fault checks
passed. Python fixtures passed sequence/invalid-ID and 005/006 preflight metadata positive
and negative cases. Offline base/proxy renders bind 006, 10/1/1 and 500m/100m/100m.
The consumed 005 seal still replays 8/8 files. No runtime or scientific data was produced.

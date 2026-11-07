# 013 invalid/incomplete closure

`ob-netdelay-500m-normal-10u-013` was executed exactly once on 2026-11-05 with the
user's explicit approval at merged revision
`cb93097e24889f523227421cb13bf27fa27a38d5`. The ID is consumed and must never be
reused. No scientific fault was injected, and no warm-up, baseline, telemetry archive,
manifestation analysis or headroom-input phase started.

All artifact-free D-145 gates passed. The repository was clean at the exact merged
revision; configuration contained exactly three plus four 013 identities; mentor policy,
decision inputs and the D-126 source-bound bundle passed; all 013 output roots were absent;
and the physical Online Boutique source was clean at
`5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` with no reparse point in its ancestry.
The bundle rendered base 1407 lines and overlay 1452 lines. The only effective route was
USB/RNDIS, physical host Wi-Fi and non-tether Ethernet were Disabled or absent, boot-scoped
WHEA-17, Kernel-Power-41 and BugCheck counts were 0/0/0, free space exceeded 15 GiB,
Docker was ready and the exact Minikube profile was Stopped. The operator freshly declared
`wifi_only_cellular_disabled` and reported no important known background load beyond normal
background processes.

The preserved Kubernetes v1.34.0/containerd profile started and the source-bound base apply
completed, but the bounded 15-minute all-deployment Available gate timed out for all 15
deployments. The runner classified the failure as `step_failed:deploy_base`. No pod-state
evidence was produced before the deploy step failed, so this record does not identify a unique
controller, image, network, resource or application root cause. The source-bound rollback apply
ran, but the bounded recommendationservice rollback rollout exceeded its progress deadline and
recorded `rollback_rollout_failed`.

The runner stopped Minikube with exit code 0. Failure closure recorded all profile components
Stopped, container exited/130 with OOMKilled=false, host event deltas 0/0/0 and the same stable
USB/RNDIS route. An independent read-only status check confirmed the Stopped profile with native
status exit 7. The eight original evidence files are sealed by `sha256-manifest.json`; PowerShell
7 and Windows PowerShell 5.1 replay report manifest SHA-256
`db1b3ea0df0cde85ad0b7389ab2fc34536d3b68239319cd5629f5abe972d9098`.

Dataset and headroom inclusion are false. D-067 remains 10u 1/3 and 15u 2/3 (3/6), and the
effective replacement slot returns to null pending a separate prospective decision. This closure
does not authorize a successor ID, retry, repair, reset/delete, restore, source change, fault
injection, Dataset inclusion or headroom calculation. The user's 2026-11-07 transport and
background-load statement is later operator provenance only and cannot reopen consumed 013.

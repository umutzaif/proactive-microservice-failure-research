# ob-docker-disk-recovery-001 preregistration

Gate: `P2-KUBERNETES-BOOTSTRAP-DIAG-001`; decision: D-093. This is a planned,
Dataset-excluded operational recovery diagnostic after invalid D-092. Repository merge
does not authorize profile deletion or runtime execution.

Before creating runtime artifacts or deleting anything, the runner must verify Docker
engine availability, a clean canonical Git checkout, a new output identity, and at least
15 GiB free on host drive C:. The 15 GiB threshold was selected prospectively on
2026-09-02 after the disk-full incident and before this diagnostic produced runtime data.
Insufficient capacity must fail before profile mutation and does not consume the ID.

After a separately approved runtime/delete action, the runner preserves the exact stopped
container, volume and latest Minikube start log. It may delete only profile
`p0-online-boutique`, verify exact container/volume absence, then perform one clean bootstrap
with unchanged Docker/v1.34.0/4 CPU/6144 MiB/32 GiB/containerd conditions. No application,
workload, proxy, toxic, fault or scientific window is allowed.

At least 30 samples over 180 seconds at five-second cadence must all show host, kubelet and
API server Running and kubeconfig Configured. Node, kube-system, host, semantic verifier,
stop and SHA replay gates remain mandatory. Any failed post-mutation gate closes the ID as
invalid/incomplete. Success supports clean reconstruction after disk exhaustion; it does
not prove disk exhaustion as a unique cause or authorize a replacement normal/fault run.

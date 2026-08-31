# ob-k8s-bootstrap-recovery-001 preregistration

Gate: `P2-KUBERNETES-BOOTSTRAP-DIAG-001`; decision: D-085. This is a separately
runtime-approved, no-fault recovery diagnostic after valid D-084. Repository merge does
not authorize profile deletion or runtime execution.

Before deletion, the runner preserves the exact stopped `p0-online-boutique` container,
volume and latest Minikube start-log evidence. It may delete only that exact profile and
must verify that its container and persistent volume are absent. It then performs one clean
bootstrap with the unchanged contract: Docker driver, Kubernetes `v1.34.0`, 4 CPU,
6144 MiB memory, 32 GiB disk and containerd. No application manifest, workload, proxy,
toxic, scientific fault or scientific window is permitted.

Host, kubelet, API server and kubeconfig must all remain healthy for at least 30 samples
over 180 seconds at 5-second cadence. Any unverified deletion, failed startup, unhealthy
sample, host-gate failure, semantic-verifier failure or seal/replay failure invalidates the
attempt and closes the ID. Success supports recoverability by clean reconstruction, but
does not prove how the partial state arose or that it was the unique root cause. Every
outcome is excluded from Dataset v1, D-067 headroom and incident counts, and cannot
authorize application readiness, a replacement normal run or fault injection.

# ob-k8s-bootstrap-001 preregistration

Gate: `P2-KUBERNETES-BOOTSTRAP-DIAG-001`. The user explicitly approved this isolated
no-fault Kubernetes bootstrap diagnosis after `ob-network-base-readiness-002` ended
before Kubernetes API startup. It does not authorize application deployment, a normal
replacement run, or fault injection.

The diagnostic first preserves the stopped `p0-online-boutique` container/volume
metadata and Minikube start log. It then deletes only that exact stale profile and
verifies that its container and persistent volume are absent. A clean profile is
started with the unchanged contract: Docker driver, Kubernetes `v1.34.0`, 4 CPU,
6144 MiB memory, 32 GiB disk and containerd. No Online Boutique manifest or workload
is applied. After successful startup, host, kubelet, API server and kubeconfig status
must all remain healthy for at least 30 samples over 180 seconds at 5-second cadence.

The clean-bootstrap hypothesis is falsified for this attempt if deletion cannot be
verified, startup fails, any stability sample is unhealthy, the host gate fails, or
the offline seal/replay fails. Success supports but cannot uniquely prove stale
persistent state as the cause. The output is dataset/headroom/incident-count excluded,
non-causal, and cannot authorize any later scientific operation.

# ob-k8s-bootstrap-observe-001 preregistration

Gate `P2-KUBERNETES-BOOTSTRAP-OBS-DIAG-001` addresses the live-evidence limitation left by
D-076. The preserved repository-local `p0-online-boutique` profile must exist and its exact
container must be stopped before execution. The diagnostic does not delete or clean the
profile. It starts Minikube with the unchanged Docker, Kubernetes `v1.34.0`, 4 CPU, 6144 MiB,
32 GiB and containerd contract while sampling the container and control-plane process view
every 5 seconds for at most 420 seconds.

If the container becomes live, kubelet and containerd journals plus the CRI container list
are captured before the profile is stopped. Minikube start stdout/stderr, last-start logs,
container inspection, host RecordId boundary, semantic verification and SHA-256 replay are
mandatory. Successful start, failed start with live evidence, failed start without a live
container, and bounded client timeout are descriptive diagnostic classifications, not causal
conclusions.

No Online Boutique manifest, workload, proxy/toxic, scientific window or fault is allowed.
The output is excluded from Dataset v1, D-067 headroom and incident counts. Success does not
authorize application deployment or a replacement normal run. Live evidence may narrow but
cannot by itself establish a unique Kubernetes bootstrap root cause. Runtime requires a
canonical merge and separate explicit approval.

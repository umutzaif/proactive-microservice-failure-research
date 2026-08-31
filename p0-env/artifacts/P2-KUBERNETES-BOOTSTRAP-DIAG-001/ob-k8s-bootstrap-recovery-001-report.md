# ob-k8s-bootstrap-recovery-001 report

- Decision/gate: D-085 / `P2-KUBERNETES-BOOTSTRAP-DIAG-001`
- Canonical runtime revision: `82f7fafbb7c25a8d3232a613fd84f34f82228844`
- Validity: valid operational diagnostic; `fresh_kubernetes_bootstrap_supported`
- Exact-profile delete verification: passed; container and volume absent before reconstruction
- Frozen runtime: Docker, Kubernetes v1.34.0, 4 CPU, 6144 MiB, 32 GiB, containerd
- Stability: 31/31 samples healthy over the preregistered 180/5 window
- System evidence: one Ready node; 8/8 kube-system pods Running
- Closure: profile stopped; container exited 130, OOMKilled=false; host WHEA17/KernelPower41/bugcheck 0/0/0
- Independent verification: semantic verifier passed; 12/12 SHA replay passed
- Seal manifest SHA256: `b4e6fb14d3de43f4873a1bc4410bd6b14679346a8b4d39de787bcb0b5dca31e0`
- Scope: no application manifest, workload, proxy/toxic, scientific fault or scientific window;
  excluded from Dataset v1, D-067 headroom and incident counts.
- Interpretation limit: clean reconstruction recoverability is supported. This does not establish
  how the prior partial state arose or prove stale persistent state as a unique root cause.

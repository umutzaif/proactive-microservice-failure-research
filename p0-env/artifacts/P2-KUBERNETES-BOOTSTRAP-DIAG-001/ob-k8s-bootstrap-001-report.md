# ob-k8s-bootstrap-001 valid diagnostic report

## Status

`ob-k8s-bootstrap-001` is valid completed operational diagnostic evidence. The exact
stopped `p0-online-boutique` profile was captured and deleted; its container and volume
absence checks passed. A clean cluster then started under the unchanged Docker,
Kubernetes `v1.34.0`, 4 CPU, 6144 MiB, 32 GiB and containerd contract.

## Result

All `30/30` observations over the preregistered 180-second/5-second window reported
host `Running`, kubelet `Running`, API server `Running` and kubeconfig `Configured`.
No Online Boutique manifest, workload, toxic or scientific fault was applied. The
RecordId host gate passed with WHEA-17, Kernel-Power-41 and BugCheck counts `0/0/0`.
The cluster was stopped, the semantic verifier passed, and all 12 sealed files replayed
with no SHA-256 mismatch.

## Interpretation boundary

The prior failed attempt combined a newly created profile/rootfs/SSH state with a
persistent `/var` volume and kubeadm/kubelet state dating to 2026-07-15. Clean bootstrap
success under the same resource/runtime contract supports stale mixed Minikube state
as the operational explanation. It does not uniquely prove the old volume as the sole
cause because profile, rootfs, certificates and persistent state were refreshed
together. It provides no recommendationservice readiness result and does not authorize
application deployment, a replacement normal run or fault injection. D-067 remains
15u `2/3`, 10u `1/3`.

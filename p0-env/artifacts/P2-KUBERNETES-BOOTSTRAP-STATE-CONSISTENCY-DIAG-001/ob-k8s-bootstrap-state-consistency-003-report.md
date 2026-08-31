# ob-k8s-bootstrap-state-consistency-003 evidence report

- Canonical revision: `168bff36c5987de7853f997428f9b52ac16953d8`
- Outcome: **valid completed operational diagnostic**; the ID is closed and must not be reused.
- Runtime: Minikube exit `105`, no timeout, live container observed in 79 process samples.
- First-live and final-live state: `/var/lib/kubelet/kubeadm-flags.env`,
  `/var/lib/kubelet/config.yaml`, `/var/lib/minikube/etcd`, and both kubeadm YAML files were
  present. `bootstrap-kubelet.conf`, `kubelet.conf`, `kube-apiserver.yaml`, and `etcd.yaml`
  were missing at both boundaries. The old/new kubeadm YAML hashes were identical; the new file
  was refreshed without a content change.
- Restart path: Minikube found the three existing-configuration markers, selected cluster restart,
  found no kubeadm reconfiguration requirement, and later exited `K8S_APISERVER_MISSING` because
  the API-server process never appeared. The kubelet journal contained 470 missing
  `bootstrap-kubelet.conf` failures; the independent CRI list contained no containers.
- Closure: profile and exact container are stopped; container exit is `130`, `OOMKilled=false`;
  host WHEA17/KernelPower41/bugcheck counts are `0/0/0`; semantic verification and 17/17 SHA
  replay passed with manifest SHA256
  `c58f3e49955c23a295633616393cfed7c16e5ae8bee1aef7e370bf63b90d9c93`.
- Scope: no profile delete/reset, application, workload, proxy/toxic, scientific fault, Dataset
  v1 inclusion, D-067 update, replacement normal run, or causal-root conclusion.

This proves a persistent partial-state inconsistency at both captured live boundaries and shows
that Minikube's existing-configuration restart path accepted its marker set while essential node
and control-plane files were absent. It does not prove when or why those files disappeared, that
the marker predicate is the unique root cause, or that a clean bootstrap/application would succeed.

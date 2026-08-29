# ob-k8s-bootstrap-state-consistency-001 preregistration

This operational diagnostic reuses the preserved stopped `p0-online-boutique` profile under
the unchanged Docker, Kubernetes `v1.34.0`, 4 CPU, 6144 MiB, 32 GiB, containerd and 420/5
contract. It records the Minikube existing-config markers, bootstrap and kubelet kubeconfigs,
control-plane manifests, etcd state and old/new kubeadm configuration at first-live and final-
live boundaries. It also requires a non-null Minikube subprocess exit code, exact CRI version,
real `crictl ps -a` output, journals, final stop, RecordId host gate, semantic verification and
SHA-256 replay.

The profile is not deleted or cleaned. Application manifests, workloads, proxy/toxic, faults,
scientific windows and Dataset/D-067 inclusion are forbidden. Results may distinguish an
incomplete existing-config restart path from kubeadm reconfiguration, but cannot alone prove
how the inconsistent state was originally created. Runtime requires canonical merge and a
separate explicit approval.

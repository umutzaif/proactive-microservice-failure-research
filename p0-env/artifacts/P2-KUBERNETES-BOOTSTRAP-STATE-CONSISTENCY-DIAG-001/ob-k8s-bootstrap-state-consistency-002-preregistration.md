# ob-k8s-bootstrap-state-consistency-002 preregistration

This is the unchanged-condition replacement for invalid `001`. The Docker inspect capture is
persisted before shape validation; exactly one object with nonempty `State.Status` is required,
and malformed shape is preserved before fail-closed exit. The Minikube process is forcibly
completed when necessary, waited, refreshed and disposed before stop/seal so redirected files
cannot remain locked. Non-null exit code and the remaining D-081 state/CRI/host/seal contract
are unchanged.

The profile is not deleted or cleaned. Application, workload, proxy/toxic, fault, scientific
window and Dataset/D-067 inclusion remain forbidden. Canonical merge is not runtime approval.

# ob-k8s-bootstrap-state-consistency-001 invalid diagnostic report

- Canonical revision: `934ca0713fb2d32a13aabf703fd4d211c5bd8f11`
- Result: invalid/incomplete operational diagnostic; ID retired
- Failure: the first live inspect parse did not expose the expected `State` property, so no
  first-live state snapshot or assessment was produced.
- Secondary tooling limitation: the Minikube child continued long enough to hold redirected
  stderr during the runner's first seal attempt; after process closure the preserved nine-file
  directory sealed and replayed successfully (`7/7`, manifest SHA-256
  `c851544db7c7dbcde03f30002c5dfd786c513508d1ec93552db791f2825c68ff`).
- Runtime closure: profile stopped; host WHEA17/Kernel-Power41/bugcheck `0/0/0`.
- Scope: no application, workload, proxy/toxic, scientific window or fault. Dataset v1 and
  D-067 counts remain unchanged. This artifact does not answer the state-consistency question
  and does not authorize a replacement.

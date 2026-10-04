# ob-k8s-bootstrap-state-consistency-004 preregistration

## Purpose and classification

This unique operational diagnostic tests whether the narrow, operator-approved SSH key repair
after D-122 restored congruence between the selected Minikube runtime state and the preserved
stopped `p0-online-boutique` container. It is not a normal baseline, treatment, control, network
delay ladder cell or scientific incident. It cannot change Dataset v1, D-067 headroom counts or
the accepted total of 10u 1/3 plus 15u 2/3 (3/6).

## Prospective identity and SSH provenance gate

The runner must receive both paths explicitly at invocation: the exact runtime state root selected
for Minikube and the exact timestamped `codex-key-backup-*` directory created by the repair.
Before `ShouldProcess`, artifact creation or Minikube start, the runner must set `MINIKUBE_HOME`
to the resolved runtime state root and verify all of the following:

- installed `id_rsa` and `id_rsa.pub` form a valid pair;
- backup `id_rsa` and `id_rsa.pub` form a valid pair;
- installed public-key SHA-256 is `86bf057eb0bf9488079879a62c297157bd9e0b2a835b9097dc9d61b79d7e02b1`
  and fingerprint is `SHA256:E8X6DYnpxGPJpp3lUOnbtLCow0oNNLC9HomdrrWBEOs`;
- backup public-key SHA-256 is `b894781bbd918c99bb6c0232d79bc2ff3a42c2b2c8d4afb92f411fa38125ea30`
  and fingerprint is `SHA256:XncUCIjw5vHqQfhCy9PM5nFy+4p6lwqRkZcgMxas5LQ`;
- the backup is inside the selected profile machine directory;
- the preserved container is `exited` and has exactly one non-comment authorized key;
- that authorized key equals the installed public key and does not equal the backup key.

Only hashes, fingerprints, paths and booleans may enter evidence; private or public key material
must not be written. Any missing, ambiguous or mismatched input stops artifact-free and does not
consume 004.

## Frozen operational lifecycle

After the provenance gate passes and separate live approval is supplied, 004 reuses the preserved
profile with Docker driver, Kubernetes `v1.34.0`, 4 CPU, 6144 MiB memory, 32 GiB disk, containerd,
a 420-second start bound and 5-second polling. The D-083/D-084 raw inspect, redirected-process,
state-path, CRI, host-health, stop, verifier and SHA-replay requirements remain binding.

The profile must not be deleted, reset or cleaned. Application manifests, workload, network proxy,
toxic/fault injection, scientific windows and telemetry collection are forbidden. Phone/USB
transport declarations are not inputs to this local operational diagnostic and must not be used to
interpret its result as network-performance evidence.

## Failure, validity and authority

Once artifacts are created or Minikube start begins, any failure consumes and permanently closes
004. Success can show only that this exact repaired state passed the frozen bootstrap diagnostic;
it cannot establish a unique root cause for D-122 or authorize a normal replacement. Repository
merge does not authorize runtime. Live execution requires a fresh explicit approval naming the
merged revision, exact runtime state root and exact backup directory.

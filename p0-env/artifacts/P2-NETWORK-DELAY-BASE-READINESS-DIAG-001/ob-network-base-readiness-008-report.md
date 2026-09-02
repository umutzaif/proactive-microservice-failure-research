# ob-network-base-readiness-008 invalid operational diagnostic report

## Status

`ob-network-base-readiness-008` ran at canonical revision
`089b67588a01e187cf8d59fbeca47d086dfa0edd` and closed **invalid/incomplete** at
`minikube_start`. The ID is closed and cannot be reused.

## Verified boundary

D-096 preflight passed against the resolved D-094 runtime-state and pinned-source roots.
The exact profile config, stopped container `exit 130`/`OOMKilled=false`, volume and source
revision were present. Minikube then failed existing-profile start with `IF_SSH_AUTH`:
the SSH handshake could not authenticate with the configured public key.

Base apply, 10u workload, readiness/stability observation, scientific window and fault did
not start. Final profile state was stopped; the container again exited 130 with
`OOMKilled=false`. RecordId host-health deltas were WHEA-17/Kernel-Power-41/BugCheck
`0/0/0`.

## Evidence and interpretation

The original 5-file seal and receipt are preserved as `sha256-manifest.initial.json` and
`offline-verification.initial.txt`. D-097 adds the byte-identical Minikube `lastStart.txt`
(SHA-256 `5d240dd09af57e5f1cf2c0937cde4a083ece5ad456f84323a5d6be61d03127eb`), a bounded
invalid assessment and this report before producing a new encompassing seal.

The SSH failure is a proximate start mechanism, not a proven unique root cause. This result
does not establish application readiness, enter Dataset v1 or D-067 headroom, or authorize
a replacement normal run, profile delete/reset or fault injection. D-067 remains 10u `1/3`
and 15u `2/3`.

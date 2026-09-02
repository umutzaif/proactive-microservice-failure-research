# ob-docker-disk-recovery-001 valid recovery report

## Status

`ob-docker-disk-recovery-001` completed as a **valid operational diagnostic** at canonical
revision `86cb3d923fcb34a1e514afd37890bd11363e8200`. It is excluded from Dataset v1,
D-067 headroom inputs and incident counts. The ID is closed and cannot be reused.

## Verified lifecycle

The pre-mutation host capacity gate observed 25,752,649,728 bytes free and passed the
prospective 15 GiB minimum. The runner preserved the exact stopped container, volume and
lastStart evidence, deleted only profile `p0-online-boutique`, and verified that its
container and volume were absent. It then completed the unchanged Docker/v1.34.0/4 CPU/
6144 MiB/32 GiB/containerd clean bootstrap.

All 31 observations over the frozen 180-second/5-second stability window were healthy.
One node was Ready and all eight kube-system pods were Running. Host WHEA-17,
Kernel-Power-41 and BugCheck deltas were 0/0/0. The semantic verifier passed. The final
profile was stopped; its container exited 130 with `OOMKilled=false`.

## Integrity and interpretation

The 12-file diagnostic seal replayed successfully. Manifest SHA256 is
`63a1b13187fdd5f6fd20b33f898017fd33ae680b0187f506119e176025721075`.

This supports clean Kubernetes reconstruction recoverability after the disk-exhaustion
incident. It does not prove disk exhaustion as the unique cause of the earlier API loss,
validate application/proxy readiness, complete D-067 headroom, or authorize a replacement
normal run or fault injection.

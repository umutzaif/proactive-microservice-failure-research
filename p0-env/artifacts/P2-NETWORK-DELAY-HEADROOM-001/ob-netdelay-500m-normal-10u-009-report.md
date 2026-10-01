# 009 invalid/incomplete closure

Executed once with the user's explicit approval on 2026-10-01 at merged revision
`242632a92cbcb610f4552151d9f2a166210eafe2`. The ID is consumed and must never be
reused. No scientific fault was injected and no warm-up or baseline window started.

The artifact-free D-118 preflight passed before launch: the only effective route was
the physical USB medium-0 Remote NDIS tether, host physical Wi-Fi and non-tether
physical Ethernet were Disabled, boot-scoped WHEA-17/Kernel-Power-41/BugCheck counts
were 0/0/0, free space exceeded 15 GiB, Docker was ready, the exact stopped profile
matched, and the pinned Online Boutique source was clean. The operator declared the
phone uplink Wi-Fi-only with cellular data disabled and kept existing background
applications unchanged.

Base deployment completed, but its observability configuration still identified the
closed predecessor `ob-netdelay-500m-normal-10u-008`. The 009 active-run gate therefore
failed closed with `Collector ConfigMap does not contain the expected run ID` and
`step_failed:active_run`. This is an identity/provenance failure, not a latency or
headroom observation. No root cause beyond the direct configuration mismatch is claimed.

Rollback succeeded. Failure closure stopped the profile with exit code 0 and recorded
Host/Kubelet/APIServer Stopped, container exited/137 with OOMKilled=false, host event
deltas 0/0/0, and the same stable USB/RNDIS route. The seven original evidence files
are preserved under the sibling run directory and sealed by `sha256-manifest.json`;
offline replay reports manifest SHA-256
`d07b38bbb5669c382d24b0a6f540d7c1fb11a2b331aa8bbfc737346c85c1669f`.

Dataset inclusion and headroom inclusion are false. D-067 remains 10u 1/3 and 15u
2/3 (3/6). The replacement slot returns to null pending a separate prospective
decision. This closure does not authorize a replacement ID, runtime retry, reset,
fault injection, or post-hoc validity change.

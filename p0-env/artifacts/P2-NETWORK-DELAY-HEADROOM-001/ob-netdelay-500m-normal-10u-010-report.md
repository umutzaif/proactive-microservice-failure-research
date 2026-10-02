# 010 invalid/incomplete closure

Executed once with the user's explicit approval on 2026-10-02 at merged revision
`e7ebc36c365dc03d1e98d1e5edffcb444f4ee58a`. The ID is consumed and must never be
reused. No scientific fault was injected, and no workload, warm-up or baseline window
started.

The artifact-free D-120 gates passed before launch: repository configuration contained
the exact three plus four `010` identities with no foreign network-delay normal ID;
the only effective route was the physical USB medium-0 Remote NDIS tether; host physical
Wi-Fi and non-tether physical Ethernet were Disabled/absent; boot-scoped WHEA-17,
Kernel-Power-41 and BugCheck counts were 0/0/0; free space exceeded 15 GiB; Docker was
ready; the exact profile was stopped; and the pinned Online Boutique source was clean.
The operator declared the phone uplink Wi-Fi-only with cellular data disabled and no
significant competing workload, while noting that ordinary Windows and personal
applications could remain open.

During `deploy_base`, Minikube restarted the existing Docker container but repeatedly
failed SSH authentication with `unable to authenticate, attempted methods [none
publickey]`. The configured six-minute host-start bound did not return control, and
the same verified error continued for more than eleven minutes. After confirming PID
18652 was the Minikube child started at 20:21:52, only that hung child was stopped so
the parent runner could execute its fail-closed cleanup. This is a bootstrap/SSH
infrastructure failure, not a latency, headroom or USB transport observation.

Rollback could not reach Kubernetes and recorded `rollback_apply_failed`. The runner's
failure closure nevertheless stopped the profile with exit code 0 and recorded all
components Stopped, container exited/130 with OOMKilled=false, host event deltas 0/0/0,
and the same Up USB/RNDIS identity and default route. A subsequent independent read-only
check confirmed the stopped profile and exited container.

The seven original evidence files are preserved under the sibling run directory and
sealed by `sha256-manifest.json`; offline replay reports manifest SHA-256
`0b6b226f9bbee094a4913c0c25465622ac3bc1a10885f91dab62636b64773e57`.

Dataset inclusion and headroom inclusion are false. D-067 remains 10u 1/3 and 15u
2/3 (3/6). The replacement slot returns to null pending a separate prospective
decision. This closure does not authorize a successor ID, runtime retry, profile reset
or deletion, Docker restart, SSH repair, fault injection, or post-hoc validity change.

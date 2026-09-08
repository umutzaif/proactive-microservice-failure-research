# ob-netdelay-500m-normal-10u-005 preregistration (D-110)

## Purpose and authorization

Repository preparation approved on 2026-09-08, starting at canonical
`4ac58456e242047472885bede223f78c8589b2c8` (D-109 / PR #130).
This unique Ethernet-only normal replacement occupies the original invalid `10u-002`
slot after invalid `10u-004`; neither consumed ID is reusable. `10u-003` remains last.
Branch, commit, push and PR preparation are authorized. Merge, reboot, device changes,
cluster/application/workload startup, live diagnostics and fault injection are not.

## Frozen scientific contract

- Experiment: `P2-NETWORK-DELAY-HEADROOM-001`; workload `ob-default-10u-1r-v1`, 10/1/1.
- No-toxic proxy overlay; pre/post `toxics=[]`; no scientific fault.
- recommendationservice server CPU limit/request `500m/100m`; proxy CPU limit `100m`.
- Stability 120 seconds / 5-second polling, warm-up 300 seconds, baseline 300 seconds.
- 60 expected / 48 minimum nonempty 5-second product-detail windows; null manifestation
  under unchanged `p2-network-delay-001-slo-v1` (594.664 ms, three violating windows).
- Stable pod lifecycle, host RecordId deltas `0/0/0`, schema-v3 logs/metrics/traces,
  rollback, stopped profile, metadata, final receipt and offline replay must pass.
- D-067 eligibility stays 10u `1/3`, 15u `2/3` until valid closure; success only makes
  10u `2/3`. Headroom/ladder selection remains blocked pending all required normals.
- The 25/50/100/250/500 ms ladder, 60 positive incidents plus 60 controls, probe exclusion
  and 2026-09-15 calendar stop gate remain unchanged. This no-fault preparation does
  not select a delay or claim the quantitative feasibility required before any fault.

## Prospective operational gates

Before any artifact or live mutation, the D-110 runner requires Ethernet, an explicit
absolute `RuntimeStateRoot`, exact profile `p0-online-boutique`, an existing profile config,
and native status exit 0 or 7 with Host/Kubelet/APIServer all Stopped. The resolved state
root contains `.minikube/profiles/p0-online-boutique/config.json`; its configuration must
match Docker, Kubernetes v1.34.0, 4 CPU, 6144 MiB, 32768 MiB disk and containerd. The state
root is exported as `MINIKUBE_HOME` and preserved by D-108 in deployment/close subprocesses.
The exact absolute state root and merged code revision must be named in the later runtime
approval; this preparation does not select or create a runtime profile or copy credentials.

Deploy and rollback consume THIS checkout's `p0-env/source/microservices-demo/kustomize/base`.
That source must exist, be clean and pinned to `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`.
An external source alone cannot satisfy the relative Kustomize path. The local source was
restored for offline manifest verification; it is an ignored dependency, not experiment data.

All detected physical wireless adapters must be Disabled (or absent), and Ethernet must
be the unique effective default route. Disconnected Wi-Fi is insufficient. A fresh boot
must have WHEA-17/Kernel-Power-41/BugCheck-1001 `0/0/0`; the System log must be enabled and
cover that boot. Event-query failures are rejected, not interpreted as zero events.
C: free space must be at least 15 GiB, and Docker must already be ready. No gate changes
network devices, power policy, drivers, BIOS or logs. Pre/post Ethernet adapter and driver
context must match; SSID/BSSID/MAC/IP/gateway are excluded.

Read-only planning observation on 2026-09-08: Ethernet 1 Gbps, effective metric 25,
Realtek driver `1168.8.515.2022`; Wi-Fi disconnected, not disabled; boot from 2026-09-05
contained host counts `12/0/0`; C: free 31.6 GiB. This is a planning snapshot, not sealed
run evidence or proof of Ethernet-caused WHEA. It does not satisfy the live gates.
D-109 remains binding; ASUS case 9222016's general update/format advice, as supplied in
the handoff, does not establish vendor-qualified remediation. No BIOS downgrade or format.

## Evidence and independent verification

The runtime writes `ethernet-preflight.json` under this ID's artifact directory before
deployment. Metadata binds its path/hash, and the verifier checks the D-110 preflight
and Ethernet-only contract. Existing run roots are immutable; artifact-free preflight
failure consumes no run evidence, while a started attempt is preserved and never retried
under this ID. A failed run must be recorded invalid/incomplete; no partial acceptance.

Run the decision-input positive/negative fixtures, runner contracts and new preflight
mock fixtures in PowerShell 5.1/7, plus metadata positive/negative fixtures. Render base
and proxy manifests offline to verify `10u-005`, 10/1/1, 500m/100m/100m and unchanged probes.
Tests establish tooling behavior only. Fresh live checks and separate explicit runtime
approval remain required after canonical merge.

This preregistration lives beside earlier run preregistrations to keep provenance together.
It is not an output directory or result. Amendments must be prospective and versioned;
do not edit its criteria after execution. The preflight helper is maintained with the
runner and depends on existing Windows/Git/Docker/Minikube read-only commands.

## Repository validation (2026-09-08)

- PowerShell 5.1 and 7: runner parse/no-fault/gate contract passed; mocked preflight
  positive case and 14 negative cases passed, including event access failure and profile mismatch.
- Python: metadata positive/negative cases passed, including D-110 preflight positive and
  five negative cases; decision-input fixtures reject consumed-ID reuse and final-slot changes.
- Offline `kubectl kustomize`: base and proxy overlay rendered with `10u-005`, workload
  10/1/1; overlay CPU 500m/100m/100m and direct port-8080 health probes verified.
- These are repository checks, not a clean-boot qualification or scientific run result.

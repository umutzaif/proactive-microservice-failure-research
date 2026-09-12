# ob-netdelay-500m-normal-10u-007 preregistration (D-114)

## Active prospective amendment D-115 (2026-09-10)

The user approved repository preparation and PR for PC -> USB -> phone -> Wi-Fi.
This section supersedes only the Ethernet-only transport in the D-114 text below.
The authorized Ethernet invocation stopped before artifacts/start with
`expected_active_physical_adapter_count:ethernet:0`; all six run-output roots were
absent and the checkout clean. Therefore 007 is unconsumed and may be amended before
execution. Original 006 and its seal remain closed and unchanged. Base revision is
`9098fcd37b36ea4530edbad6e9547ecd330bc9b2`; new merged-revision/runtime approval is required.

Active transport is `usb_tether_wifi`, not Ethernet or host Wi-Fi. Accept only one
Up physical adapter with USB PnP bus, medium 0 and exact description
`Remote NDIS based Internet Sharing Device`, plus the existing unique effective
default-route gate. The observed driver is 10.0.26100.1; actual before/after driver
identity must remain stable. Unknown/virtual adapters fail closed. Raw PnP identifiers
are used locally for a boolean bus check and never written to evidence.

Before invocation the operator must turn off phone cellular data and declare
`PhoneUpstreamDeclaration=wifi_only_cellular_disabled`, alongside a fresh background
load note. This is operator evidence, not a host-verified phone uplink. Monitor the
phone's Wi-Fi throughout; report loss, switching or uncertainty at closure. Such an
observed violation prevents valid acceptance; a successful runner alone does not
override operator closure review. No automatic mobile-data fallback or next run.
Mobile-data testing requires separate prospective preparation and runtime approval.

Host wireless must remain Disabled/absent, and all clean-boot, disk, pinned source,
stopped exact state-root, D-111 convergence, stability, no-toxic, workload/resource,
300/300, 60/48, SLO and complete closure gates below remain binding. No engine-loss
investigation or remediation is authorized. D-109 host Wi-Fi remains blocked.

The existing `ethernet-preflight.json` filename/metadata keys are retained for tooling
compatibility; for 007 their content must say D-115 and usb_tether_wifi, include USB bus
verification and the explicitly operator-declared uplink. They do not claim Ethernet.
Environment note and scientific metadata also carry that declaration and evidence basis.
Seal after cleanup, then review operator-observed uplink continuity before accepting
scientific validity. No SSID, BSSID, MAC, IP, gateway or raw PnP ID is collected.

A valid run supports this observed USB/phone-Wi-Fi condition only; it does not prove
Ethernet equivalence or future KYK reliability. Preserve transport differences in
headroom analysis; material performance changes require a new comparison decision,
not silent pooling or retrospective relabeling. Current D-067 counts remain unchanged.

Implementation stays in the shared host-network/preflight helper and normal runner;
inputs are adapter/route observations and the operator declaration, outputs are
privacy-limited context and existing evidence files. No new dependency or topology.
Main risks are classifying all medium-0 adapters as USB, assuming the phone uplink is
host-verified, and silently falling back to cellular. `test-d115-usb-tether.ps1` lives
beside the runner to challenge these boundaries; maintain it with future contract
changes. Existing preflight and metadata fixtures cover inherited gates and mutations.

D-115 repository verification: policy passed; USB classifier positive and six negative
fixtures plus three runner rejection cases passed on PowerShell 5.1 and 7. Existing
host-network, preflight (including USB transport propagation), closed-ID and runner
tests passed. Python metadata tests passed three positive identities and eight negative
preflight cases; sequence/exclusion tests passed. 006 seal remains 20/20 and 007 output
root remains absent. No live experiment was executed during this preparation.

## Identity and authority

Repository preparation and PR approved on 2026-09-10, based on canonical
`7627817d55218186fd7c7fe412ef1c000d96b55a` (PR #134). This new identity replaces
consumed invalid/incomplete `10u-006` at the original D-067 `10u-002` slot.
The randomized sequence is unchanged; `10u-003` remains last. One manual run,
no queue, automatic retry or ID reuse. Merge and separate explicit runtime approval
of the merged revision and exact state root are required before execution.

## Frozen contract and gates

The complete D-113 contract in `ob-netdelay-500m-normal-10u-006-preregistration.md`
is inherited prospectively for 007, including:

- `P2-NETWORK-DELAY-HEADROOM-001`, `ob-default-10u-1r-v1`, users/rate/seed 10/1/1.
- No-toxic proxy; pre/post toxics empty; server CPU limit/request 500m/100m, proxy 100m.
- Full-selector convergence at most 120 s / 5 s, then unchanged 120 s / 5 s stability.
- Warm-up/baseline 300/300 s; 60 expected, 48 minimum nonempty 5-second windows.
- Frozen SLO 594.664 ms, three consecutive violating windows; null manifestation required.
- Full raw/enriched logs, schema-v3 telemetry, metadata, verified rollback/stopped state,
  host 0/0/0, stable Ethernet, final receipt and independent offline replay.
- Before artifacts/start: mentor policy passes, clean checkout, boot-covered enabled
  System log with 0/0/0, unique Ethernet route, wireless Disabled/absent, >=15 GiB,
  Docker ready, exact existing stopped profile and clean pinned local source.
- Profile `p0-online-boutique`: Docker, Kubernetes v1.34.0, 4 CPU, 6144 MiB,
  disk 32768 MiB, containerd. Candidate state root:
  `C:\Users\Asus-PC\.codex\worktrees\44eb\Makale\p0-env\state\minikube`.
- Checkout-local source `p0-env/source/microservices-demo` at
  `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`, including `kustomize/base`.
- Fresh operator `BackgroundLoadNote` mandatory; environment note records run times,
  node/pod state, Ethernet and anomalies as covariates, never post-hoc exclusions.
  Finalize after cleanup and seal after process exit.

D-112 requires six fresh normals, sealed headroom and health-path isolation by
2026-09-19; otherwise stop fault preparation and refer an alternative environment
to the mentor. Later selection is exactly three candidate delays and one workload,
three valid independent repeats each; continue only with manifestation and >=15 s
lead in 2/3 of at least one selected cell. This registration selects no fault cell.
D-109 Wi-Fi prohibition, historical 750 ms exclusions, future 60/60 confirmatory
target and future model/LLM/graph scope remain unchanged.

## Prior failure and limits

006 failed at archive_telemetry; original rollback failed and stop returned 82.
Its 20-file seal and partial evidence remain immutable. Later stopped observations
do not repair its closure. Engine-loss cause is unknown; the user declined further
investigation. No Engine-loss investigation or recovery claim accompanies D-114.
Current Engine availability is a user declaration until future authorized preflight.
Future normal execution must pass its existing base deployment/availability gates;
no reset, deletion, remediation or relaxed gate is authorized here.

Any artifact-producing failed attempt consumes 007; preserve evidence and stop.
Artifact-free preflight rejection does not consume it. D-067 remains 10u 1/3,
15u 2/3; a valid 007 could advance only 10u to 2/3.

## Files and independent verification

This prospective file lives beside previous preregistrations for chronology; amend
only prospectively through version control. Existing runner/config/metadata and
decision-input checks bind 007 while retaining historical metadata replay. The
closed-ID guard must reject 006 even if local artifacts are absent. Tests check
closed IDs, Wi-Fi/empty-note rejection, sequence exclusions and metadata preflight.
Offline renders check run identity and frozen resources; seal replay checks bytes,
not scientific validity. No new service, dependency or execution stage is introduced.

## Repository verification (2026-09-10)

Mentor policy passed. D-114 rejection tests passed on PowerShell 5.1 and 7;
historical D-113 closure tests and runner parse/no-fault/gate checks passed.
Python sequence/exclusion fixtures and metadata preflight fixtures passed
(three positive identities, five negative preflight cases). Offline base and
resource-compatibility overlay renders bind 007; the overlay retains server
500m/100m and proxy 100m. Sealed 005 and 006 files replayed 8/8 and 20/20.
No live runtime or Engine-loss investigation was performed during preparation.

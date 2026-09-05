# ob-host-network-portability-wifi-002 preregistration

## Status

Repository-only preregistration under D-107. Live execution is not authorized.
`ob-host-network-portability-wifi-001` remains consumed and invalid/incomplete.

## Fixed contract

This replacement diagnostic preserves the D-102 contract without relaxation: two independent
1800-second active-load windows and one 600-second end-to-end closure, three distinct
loadgenerator UIDs, stable exact physical Wi-Fi adapter and driver, and RecordId-bounded
WHEA-Logger 17, Kernel-Power 41 and BugCheck 1001 counts of `0/0/0` in every window. Full
application/telemetry closure and offline receipt verification must pass. No scientific fault
is permitted.

The sole technical delta is D-106: raw-log Minikube status captures output as `[string[]]` and
stores the native exit code before text processing. Exit `0` and exact `host: Running` remain
mandatory. SSID, BSSID, MAC, IP and gateway remain forbidden evidence fields.

## Interpretation and authorization boundary

A valid result supports only Wi-Fi host portability for the exact adapter and driver. It does
not enter Dataset v1 or D-067 accounting, authorize a normal/fault run, establish access-point
or ISP quality, or alter the invalid interpretation of `001`. Canonical merge and a separate
explicit runtime approval are required before `002` may execute.

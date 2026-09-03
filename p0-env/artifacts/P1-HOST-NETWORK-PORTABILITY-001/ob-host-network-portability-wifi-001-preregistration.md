# ob-host-network-portability-wifi-001 preregistration

## Status

Repository-only preregistration under D-102. Live execution is not authorized.

## Question and fixed contract

Can the current physical Wi-Fi adapter and exact driver support the existing host-stability
contract without new WHEA-Logger 17, Kernel-Power 41 or BugCheck 1001 events? The diagnostic
uses two independent 30-minute active-load windows and one 10-minute end-to-end closure,
with no scientific fault. All three windows must complete, application/telemetry closure must
pass, and each RecordId-bounded host-event result must be `0/0/0`.

The evidence records transport, adapter name/description, interface index and driver version.
SSID, BSSID, MAC address, IP address and gateway are forbidden. Dorm Wi-Fi and phone hotspot
belong to the same qualified transport only when they use the same physical adapter and driver;
scientific traffic remains local to Minikube. An adapter or driver change requires a new
qualification decision and identity.

## Interpretation boundary

A valid result supports Wi-Fi host portability only. It does not prove universal network
availability, validate an access point or ISP, enter Dataset v1/D-067 accounting, authorize a
normal/fault run, or establish causality for historical failures. The diagnostic ID is not live
until canonical merge and a separate explicit runtime approval.

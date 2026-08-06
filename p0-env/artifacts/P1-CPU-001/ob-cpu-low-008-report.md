# ob-cpu-low-008 Invalid Run Report

- Status: `invalid/incomplete`
- Scientific dataset inclusion: `false`
- Fault worker executed: `true`
- Warm-up start UTC: `2026-08-06T12:26:24.6728843Z`
- Normal baseline start UTC: `2026-08-06T12:31:24.6785082Z`
- Worker start UTC: `2026-08-06T12:36:33.996176Z`
- Worker completion UTC: `2026-08-06T12:43:33.968847Z`
- Worker monotonic duration: `420.000141584` seconds
- Heartbeats: `84`
- Pod UID/restarts: stable (`0 -> 0`)
- Post-cleanup host totals: WHEA Event 17 `881`; Kernel-Power 41 `5`; bugcheck `1` (delta `0/0/0`).

The v4 canonical worker hash passed and the bounded worker completed. The
injector nevertheless rejected lifecycle verification because Windows
PowerShell 5.1 cannot bind `@($events)` over a
`System.Collections.Generic.List[object]` to the resolver's `object[]`
parameter (`Argument types do not match`). The same events pass when explicitly
converted with `.ToArray()`.

The orchestrator stopped Minikube and preserved execution/error evidence. No
cooldown, telemetry archive, physical-effect decision, scientific metadata or
final receipt completed. The run is therefore invalid regardless of the
observed worker duration and will not be reused or retroactively finalized.

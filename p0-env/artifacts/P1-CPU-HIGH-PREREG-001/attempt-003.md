# ob-cpu-high-003 Attempt Binding

`ob-cpu-high-003` is the second independent repeat of valid
`ob-cpu-high-001`. It uses the same `cpu-recommendation-high-v1`, workload
`ob-default-10u-1r-v1`, seed `1`, frozen SLO `p1-cpu-001-slo-v1`, target,
coverage, D-026 series selection and lifecycle as `ob-cpu-high-001` and
`ob-cpu-high-002`.

Acceptance remains fail closed: at least 75 mCPU steady-minus-baseline CPU
increase; at least 48 real Prometheus intervals in each measured phase; stable
15-deployment pod lifecycle; zero new WHEA Event 17, Kernel-Power 41 and
bugcheck events; complete immutable log, metric and schema-v3 trace archives;
and passing close-run plus independent offline receipt verification. Null
manifestation remains scientifically admissible.

The run requires its own canonical revision, empty artifacts, active run-ID
and host preflight. Invalid evidence is preserved and the run ID is never
reused. Three valid high candidates may support a descriptive repeatability
summary but do not authorize SLO changes, another workload/service or models.

# P1-CPU Low-Severity Repeatability Summary

This descriptive summary uses the three valid low-severity candidates only:
`ob-cpu-low-004`, `ob-cpu-low-005` and `ob-cpu-low-009`. Invalid attempts are
preserved in the registry but excluded from the numerical repeatability summary.

| Run | Baseline mCPU | Steady mCPU | Increase mCPU | Coverage baseline/steady | Manifestation |
|---|---:|---:|---:|---:|---|
| ob-cpu-low-004 | 9.551 | 58.014 | 48.463 | 59/60 | null |
| ob-cpu-low-005 | 11.300 | 63.351 | 52.050 | 59/60 | null |
| ob-cpu-low-009 | 13.138 | 63.672 | 50.534 | 59/59 | null |

The CPU increase mean is `50.349m`, sample standard deviation is `1.801m`,
coefficient of variation is `3.576%`, and range is `48.463m` to `52.050m`.
All three runs passed physical-effect, telemetry, pod, host, receipt and offline
verification gates. All three produced null SLO manifestation.

This establishes repeatable physical actuation for this low profile under the
current workload. It does not establish pre-failure predictability, does not
prove that the frozen SLO is universally insensitive, and does not authorize a
new severity or workload without a separate preregistered decision.

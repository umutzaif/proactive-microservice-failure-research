# P2-NETWORK-DELAY-PROBE-RESOURCE-DIAG-001 ön-kaydı

- Diagnostic ID `ob-network-probe-resource-001`; benzersizdir ve tekrar kullanılmaz.
- Scientific toxic/fault yoktur; 15-user mevcut workload ve no-toxic proxy overlay
  bağlamı 180 saniye / 5 saniye cadence ile gözlenir.
- Aynı UTC penceresinde server için cAdvisor CPU usage, CFS periods/throttled
  periods/throttled seconds, memory working set/RSS/usage/failcnt, OOM events ve
  CPU/memory pressure counter serileri Prometheus'tan immutable arşivlenir.
- Pod/container state, Kubernetes events, current/previous logs, node conditions,
  rollback ve host `0/0/0` kanıtları önceki diagnostic sözleşmesiyle korunur.
- OOM ancak status/counter kanıtıyla desteklenir. CPU/throttling ile probe failure
  birlikteliği nedensellik olarak sunulmaz; coverage ve restart zamanları raporlanır.
- Probe timeout/period/failureThreshold, CPU/memory request/limit ve scientific
  eşikler değiştirilmez. Replacement aynı committe belirlenmez.
- Diagnostic Dataset v1/modeling dışıdır; model, LLM ve GAT çalıştırılmaz.

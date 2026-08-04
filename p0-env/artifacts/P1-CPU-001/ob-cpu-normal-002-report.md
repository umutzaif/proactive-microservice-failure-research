# ob-cpu-normal-002 bilimsel run raporu

## Sonuç

- Deney: `P1-CPU-001`
- Run türü: normal baseline
- Durum: `completed`; bilimsel normal baseline adayı
- Fault injection: yapılmadı
- Workload profile: `ob-default-10u-1r-v1`
- Random seed: `1`
- Code revision: `7872498366444c927e3eb8ff377b74e42e50d5e3`

## Lifecycle ve host

- Reset/health check: `2026-08-02T12:22:27.2897167Z`
- Warm-up: `2026-08-02T12:22:27.2897167Z`–`2026-08-02T12:27:27.5343965Z` (`300.2446798` saniye)
- Normal baseline: `2026-08-02T12:27:27.5343965Z`–`2026-08-02T12:32:28.3459375Z` (`300.811541` saniye)
- NTP sapma örnekleri: `+0.0246446`, `+0.0257241`, `+0.0257958` saniye.
- Run öncesi, pencere sonrası ve kontrollü shutdown sonrası WHEA Event 17, Kernel-Power 41 ve bugcheck: `0`.
- Loadgenerator, collector ve Prometheus pod UID/restart değerleri bilimsel lifecycle içinde değişmedi.

## Aktif run-ID kapısı

- Lifecycle öncesinde ConfigMap, pod rollout, Prometheus runtime config ve gerçek metric query kapıları geçti; `4.963` run-scoped series görüldü.
- Baseline sonunda kapı yeniden geçti; `4.085` run-scoped series görüldü.

## Immutable veri ve doğrulama

- Ham log dosyası: 15; timestamp sınır hatası 0.
- Enriched log: 19.599; missing timestamp, JSON, run-ID ve sequence hatası 0.
- Metric series: 4.975.
- Metric sample: 532.256; run-ID ve zaman hatası 0.
- Telemetry schema: v3.
- Trace chunk: 21; coverage hatası 0.
- Raw unique trace: 3.008.
- Selected unique trace: 3.004.
- Selected span: 31.439.
- Boundary-crossing olarak dışlanan trace: 4.
- Final receipt ve offline finalized-run verifier geçti; failure count 0.
- Metadata ve workload profili checksum ile receipt içine mühürlendi.

## Korunan teknik hata

İlk finalization denemesi, 7 basamaklı lifecycle UTC değerlerinin finalizer tarafından 3 basamağa kısaltılarak metadata verifier'a aktarılması nedeniyle `metadata_start_utc_mismatch` ve `metadata_end_utc_mismatch` ile reddedildi. Hata receipt'i `p0-env/artifacts/finalized/_invalid/ob-cpu-normal-002-close-failed-20260802T123834014Z/` altında korundu. Immutable raw, enriched ve telemetry arşivleri değiştirilmeden finalizer özgün UTC değerlerini kullanacak biçimde düzeltildi; final receipt ve offline doğrulama daha sonra geçti.

## Artefact yolları

- Raw: `p0-env/artifacts/runs/ob-cpu-normal-002/`
- Enriched: `p0-env/artifacts/derived/ob-cpu-normal-002/`
- Telemetry: `p0-env/artifacts/telemetry/ob-cpu-normal-002/`
- Final receipt: `p0-env/artifacts/finalized/ob-cpu-normal-002/`
- Bilimsel metadata: `p0-env/artifacts/scientific-run-metadata/ob-cpu-normal-002/scientific-run-metadata.json`

Bu run fault injection'a otomatik geçiş izni vermez.

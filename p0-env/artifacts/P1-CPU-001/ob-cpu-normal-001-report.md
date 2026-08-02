# ob-cpu-normal-001 bilimsel run raporu

## Sonuç

- Deney: `P1-CPU-001`
- Run türü: ilk normal baseline
- Durum: `invalid`
- Fault injection: yapılmadı
- Dataset kullanımı: hayır
- Ana dışlama gerekçesi: Prometheus yanıtında `ob-cpu-normal-001` ile etiketlenmiş metric sample bulunmadı.

## Lifecycle

- Reset/health check: `2026-08-02T10:42:04.2429664Z`
- Warm-up: `2026-08-02T10:42:04.2448008Z`–`2026-08-02T10:47:04.4791763Z` (`300.2343755` saniye)
- Normal baseline: `2026-08-02T10:47:04.4791763Z`–`2026-08-02T10:52:05.2619431Z` (`300.7827668` saniye)
- Workload profile: `ob-default-10u-1r-v1`
- Random seed: `1`; Python `random` ve Faker çalışma zamanında seed edildi.
- Code revision: `9ecb59fcba6019223599c1b80eb5334331baeb5b`
- Loadgenerator restart: `1 -> 1`; bilimsel lifecycle içinde değişmedi.

## Geçen kapılar

- Harici NTP sapması: `+0.0129380`–`+0.0131992` saniye.
- Warm-up ve normal baseline minimum 300 saniye koşulu geçti.
- Run öncesi/sonrası WHEA Event 17: `0 -> 0`.
- Run öncesi/sonrası Kernel-Power 41: `0 -> 0`.
- Run öncesi/sonrası bugcheck: `0 -> 0`.
- Ham log: 15 dosya; zaman sınırı hatası 0; SHA-256/read-only doğrulaması geçti.
- Enriched log: 20.136 kayıt; timestamp, run ID ve sequence hatası 0.

## Geçmeyen kapılar ve korunan kanıt

- `archive_metrics_and_traces`, `Prometheus response does not contain run-scoped metric samples` gerekçesiyle reddedildi.
- Partial telemetry: `p0-env/artifacts/telemetry/_invalid/ob-cpu-normal-001-telemetry-capture-failed-20260802T105541842Z/`
- Kubeconfig endpoint uyuşmazlığı nedeniyle iki erken close-run reddi ve metric kapısındaki son ret, `p0-env/artifacts/finalized/_invalid/` altında üç ayrı receipt olarak korundu.
- Ham arşiv: `p0-env/artifacts/runs/ob-cpu-normal-001/`
- Enriched arşiv: `p0-env/artifacts/derived/ob-cpu-normal-001/`
- Nihai invalid metadata: `p0-env/artifacts/scientific-run-metadata/ob-cpu-normal-001/scientific-run-metadata.json`

## Teknik değerlendirme

ConfigMap yeni run ID ile güncellendiği halde Prometheus deployment'ı yeniden başlamadı. Prometheus process'inin eski scrape yapılandırmasını bellekte tutması kuvvetli teknik hipotezdir; bu raporda doğrulanmış kök neden olarak ilan edilmez. Yeni normal baseline girişiminden önce Prometheus ve collector'ın etkin run ID değerleri deployment sonrası API üzerinden bağımsız doğrulanmalıdır.

Bu run silinmez, başarılı sayılmaz ve fault injection için geçiş izni oluşturmaz.

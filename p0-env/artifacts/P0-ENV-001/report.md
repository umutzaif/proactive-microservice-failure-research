# P0-ENV-001 sonuç raporu

- Tarih: 2026-07-15
- Durum: completed (run_id propagation açık bulgu)
- Sistem: Online Boutique v0.10.6
- Kaynak commit: `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`
- Platform: Windows 11 Home Single Language 25H2, Docker Desktop, minikube
- Kubernetes: v1.34.0, tek node, containerd 2.2.1
- Kaynak: `p0-env/source/microservices-demo`
- Yapılandırma: `p0-env/config`
- Tekrar üretim: `p0-env/scripts`

## Sonuç

Online Boutique ve yerel observability stack kuruldu. 15/15 deployment `Available` oldu. Normal kullanıcı smoke akışında ana sayfa, ürün sayfası, sepete ekleme, sepet görüntüleme ve checkout adımlarının tamamı HTTP 200 döndürdü; sepet ürünü ve sipariş confirmation içeriği doğrulandı.

Log, metric ve distributed trace toplama kanalları çalıştı:

- Logs: Kubernetes container log API üzerinden frontend'in UTC timestamp, severity, request ID, path, status ve süre içeren JSON kayıtları alındı.
- Metrics: Prometheus `kubernetes-cadvisor` target'ı `up` oldu. `sum(rate(container_cpu_usage_seconds_total{namespace="online-boutique",container!=""}[1m]))` sorgusu `0.1194279549487128` döndürdü.
- Traces: OpenTelemetry Collector debug exporter çok sayıda span batch'i kaydetti. Jaeger servis API'sinde `paymentservice`, `currencyservice` ve checkout süreçleri görüldü; `paymentservice` için 5 trace döndü. Örnek trace ID: `c25bd0e8f65c3ca007a10f6b6133136d`.

## Smoke test çıktısı

```text
GET / = 200 bytes=10499
GET /product = 200 bytes=7974
POST /cart = 200 bytes=16459
GET /cart = 200 has_cart_item=True
POST /cart/checkout = 200 bytes=6796 confirmation=True
```

## Gözlemlenebilirlik bileşenleri

| Bileşen | Sürüm/image | İşlev |
|---|---|---|
| Kubernetes/cAdvisor | Kubernetes v1.34.0 | Container CPU/memory/request kaynak metrikleri |
| Prometheus | `prom/prometheus:v3.7.3` | 5 saniyelik scrape ve metrik sorgusu |
| OpenTelemetry Collector Contrib | `otel/opentelemetry-collector-contrib:0.155.0` | OTLP gRPC/HTTP trace alımı ve batch export |
| Jaeger all-in-one | `jaegertracing/all-in-one:1.76.0` | Trace saklama ve sorgulama |
| Kubernetes container logs | Kubernetes v1.34.0 | Uygulama stdout/stderr log erişimi |

## Denenen seçenekler ve sorunlar

1. GKE: Resmi quickstart ve managed ortam açısından uygulanabilir; bulut hesabı/maliyet gerektirdiği için yerel P0'da seçilmedi.
2. Docker Desktop Kubernetes / kind: Yerel alternatifler; kurulu değildi. Minikube, profil/state izolasyonu ve açık kaynak gereksinimleri nedeniyle seçildi.
3. İlk Chocolatey çalıştırması: Yönetici belirteci olmadığı için `C:\ProgramData\chocolatey` erişiminde durdu; 0 paket kuruldu. UAC ile yükseltilmiş süreçte tekrarlandı ve tamamlandı.
4. İlk minikube oluşturma: Yürütme oturumu kesildi ve yarım profile ait bozuk API sertifikası `GUEST_CERT` hatası verdi. Yalnızca üretilen profil silindi; cache korunarak aynı sabit ayarlarla tekrarlandı.
5. İlk observability rollout: Collector 0.155.0 eski `service.telemetry.metrics.address` anahtarını reddetti; kaldırıldı. Node servislerinde profiler env kaybı native `pprof` modül hatası oluşturdu; `DISABLE_PROFILER=1` deterministik yamayla geri kondu.
6. Windows host doğrudan minikube NodePort IP'sine erişemedi; smoke test `kubectl port-forward` ile localhost üzerinden yapıldı.

## Açık bulgular

- `run_id`: deployment env, log örnekleri ve trace/metric kaynaklarında deney run ID'si yok. P1 öncesi üç modaliteye ortak run metadata propagation eklenmeden deney verisi toplanmamalıdır.
- Trace service naming: Bazı runtime'lar Jaeger'de `unknown_service:*` adı üretiyor. P1 öncesi her instrumented deployment için açık `OTEL_SERVICE_NAME` yamaları eklenmeli ve topoloji kimlikleri doğrulanmalıdır.
- Log saklama: P0'da Kubernetes container log API doğrulandı; immutable/checksum'lı ham log arşivi P1 run pipeline'ında ayrıca kurulmalıdır.
- Trace sampling: Uygulama varsayılanı kullanıldı. Deney protokolü gereği P1 öncesi sampling oranı açıkça sabitlenmeli ve kaydedilmelidir.

## Karar

O-001 için yerel Online Boutique sürdürülebilir kurulum ve normal akış kanıtlandı. P0 ortam/telemetri smoke testi tamamlandı. Ancak deneysel run toplamaya geçiş, `run_id`, service naming, immutable log arşivi ve sabit trace sampling eksikleri giderilene kadar uygun değildir. Fault injection, model eğitimi, LLM doğrulaması veya GAT uygulanmadı.


# Dosya Bazlı Kod Haritası

## Hâkimiyet seviyeleri

| Seviye | Beklenti |
|---|---|
| A | Deneyden önce satır düzeyinde anlayın |
| B | Girdi, çıktı, garanti ve sınırlarını bilin |
| C | Gerektiğinde referans olarak okuyun |

## Akademik sözleşmeler

| Dosya | Seviye | Rol |
|---|---:|---|
| `research_decisions.md` | A | Split, horizon, hata sınıfı ve metrik kararları |
| `experiment_protocol.md` | A | Run, zaman, telemetry, fault ve SLO kuralları |
| `dataset_card.md` | A | Şema, lineage, kalite, leakage ve privacy |
| `pilot_experiment_plan.md` | A | P0/P1 sırası ve karar kapısı |
| `results_registry.md` | A | Başarılı/başarısız çalışma kaydı |
| `literatur_degerlendirmesi.md` | B | Literatür gerekçesi |

Kod çalışsa bile bu sözleşmelere aykırıysa bilimsel olarak geçersizdir.

## Ortam betikleri

| Dosya | Seviye | Ne yapar? |
|---|---:|---|
| `env.ps1` | B | PATH, MINIKUBE_HOME ve KUBECONFIG ayarlar |
| `fetch-online-boutique.ps1` | B | Upstream kaynağı sabit commit ile getirir |
| `deploy.ps1` | A | Minikube başlatır, Kustomize uygular, Collector/Prometheus'u yeniden başlatır ve readiness bekler |
| `cleanup.ps1` | B | Yerel ortam yaşam döngüsü yardımcısı |

`Available` deployment sonucu, kullanıcı akışı ve export başarısını tek başına
kanıtlamaz.

## Veri hattı betikleri

| Dosya | Seviye | Ana garanti |
|---|---:|---|
| `set-experiment-run-id.ps1` | A | Geri alınabilir 3+2 run ID değişimi |
| `archive-raw-logs.ps1` | A | Zaman sınırlı ham log ve SHA manifest |
| `verify-raw-log-archive.ps1` | A | Hash, dosya seti ve zaman doğrulaması |
| `enrich-log-run-id.ps1` | A | Provenance taşıyan `log-envelope-v1` |
| `verify-enriched-logs.ps1` | A | JSON, run ID, sıra ve bütünlük |
| `archive-run-telemetry.ps1` | A | Prometheus ve zaman parçalı Jaeger export |
| `verify-run-telemetry.ps1` | A | Run ID, zaman, parça kapsamı ve trace bütünlüğü |
| `test-trace-export-chunking.ps1` | B | Schema v3 sentetik pozitif/negatif testleri |
| `finalize-run-artifacts.ps1` | A | Üç arşivi bağlayan receipt |
| `verify-finalized-run.ps1` | A | Offline receipt doğrulaması |
| `close-run.ps1` | A | Sekiz adımlı fail-fast kapanış |

## Kubernetes yapılandırması

| Dosya | Seviye | Rol |
|---|---:|---|
| `versions.yaml` | A | Sabit sürümler ve sampling kaydı |
| `kustomization.yaml` | A | Upstream base, patch'ler, run ID, OTel env |
| `observability.yaml` | A | Collector, Jaeger, Prometheus ve RBAC |
| `namespace.yaml` | C | `online-boutique` namespace |

`versions.yaml` belge kaydıdır; gerçek çalışan image ve manifest ayrıca
doğrulanmalıdır.

## Raporlar ve yerel veri

| Yol | Seviye | Rol |
|---|---:|---|
| `artifacts/P0-ENV-001/` | B | Ortam ve smoke kanıtı |
| `artifacts/P1-LOG-ARCHIVE-001/` | B | Ham log aracı kabulü |
| `artifacts/P1-ARCHIVE-UTC-001/` | B | UTC hata/düzeltme kanıtı |
| `artifacts/P1-LOG-ENRICH-001/` | B | Enrichment kabulü |
| `artifacts/P1-NORMAL-E2E-001/` | A | Invalid E2E ve host çökmesi |
| `artifacts/P1-TELEMETRY-EXPORT-001/` | A | Export/close-run doğrulaması |
| `artifacts/P1-HOST-STABILITY-002/` | A | Temiz boot host kapısı kanıtı |
| `artifacts/P1-TRACE-CHUNK-TOOL-001/` | A | Schema v3 parça export araç doğrulaması |
| `artifacts/runs/` | A | Git dışı ham loglar |
| `artifacts/derived/` | A | Git dışı enriched loglar |
| `artifacts/telemetry/` | A | Git dışı metric/trace |
| `artifacts/finalized/` | A | Git dışı receipt |

## Upstream kod ekosistemi

`p0-env/source/microservices-demo` sabitlenmiş upstream kaynak ağacıdır:

| Dil/teknoloji | Örnek servis | Bilmeniz gereken |
|---|---|---|
| Go | frontend, checkout, catalog, shipping | HTTP/gRPC, middleware logları, OTel |
| Python | email, recommendation, loadgenerator | gRPC, log biçimi, Locust |
| Java | adservice | JVM logları ve gRPC |
| C#/.NET | cartservice | ASP.NET logları, Redis bağımlılığı |
| Node.js | currency, payment | JSON logları ve OTel service name |
| Redis | redis-cart | Sepet state'i |

Upstream'in her satırını ezberlemek gerekmez. Hedef servisin istek yolu,
bağımlılıkları, log semantiği ve span üretimi fault deneyi öncesinde
okunmalıdır.

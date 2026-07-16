# Proactive Microservice Failure Research

Bu repository, Online Boutique üzerinde leakage-free erken hata tahmini, kanıta bağlı LLM doğrulaması ve root-cause service sıralaması araştırmasının karar, protokol ve tekrarlanabilir altyapı dosyalarını içerir.

## Bağlayıcı araştırma belgeleri

- `research_decisions.md`: kabul edilmiş akademik kararların tek kaynağı
- `experiment_protocol.md`: run, zaman, telemetry, leakage ve raporlama kuralları
- `dataset_card.md`: dataset kapsamı, sınıflar ve kalite gereksinimleri
- `pilot_experiment_plan.md`: pilot aşamaları ve karar kapıları
- `results_registry.md`: başarılı ve başarısız bütün çalışma ailelerinin kaydı
- `literatur_degerlendirmesi.md`: literatür konumlandırması ve kapsam gerekçesi

Bu belgelerdeki veri bölme birimi, `failure_manifestation` tanımı, prediction horizon, hata sınıfları, metrikler ve leakage kuralları uygulama kodu tarafından sessizce değiştirilemez.

## Mevcut operasyonel durum

`P0-ENV-001` tamamlandı:

- Online Boutique `v0.10.6` sabitlendi.
- Docker Desktop + minikube üzerinde Kubernetes ortamı kuruldu.
- Normal kullanıcı akışı smoke testten geçti.
- Kubernetes logları, Prometheus/cAdvisor metrikleri ve OpenTelemetry/Jaeger trace akışı doğrulandı.

P1 veri toplamadan önce çözülmesi gereken açık konular:

- `run_id` değerinin logs, metrics ve traces içine taşınması,
- bütün trace servis adlarının açıkça sabitlenmesi,
- trace sampling oranının sabitlenmesi,
- immutable ve checksum'lı ham log arşivi.

Ayrıntılar: `p0-env/artifacts/P0-ENV-001/report.md`.

## Online Boutique kaynağını hazırlama

Upstream kaynak kodu bu repository'de yeniden yayımlanmaz. Sabit sürümü indirmek için:

```powershell
powershell -ExecutionPolicy Bypass -File .\p0-env\scripts\fetch-online-boutique.ps1
```

Ardından ortam kurulumu:

```powershell
powershell -ExecutionPolicy Bypass -File .\p0-env\scripts\deploy.ps1
```

Sabit sürümler `p0-env/config/versions.yaml` dosyasındadır.

## Kapsam dışı yerel içerik

`papers/`, `p0-env/state/`, `p0-env/source/` ve `tmp/` Git tarafından izlenmez. Makale PDF'leri araştırmacının yerel arşivinde tutulur.


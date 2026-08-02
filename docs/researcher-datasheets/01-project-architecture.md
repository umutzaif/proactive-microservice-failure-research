# Datasheet 01 — Proje Mimarisi

## 1. Sistem neyi araştırıyor?

Araştırmanın savunulabilir çekirdeği üç aşamalıdır:

1. Hata gerçekleşmeden önceki telemetri pencerelerinden temporal bir hata
   adayı üretmek.
2. Bu adayı zaman damgalı kanıtlarla LLM'e doğrulatmak.
3. Kök neden servisini graph tabanlı yöntemlerle sıralamak.

Repository'nin mevcut kodu yalnızca bu çalışmanın güvenilir veri üretebilmesi
için gereken operasyon katmanını uygular.

## 2. Katmanlar

```mermaid
flowchart TB
    subgraph Research["Akademik sözleşme"]
        RD["research_decisions.md"]
        EP["experiment_protocol.md"]
        DC["dataset_card.md"]
        PP["pilot_experiment_plan.md"]
        RR["results_registry.md"]
    end

    subgraph Platform["Çalıştırma platformu"]
        DD["Docker Desktop"]
        MK["Minikube"]
        K8S["Kubernetes v1.34.0"]
        OB["Online Boutique v0.10.6"]
        DD --> MK --> K8S --> OB
    end

    subgraph Observe["Observability"]
        LOG["kubectl logs"]
        PROM["Prometheus / cAdvisor"]
        OTEL["OpenTelemetry Collector"]
        JAEGER["Jaeger"]
        OB --> LOG
        OB --> OTEL --> JAEGER
        K8S --> PROM
    end

    subgraph Evidence["Kanıt ve arşiv"]
        RAW["raw logs"]
        DERIVED["enriched NDJSON"]
        METRIC["Prometheus query_range JSON"]
        TRACE_RAW["Jaeger raw API JSON"]
        TRACE_SELECTED["selected complete traces"]
        RECEIPT["finalization receipt"]
        LOG --> RAW --> DERIVED
        PROM --> METRIC
        JAEGER --> TRACE_RAW --> TRACE_SELECTED
        RAW --> RECEIPT
        DERIVED --> RECEIPT
        METRIC --> RECEIPT
        TRACE_SELECTED --> RECEIPT
    end

    Research -. "kuralları belirler" .-> Platform
    Research -. "geçerlilik kuralları" .-> Evidence
```

## 3. Kontrol düzlemi ve veri düzlemi

### Kontrol düzlemi

Deneyi nasıl çalıştıracağımızı belirleyen dosyalardır:

- `p0-env/config/versions.yaml`
- `p0-env/config/online-boutique/*.yaml`
- `p0-env/scripts/*.ps1`
- run metadata ve profile dosyaları

### Veri düzlemi

Çalışan sistemden elde edilen kanıttır:

- Kubernetes log satırları
- Prometheus zaman serileri
- Jaeger trace/span kayıtları
- parsed/enriched loglar
- manifestler ve receipt'ler

Kontrol düzlemindeki bir değişiklik `deployment_revision` veya Git revision ile
izlenmeden veri düzlemine karıştırılamaz.

## 4. Güven sınırları

```mermaid
flowchart LR
    subgraph Mutable["Değişebilir çalışma alanı"]
        CONFIG["YAML config"]
        SCRIPT["PowerShell scripts"]
        CLUSTER["Running cluster memory/disk"]
    end

    subgraph Sealed["Proje seviyesinde mühürlü"]
        ARCHIVE["SHA-256 manifestli arşiv"]
        READONLY["Windows read-only files"]
        RECEIPT["Final receipt"]
    end

    subgraph Versioned["Git ile sürümlenen"]
        CODE["Scripts + configs"]
        REPORT["Küçük raporlar"]
        REGISTRY["results_registry.md"]
    end

    CONFIG --> CLUSTER
    SCRIPT --> CLUSTER
    CLUSTER --> ARCHIVE --> READONLY --> RECEIPT
    CONFIG --> CODE
    SCRIPT --> CODE
    RECEIPT -. "özet/hash" .-> REPORT --> REGISTRY
```

Windows read-only + SHA-256, proje seviyesinde değişmezlik sağlar; gerçek
donanım veya cloud WORM object lock değildir. Bu sınır raporlarda açıkça
belirtilir.

## 5. Neden Prometheus ve Jaeger içinde bırakmak yeterli değil?

Prometheus ve Jaeger deployment'larında kalıcı volume yoktur. Pod, cluster
veya host yeniden başlarsa veri kaybolabilir. Ayrıca aynı `run_id` ile
loadgenerator yeniden trafik üretirse eski run kontamine olur.

Bu nedenle run kapanırken:

- API yanıtları cluster dışına alınır,
- tam UTC sınırı kaydedilir,
- checksum manifesti üretilir,
- bağımsız verifier çalışır,
- bilimsel run ise sürümlü workload profili ile lifecycle/host-health metadata'sı doğrulanır,
- doğrulanmış metadata ve workload profili receipt dizinine checksum ile mühürlenir,
- sonra final receipt üretilir.

Normal workload'un tekrarlanabilirlik zinciri şöyledir:

`versioned JSON profile -> Kubernetes env -> Python random + Faker seed -> Locust -> scientific metadata verifier -> final receipt`

Sabit seed, kullanıcı davranışı için kullanılan sözde-rastgele üreticileri kontrol eder;
eşzamanlı isteklerin ağ ve scheduler kaynaklı tamamlanma sırasını deterministik yapmaz.
Bu nedenle profil ayrıca çalışan image, Locust/Faker sürümleri ve workload kodu
SHA-256 değerini sabitler.

## 6. Mimarinin şu anda uygulamadığı parçalar

Şu bileşenler tasarım belgelerinde vardır fakat kodlanmamıştır:

- CPU fault injector,
- run phase state machine,
- failure manifestation/SLO detector,
- 5 saniyelik feature window üretimi,
- grouped train/validation/test split,
- rule/logistic/XGBoost/GRU modelleri,
- LLM verifier,
- graph RCA ve GAT.

Bu ayrım önemlidir: observability pipeline'ın çalışması, araştırma hipotezinin
kanıtlandığı anlamına gelmez.

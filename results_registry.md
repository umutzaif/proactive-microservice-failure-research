# Deney Sonuçları Kaydı

Bu belge bütün deneylerin, başarısız olanlar dahil, değişmez özet kaydıdır. Her satır bir çalıştırma ailesini temsil eder; ayrıntılı artefact yolu verilmelidir.

## Durumlar

- `planned`
- `running`
- `completed`
- `invalid`
- `superseded`

## Deney kayıt tablosu

| Experiment ID | Tarih | Durum | Amaç | Dataset/split | Model/koşul | Birincil sonuç | Artefact | Not |
|---|---|---|---|---|---|---|---|---|
| P0-ENV-001 | 2026-07-15 | completed | Online Boutique ve observability smoke test | Pilot v0 | Online Boutique v0.10.6, normal sistem | 15/15 deployment hazır; kullanıcı akışı 5/5 HTTP 200; log/metric/trace toplandı | `p0-env/artifacts/P0-ENV-001/` | `run_id` propagation yok; P1 öncesi giderilecek |
| P1-CPU-001 | 2026-07-15 | planned | CPU stress altında pre-failure sinyal fizibilitesi | Pilot v0 | 10–15 fault + 5–10 normal run | Bekleniyor | - | İlk karar kapısı |
| M0-RULE-001 | - | planned | Kural tabanlı alarm baseline | Pilot sonrası | Threshold baseline | Bekleniyor | - | Validation ile eşik seçilecek |
| M1-XGB-001 | - | planned | Tabular temporal baseline | Dataset v1 | XGBoost | Bekleniyor | - | Kalibrasyon dahil |
| M2-GRU-001 | - | planned | Sequence temporal model | Dataset v1 | GRU | Bekleniyor | - | 15/30/60 s horizon |
| L1-VERIFY-001 | - | planned | LLM false-positive azaltımı | Dataset v1 test | Evidence-grounded verifier | Bekleniyor | - | Kodlu/kodsuz kontroller |
| R1-GRAPH-001 | - | planned | Root-cause ranking | Dataset v1 test | Graph baselines -> GCN/GAT | Bekleniyor | - | Top-1/Top-3/MRR |

## P0-ENV-001 tamamlanma özeti

```yaml
experiment_id: "P0-ENV-001"
research_question: "Online Boutique yerel ortamda sürdürülebilir biçimde çalışıyor ve log/metric/trace toplanabiliyor mu?"
status: completed
code_revision: "online-boutique v0.10.6 / 5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb"
config_revision: "kustomization sha256:DD7A94CC04FECA210AC30A2A53DFB31FF047BE961F010A1EFF57F693F557C914; observability sha256:E7F4BBE531AB4645D536969DA2DCDE20FF7120521C5DEB22455279626526489B"
dataset_version: "Pilot v0 (veri üretilmedi)"
split_manifest: null
feature_version: null
model: "Normal sistem; model yok"
seeds: []
primary_metric: "deployment readiness + normal-flow smoke + telemetry availability"
primary_result: "15/15 deployment Available; 5/5 smoke adımı HTTP 200; log/metric/trace toplandı"
confidence_interval: null
secondary_results:
  prometheus_cadvisor_target: "up"
  namespace_cpu_rate_example: 0.1194279549487128
  jaeger_paymentservice_trace_count: 5
  run_id_present_in_three_modalities: false
runtime: "Kurulum ve doğrulama oturumu, 2026-07-15"
hardware: "8 logical CPU host; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P0-ENV-001/"
known_issues:
  - "run_id logs/metrics/traces içinde yok; P1 öncesi propagation gerekli"
  - "bazı trace service adları unknown_service; OTEL_SERVICE_NAME sabitlenmeli"
  - "immutable ham log arşivi P1 run pipeline'ında kurulmalı"
  - "trace sampling oranı P1 öncesi açıkça sabitlenmeli"
decision: "repeat"
```

## Her tamamlanan deney için zorunlu özet

```yaml
experiment_id: ""
research_question: ""
status: completed
code_revision: ""
config_revision: ""
dataset_version: ""
split_manifest: ""
feature_version: ""
model: ""
seeds: []
primary_metric: ""
primary_result: ""
confidence_interval: ""
secondary_results: {}
runtime: ""
hardware: ""
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: ""
known_issues: []
decision: "accept | repeat | reject | supersede"
```

## Pilot karar kapısı

P1-CPU-001 sonrasında aşağıdakiler doldurulur:

| Soru | Ölçüt | Sonuç | Karar |
|---|---|---|---|
| Fault etkisi tekrarlanabilir mi? | Aynı profilde benzer metric/SLO davranışı | Bekleniyor | - |
| Manifestation enjeksiyondan ayrılabiliyor mu? | Pozitif ve değişken lead time | Bekleniyor | - |
| Pre-failure sinyal var mı? | Basit baseline chance üstünde ve olay-bazlı tutarlı | Bekleniyor | - |
| Modaliteler hizalı mı? | Kabul edilebilir missingness ve timestamp uyumu | Bekleniyor | - |
| Dataset v1'e geçilmeli mi? | Yukarıdaki kanıtların bütünü | Bekleniyor | - |

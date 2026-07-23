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
| P1-LOG-ARCHIVE-001 | 2026-07-21 | completed | Ham log arşivleme ve bütünlük doğrulaması | Uygulanamaz; araç doğrulaması | Normal sistem, fault injection yok | 16/16 manifest girdisi doğrulandı; 17/17 dosya salt okunur | `p0-env/artifacts/P1-LOG-ARCHIVE-001/` | İlk bozuk manifest denemesi silinmeden invalid olarak korundu; yerel mühür WORM değildir |
| P1-ARCHIVE-UTC-001 | 2026-07-23 | completed | Ham log arşivinin UTC başlangıç sınırını düzeltmek | Uygulanamaz; araç doğrulaması | Normal sistem, fault injection yok | Alt süreç UTC round-trip eşit; belirsiz yerel tarih reddedildi | `p0-env/artifacts/P1-ARCHIVE-UTC-001/` | Önceki araç arşivinde pencere 182,16 dakika; bilimsel veri olarak kullanılamaz |
| P1-LOG-ENRICH-001 | 2026-07-23 | completed | Ham logları değiştirmeden parsed kayıtlara run ID eklemek | Uygulanamaz; araç doğrulaması | `log-envelope-v1`, fault injection yok | 58.670 kayıt; run ID uyuşmazlığı 0; JSON hatası 0 | `p0-env/artifacts/P1-LOG-ENRICH-001/` | Kaynak pencere bilimsel veri değildir; yeni benzersiz run ile E2E test gerekli |
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

## P1-LOG-ARCHIVE-001 tamamlanma özeti

```yaml
experiment_id: "P1-LOG-ARCHIVE-001"
research_question: "Ham Kubernetes logları run bazında, üzerine yazılmadan ve SHA-256 ile doğrulanabilir biçimde arşivlenebiliyor mu?"
status: completed
code_revision: "82ed754 environment baseline; implementation revision is the Git commit containing this record"
config_revision: "deployment_revision is recorded in the local run metadata"
dataset_version: null
split_manifest: null
feature_version: null
model: null
seeds: []
primary_metric: "verified manifest entries / total manifest entries"
primary_result: "16/16 manifest entry verified; failure_count=0"
confidence_interval: null
secondary_results:
  raw_log_file_count: 15
  raw_log_files_containing_run_id: 0
  readonly_file_count: 17
  wrong_run_id_rejected: true
  invalid_manifest_rejected: true
  unmanifested_file_rejected: true
  invalid_archive_preserved: true
runtime: "P1 readiness tooling validation, 2026-07-21"
hardware: "Local Windows 11 host; existing p0-online-boutique Minikube profile"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-LOG-ARCHIVE-001/"
known_issues:
  - "Run ID is linked at archive metadata level but is absent from 15/15 raw log files; parsed log enrichment is required before experimental collection"
  - "Windows read-only attribute and SHA-256 manifest provide project-level sealing, not hardware/cloud WORM object lock"
  - "Local raw run archives are excluded from Git and require separate backed-up storage before scientific runs"
  - "The first manifest-path implementation failed verification and remains preserved under the local _invalid archive path"
decision: "accept"
```

## P1-ARCHIVE-UTC-001 tamamlanma özeti

```yaml
experiment_id: "P1-ARCHIVE-UTC-001"
research_question: "Ham log arşivinin başlangıç UTC sınırı alt PowerShell sürecinde saat kayması olmadan korunabiliyor mu?"
status: completed
code_revision: "f41a15c environment baseline; implementation revision is the Git commit containing this record"
config_revision: null
dataset_version: null
split_manifest: null
feature_version: null
model: null
seeds: []
primary_metric: "parent/child PowerShell UTC round-trip equality"
primary_result: "roundtrip_equal=True"
confidence_interval: null
secondary_results:
  ambiguous_local_datetime_rejected: true
  syntax_errors: 0
  previous_capture_window_minutes: 182.16
runtime: "P1 readiness UTC tooling validation, 2026-07-23"
hardware: "Local Windows 11 host"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-ARCHIVE-UTC-001/"
known_issues:
  - "A new unique run ID still requires an end-to-end archive window validation"
  - "The prior 182.16-minute tooling archive is not eligible as scientific data and remains preserved"
  - "Parsed log run ID enrichment remains required before experimental collection"
decision: "accept"
```

## P1-LOG-ENRICH-001 tamamlanma özeti

```yaml
experiment_id: "P1-LOG-ENRICH-001"
research_question: "Mühürlenmiş ham loglar değiştirilmeden her parsed kayda run ID ve kaynak provenance bilgisi eklenebiliyor mu?"
status: completed
code_revision: "9823020 environment baseline; implementation revision is the Git commit containing this record"
config_revision: "source deployment revision 55585918b90772dc5d33ca6107eace832885741f8064974f0e2fb1ad6d80a544"
dataset_version: null
split_manifest: null
feature_version: "log-envelope-v1"
model: null
seeds: []
primary_metric: "run ID mismatch count across enriched records"
primary_result: "0 mismatch across 58670 records"
confidence_interval: null
secondary_results:
  source_log_file_count: 15
  output_ndjson_file_count: 15
  verified_record_count: 58670
  timestamp_missing_count: 0
  json_failure_count: 0
  sequence_failure_count: 0
  verified_manifest_file_count: 16
  readonly_file_count: 17
  invalid_outputs_preserved: 2
  unmanifested_file_rejected: true
runtime: "P1 readiness log enrichment validation, 2026-07-23"
hardware: "Local Windows 11 host"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-LOG-ENRICH-001/"
known_issues:
  - "Source raw archive spans 182.16 minutes and is tooling-only, not scientific data"
  - "A new unique run ID with corrected UTC boundary requires end-to-end normal-run validation"
  - "Embedded severity, trace ID and message-template parsing remains versioned future work"
decision: "accept"
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

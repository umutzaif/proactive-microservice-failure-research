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
| P1-NORMAL-E2E-001 | 2026-07-25 | invalid | Benzersiz run ID ile normal koşul E2E telemetry doğrulaması | Uygulanamaz; altyapı E2E doğrulaması | Normal sistem, fault injection yok; `ob-normal-e2e-001` ve `ob-normal-e2e-002` | E2E-002 ham ve enriched log doğrulaması geçti; çok-modlu run host çökmesi nedeniyle geçersiz | `p0-env/artifacts/P1-NORMAL-E2E-001/` | DPC_WATCHDOG_VIOLATION 0x133; restart sonrası Jaeger/Prometheus verisi korunmadı ve aynı run ID ile yeni telemetry oluştu |
| P1-TELEMETRY-EXPORT-001 | 2026-07-25 | completed | Log, metric ve trace verisini aynı run penceresinde immutable dışa aktarmak ve final receipt üretmek | Uygulanamaz; araç doğrulaması | Normal tooling trafiği; fault injection yok; telemetry schema v2 | 47.546 metric sample, 1.109 enriched log, 152 tam trace ve 806 span doğrulandı; `close_run=passed` | `p0-env/artifacts/P1-TELEMETRY-EXPORT-001/` | 15 boundary-crossing trace ham katmanda korundu ve selected katmandan dışlandı; PR #10 ile `main` revision `f650bdd` üzerine merge edildi |
| P1-HOST-STABILITY-001 | 2026-07-25 | invalid | Hostun telemetry yükü altında deney çalıştırmaya uygunluğunu doğrulamak | Uygulanamaz; host kapısı | Docker/Minikube tooling yükü; Wi-Fi disabled | Aynı PCIe Root Port 00:1D.5 üzerinde 2 yeni WHEA Event 17 | `p0-env/artifacts/P1-TELEMETRY-EXPORT-001/` | Host düzeltilmeden P1-CPU-001 başlatılmamalı |
| P1-HOST-STABILITY-002 | 2026-07-28 | completed | Temiz boot altında host stabilite kapısını tekrar doğrulamak | Uygulanamaz; altyapı doğrulaması | İki 30 dakikalık yük gözlemi ve bir 10 dakikalık tam E2E kapanış | WHEA Event 17: 0; Kernel-Power 41: 0; tam close-run başarılı | `p0-env/artifacts/P1-HOST-STABILITY-002/` | Host kapısı kabul edildi; uzun koşularda Jaeger trace limitine ulaşılması ayrı teknik engel olarak kaldı |
| P1-HOST-STABILITY-003 | 2026-07-29 | invalid | Temiz boot sonrasında aktif yük altında host stabilitesini yeniden doğrulamak | Uygulanamaz; host kapısı | Online Boutique loadgenerator; fault injection yok | 5. dakikada PCIe 00:1D.5 üzerinde 8 yeni WHEA Event 17; Kernel-Power 41 ve bugcheck 0 | `p0-env/artifacts/P1-HOST-STABILITY-003/` | Bilimsel baseline başlatılmadı; PCIe sorunu giderilip temiz-boot host doğrulaması geçmeden P1-CPU-001 veri toplamasına geçilmemeli |
| P1-HOST-STABILITY-004 | 2026-08-02 | completed | BIOS işlemi sonrasında host stabilite kapısını yeniden doğrulamak | Uygulanamaz; host kapısı | 30 dakika aktif yük ve `ob-host-stability-004` ile 10 dakika tam E2E kapanış; fault injection yok | WHEA Event 17, Kernel-Power 41 ve bugcheck 0; close-run ve offline receipt geçti | `p0-env/artifacts/P1-HOST-STABILITY-004/` | 530.862 metric sample, 3.087 selected trace ve 32.697 span; bilimsel dataset değildir; P1-CPU-001 başlamadan ana araştırma değerlendirmesi ve kullanıcı onayı beklenmeli |
| P1-CPU-001 / ob-cpu-normal-001 | 2026-08-02 | invalid | İlk normal baseline adayını fault injection olmadan toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | Host ve log kapıları geçti; Prometheus run-scoped metric sample bulunmadığı için close-run reddedildi | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-001-report.md` | 20.136 enriched log korundu; partial telemetry ve üç close-run hata receipt'i `_invalid` altında; dataset'e alınmaz, fault injection başlatılmaz |
| P1-CPU-001 / ob-cpu-normal-002 | 2026-08-02 | completed | İkinci fault'suz normal baseline adayını tüm bilimsel kapılarla toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 532.256 metric sample, 3.004 selected trace, 31.439 span; tüm verifier'lar ve post-shutdown host kapısı geçti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-002-report.md` | İlk geçerli bilimsel normal baseline adayı; finalization UTC hassasiyet hatası `_invalid` receipt olarak korundu; fault injection başlatılmadı |
| P1-CPU-001 / ob-cpu-normal-003 | 2026-08-02 | completed | Üçüncü fault'suz normal baseline adayını bağımsız tekrar olarak toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 538.304 metric sample, 3.338 selected trace, 35.109 span; 15 deployment lifecycle ve tüm verifier kapıları geçti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-003-report.md` | Geçerli bilimsel normal baseline adayı; host olayı 0; fault injection başlatılmadı |
| P1-CPU-001 / ob-cpu-normal-004 | 2026-08-02 | completed | Dördüncü fault'suz normal baseline adayını bağımsız tekrar olarak toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 513.784 metric sample, 3.257 selected trace, 33.970 span; 15 deployment lifecycle ve tüm verifier kapıları geçti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-004-report.md` | Geçerli bilimsel normal baseline adayı; post-shutdown host olayı 0; fault injection başlatılmadı |
| P1-ACTIVE-RUN-ID-GATE-001 | 2026-08-02 | completed | Deployment sonrasında collector ve Prometheus'un beklenen run ID'yi gerçekten etkinleştirdiğini doğrulamak | Uygulanamaz; tooling doğrulaması | `ob-active-run-gate-tool-001`; fault injection yok | ConfigMap/pod/runtime kapıları geçti; 4.112 run-scoped metric series; yanlış ID negatif testi reddedildi | `p0-env/artifacts/P1-ACTIVE-RUN-ID-GATE-001/report.md` | Bilimsel dataset değildir; yeni baseline öncesinde zorunlu pre-lifecycle kapı olarak kullanılır |
| P1-TARGET-SERVICE-SELECTION-001 | 2026-08-02 | completed | İlk CPU-stress kalibrasyon hedefini iki aday arasında kanıta dayalı seçmek | Uygulanamaz; geçerli normal baseline yeniden analizi | checkoutservice ve recommendationservice; fault injection yok | Recommendation: 11,962 mCPU ortalama ve 1.078 kullanıcı-yolu spanı; checkout: 1,225 mCPU ve 340 span | `p0-env/artifacts/P1-TARGET-SERVICE-SELECTION-001/` | `recommendationservice` D-014 ile seçildi; sonuç fault yanıtı kanıtı veya bilimsel fault run değildir |
| P1-SLO-CANDIDATE-001 | 2026-08-03 | completed | Üç geçerli normal run'dan latency/error SLI dağılımını çıkarmak | Geçerli normal-baseline yeniden analizi | 180 tam 5 sn pencere; frontend server spanları; fault injection yok | Pencere-p95 latency p99 4.279,712 ms; 2.219 istekte hata 0; tekrar analizi byte-identical | `p0-env/artifacts/P1-SLO-CANDIDATE-001/` | O-003 açık: `/` route normalde yaklaşık 4 sn; neden açıklanmadan SLO dondurulmadı ve fault injection başlatılmadı |
| P1-SLO-ROOT-DIAGNOSTIC-001 | 2026-08-03 | completed | `/` normal gecikmesinin trace kritik-yol adayını ve kaynak/log karşılığını belirlemek | Geçerli normal-baseline yeniden analizi | 236 HTTP 200 `/` trace'i; fault injection ve deployment değişikliği yok | Downstream spanlar ms düzeyinde; frontend kaynak kodundaki spansız, koşulsuz GCP metadata DNS lookup güçlü neden hipotezi | `p0-env/artifacts/P1-SLO-CANDIDATE-001/frontend-root-diagnostic-report.md` | Nedensellik henüz kanıtlanmadı; benchmark patch/A-B smoke akademik karşılaştırılabilirliği etkilediği için karar bekleniyor |
| P1-FRONTEND-DNS-AB-001 | 2026-08-03 | invalid | GCP metadata DNS autodetection patch'inin `/` latency etkisini A/B/A ile sınamak | Tooling smoke; bilimsel dataset değil | Upstream A → patched B → upstream A; 5 warm-up + 5 ölçüm isteği; fault yok | Treatment warm p95 227,792 ms; A kontrolleri 101,283 ms median ile 4.030,807 ms median arasında uyuşmadı | `p0-env/artifacts/P1-FRONTEND-DNS-AB-001/report.md` | Cold-start ve DNS-cache/sequence carry-over nedeniyle nedensellik kurulamadı; iki attempt silinmeden korundu, patch reddedilmedi fakat kabul de edilmedi |
| P1-FRONTEND-DNS-AB-002 | 2026-08-03 | completed | DNS patch etkisini bağımsız eşzamanlı podlar ve randomize eşlenmiş turlarla sınamak | Preregistered tooling testi; bilimsel dataset değil | 6 tur × 2 varyant × 10 concurrent `/` isteği; seed 20260803; fault yok | 120/120 HTTP 200; treatment 6/6 hızlı; maksimum median oranı 0,722 ile preregistered ≤0,25 kapısı başarısız | `p0-env/artifacts/P1-FRONTEND-DNS-AB-002/report.md` | Geçerli negatif sonuç; eşik post hoc gevşetilmedi, patch bilimsel deployment'a alınmadı, SLO açık ve fault injection başlamadı |
| P1-SLO-ROUTE-CANDIDATE-001 | 2026-08-03 | completed | Global, `/`-hariç ve `/product/{id}` normal SLI nüfuslarını karşılaştırmak | Geçerli normal-baseline yeniden analizi | 3 run; 180 tam 5 sn pencere; frontend server spanları; fault yok | Ürün ailesi 1.066 istek, 179/180 dolu pencere; window-p95 p99 345,992 ms, maksimum 451,162 ms, hata 0; replay byte-identical | `p0-env/artifacts/P1-SLO-ROUTE-CANDIDATE-001/` | Karar desteği aşamasında O-003 açıktı; daha sonra P1-SLO-FREEZE-001 ve D-015 ile çözüldü. Fault injection bu analizde başlamadı |
| P1-SLO-FREEZE-001 | 2026-08-03 | completed | P1-CPU-001 failure manifestation kuralını fault verisi öncesi dondurmak ve normal veride falsifiye etmek | Sürüm `p1-cpu-001-slo-v1`; bilimsel dataset değil | Product window-p95 >345,992 ms veya global error rate >0; 3 ardışık dolu 5 sn pencere | Üç normal run'da latency aşım sayısı 0/0/1, maksimum streak 0/0/1; error streak 0; yanlış manifestation 0 | `p0-env/artifacts/P1-SLO-FREEZE-001/` | D-015 ile O-003 çözüldü; yalnız normal uyumluluğu kanıtlar, fault duyarlılığı henüz bilinmez ve fault injection bu kayıtla otomatik başlamaz |
| P1-CPU-LOW-PREREG-001 | 2026-08-04 | completed | İlk düşük CPU kalibrasyonunu fault verisi öncesi preregister etmek ve güvenlik araçlarını doğrulamak | Tooling/preregistration; bilimsel dataset değil | recommendationservice; 50m; 120 sn ramp; 300 sn steady; sabit SLO grid; bounded worker; Prometheus etki kapısı | Worker, CPU-effect pozitif/negatif, metadata pozitif/negatif, fixed-grid/empty-window/timestamp ve parser testleri geçti | `p0-env/artifacts/P1-CPU-LOW-PREREG-001/` | Fault uygulanmadı; canlı preflight ve temiz committed revision geçmeden `ob-cpu-low-001` başlayamaz |
| P1-CPU-001 / ob-cpu-low-001 | 2026-08-04 | invalid | İlk düşük CPU-stress kalibrasyon attempt'i | `cpu-recommendation-low-v1`; workload/SLO değişmedi | 5 dk warm-up + 5 dk pre-fault baseline tamamlandı; injector başlangıcında PowerShell Confirm binding hatası | Fault worker başlamadı; fault_injected=false; Minikube durdu; post-cleanup WHEA/KP41/bugcheck toplamları 881/5/1 | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-001-report.md` | Lifecycle eksik; dataset'e alınmaz, silinmez ve run ID yeniden kullanılmaz. Aynı donmuş koşullarda yeni benzersiz run gerekir |
| P1-CPU-001 / ob-cpu-low-002 | 2026-08-04 | invalid | Düşük CPU-stress kalibrasyonunu tam lifecycle ile sınamak | `cpu-recommendation-low-v1`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | CPU +50,591m ve tüm telemetry/host/pod kapıları geçti; interval 59/60 < preregistered 240 olduğu için effect gate başarısız; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-002-report.md` | Dataset'e alınmaz ve retroaktif geçerli yapılmaz. 5 sn gerçek scrape aralığına uygun coverage kapısı için açık karar ve yeni run ID gerekir |
| P1-TRACE-CHUNK-TOOL-001 | 2026-07-28 | completed | Uzun run pencerelerini kayıpsız trace sorgu parçalarına bölmek | Uygulanamaz; sentetik araç doğrulaması | Schema v3; iki servis ve dört zaman parçası | Pozitif fixture geçti; boşluk ve limit negatif testleri reddedildi | `p0-env/artifacts/P1-TRACE-CHUNK-TOOL-001/` | Bilimsel veri değildir; canlı doğrulama daha sonra P1-TRACE-CHUNK-LIVE-001 ile geçti |
| P1-TRACE-CHUNK-LIVE-001 | 2026-07-28 | completed | Schema v3 trace export hattını 30 dakikalık gerçek yükte doğrulamak | Uygulanamaz; canlı tooling doğrulaması | `ob-trace-chunk-live-001`, fault injection yok | 49/49 parça doğrulandı; maksimum 924/5000; close-run geçti | `p0-env/artifacts/P1-TRACE-CHUNK-LIVE-001/` | 9.441 selected trace ve 100.056 span; PR #12 ile `main` revision `c29e2b2` üzerine merge edildi |
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

## P1-NORMAL-E2E-001 tamamlanma özeti

```yaml
experiment_id: "P1-NORMAL-E2E-001"
research_question: "Benzersiz run ID ile normal koşul log, metric ve trace hattı uçtan uca doğrulanabiliyor mu?"
status: invalid
code_revision: "da5c88b21a9fe557bcf563be9b4271c912bbd54e"
config_revision: "kustomization sha256:2C29B96EFB19D64CFEE7C2515209FE2CA3EFA47743F97A73D0F215A303D50B70; observability sha256:5922741E09B3BF11AC5773AB5F0F710CA9899F3A3F868838B4BBFA72EAE6BAB3"
dataset_version: null
split_manifest: null
feature_version: "log-envelope-v1"
model: "Normal sistem; model yok; fault injection yok"
seeds: []
primary_metric: "Aynı run penceresinde doğrulanmış telemetry modality sayısı / 3"
primary_result: "Log hattı doğrulandı; metric ve trace host restartı nedeniyle doğrulanamadı; tam run invalid"
confidence_interval: null
secondary_results:
  smoke_http_200: "5/5"
  raw_manifest_verified: "16/16"
  raw_readonly_files: "17/17"
  enriched_records_verified: 4586
  missing_timestamp_count: 0
  json_failure_count: 0
  run_id_mismatch_count: 0
  host_bugcheck: "DPC_WATCHDOG_VIOLATION 0x133"
  whea_count_after_power_cycle_and_cluster_restart: 0
runtime: "E2E-002 valid log window 2026-07-25T12:26:52.664Z sonrası 2,38 dakika; host crash ve restart sonrası telemetry kapsam dışı"
hardware: "ASUS TUF Gaming F15 FX506LHB; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-NORMAL-E2E-001/"
known_issues:
  - "E2E-001 yapay newline nedeniyle 3 eksik timestamp üretti ve invalid olarak korundu"
  - "E2E-002 doğrulaması sırasında host DPC_WATCHDOG_VIOLATION 0x133 ile yeniden başladı"
  - "Jaeger ve Prometheus kalıcı telemetry volume kullanmıyor"
  - "Restart sonrası loadgenerator aynı run ID ile yeni telemetry üretti"
  - "BSOD için minidump stack analizi henüz yapılmadı"
decision: "repeat"
```

## P1-TELEMETRY-EXPORT-001 tamamlanma özeti

```yaml
experiment_id: "P1-TELEMETRY-EXPORT-001"
research_question: "Log, metric ve trace artefact'ları aynı run ID ve UTC penceresiyle cluster dışında mühürlenip bağımsız doğrulanabiliyor mu?"
status: completed
code_revision: "8e39ac9 environment baseline; implementation revision is the Git commit containing this record"
config_revision: "kustomization sha256:E87C27F5A083504D023FE2FD933AC95F911F5BB643224DA50B295D41A02774A8; observability sha256:F4D5C2AE2F86DA3EB14673F2FBB76D085F178A93DCC2821EB520EFB2B3FBD5F7"
dataset_version: null
split_manifest: null
feature_version: "log-envelope-v1; telemetry-schema-v2"
model: null
seeds: []
primary_metric: "verified finalization gates / total finalization gates"
primary_result: "8/8 close-run gates passed; offline final receipt verification passed"
confidence_interval: null
secondary_results:
  raw_log_file_count: 15
  enriched_record_count: 1109
  metric_series_count: 4883
  metric_sample_count: 47546
  raw_unique_trace_count: 167
  boundary_excluded_trace_count: 15
  selected_complete_trace_count: 152
  selected_span_count: 806
  run_id_mismatch_count: 0
  timestamp_failure_count: 0
  manifest_tamper_rejected: true
  overwrite_rejected: true
  wrong_deployed_run_id_rejected: true
  failed_close_receipt_preserved: true
runtime: "Tooling-only validation, 2026-07-25"
hardware: "ASUS TUF Gaming F15 FX506LHB; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TELEMETRY-EXPORT-001/"
known_issues:
  - "Local read-only plus SHA-256 sealing is project-level immutability, not hardware/cloud WORM"
  - "Boundary-crossing traces are preserved raw but excluded from the complete in-window selected trace layer"
  - "Scientific runs remain blocked by the separate host stability gate"
decision: "accept"
```

## P1-HOST-STABILITY-001 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-001"
research_question: "Yerel host telemetry tooling yükü altında WHEA hatası üretmeden kararlı kalıyor mu?"
status: invalid
code_revision: "8e39ac9 environment baseline"
config_revision: null
dataset_version: null
split_manifest: null
feature_version: null
model: null
seeds: []
primary_metric: "WHEA-Logger Event 17 count during tooling load"
primary_result: "2 corrected PCIe AER errors on root port 00:1D.5; host gate failed"
confidence_interval: null
secondary_results:
  whea_event_id: 17
  whea_count: 2
  pci_root_port: "PCI\\VEN_8086&DEV_06B5&SUBSYS_1E911043&REV_F0"
  wifi_adapter_disabled_during_load: true
  minikube_stopped_cleanly: true
  docker_stopped_cleanly: true
runtime: "2026-07-25 tooling load; WHEA events at 21:10:01 Europe/Istanbul"
hardware: "ASUS TUF Gaming F15 FX506LHB; BIOS FX506LHB.311"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TELEMETRY-EXPORT-001/"
known_issues:
  - "Same PCIe root port was implicated around the prior DPC_WATCHDOG_VIOLATION 0x133"
  - "Disabling the MediaTek MT7921 adapter in Windows did not prevent corrected PCIe errors"
  - "Minidump stack analysis and firmware/driver remediation remain required"
decision: "repeat"
```

## P1-HOST-STABILITY-002 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-002"
research_question: "Temiz boot altında Docker, Minikube, Online Boutique yükü ve artefact kapatma işlemleri sırasında host kararlı kalıyor mu?"
status: completed
code_revision: "f650bdd"
config_revision: "kustomization sha256:7bd29d2fde51fe35cdf36d4b31f0f2310ecab67bfdb266791ef4c3a052ad2bc4; observability sha256:9b8f72cb8435e30e7d70ed09050ecb2b053902905d5525de8251cad1c9f26262"
dataset_version: "Uygulanamaz; bilimsel dataset üretilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "Temiz boot sonrasında gözlenen WHEA Event 17 sayısı"
primary_result: "0"
confidence_interval: null
secondary_results:
  kernel_power_41_count: 0
  completed_30_minute_load_windows: 2
  completed_10_minute_e2e_windows: 1
  final_run_id: "ob-host-stability-003"
  final_run_duration_seconds: 616.342
  raw_log_file_count: 15
  enriched_record_count: 14881
  metric_series_count: 4013
  metric_sample_count: 497612
  raw_unique_trace_count: 3187
  verified_unique_trace_count: 3185
  verified_span_count: 33417
  boundary_excluded_trace_count: 2
  close_run_passed: true
runtime: "Temiz boot altında iki 30 dakikalık aktif yük gözlemi ve bir 10 dakikalık tam E2E doğrulama"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet bağlı, Wi-Fi devre dışı"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-002/"
known_issues:
  - "P1-HOST-STABILITY-001 önceki boot dönemindeki WHEA ve bugcheck kanıtıyla invalid olarak korunmaktadır"
  - "ob-host-stability-001 Prometheus run etiketi yenilenmediği için geçersizdir"
  - "ob-host-stability-002 Jaeger servis başına 5000 trace sınırına ulaştığı için geçersizdir"
  - "Uzun süreli deneylerden önce trace export zaman dilimlerine bölünmeli ve trace ID ile tekilleştirilmelidir"
decision: "accept"
```

## P1-CPU-001 / ob-cpu-normal-003 ve ob-cpu-normal-004 tamamlanma özeti

```yaml
experiment_id: "P1-CPU-001"
run_kind: "normal_baseline"
status: completed
scientific_candidates: true
run_ids: ["ob-cpu-normal-003", "ob-cpu-normal-004"]
workload_profile: "ob-default-10u-1r-v1"
random_seed: 1
fault_injection: false
tracked_deployment_count: 15
deployment_uid_or_restart_changes: 0
host_health_failures: 0
post_shutdown_host_health: passed
metric_sample_counts: [538304, 513784]
enriched_record_counts: [21798, 21150]
unique_trace_counts: [3338, 3257]
selected_span_counts: [35109, 33970]
telemetry_schema_version: 3
trace_chunk_counts: [21, 21]
run_id_time_chunk_failure_count: 0
final_receipts: passed
offline_finalized_run_verification: passed
dataset_inclusion: true
fault_injection_started: false
decision: "accept-two-additional-normal-baseline-candidates-and-stop"
```

## P1-CPU-001 / ob-cpu-normal-002 tamamlanma özeti

```yaml
experiment_id: "P1-CPU-001"
run_id: "ob-cpu-normal-002"
run_kind: "normal_baseline"
status: completed
scientific_candidate: true
code_revision: "7872498366444c927e3eb8ff377b74e42e50d5e3"
workload_profile: "ob-default-10u-1r-v1"
random_seed: 1
warmup_seconds: 300.2446798
normal_baseline_seconds: 300.811541
fault_injection: false
host_health:
  whea_event_17_delta: 0
  kernel_power_41_delta: 0
  bugcheck_delta: 0
post_shutdown_host_health: passed
raw_log_file_count: 15
enriched_record_count: 19599
metric_series_count: 4975
metric_sample_count: 532256
telemetry_schema_version: 3
trace_chunk_count: 21
unique_trace_count: 3004
selected_span_count: 31439
boundary_excluded_trace_count: 4
run_id_time_chunk_failure_count: 0
final_receipt: passed
offline_finalized_run_verification: passed
dataset_inclusion: true
fault_injection_authorized: false
artifact_path: "p0-env/artifacts/P1-CPU-001/ob-cpu-normal-002-report.md"
decision: "accept-normal-baseline-candidate-and-stop"
```

## P1-CPU-001 / ob-cpu-normal-001 invalid run özeti

```yaml
experiment_id: "P1-CPU-001"
run_id: "ob-cpu-normal-001"
run_kind: "normal_baseline"
status: invalid
code_revision: "9ecb59fcba6019223599c1b80eb5334331baeb5b"
workload_profile: "ob-default-10u-1r-v1"
random_seed: 1
warmup_seconds: 300.2343755
normal_baseline_seconds: 300.7827668
fault_injection: false
host_health:
  whea_event_17_delta: 0
  kernel_power_41_delta: 0
  bugcheck_delta: 0
raw_log_file_count: 15
enriched_record_count: 20136
log_verification: passed
metric_trace_archive: failed
invalid_reason: "Prometheus response does not contain run-scoped metric samples"
dataset_inclusion: false
fault_injection_authorized: false
artifact_path: "p0-env/artifacts/P1-CPU-001/ob-cpu-normal-001-report.md"
decision: "invalid-preserve-and-diagnose-before-repeat"
```

## P1-HOST-STABILITY-003 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-003"
research_question: "Temiz boot sonrasında Online Boutique aktif yükü altında host yeni WHEA, Kernel-Power 41 veya bugcheck üretmeden kararlı kalıyor mu?"
status: invalid
code_revision: "b604d390b61c2e85e880e8081dc9ddf1a52dcda2"
config_revision: "değişmedi"
dataset_version: "Uygulanamaz; bilimsel dataset üretilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "30 dakikalık aktif yük penceresinde yeni WHEA-Logger Event 17 sayısı"
primary_result: "8; pencere 5. dakikada erken durduruldu"
confidence_interval: null
secondary_results:
  boot_utc: "2026-07-29T17:52:44.5000000Z"
  window_start_utc: "2026-07-29T18:02:43.1006252Z"
  first_whea_utc: "2026-07-29T18:06:57.4575789Z"
  last_whea_utc: "2026-07-29T18:06:57.5423638Z"
  whea_event_id: 17
  whea_count: 8
  pci_root_port: "00:1D.5"
  pci_device: "PCI\\VEN_8086&DEV_06B5&SUBSYS_1E911043&REV_F0"
  kernel_power_41_count: 0
  bugcheck_count: 0
  controlled_shutdown: true
  scientific_run_started: false
runtime: "2026-07-29; aktif pencere yaklaşık 5 dakika"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet bağlı, Wi-Fi PnP üzerinde yok"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-003/"
known_issues:
  - "PCIe Root Port 00:1D.5 üzerinde temiz boot sonrasında aktif yük altında WHEA Event 17 tekrarlandı"
  - "Yerel CPU performance counter sorgusu başarısız oldu; host kapısı kararı olay günlüğü farkına dayanır"
decision: "repeat"
```

## P1-HOST-STABILITY-004 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-004"
research_question: "BIOS işlemi sonrasında host Online Boutique aktif yükü ve tam telemetry kapanışı altında kararlı kalıyor mu?"
status: completed
code_revision: "b604d390b61c2e85e880e8081dc9ddf1a52dcda2"
config_revision: "kustomization sha256:9fb58c8af5abbcc72555e09561da30bc2aab93579278090b90871a37505ac16b; observability sha256:778cce588b05c65c923657e55418da421355a7610eaf3569b6b085bbd9045307"
dataset_version: "Uygulanamaz; bilimsel dataset üretilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "30 dakikalık aktif yük ve 10 dakikalık E2E kapanışta yeni host olayı sayısı"
primary_result: "WHEA Event 17: 0; Kernel-Power 41: 0; bugcheck: 0; close_run=passed"
confidence_interval: null
secondary_results:
  bios: "FX506LHB.311"
  active_load_duration_seconds: 1824.808
  active_load_sample_count: 31
  maximum_cpu_percent: 73
  minimum_free_memory_mb: 568.86
  run_id: "ob-host-stability-004"
  e2e_duration_seconds: 609.522
  raw_log_file_count: 15
  enriched_record_count: 20153
  metric_series_count: 4771
  metric_sample_count: 530862
  telemetry_schema_version: 3
  trace_query_chunk_seconds: 300
  trace_chunk_count: 21
  raw_unique_trace_count: 3097
  unique_trace_count: 3087
  selected_span_count: 32697
  boundary_excluded_trace_count: 10
  trace_chunk_coverage_failure_count: 0
  close_run_passed: true
  offline_finalized_run_verification: true
  whea_count: 0
  kernel_power_41_count: 0
  bugcheck_count: 0
runtime: "2026-08-02T09:03:04.968Z/2026-08-02T09:55:06.571Z; aktif yük, E2E ve kontrollü kapanış dahil"
hardware: "ASUS TUF Gaming F15 FX506LHB; BIOS 311; Ethernet bağlı; MT7921 WLAN ve Bluetooth PnP OK"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-004/"
known_issues:
  - "P1-HOST-STABILITY-003 önceki WHEA başarısızlığıyla invalid olarak korunmaktadır"
  - "Bu doğrulama bilimsel dataset değildir"
decision: "accept"
```

## P1-TRACE-CHUNK-TOOL-001 tamamlanma özeti

```yaml
experiment_id: "P1-TRACE-CHUNK-TOOL-001"
research_question: "Jaeger trace sorguları zaman parçalarına bölünerek sessiz kırpma olmadan doğrulanabilir mi?"
status: completed
code_revision: "68d8106 + trace chunking work package"
config_revision: "değişmedi"
dataset_version: "Uygulanamaz; sentetik fixture"
split_manifest: null
feature_version: null
model: "Araç doğrulaması; model yok"
seeds: []
primary_metric: "geçen sentetik trace chunking doğrulama kapısı"
primary_result: "5/5 passed"
confidence_interval: null
secondary_results:
  telemetry_schema_version: 3
  synthetic_service_count: 2
  synthetic_trace_chunk_count: 4
  synthetic_unique_trace_count: 3
  schema_v3_fixture_verification: true
  cross_chunk_trace_id_deduplication: true
  chunk_gap_negative_test: true
  chunk_limit_negative_test: true
  invalid_limit_archive_preservation: true
  schema_v2_backward_compatibility_archives: 2
runtime: "Yerel sentetik araç testi; canlı cluster deneyi yok"
hardware: "Uygulanamaz"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TRACE-CHUNK-TOOL-001/"
known_issues:
  - "En az 30 dakikalık gerçek yük altında schema v3 close-run doğrulaması bekleniyor"
  - "Varsayılan 300 saniyelik parça yoğun yükte yine Jaeger limitine ulaşabilir"
decision: "accept"
```

## P1-TRACE-CHUNK-LIVE-001 tamamlanma özeti

```yaml
experiment_id: "P1-TRACE-CHUNK-LIVE-001"
research_question: "Schema v3 zaman parçalı Jaeger export hattı 30 dakikalık gerçek yükte kırpılmadan doğrulanabiliyor mu?"
status: completed
code_revision: "31d0373"
config_revision: "kustomization sha256:807d94bf496c75d53351940fe3297a9e023eddb6204bbb6b96fa16fa148e6514; observability sha256:566737186884dcc0ab51a0a820b60bd2931ec9c24f0ec5eb0d27b5ee04a80a48"
dataset_version: "Uygulanamaz; canlı tooling doğrulaması"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "doğrulanan trace parçaları / toplam trace parçaları"
primary_result: "49/49; close_run=passed"
confidence_interval: null
secondary_results:
  run_id: "ob-trace-chunk-live-001"
  duration_seconds: 1826.833
  host_sample_count: 31
  maximum_cpu_percent: 69
  minimum_free_memory_mb: 497.02
  raw_log_file_count: 15
  enriched_record_count: 61812
  metric_series_count: 4124
  metric_sample_count: 1492623
  jaeger_service_count: 7
  trace_query_chunk_seconds: 300
  trace_chunk_count: 49
  maximum_chunk_trace_count: 924
  trace_limit_per_service: 5000
  trace_response_count: 21647
  raw_unique_trace_count: 9443
  unique_trace_count: 9441
  selected_span_count: 100056
  boundary_excluded_trace_count: 2
  trace_chunk_coverage_failure_count: 0
  whea_count: 0
  kernel_power_41_count: 0
  bugcheck_count: 0
  merged_pull_request: 12
  merged_main_revision: "c29e2b2"
runtime: "2026-07-28T17:53:29.122Z/2026-07-28T18:23:55.955Z"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet bağlı, Wi-Fi devre dışı"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TRACE-CHUNK-LIVE-001/"
known_issues:
  - "Minimum free memory 497.02 MB düzeyine indi; fault run sırasında izlenmelidir"
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

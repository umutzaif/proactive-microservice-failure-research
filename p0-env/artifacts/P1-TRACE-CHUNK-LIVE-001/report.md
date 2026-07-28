# P1-TRACE-CHUNK-LIVE-001 — 30 Dakikalık Canlı Trace Export Doğrulaması

- Tarih: 2026-07-28
- Dal: `researcher/p1-trace-export-chunking`
- Run ID: `ob-trace-chunk-live-001`
- Durum: `completed`
- Karar: `accept`
- Fault injection: yok
- Bilimsel dataset kullanımı: hayır; P1 öncesi tooling kapısı

## Amaç

Schema v3 zaman parçalı Jaeger exporter'ının gerçek Online Boutique yükü
altında en az 30 dakikalık pencerede sessiz trace kırpması olmadan
çalışabildiğini doğrulamak.

## Başlangıç koşulları

- Git revision: `31d0373`
- Docker Server: `29.6.1`
- Minikube profili: `p0-online-boutique`
- Ethernet: bağlı
- MediaTek Wi-Fi: devre dışı
- Gerçek WHEA-Logger Event 17 baseline: `0`
- Bugcheck baseline: `0`
- Kernel-Power Event 41 baseline: `0`
- Deployment run ID: `ob-trace-chunk-live-001`
- Prometheus run ID label değeri: yalnızca `ob-trace-chunk-live-001`
- Loadgenerator: `1/1 Available`

TPM ve BTHUSB sağlayıcılarının aynı Event ID 17 değerini kullanabildiği
görüldü. Host kapısında yalnızca
`ProviderName=Microsoft-Windows-WHEA-Logger` filtresi kullanıldı.

## Canlı pencere

```text
run_start_utc=2026-07-28T17:53:29.122Z
run_end_utc=2026-07-28T18:23:55.955Z
sample_count=31
maximum_cpu_percent=69
minimum_free_memory_mb=497.02
final_whea_count=0
final_kernel_power_41_count=0
```

Pencere yaklaşık 30 dakika 27 saniye sürdü. Bellek 497,02 MB düzeyine kadar
geriledi ancak run, export ve finalization tamamlandı. Bu değer ilerideki
fault run'larda izlenmesi gereken operasyonel bir risktir.

## Log hattı

```text
raw_log_file_count=15
raw_manifest_file_count=16
timestamp_parse_failure_count=0
timestamp_before_start_count=0
timestamp_after_end_count=0
enriched_record_count=61812
missing_timestamp_count=0
json_failure_count=0
run_id_mismatch_count=0
sequence_failure_count=0
```

Ham log arşivi ve enriched log katmanı ayrı ayrı mühürlendi ve doğrulandı.

## Metric hattı

```text
metric_series_count=4124
metric_sample_count=1492623
metric_run_id_mismatch_count=0
metric_time_failure_count=0
```

## Schema v3 trace hattı

```text
schema_version=3
jaeger_service_count=7
trace_query_chunk_seconds=300
trace_chunk_count=49
trace_response_count=21647
raw_unique_trace_count=9443
unique_trace_count=9441
selected_span_count=100056
boundary_excluded_trace_count=2
trace_run_id_mismatch_count=0
trace_time_failure_count=0
trace_chunk_coverage_failure_count=0
maximum_chunk_trace_count=924
trace_limit_per_service=5000
```

Yedi servisin her biri yedi zaman parçasıyla sorgulandı. Toplam 49 parça
run penceresini boşluksuz ve örtüşmesiz kapsadı.

En yoğun parça frontend servisinin 5 numaralı parçasıydı ve 924 trace
döndürdü. Bu değer 5.000 sınırının yüzde 18,48'idir.

Ham servis/parça yanıtlarında 21.647 trace kaydı bulunurken global trace-ID
tekilleştirmesi sonrasında 9.443 benzersiz trace kaldı. Tekrarlanan 12.204
yanıt sessizce kaybedilmedi; ham dosyalarda korundu ve selected kümede
tekilleştirildi.

Run sınırını kesen iki trace ham kanıtta tutuldu ancak selected kümeden
çıkarıldı.

## Finalization

```text
manifest_file_count=53
verified_manifest_file_count=53
readonly_file_count=54
run_telemetry_verification=passed
run_finalization=passed
finalized_run_verification=passed
close_run=passed
finalized_run_verification_after_shutdown=passed
```

Final receipt schema v3, 300 saniyelik parça süresi ve 49 parça sayısını
taşıdı. Offline finalization doğrulaması kaynak manifestleri tekrar kontrol
ederek geçti. Minikube ve Docker durdurulduktan sonra aynı receipt ikinci kez
doğrulandı; sonuç yine `failure_count=0` oldu.

## Kontrollü kapanış

Minikube ve Docker Desktop kontrollü biçimde durduruldu.

```text
whea_count_after_shutdown=0
kernel_power_41_after_shutdown=0
bugcheck_count_after_shutdown=0
```

## Artefact yolları

Yerel ve Git dışı:

- `p0-env/artifacts/runs/ob-trace-chunk-live-001/`
- `p0-env/artifacts/derived/ob-trace-chunk-live-001/`
- `p0-env/artifacts/telemetry/ob-trace-chunk-live-001/`
- `p0-env/artifacts/finalized/ob-trace-chunk-live-001/`
- `p0-env/state/trace-chunk-live/ob-trace-chunk-live-001-host-monitor.csv`

Git'te yalnızca bu küçük doğrulama raporu saklanır.

## Karar

Schema v3 uzun pencere trace export kapısı geçti:

- gerçek yük penceresi 30 dakikadan uzundu,
- hiçbir parça Jaeger limitine ulaşmadı,
- parça kapsam hatası sıfırdı,
- run ID ve zaman hataları sıfırdı,
- global trace-ID tekilleştirmesi doğrulandı,
- close-run ve finalization zinciri geçti,
- host kararlılık olayları sıfır kaldı.

## Merge sonucu

Schema v3 uygulaması ve canlı doğrulama kaydı iki commit halinde PR #12 ile
`main` dalına merge edildi. Yerel `main` ve `origin/main` `c29e2b2`
revisionında senkronlandı.

Bu sonuçla P1 deney başlangıç kapılarının tamamı kapanmıştır. `P1-CPU-001`,
deney protokolündeki benzersiz run ID, metadata, kontrollü yük/fault profili
ve immutable artefact kuralları korunarak başlatılabilir.

# P1-HOST-STABILITY-004 — BIOS Sonrası Host Doğrulaması

- Tarih: 2026-08-02
- Durum: `completed`
- Karar: `accept`
- Bilimsel dataset kullanımı: hayır; host başlangıç kapısı doğrulaması
- Fault injection: yok

## Amaç

ASUS servisindeki BIOS yeniden yazma/güncelleme işlemi sonrasında MediaTek
MT7921 kartının bağlı olduğu PCIe `00:1D.5` hattının Online Boutique aktif
yükü ve tam telemetri kapanışı sırasında yeni WHEA-Logger Event 17,
Kernel-Power Event 41 veya bugcheck üretmeden kararlı kaldığını doğrulamak.

## Başlangıç koşulları

```text
code_revision=b604d390b61c2e85e880e8081dc9ddf1a52dcda2
bios=FX506LHB.311
boot_utc=2026-07-31T18:15:40.5000000Z
precheck_utc=2026-08-02T08:59:28.2846123Z
whea_event_17_since_boot=0
kernel_power_event_41_since_boot=0
bugcheck_event_1001_since_boot=0
root_port_pnp=OK
mediatek_wlan_pnp=OK
mediatek_bluetooth_pnp=OK
ethernet=Up, 1 Gbps
wifi=Disconnected, Present
```

## 30 dakikalık aktif yük penceresi

```text
window_start_utc=2026-08-02T09:03:04.9683816Z
window_end_utc=2026-08-02T09:33:29.7766192Z
sample_count=31
minimum_cpu_percent=13
maximum_cpu_percent=73
minimum_free_memory_mb=568.86
maximum_free_memory_mb=3150.13
whea_event_17_delta=0
kernel_power_event_41_delta=0
bugcheck_event_1001_delta=0
host_stability_window=passed
```

Önceki `P1-HOST-STABILITY-003` tekrarı yaklaşık dört dakika içinde sekiz
WHEA olayı üretmişti. Aynı Online Boutique loadgenerator yükü bu tekrarda
30 dakikadan uzun süre yeni host olayı üretmeden tamamlandı.

## 10 dakikalık tam E2E kapanışı

```text
run_id=ob-host-stability-004
start_utc=2026-08-02T09:35:27.847Z
end_utc=2026-08-02T09:45:37.369Z
duration_seconds=609.522
raw_log_file_count=15
enriched_record_count=20153
metric_series_count=4771
metric_sample_count=530862
telemetry_schema_version=3
jaeger_service_count=7
trace_query_chunk_seconds=300
trace_chunk_count=21
trace_response_count=7034
raw_unique_trace_count=3097
selected_unique_trace_count=3087
selected_span_count=32697
boundary_excluded_trace_count=10
metric_run_id_mismatch_count=0
metric_time_failure_count=0
trace_run_id_mismatch_count=0
trace_time_failure_count=0
trace_chunk_coverage_failure_count=0
whea_event_17_delta=0
kernel_power_event_41_delta=0
bugcheck_event_1001_delta=0
close_run=passed
```

On boundary-crossing trace ham servis/parça yanıtlarında korundu ve yalnız
tam pencere içindeki selected trace katmanından dışlandı. Schema v3 zaman
parçaları boşluksuz doğrulandı.

## Kontrollü kapanış ve offline receipt

Minikube ve Docker Desktop kontrollü kapatıldı. Cluster ve Docker kapalıyken
final receipt kaynak manifestleri üzerinden tekrar doğrulandı:

```text
post_shutdown_utc=2026-08-02T09:55:06.5712755Z
offline_finalized_run_verification=passed
offline_failure_count=0
whea_event_17_since_boot=0
kernel_power_event_41_since_boot=0
bugcheck_event_1001_since_boot=0
controlled_shutdown=passed
```

## Karar

BIOS sonrası host doğrulaması kabul edildi. Bu koşu yalnız host ve telemetry
tooling kanıtıdır; bilimsel dataset'e alınmaz. `P1-HOST-STABILITY-003`
başarısızlık kanıtı silinmez veya geçersiz sayılmaz.

Bilimsel normal baseline'a geçiş, bu yeni kanıt ana araştırma görevi
tarafından değerlendirildikten ve ayrıca kullanıcı onayı verildikten sonra
yapılmalıdır. Bu görevde bilimsel baseline veya fault injection başlatılmadı.

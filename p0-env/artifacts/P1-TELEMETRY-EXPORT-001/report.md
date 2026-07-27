# P1-TELEMETRY-EXPORT-001 — Immutable Telemetry Export ve Run Finalization

- Tarih: 2026-07-25
- Dal: `researcher/p1-telemetry-export`
- Aşama: P1 öncesi altyapı hazırlığı
- Fault injection: yok
- Model/LLM/GAT: yok
- Başlangıç Git revision: `8e39ac90cf4c0e9a7739a8dccd569d8d527c57fa`

## Amaç

Run bitmeden log, metric ve distributed trace verilerini aynı UTC zaman
aralığında cluster dışına almak; ham çıktıları checksum ile mühürlemek;
bağımsız verifier'larla run ID, zaman sınırı ve dosya bütünlüğünü doğrulamak;
yalnızca bütün kapılar geçtiğinde finalization receipt üretmek.

Bu çalışma bilimsel normal/fault run değildir. Araç doğrulamasıdır.

## Bağlayıcı akademik kurallar

Uygulama aşağıdaki mevcut kararları değiştirmedi:

- deney birimi bağımsız `run` olarak kaldı,
- group key `run_id` olarak kaldı,
- ham veri üzerine yazılmadı,
- UTC ISO-8601 zamanları kullanıldı,
- log, metric ve trace aynı başlangıç/bitiş sınırına bağlandı,
- trace sampling `parentbased_traceidratio / 1.0` olarak korundu,
- fault injection ve manifestation zamanı tanımları değiştirilmedi,
- pencere, prediction horizon, veri bölme ve başarı metrikleri değiştirilmedi.

## Eklenen araçlar

### `archive-run-telemetry.ps1`

- Deployed run ID ile istenen run ID'nin eşleşmesini zorunlu tutar.
- Yalnızca kapanmış bir `[start_utc, end_utc]` aralığını kabul eder.
- Kubernetes service proxy üzerinden Prometheus `query_range` yanıtını alır.
- Prometheus sorgusunu `experiment_run_id` ile sınırlar.
- Jaeger servis listesini ve servis-bazlı ham trace API yanıtlarını saklar.
- Trace limitine ulaşılırsa sessiz truncation yerine işlemi reddeder.
- Ham Jaeger yanıtlarını değiştirmeden korur.
- Şema 2'de yalnızca bütün span'ları run aralığında kalan tam trace'leri
  `selected/traces.ndjson` içine alır.
- Pencere sınırını kesen trace'leri ham katmanda korur ve dışlama sayısını
  metadata'ya yazar.
- SHA-256 manifest üretir ve dosyaları salt okunur mühürler.
- Var olan arşivin üzerine yazmayı reddeder.
- Kısmi başarısız çıktıyı `_invalid` altında korur.

### `verify-run-telemetry.ps1`

- Manifest checksum'larını ve path traversal kurallarını doğrular.
- Manifest dışı dosyaları ve salt-okunur farklarını reddeder.
- Metric run ID ve sample zaman sınırlarını yeniden hesaplar.
- Trace process run ID'lerini doğrular.
- Şema 2 seçilmiş trace katmanında bütün span zamanlarını yeniden denetler.
- Ham/selected trace sayılarını ve boundary dışlamalarını metadata ile
  karşılaştırır.
- Şema 1 tooling arşivleri için geriye dönük doğrulama yolu içerir.
- Cluster API'sine bağlanmadan çalışır.

### Log pencere düzeltmesi

`archive-raw-logs.ps1` aracına isteğe bağlı `UntilUtc` üst sınırı eklendi.
Yeni finalization akışında loglar fiziksel satır timestamp'i ile tam
`[SinceUtc, UntilUtc]` aralığına filtrelenir.

`verify-raw-log-archive.ps1`:

- metadata/manifest run ID eşleşmesini,
- timestamp parse başarısını,
- başlangıç öncesi satır sayısını,
- bitiş sonrası satır sayısını

bağımsız olarak doğrular. Eski arşivlere geçmişte bulunmayan üst sınır
zorla uygulanmaz.

### `finalize-run-artifacts.ps1`

- Ham log, enriched log ve telemetry verifier'larını yeniden çalıştırır.
- Altı metadata/manifest run ID değerinin aynı olduğunu doğrular.
- Log ve telemetry başlangıç/bitiş zamanlarının istenen run aralığıyla tam
  eşleşmesini zorunlu tutar.
- Üç kaynak manifestin SHA-256 değerini receipt'e bağlar.
- Yalnızca tüm kontroller geçerse `valid_for_modeling=true` receipt üretir.
- Receipt üzerine yazmayı reddeder ve başarısız receipt'i `_invalid` altında
  korur.

### `verify-finalized-run.ps1`

- Receipt manifestini ve salt-okunurluğu doğrular.
- Üç kaynak manifestin güncel checksum'larını receipt ile karşılaştırır.
- Üç kaynak verifier'ını yeniden çalıştırır.
- Docker ve Minikube kapalıyken çevrimdışı çalışır.

### `close-run.ps1`

Aşağıdaki sırayı tek komutta ve fail-fast biçimde uygular:

1. ham log arşivi,
2. ham log doğrulaması,
3. parsed/enriched log üretimi,
4. enriched log doğrulaması,
5. metric/trace arşivi,
6. metric/trace doğrulaması,
7. finalization receipt,
8. final receipt doğrulaması.

Bir adım başarısızsa sonraki adımlar çalışmaz. Hata adımı, child exit code,
son hata çıktısı ve oluşmuş artefact bilgisi
`finalized/_invalid/.../close-run-error.json` içinde mühürlenir.

## Negatif testler

### Geçersiz zaman sırası

`StartUtc >= EndUtc` denemesi cluster erişiminden önce reddedildi.

Sonuç:

```text
StartUtc must be earlier than EndUtc.
unexpected_artifact_exists=False
```

### Üzerine yazma

Aynı run ID ile ikinci telemetry export reddedildi.

```text
Telemetry archive already exists and will not be overwritten
```

### Manifest dışı dosya

Test kopyasına `unexpected.txt` eklendi. Verifier:

```text
failure=unexpected_unmanifested_file:unexpected.txt
failure=readonly_mismatch:expected=12,actual=11
```

Test kopyası silindi; asıl arşiv tekrar doğrulandı.

### Yanlış deployed run ID

`ob-tooling-intentional-wrong-id` isteği, deployed
`ob-tooling-close-002` ile eşleşmediği için ilk adımda reddedildi.

```text
status=invalid
failed_step=archive_raw_logs
child_exit_code=1
raw_logs=False
enriched_logs=False
telemetry=False
```

Failure receipt `_invalid` altında korundu.

## Tooling run sonuçları

### `ob-tooling-telemetry-001`

İlk ayrı-modül doğrulaması:

```text
metric_series_count=4061
metric_sample_count=77159
raw/selected unique_trace_count=483
enriched_record_count=3125
failure_count=0
run_finalization=passed
finalized_run_verification=passed
```

Bu run telemetry şema 1 ile üretildi ve geriye dönük verifier yoluyla
doğrulanmaya devam ediyor.

### `ob-tooling-close-001`

İlk tek-komut denemesi log kapılarını geçti. Ham Jaeger yanıtındaki 306 span
run sınırını kestiği için telemetry verifier doğru biçimde zinciri durdurdu.
Receipt üretilmedi. Çıktılar silinmedi.

Bu bulgu trace API'nin zaman aralığı içinde eşleşen bir span bulunduğunda
trace'in tamamını döndürdüğünü gösterdi. Trace'i parçalamak yerine ham yanıtı
koruyan ve yalnızca tam pencere-içi trace'leri seçen şema 2 geliştirildi.

### `ob-tooling-close-002`

Başarılı şema 2 tek-komut testi:

```text
start_utc=2026-07-25T18:16:25.018Z
end_utc=2026-07-25T18:17:10.026Z

raw_log_file_count=15
verified_manifest_file_count=16
timestamp_parse_failure_count=0
timestamp_before_start_count=0
timestamp_after_end_count=0

enriched_record_count=1109
timestamp_missing_count=0
json_failure_count=0
run_id_mismatch_count=0
sequence_failure_count=0

metric_series_count=4883
metric_sample_count=47546
metric_run_id_mismatch_count=0
metric_time_failure_count=0

jaeger_service_count=8
trace_response_count=293
raw_unique_trace_count=167
boundary_excluded_trace_count=15
unique_trace_count=152
selected_span_count=806
selected_trace_json_failure_count=0
trace_run_id_mismatch_count=0
trace_time_failure_count=0

run_telemetry_verification=passed
run_finalization=passed
finalized_run_verification=passed
close_run=passed
```

Final receipt, Docker ve Minikube kapatıldıktan sonra tekrar doğrulandı.

## Kod ve config checksum'ları

```text
kustomization.yaml:
E87C27F5A083504D023FE2FD933AC95F911F5BB643224DA50B295D41A02774A8

observability.yaml:
F4D5C2AE2F86DA3EB14673F2FBB76D085F178A93DCC2821EB520EFB2B3FBD5F7

archive-run-telemetry.ps1:
AB87FEFF794C1CF444BB36F44DA53F5DA2C22D282AF5EC0238F1F0F0B76713DA

verify-run-telemetry.ps1:
295D20AF013BAF501D15C9CD676B8787B46DFD593AA00E0EFD26D7D9E0958384

close-run.ps1:
6294BF3E370FD10331C125C1718C9E7AF649BF6A0BC463670A10D17BB7D3845F

finalize-run-artifacts.ps1:
ED11BCB48F650A8842CDBAC694D6ED2019EBB94562709E42314E2ECEE4FAEB47

verify-finalized-run.ps1:
EC3DA95F4961F2F73F1C1FDAFF896A2DE16EC0474B80057BE6817DB00D3245C3
```

Checksum'lar rapor yazılmadan önceki çalışma ağacı sürümüne aittir. Nihai
commit revision ve checksum'lar Git geçmişiyle ayrıca sabitlenecektir.

## Host kararlılık kapısı

Tooling pipeline başarılı olmasına rağmen yük testi sonrasında iki yeni
WHEA-Logger Event 17 kaydı oluştu:

```text
TimeCreated=2026-07-25 21:10:01 Europe/Istanbul
Component=PCI Express Root Port
Bus:Device:Function=00:1D.5
PrimaryDevice=PCI\VEN_8086&DEV_06B5&SUBSYS_1E911043&REV_F0
```

Bu, önceki `DPC_WATCHDOG_VIOLATION (0x133)` olayıyla aynı Intel PCI Express
Root Port #14 hattıdır. MediaTek MT7921 Windows'ta devre dışı olmasına rağmen
WHEA tekrarlandı. Windows'ta adaptörü kapatmak root portu tamamen güçten
kesmemektedir.

Minikube ve Docker kontrollü biçimde durduruldu. Tooling artefact'ları cluster
dışında mühürlü kaldı.

## Karar

### Yazılım pipeline'ı

`completed / accept`

Immutable log, metric ve trace export; bağımsız doğrulama; ortak run
ID/zaman hizalama; boundary trace dışlama; final receipt ve failure receipt
kapıları çalışmaktadır.

### Host kararlılığı

`invalid / repeat`

Bu bilgisayarda aynı PCIe root portunda WHEA tekrarlandığı için bilimsel
normal run veya fault injection başlatılmamalıdır. Minidump/driver/firmware
incelemesi ve yük altında WHEA'sız stabilite kanıtı gereklidir.

### Deneye geçiş

P1-CPU-001 durumu `planned` kalır. Host kararlılık kapısı geçmeden fault
injection, SLO kalibrasyonu veya model verisi toplama yapılmaz.

# P1-NORMAL-E2E-001 — Normal Koşul E2E Telemetry Doğrulaması

- Tarih: 2026-07-25

- Dal: `researcher/p1-normal-run-e2e`

- Durum: `invalid`

- Sistem: Online Boutique v0.10.6

- Fault injection: yok

- Model eğitimi/LLM/GAT: yok

- Git revision: `da5c88b21a9fe557bcf563be9b4271c912bbd54e`

## Amaç

Benzersiz bir run ID ile normal kullanıcı akışının çalıştığını ve log, metric ve distributed trace verilerinin aynı run kapsamında uçtan uca doğrulanabildiğini sınamak.

Bu çalışma deneysel fault run değildir. P1 öncesi operasyonel E2E doğrulamasıdır.

## Tekrarlanabilir yapılandırma

Ortak run ID aşağıdaki beş noktada güncellendi:

- pod label,

- pod annotation,

- uygulama ortam değişkeni,

- OpenTelemetry resource attribute,

- Prometheus metric label.

Run ID değişikliği `p0-env/scripts/set-experiment-run-id.ps1` ile kontrollü olarak yapıldı. Script:

- eski run ID’nin beklenen 3+2 konumda bulunmasını zorunlu tutar,

- yeni run ID’ye ait ham veya derived çıktı varsa işlemi reddeder,

- kısmi yazma oluşursa iki config dosyasını geri yükler,

- sonuç dosyalarının SHA-256 değerlerini raporlar.

Negatif testte yanlış mevcut run ID reddedildi ve `files_unchanged=True` doğrulandı.

## Config ve araç checksum’ları

kustomization.yaml:

2C29B96EFB19D64CFEE7C2515209FE2CA3EFA47743F97A73D0F215A303D50B70

observability.yaml:

5922741E09B3BF11AC5773AB5F0F710CA9899F3A3F868838B4BBFA72EAE6BAB3

archive-raw-logs.ps1:

603233940C26D33BF28C4C52A382F9341E96A8B8705887D670B31EE1BD029FE1

set-experiment-run-id.ps1:

4CF85147624907FA257761132D8AAF5A3FBB424E246595D6FDAFF8F444E9B09D

## E2E-001 denemesi

Run ID: ob-normal-e2e-001

Yedi instrumented deployment hazırdı.

Run başlangıcı: 2026-07-25T12:15:36.240Z

Normal kullanıcı akışı: 5/5 HTTP 200

Ham log arşivi: 16/16 manifest girdisi doğrulandı

Salt-okunur dosya: 17/17

Toplama penceresi: 2,19 dakika

Enriched kayıt: 4.240

Eksik timestamp: 3

Eksik timestamp’lerin nedeni, gerçek içerik üretmeyen Kubernetes log çıktılarının arşivleme sırasında newline içeren yapay bir kayıt olarak yazılmasıydı.

Ham ve derived çıktılar silinmedi; aşağıdaki invalid yollarında korundu:

p0-env/artifacts/runs/_invalid/ob-normal-e2e-001-empty-log-placeholder/

p0-env/artifacts/derived/_invalid/ob-normal-e2e-001-missing-timestamp-placeholder/

Arşivleme aracı, boş log çıktısını gerçek sıfır-byte dosya olarak yazacak şekilde düzeltildi.

## E2E-002 denemesi

Run ID: ob-normal-e2e-002

Run başlangıcı: 2026-07-25T12:26:52.664Z

İlk smoke isteği, frontend port-forward kapalı olduğu için cluster’a ulaşmadı.

Port-forward yeniden açıldı.

Başarılı normal kullanıcı akışı: 5/5 HTTP 200

Ham log dosyası: 15

Manifest girdisi: 16/16 doğrulandı

Salt-okunur dosya: 17/17

Toplama penceresi: 2,38 dakika

Sıfır-byte fakat geçerli log dosyası: 4

Ham arşiv yolu:

p0-env/artifacts/runs/ob-normal-e2e-002/

Enrichment sonucu:

transform_version=log-envelope-v1

source_log_file_count=15

output_log_file_count=15

record_count=4586

missing_timestamp_count=0

Bağımsız doğrulama sonucu:

manifest_file_count=16

verified_manifest_file_count=16

ndjson_file_count=15

verified_record_count=4586

timestamp_missing_count=0

json_failure_count=0

run_id_mismatch_count=0

sequence_failure_count=0

readonly_file_count=17

failure_count=0

enriched_log_verification=passed

Derived çıktı yolu:

p0-env/artifacts/derived/ob-normal-e2e-002/

## Host kararlılık olayı

Enriched log doğrulaması çalışırken Windows aşağıdaki hata ile yeniden başladı:

DPC_WATCHDOG_VIOLATION (0x133)

Windows System log kanıtı:

WER-SystemErrorReporting Event ID: 1001

Bugcheck: 0x00000133

Minidump: C:\\WINDOWS\\Minidump\\072526-33062-01.dmp

Kernel-Power Event ID: 41

Aynı zaman aralığında Intel PCI Express Root Port #14 üzerinde çok sayıda düzeltilmiş WHEA-Logger Event 17 kaydı görüldü.

İlgili PCIe yolunda kayıtlı aygıt:

MediaTek Wi-Fi 6 MT7921 Wireless LAN Card

PCIROOT(0)#PCI(1D05)#PCI(0000)

Driver: 3.0.1.1314

Crash sonrasında aygıt Disconnected/Present=False durumundaydı. Tam kapatma ve güç döngüsünden sonra aygıt yeniden Present=True/Status=OK oldu. Wi-Fi tarama ve bağlantı testi başarılıydı. Docker ve Minikube, Wi-Fi geçici olarak devre dışıyken yeniden başlatıldı ve açılıştan itibaren whea_count_since_boot=0 doğrulandı.

Bu bulgular PCIe/Wi-Fi güç durumu sorununu güçlü şüpheli yapar; ancak minidump stack analizi yapılmadan BSOD’nin kesin nedeni olarak kabul edilmez.

## Metric ve trace geçersizliği

Crash sonrasında observability podları yeniden başladı:

jaeger restart_count=4

jaeger started=2026-07-25T13:34:22Z

prometheus restart_count=1

prometheus started=2026-07-25T13:34:23Z

Jaeger ve Prometheus için kalıcı telemetry volume’u tanımlı değildir. Cluster yeniden başlatıldığında loadgenerator, aynı ob-normal-e2e-002 run ID ile yeni telemetry üretmeye başladı.

Jaeger sorgusunda görülen trace aralığı:

trace_count=20

earliest_span_utc=2026-07-25T13:46:17.821Z

latest_span_utc=2026-07-25T13:46:24.029Z

Bu zamanlar geçerli E2E-002 toplama penceresinin dışındadır. Dolayısıyla restart sonrası trace ve metric verileri E2E-002’nin bilimsel kanıtı olarak kullanılamaz.

## Karar

Ham log arşivleme: başarılı

Parsed/enriched log doğrulaması: başarılı

Metric doğrulaması: geçersiz/kaybedilmiş

Trace doğrulaması: restart sonrası kontamine

Tam çok-modlu E2E run: invalid

Fault injection’a geçiş: durduruldu

E2E-002 hiçbir model, eşik, feature veya bilimsel sonuç üretiminde kullanılmamalıdır.

Yeni normal run’dan önce:

Her run için benzersiz run ID kullanılmalı.

Run başlangıç ve bitiş zamanı ayrı metadata dosyasına yazılmalı.

Loadgenerator, run başlamadan kontrollü duruma getirilmeli.

Metric ve trace verileri run bitiminde cluster durdurulmadan immutable dışa aktarılmalı.

Export doğrulaması tamamlanmadan run başarılı sayılmamalı.

Host kararlılığı tekrar kontrol edilmeli.

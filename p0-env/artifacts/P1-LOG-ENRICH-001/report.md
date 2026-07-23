# P1-LOG-ENRICH-001 — Parsed Log Run ID Zenginleştirmesi

- Tarih: 2026-07-23

- Aşama: P1 öncesi altyapı hazırlığı

- Dal: `researcher/p1-log-run-id-enrichment`

- Kaynak run ID: `ob-normal-telemetry-001`

- Transform sürümü: `log-envelope-v1`

- Fault injection: yapılmadı

- Deneysel veri uygunluğu: hayır; yalnızca araç doğrulamasıdır

## Amaç

Mühürlenmiş ham logları değiştirmeden, her fiziksel log satırını run ID ve

kaynak provenance alanları içeren ayrı bir NDJSON kaydına dönüştürmek.

## Veri ayrımı

Ham kaynak arşivi:

`p0-env/artifacts/runs/ob-normal-telemetry-001/`

Derived çıktı:

`p0-env/artifacts/derived/ob-normal-telemetry-001/`

Derived çıktı ham arşivin içine yazılmaz. Mevcut derived dizinin üzerine

yazılmaz. Yerel derived veriler `.gitignore` ile repository dışında tutulur.

## Kayıt şeması

Her NDJSON kaydı şu alanları içerir:

- `schema_version`

- `transform_version`

- `run_id`

- `system`

- `service`

- `pod`

- `container`

- `timestamp`

- `timestamp_status`

- `raw_message`

- `source_file`

- `source_line_number`

- `source_sha256`

Mesaj gövdesi bu aşamada semantik olarak zorla parse edilmez. Heterojen JSON,

.NET ve düz metin formatları `raw_message` içinde korunur.

## Uygulama sırasında korunan başarısızlıklar

İlk denemede PowerShell 5.1 generic liste dönüşümü hata verdi. Kısmi çıktı

silinmeden şu yerel invalid yolunda korundu:

`p0-env/artifacts/derived/_invalid/ob-normal-telemetry-001-log-envelope-v1-failed-20260723T172801961Z/`

İkinci denemede timestamp-only boş log mesajı yanlışlıkla `missing` sayıldı.

Bu çıktı da silinmeden şu yerel yolda korundu:

`p0-env/artifacts/derived/_invalid/ob-normal-telemetry-001-timestamp-only-regex/`

Regex, timestamp sonrasında mesaj bulunmayan boş log satırlarını kabul edecek

şekilde düzeltildi.

## Başarılı dönüşüm

- Kaynak ham log dosyası: 15

- Derived NDJSON dosyası: 15

- Toplam kayıt: 58.670

- Timestamp eksikliği: 0

- Durum: `sealed-read-only`

## Bağımsız doğrulama

- Manifest girdisi: 16

- Doğrulanan manifest girdisi: 16

- NDJSON dosyası: 15

- Doğrulanan kayıt: 58.670

- JSON hatası: 0

- Run ID uyuşmazlığı: 0

- Kaynak satır sırası hatası: 0

- Salt-okunur dosya: 17

- Toplam hata: 0
- Manifest dışı dosya negatif testi: reddedildi
- Salt-okunur olmayan ek dosya negatif testi: reddedildi

- Sonuç: `enriched_log_verification=passed`

## Teknik sınırlar

Kaynak ham arşiv yaklaşık 182,16 dakikalık araç doğrulama penceresidir ve

bilimsel veri olarak kullanılamaz. Bu derived çıktı da yalnızca dönüşüm

mekanizmasını doğrular.

Servis içi embedded timestamp, severity, trace ID ve message template

ayrıştırması bu iş paketinin kapsamında değildir. `raw_message` korunmuştur;

bu alanlar daha sonraki versioned parsing katmanında üretilebilir.

## Karar

Parsed logların tamamında run ID bulunması doğrulandı. Ancak yeni ve benzersiz

bir run ID ile doğru UTC penceresinde uçtan uca normal-run testi yapılmadan P1

fault deneyine geçilmemelidir.

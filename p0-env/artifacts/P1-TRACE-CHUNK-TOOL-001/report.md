# P1-TRACE-CHUNK-TOOL-001 — Zaman Parçalı Trace Export Araç Doğrulaması

- Tarih: 2026-07-28
- Dal: `researcher/p1-trace-export-chunking`
- Aşama: P1 öncesi araç geliştirme
- Durum: `completed`
- Karar: `accept`
- Bilimsel dataset kullanımı: hayır
- Fault injection: yok
- Canlı cluster deneyi: yok

## Amaç

Uzun run pencerelerinde Jaeger servis başına trace limitine ulaşılması
durumunda sessiz veri kırpılmasını önlemek ve run penceresini doğrulanabilir
zaman parçalarıyla dışa aktarmak.

Bu çalışma bilimsel bir normal veya fault run değildir. Gerçek yük altında
30 dakikalık doğrulama ayrıca yapılmadan P1 deney başlangıç kapısını kapatmaz.

## Tetikleyen bulgu

`ob-host-stability-002` kapanışında frontend servisi Jaeger sorgusunun 5.000
trace limitine ulaştı. Önceki exporter sonucu kırpılmış kabul etmek yerine
arşivi `invalid` olarak korudu.

Bu davranış veri bütünlüğü açısından doğruydu ancak uzun pencerenin
dışa aktarılmasını engelliyordu.

## Uygulanan tasarım

Telemetry metadata şeması v3'e yükseltildi.

Run penceresi varsayılan olarak 300 saniyelik sorgu parçalarına ayrılır.
Parçalar:

- mikrosaniye çözünürlüğünde sıralıdır,
- birbirleriyle örtüşmez,
- aralarında boşluk bırakmaz,
- bütün run penceresini kapsar,
- servis ve parça başına ayrı ham JSON dosyası üretir.

Son parça, dahil run bitiş noktasını korumak için hedef parça süresinden en
fazla bir mikrosaniye uzun olabilir.

Her ham parça için metadata içinde şu alanlar saklanır:

- `service`
- `path`
- `chunk_index`
- `start_microseconds`
- `end_microseconds`
- `returned_trace_count`

Servisler veya parçalar arasında tekrar dönen trace'ler global `traceID`
üzerinden tekilleştirilir. Ham yanıtlar değiştirilmeden korunur; modellemeye
aday selected küme benzersiz trace'lerden üretilir.

## Güvenli limit davranışı

Bir parçadaki trace sayısı yapılandırılmış Jaeger limitine ulaşırsa exporter:

- çıktıyı başarılı saymaz,
- daha küçük `TraceQueryChunkSeconds` kullanılmasını bildirir,
- kısmi arşivi `_invalid` altında salt okunur biçimde korur.

Bu nedenle zaman parçalama sessiz kırpılmayı gizlemez.

## Verifier kuralları

Schema v3 doğrulayıcısı:

- metadata ve manifest dosyalarını doğrular,
- manifest dışı dosyaları reddeder,
- her ham dosyanın metadata özetinde bulunmasını zorunlu tutar,
- dosyadaki gerçek trace sayısını metadata sayacıyla karşılaştırır,
- servis başına parça indekslerinin sıralı olduğunu doğrular,
- zaman parçalarında boşluk veya örtüşme bulunmadığını doğrular,
- bütün run penceresinin kapsandığını doğrular,
- hiçbir parçanın Jaeger limitine ulaşmadığını doğrular,
- selected trace ID tekrarlarını reddeder,
- run ID ve span zaman sınırlarını yeniden hesaplar.

Schema v1 ve v2 arşivleri geriye dönük olarak desteklenmeye devam eder.

## Close-run entegrasyonu

`close-run.ps1` aşağıdaki parametreleri exporter'a geçirir:

- `TraceLimitPerService`, varsayılan `5000`
- `TraceQueryChunkSeconds`, varsayılan `300`

Operatör, limit dolarsa aynı run'ı tekrar kullanmaz. Geçersiz kanıt korunur ve
yeni benzersiz tooling run daha küçük bir parça süresiyle yürütülür.

## Sentetik test

`test-trace-export-chunking.ps1` cluster gerektirmeyen kontrollü bir Minikube
API taklidi kullanır.

Pozitif fixture:

- 10 dakikalık pencere,
- iki servis,
- servis başına iki adet 5 dakikalık parça,
- toplam dört ham trace yanıt dosyası,
- servis ve parça yanıtları arasında tekrarlanan bir trace ID,
- global tekilleştirme sonrasında üç benzersiz trace.

Doğrulama sonuçları:

```text
schema_v3_fixture_verification=passed
cross_chunk_trace_id_deduplication=passed
trace_export_chunking_tests=passed
```

Negatif fixture sonuçları:

```text
chunk_gap_negative_test=passed
chunk_limit_negative_test=passed
invalid_limit_archive_preservation=passed
```

## Geriye dönük uyumluluk

Değişiklik sonrasında iki mevcut schema v2 arşivi yeniden doğrulandı:

- `ob-tooling-close-002`: doğrulama geçti
- `ob-host-stability-003`: doğrulama geçti

`ob-host-stability-003` için 497.612 metric örneği, 3.185 selected trace ve
33.417 span yeniden sayıldı; hata sayısı sıfır kaldı.

## Değiştirilen bileşenler

- `archive-run-telemetry.ps1`
- `verify-run-telemetry.ps1`
- `close-run.ps1`
- `test-trace-export-chunking.ps1`
- ilgili researcher datasheet belgeleri

## Teknik sınırlar

- Sentetik test gerçek Jaeger depolama ve sorgu performansını kanıtlamaz.
- Varsayılan 300 saniyelik parça yoğun yükte yine 5.000 sınıra ulaşabilir.
- Canlı doğrulamada limit dolarsa parça süresi azaltılmalıdır.
- Jaeger ve Prometheus kalıcı volume kullanmadığından export cluster
  durdurulmadan tamamlanmalıdır.
- Bu araç doğrulaması bilimsel dataset veya model girdisi değildir.

## Karar

Zaman parçalı exporter ve schema v3 verifier uygulaması araç düzeyinde kabul
edildi.

P1 deney başlangıç kapısı henüz kapanmadı. Birlikte yürütülecek en az
30 dakikalık gerçek yük koşusunda:

- hiçbir parça Jaeger limitine ulaşmamalı,
- parça kapsam hatası sıfır olmalı,
- trace ID tekrarları selected kümede bulunmamalı,
- bütün close-run ve finalization adımları geçmelidir.

## Sonraki doğrulama

Bu rapordan sonra `P1-TRACE-CHUNK-LIVE-001` tamamlandı. 30 dakikadan uzun
gerçek yük penceresinde 49/49 parça doğrulandı ve `close_run=passed` sonucu
alındı. Ayrıntılar:

`p0-env/artifacts/P1-TRACE-CHUNK-LIVE-001/report.md`

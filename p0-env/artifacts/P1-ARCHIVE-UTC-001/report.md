# P1-ARCHIVE-UTC-001 — UTC Toplama Penceresi Düzeltmesi

- Tarih: 2026-07-23

- Aşama: P1 öncesi altyapı hazırlığı

- Dal: `researcher/p1-archive-utc-fix`

- Fault injection: yapılmadı

- Deneysel veri üretimi: yapılmadı

## Bulgu

`archive-raw-logs.ps1` scriptine alt PowerShell süreci üzerinden bir

`System.DateTime` değeri aktarıldığında UTC değer yerel saat gibi yeniden

yorumlandı. Script içindeki `ToUniversalTime()` dönüşümü UTC+3 farkını ikinci

kez çıkardı.

Araç doğrulama arşivinde ölçülen pencere:

- Beklenen süre: yaklaşık 2 dakika

- Gerçek metadata süresi: 182,16 dakika

- `since_utc`: `2026-07-21T10:47:10.000Z`

- `capture_completed_utc`: `2026-07-21T13:49:19.8956451Z`

Bu arşiv daha önce de yalnızca araç doğrulaması olarak işaretlenmişti.

Bilimsel eğitim, validation veya test verisi olarak kullanılmayacaktır ve

silinmeyecektir.

## Düzeltme

`SinceUtc` parametresi belirsiz `datetime` yerine açık ISO-8601 UTC metni

olarak tanımlandı.

Kabul edilen örnek biçim:

`2026-07-23T16:41:24.364Z`

Uygulanan korumalar:

- Değer mutlaka `Z` ile bitmelidir.

- Yerel tarih biçimleri parametre doğrulamasında reddedilir.

- Ayrıştırma invariant culture ile yapılır.

- Değer UTC olarak korunur.

- Gelecekteki başlangıç zamanı reddedilir.

- Arşiv klasörü tarih doğrulaması tamamlandıktan sonra oluşturulur.

## Doğrulama

Belirsiz yerel tarih girdisi reddedildi:

`07/23/2026 10:15:30`

Alt PowerShell süreci round-trip testi:

- Girdi: `2026-07-23T16:41:24.364Z`

- Alt süreç çıktısı: `2026-07-23T16:41:24.364Z`

- Eşitlik: `True`

- PowerShell sözdizimi hatası: 0

- Git whitespace hatası: 0

## Karar

UTC yorumlama düzeltmesi kabul edildi. Ancak yeni ve benzersiz bir run ID ile

uçtan uca arşivleme testi yapılmadan ve parsed log run ID zenginleştirmesi

tamamlanmadan P1 deneysel veri toplamaya geçilmemelidir.

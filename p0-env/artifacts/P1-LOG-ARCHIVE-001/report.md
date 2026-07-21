# P1-LOG-ARCHIVE-001 — Ham Log Arşivi Hazırlık Doğrulaması



- Tarih: 2026-07-21

- Aşama: P1 öncesi altyapı hazırlığı

- Dal: `researcher/p1-immutable-logs`

- Sistem: Online Boutique v0.10.6

- Doğrulama run ID: `ob-normal-telemetry-001`

- Fault injection: yapılmadı

- Deneysel veri uygunluğu: hayır; yalnızca araç doğrulamasıdır



## Amaç



Ham Kubernetes container loglarının run bazında, üzerine yazma engeli,

SHA-256 manifesti ve salt-okunur dosya niteliğiyle arşivlenebildiğini

doğrulamak.



## Eklenen tekrarlanabilir araçlar



- `p0-env/scripts/archive-raw-logs.ps1`

- `p0-env/scripts/verify-raw-log-archive.ps1`



Arşivleme scripti:



- istenen run ID ile deployment'lardaki `EXPERIMENT_RUN_ID` değerini karşılaştırır,

- mevcut bir run dizininin üzerine yazmayı reddeder,

- logları pod/container bazında Kubernetes timestamp'leriyle toplar,

- Git ve deployment configuration revision bilgilerini metadata'ya yazar,

- dosyalar için SHA-256 manifesti üretir,

- arşiv dosyalarını Windows salt-okunur niteliğiyle mühürler.



Doğrulama scripti:



- manifest yollarının arşiv dışına çıkmasını engeller,

- eksik dosyaları tespit eder,

- SHA-256 değerlerini yeniden hesaplar,

- salt-okunur dosya sayısını kontrol eder,

- herhangi bir başarısızlıkta sıfırdan farklı hata sonucu üretir.



## Negatif testler



### Yanlış run ID



İstenen `ob-intentional-wrong-id`, deployment'lardaki

`ob-normal-telemetry-001` ile eşleşmediği için arşiv oluşturulmadan reddedildi.



- Sonuç: `expected_archive=absent`

### Bozuk manifest yolu

İlk araç doğrulamasında normalize edilmemiş `scripts\..\artifacts` yolu,
manifestteki göreli yolların başının kesilmesine neden oldu.

- Manifest girdisi: 16
- Doğrulanan dosya: 0
- Ham log dosyası: 15
- Salt-okunur dosya: 17
- Hata sayısı: 16
- Sonuç: `Archive verification failed`

Başarısız arşiv silinmedi ve şu yerel yolda korundu:
`p0-env/artifacts/runs/_invalid/ob-normal-telemetry-001-manifest-path-bug/`

Hata, arşiv kökünün `System.IO.Path.GetFullPath` ile manifest
hesaplamasından önce normalize edilmesiyle giderildi.
### Manifest dışı dosya

Geçerli arşivin `state` altındaki geçici kopyasına bilerek
`unexpected.txt` eklendi.

- Manifestteki doğrulanan dosya: 16
- Hata sayısı: 2
- Tespit: `unexpected_unmanifested_file:unexpected.txt`
- Tespit: `readonly_mismatch:expected=18,actual=17`
- Sonuç: `Archive verification failed`

Geçici test kopyası doğrulama sonrasında silindi; mühürlenmiş gerçek arşive
dokunulmadı.
## Başarılı doğrulama

Düzeltilmiş arşivleme sonucu:

- Run ID: `ob-normal-telemetry-001`
- Ham log dosyası: 15
- Manifest girdisi: 16
- Arşiv durumu: `sealed-read-only`

Bağımsız doğrulama sonucu:

- Manifest girdisi: 16
- Doğrulanan dosya: 16
- Ham log dosyası: 15
- Salt-okunur dosya: 17
- Hata sayısı: 0
- Sonuç: `archive_verification=passed`

Geçerli yerel arşiv:
`p0-env/artifacts/runs/ob-normal-telemetry-001/`

Yerel run arşivleri `.gitignore` ile repository dışında tutulur. Scriptler ve
bu küçük doğrulama raporu Git ile sürümlenir.

## Ham log run ID denetimi

Arşivleme sonrasında ham log içerikleri ayrıca tarandı.

- Ham log dosyası: 15
- Run ID içeren ham log dosyası: 0

`run_id`, arşiv düzeyindeki `metadata.json` dosyasında bulunmaktadır; ancak ham
container log satırlarında bulunmamaktadır. Ham dosyalar mühürlendikten sonra
değiştirilmeyecektir.

`experiment_protocol.md` gereği parsed/zenginleştirilmiş log sürümü ham
arşivden ayrı üretilmeli ve her kayda `run_id` eklenmelidir. Bu adım
tamamlanmadan arşivleme mekanizması çalışır kabul edilse de deneysel run veri
toplamaya geçilmemelidir.

## Teknik sınır

Bu mekanizma yerel Windows dosya sisteminde SHA-256 tabanlı değişiklik tespiti,
üzerine yazma reddi ve salt-okunur dosya niteliği sağlar. Donanımsal veya
bulut tabanlı WORM/object-lock depolama sağlamaz. Burada “immutable”, proje
düzeyinde mühürlenmiş ve değişiklikleri doğrulanabilir arşiv anlamındadır.

## Kapsam dışı

- Fault injection yapılmadı.
- Model eğitimi yapılmadı.
- LLM doğrulaması yapılmadı.
- GAT uygulanmadı.
- Bu araç doğrulama arşivi bilimsel eğitim/test verisi olarak kullanılmayacak.

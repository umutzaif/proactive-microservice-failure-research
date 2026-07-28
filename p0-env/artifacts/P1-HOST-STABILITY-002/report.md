# P1-HOST-STABILITY-002 — Temiz Boot Altında Host Stabilite Tekrarı

- Tarih: 2026-07-28
- Dal: `researcher/p1-host-stability`
- Sistem: ASUS TUF Gaming F15 FX506LHB
- İşletim sistemi: Windows 11 Home Single Language 25H2
- Benchmark: Online Boutique v0.10.6
- Fault injection: yok
- Model eğitimi/LLM/GAT: yok
- Amaç: deney öncesi host stability kapısını tekrar değerlendirmek
- Sonuç: `completed / accept`
- Bilimsel dataset kullanımı: hayır; tooling ve host doğrulaması

## Arka plan

Önceki `P1-HOST-STABILITY-001` çalışmasında aynı PCI Express Root Port
`00:1D.5` üzerinde WHEA-Logger Event 17 olayları oluştu.

Aynı host daha önce `DPC_WATCHDOG_VIOLATION (0x133)` bugcheck yaşamıştı.
25 Temmuz 2026 boot döneminde toplam 22 WHEA Event 17 ve bir Kernel-Power
Event 41 gözlendi.

Bu nedenle P1-CPU-001 başlatılmadı ve temiz boot altında tekrar doğrulama
zorunlu tutuldu.

## Temiz boot baseline

- Boot zamanı: `2026-07-27 20:40:09` Europe/Istanbul
- Baseline WHEA sayısı: `0`
- Baseline Kernel-Power 41 sayısı: `0`
- Ethernet: `Connected`
- Wi-Fi: `Disconnected`
- Docker Server: `29.6.1`
- Docker başlangıcı sonrası WHEA: `0`
- Cluster deploy sonrası WHEA: `0`
- Hazır deployment sayısı: `15`

## Tekrar 1 — ob-host-stability-001

İlk 30 dakikalık gözlem:

- Başlangıç: `2026-07-28T10:14:11.393Z`
- Bitiş: `2026-07-28T10:44:54.020Z`
- Örnek sayısı: `31`
- CPU aralığı: `%16–79`
- Minimum boş bellek: `2059.31 MB`
- Final WHEA sayısı: `0`

Ham ve enriched log sonucu:

- Ham log dosyası: `15`
- Doğrulanan manifest girdisi: `16`
- Enriched kayıt: `42496`
- Eksik timestamp: `0`
- Run ID uyuşmazlığı: `0`

Telemetry export şu nedenle invalid oldu:

`Prometheus response does not contain run-scoped metric samples.`

Kök neden, ConfigMap güncellendikten sonra Prometheus ve OpenTelemetry
Collector deployment'larının otomatik restart edilmemesiydi. Prometheus hâlâ
`ob-tooling-close-002` etiketini kullanıyordu.

Bu tekrar host stabilitesi açısından temizdir fakat geçerli final receipt
üretmediği için operasyonel run olarak invalid korunmuştur.

## Tekrar 2 — ob-host-stability-002

Prometheus ve OpenTelemetry Collector zorunlu restart edildi. Yeni run ID hem
deployment'larda hem Prometheus label API'sinde doğrulandı.

İkinci 30 dakikalık gözlem:

- Başlangıç: `2026-07-28T11:02:15.276Z`
- Bitiş: `2026-07-28T11:33:00.558Z`
- Örnek sayısı: `31`
- CPU aralığı: `%2–46`
- Minimum boş bellek: `2149.29 MB`
- Final WHEA sayısı: `0`

Ham ve enriched log sonucu:

- Ham log dosyası: `15`
- Enriched kayıt: `61955`
- Eksik timestamp: `0`
- Run ID uyuşmazlığı: `0`

Telemetry export şu nedenle invalid oldu:

`Jaeger trace limit reached for service 'frontend'; archive would be truncated.`

Araç, 5000 trace sınırına ulaşan cevabı sessizce kırpmak yerine run'ı
reddetti. Ham ve kısmi çıktı `_invalid` altında korundu.

Bu tekrar host stabilitesi açısından temizdir fakat trace-limit koruması
nedeniyle geçerli final receipt üretmemiştir.

## Tekrar 3 — ob-host-stability-003

Doğru run ID ve restart edilmiş observability bileşenleriyle 10 dakikalık tam
E2E kapanış gerçekleştirildi.

Gözlem penceresi:

- Başlangıç: `2026-07-28T11:54:18.819Z`
- Bitiş: `2026-07-28T12:04:35.161Z`
- Örnek sayısı: `11`
- CPU aralığı: `%16–43`
- Minimum boş bellek: `4174.20 MB`
- Final WHEA sayısı: `0`

Tam kapanış sonucu:

- Ham log dosyası: `15`
- Enriched kayıt: `14881`
- Metric serisi: `4013`
- Metric sample: `497612`
- Ham benzersiz trace: `3187`
- Tam seçilmiş trace: `3185`
- Seçilmiş span: `33417`
- Boundary-excluded trace: `2`
- Trace run ID uyuşmazlığı: `0`
- Trace zaman hatası: `0`
- `close_run=passed`
- `finalized_run_verification=passed`

Yerel artefact yolları:

- `p0-env/artifacts/runs/ob-host-stability-003/`
- `p0-env/artifacts/derived/ob-host-stability-003/`
- `p0-env/artifacts/telemetry/ob-host-stability-003/`
- `p0-env/artifacts/finalized/ob-host-stability-003/`

Bu büyük yerel artefactlar Git dışında tutulur.

## Kontrollü kapatma

Minikube ve Docker Desktop kontrollü biçimde durduruldu.

- Minikube host: `Stopped`
- Kubelet: `Stopped`
- API server: `Stopped`
- Minikube durduktan sonra WHEA: `0`
- Minikube durduktan sonra Kernel-Power 41: `0`
- Docker durduktan sonra WHEA: `0`
- Docker durduktan sonra Kernel-Power 41: `0`

## Host stability kararı

Temiz boot sonrasında:

- iki ayrı 30 dakikalık aktif yük penceresi,
- bir 10 dakikalık tam E2E pencere,
- metric, trace ve log export yükü,
- finalization ve bağımsız doğrulama,
- kontrollü Minikube ve Docker kapatma

boyunca yeni WHEA, bugcheck veya kontrolsüz restart oluşmadı.

Bu nedenle `P1-HOST-STABILITY-002` mevcut test koşulları için
`completed / accept` olarak değerlendirilmiştir.

Önceki WHEA ve bugcheck geçmişi silinmez veya geçersiz sayılmaz.
`P1-HOST-STABILITY-001` invalid kayıt olarak korunur.

## Açık teknik bulgular

### ConfigMap tüketicilerinin yeniden başlatılması

Run ID değişiminden sonra Prometheus ve OpenTelemetry Collector config'i
otomatik reload etmeyebilir. `deploy.ps1`, Kustomize apply sonrasında iki
deployment'ı zorunlu restart edecek biçimde güncellenmiştir.

### Uzun pencere trace export kapasitesi

30 dakikalık `ob-host-stability-002` penceresinde frontend servisi 5000 trace
sorgu limitine ulaştı. Araç truncation'ı reddederek doğru fail-fast davranışı
gösterdi.

Bu bulgu çözülmeden uzun süreli bilimsel run başlatılmamalıdır. Aday çözüm,
Jaeger sorgularını versioned ve çakışmasız zaman parçalarına bölerek sonuçları
trace ID düzeyinde birleştirmektir.

## Nihai karar

- Telemetry merge kapısı: geçti
- Host stability kapısı: mevcut koşullarda geçti
- Uzun pencere trace export kapasitesi: açık teknik kapı
- P1-CPU-001: trace export ölçekleme tamamlanana kadar `planned / blocklu`
- Fault injection: uygulanmadı
- Bilimsel dataset üretimi: yapılmadı
# Araştırma Kararları Kaydı

Bu belge akademik kararların, gerekçelerinin ve değişiklik geçmişinin tek kaynağıdır. Operasyonel uygulama bu kararları sessizce değiştiremez.

## Durum etiketleri

- **Kabul edildi:** Araştırma tasarımının bağlayıcı parçası.
- **Pilot varsayımı:** Pilot veriden sonra onaylanacak veya değiştirilecek.
- **Ertelendi:** İlk çalışma kapsamı dışında.
- **Açık:** Karar için kanıt veya kullanıcı seçimi gerekiyor.

## D-001 - Araştırmanın çekirdek iddiası

- Durum: **Kabul edildi**
- Karar: Hata öncesi telemetriden üretilen kalibre edilmiş hata adaylarının, kanıta bağlı LLM doğrulamasıyla filtrelenmesinin erken uyarı false-positive oranına ve root-cause service sıralamasına etkisi ölçülecek.
- Gerekçe: MULAN ve GALR nedeniyle `LLM + multimodal telemetry + graph RCA` birleşimi tek başına özgün değildir. Ayrım pre-failure horizon, leakage-free değerlendirme ve doğrulamanın ölçülebilir etkisidir.

## D-002 - İlk çalışma kapsamı

- Durum: **Kabul edildi**
- Dahil:
  - belirli horizon içinde fault-class prediction,
  - evidence-grounded LLM verification,
  - root-cause service ranking.
- Ertelendi:
  - recovery planı,
  - propagation-path ground truth ve tahmini,
  - affected-services tahmini,
  - çoklu eşzamanlı hata,
  - LLM tabanlı sayısal time-to-failure.

## D-003 - Deney platformu

- Durum: **Pilot varsayımı**
- Birincil tercih: Online Boutique.
- Yedekler: SockShop, ardından Train Ticket.
- Pilot kabul ölçütü: Seçili serviste kontrollü CPU stress uygulanabilmeli; log, metric ve trace aynı zaman ekseninde toplanabilmeli; kullanıcıya yansıyan failure/SLO zamanı enjeksiyon zamanından ayrı kaydedilebilmeli.

## D-004 - İlk hata sınıfları

- Durum: **Pilot varsayımı**
- Erken tahmin adayları: CPU stress, kademeli network delay, gelişen service degradation.
- RCA kontrol senaryosu: Ani pod kill/failure.
- Kural: Doğal öncül sinyali bulunmayan ani hata “erken tahmin edildi” şeklinde raporlanamaz.

## D-005 - Zaman tanımları

- Durum: **Kabul edildi**
- `injection_start`: Pertürbasyonun başladığı zaman.
- `first_symptom`: Önceden tanımlanmış ilk telemetri semptomu.
- `failure_manifestation`: Kullanıcıya yansıyan hata veya SLO ihlalinin ilk zamanı.
- `recovery_time`: Sistemin kararlı normal duruma dönüş zamanı.
- Kural: `injection_start`, otomatik olarak `failure_manifestation` kabul edilmeyecek.

## D-006 - Pencere ve horizon

- Durum: **Pilot varsayımı**
- Pencere: 5 saniye.
- Gözlem: 30 pencere / 150 saniye.
- Ana prediction horizon: 30 saniye.
- Duyarlılık analizi: 15 ve 60 saniye.

## D-007 - Veri bölme

- Durum: **Kabul edildi**
- Ayrım birimi: Bağımsız fault run/incident.
- Yasak: Aynı koşudan türetilen komşu pencerelerin train, validation ve test kümelerine dağılması.
- Ek testler: unseen severity/workload ve mümkünse unseen service.

## D-008 - LLM rolü

- Durum: **Kabul edildi**
- LLM sınıflandırıcının yerine geçmez; temporal adayın kanıtlarla desteklenip desteklenmediğini değerlendirir.
- Çıktı: `supported`, `uncertain`, `contradicted`.
- Zorunlu alanlar: evidence ID, counter-evidence, assumptions, missing information.
- Yasak: LLM çıktısındaki serbest yüzdeyi kalibre edilmiş olasılık kabul etmek; otonom recovery eylemi yürütmek.

## D-009 - Model ilerleme sırası

- Durum: **Kabul edildi**
- Temporal: rule baseline -> logistic/XGBoost -> GRU -> gerekirse daha karmaşık model.
- RCA: anomaly/trace ranking -> tabular node ranker -> GCN -> GAT.
- Kural: Basit baseline geçilmeden daha karmaşık mimari ana model ilan edilmeyecek.

## D-010 - Birincil metrikler

- Durum: **Kabul edildi**
- Prediction: event-level AUPRC, macro-F1, false alarms/hour, event detection rate, lead time, Brier/ECE.
- LLM: false-positive reduction, recall değişimi, abstention rate, evidence precision/recall, latency ve maliyet.
- RCA: Top-1, Top-3 ve MRR.

## D-011 - Bilimsel deney başlangıç kapıları

- Durum: **Kabul edildi**
- P1-CPU-001 ancak dört bağımsız kapının tamamı geçildikten sonra başlatılabilir:
  1. **Telemetry merge kapısı - GEÇTİ:** `P1-TELEMETRY-EXPORT-001` bileşenleri PR #10 ile `main` dalına alındı; yerel `main` ve `origin/main` `f650bdd` revisionında senkronlandı.
  2. **Host stability kapısı - GEÇTİ:** `P1-HOST-STABILITY-002` kapsamında temiz boot sonrasında iki ayrı 30 dakikalık aktif yük gözlemi ile bir 10 dakikalık tam E2E kapanış tamamlandı. Yeni WHEA Event 17, bugcheck veya Kernel-Power Event 41 oluşmadı. Son koşunun log, metric, trace ve finalization doğrulamaları geçti.
  3. **Uzun pencere trace export kapısı - GEÇTİ:** `P1-TRACE-CHUNK-LIVE-001` kapsamında 30 dakikadan uzun gerçek yükte 49/49 parça doğrulandı. Maksimum parça 924/5000 trace içerdi; global trace ID tekilleştirmesi, finalization ve offline receipt doğrulaması geçti.
  4. **Schema v3 merge kapısı - GEÇTİ:** İki commit PR #12 ile `main` dalına merge edildi; yerel `main` ve `origin/main` `c29e2b2` revisionında senkronlandı.
- Pipeline'ın işlevsel olarak doğrulanması tek başına host kararlılığı veya uzun pencere veri bütünlüğü kanıtı değildir.
- Dört başlangıç kapısının tamamı geçmiştir. `P1-CPU-001`, protokoldeki benzersiz run ID, metadata, yük profili ve kontrollü fault koşulları korunarak başlatılabilir.
- `P1-HOST-STABILITY-001`, önceki boot dönemindeki WHEA ve bugcheck kanıtıyla `invalid` olarak korunur; `P1-HOST-STABILITY-002` bu kaydı silmez.
- Açık kapılar sırasında üretilen telemetry yalnızca tooling veya altyapı doğrulaması olarak etiketlenir ve bilimsel dataset'e alınmaz.

## D-012 - Normal baseline workload tekrarlanabilirliği ve metadata mühürleme

- Durum: **Kabul edildi mevcut protokolün teknik uygulaması**
- `P1-CPU-001` normal baseline workload'u, repository içinde sürümlenen bir JSON profil ile sabitlenir. Profil; image, kullanıcı sayısı, spawn rate, bekleme dağılımı, task ağırlıkları, seed, Locust/Faker sürümleri ve `locustfile.py` SHA-256 değerini içerir.
- Aynı pozitif seed hem Python `random` hem Faker üreticisine çalışma zamanında uygulanır. Seed'in yalnız metadata'ya yazılması yeterli kabul edilmez.
- Bilimsel metadata; run kimliği, kod/config revisionları, workload profile kimliği/hash'i, UTC evreleri ve run öncesi/sonrası host-health sayaçlarını içerir. Geçerli metadata ve profil final receipt içine kopyalanıp checksum ile mühürlenir.
- Alternatifler: Upstream loadgenerator'ı seedsiz kullanmak reddedildi; özel image üretmek bu aşamada gereksiz bakım ve supply-chain yüzeyi oluşturduğu için ertelendi.
- Fayda: Aynı deney girdisinin sonradan bağımsız olarak incelenmesi ve metadata ile gerçek deployment arasındaki uyuşmazlıkların reddedilmesi.
- Bedel: Aynı seed eşzamanlı isteklerin tamamlanma sırasını deterministik yapmaz; Faker tekrar üretilebilirliği aynı sürüm ve aynı çağrı sırasına bağlıdır. Bu sınırlılık workload profilinde açıkça tutulur.
- Bu karar workload ve kanıt bütünlüğünü uygular; run süresini, fault protokolünü, SLO'yu veya akademik kapsamı değiştirmez.

## D-013 - Deployment sonrası etkin run-ID kapısı

- Durum: **Kabul edildi mevcut protokolün teknik geçerlilik kapısı**
- Karar: Bilimsel lifecycle, collector ve Prometheus için beklenen run ID'nin ConfigMap, pod rollout ve runtime kanıtları aynı anda doğrulanmadan başlatılmaz. Prometheus'ta beklenen kimlikle gerçek metric serisi oluşması zorunludur.
- Gerekçe: `ob-cpu-normal-001`, ConfigMap güncel olduğu halde Prometheus process'i eski config'i bellekte tuttuğu için run-scoped metric üretmeden tamamlandı ve `invalid` oldu.
- Alternatifler: Operatörün elle rollout restart yapmasına güvenmek kırılgan olduğu için tek başına reddedildi. Yalnız ConfigMap metnini kontrol etmek çalışan process durumunu kanıtlamadığı için reddedildi. Her run için yeni observability image üretmek gereksiz bakım maliyeti nedeniyle seçilmedi.
- Uygulama: Run ID, collector ve Prometheus pod-template annotation'ına eklenir; değişiklik otomatik rollout tetikler. Bağımsız verifier ConfigMap, canlı pod annotation, Prometheus runtime config ve run-scoped metric query katmanlarını sınar.
- Fayda: Yanlış run-ID ile sessiz metric kaybı bilimsel pencere başlamadan reddedilir; operatörün doğru komutu hatırlamasına bağımlılık azalır.
- Bedel ve sınırlılık: Kapı deployment süresini en fazla tanımlı metric bekleme timeout'u kadar uzatır. Collector için doğrudan etkin-config API'si bulunmadığından ConfigMap + yeni pod annotation + Ready durumu birlikte dolaylı runtime kanıtıdır.
- Bu karar workload, süre, fault sınıfı, SLO veya akademik kapsamı değiştirmez.

## D-014 - İlk CPU-stress hedef servisi

- Durum: **Kabul edildi pilot kalibrasyon kararı**
- Karar: İlk CPU-stress kalibrasyon hedefi `recommendationservice` olarak seçildi.
- Gerekçe: Geçerli `ob-cpu-normal-002` normal-baseline penceresinde recommendationservice ortalama 11,962 mCPU, p95 41,982 mCPU ve 1.078 kullanıcı-yolu spanı üretti; checkoutservice karşılıkları 1,225 mCPU, 7,074 mCPU ve 340 spandır. Recommendationservice 539 düzenli `ListRecommendations` çağrısı ve basit ProductCatalog bağımlılığıyla fault etkisini zaman içinde ölçmek için daha güçlü adaydır.
- Alternatif: `checkoutservice`, daha geniş downstream kullanıcı etkisi ve zengin JSON logları nedeniyle değerlendirildi; ancak aynı workload'ta yalnız 26 `PlaceOrder` çağrısı bulunması ilk CPU ramp kalibrasyonunda seyrek örnekleme riski oluşturdu.
- Fayda: Daha yoğun normal trafik, ölçülebilir CPU sinyali ve daha basit causal yol; hedef etkisi ile downstream semptom ayrımını kolaylaştırır.
- Bedel ve sınırlılık: Karar tek geçerli normal baseline'a dayanır ve fault yanıtını kanıtlamaz. Servis içindeki seed edilmemiş Python `random.sample` öneri içeriğine değişkenlik ekler. İlk kalibrasyon semptom veya gecikmeli SLO etkisi üretmezse hedef karar protokole göre yeniden açılır.
- Karar workload profilini, SLO'yu, fault şiddetini veya run zaman çizelgesini değiştirmez.

## Açık kararlar

| ID | Soru | Karar için gerekli kanıt | Hedef aşama |
|---|---|---|---|
| O-001 | Online Boutique yerel ortamda sürdürülebilir biçimde çalışıyor mu? | Yazılım smoke testi ve temiz boot host stability tekrarı geçti; uzun pencere trace export kapısı bekleniyor | P1 öncesi |
| O-002 | Hangi servis CPU-stress pilotu için en uygun? | Çözüldü: `ob-cpu-normal-002` normal-baseline karşılaştırmasıyla `recommendationservice` seçildi; checkoutservice alternatif olarak korundu | Pilot P0 |
| O-003 | Failure manifestation için ana SLO nedir? | Üç geçerli normal run'da 180 tam pencere analiz edildi: pencere-p95 latency p99 4.279,712 ms, 2.219 istekte hata 0. Kaynak/log/trace kanıtı `/` gecikmesi için koşulsuz `metadata.google.internal.` DNS lookup'unu güçlü hipotez yapıyor; benchmark patch, route-specific SLO veya mevcut global eşik arasında karar ve A/B kanıtı gerekli | Pilot P1 |
| O-004 | Kaç bağımsız run gerekli? | Pilot varyansı ve olay oranı | Dataset v1 öncesi |
| O-005 | Kullanılacak LLM ve sürüm hangisi? | Erişim, maliyet, tekrarlanabilirlik | LLM aşaması |
| O-006 | Mevcut host nasıl kararlı hale getirilecek veya hangi alternatif host kullanılacak? | Çözüldü: temiz boot, Ethernet kullanımı ve Wi-Fi’nin devre dışı bırakılması altında `P1-HOST-STABILITY-002` geçti | P1 öncesi |
| O-007 | Uzun deney pencerelerinde Jaeger trace verisi kayıpsız nasıl dışa aktarılacak? | Çözüldü: schema v3 ile 49/49 parça doğrulandı; maksimum parça 924/5000 trace | P1 öncesi |

## Değişiklik kaydı

| Tarih | Karar | Değişiklik | Gerekçe |
|---|---|---|---|
| 2026-07-15 | D-001–D-010 | İlk sürüm oluşturuldu | Literatür değerlendirmesi ve kapsam daraltma kararı |
| 2026-07-27 | D-011 | Host stability ve telemetry merge bağımsız deney başlangıç kapıları olarak eklendi | P1-TELEMETRY-EXPORT-001 geçti; P1-HOST-STABILITY-001 WHEA Event 17 nedeniyle başarısız oldu |
| 2026-07-27 | D-011 | Telemetry merge kapısı kapatıldı; yalnız host stability kapısı açık kaldı | PR #10 iki commit ile merge edildi; `main` ve `origin/main` `f650bdd` revisionında senkron |
| 2026-07-28 | D-011 | Host stability kapısı kapatıldı; uzun pencere trace export kapısı eklendi | `P1-HOST-STABILITY-002` temiz boot altında WHEA ve Kernel-Power olayı olmadan geçti; `ob-host-stability-002` Jaeger 5.000 trace sınırında güvenli biçimde reddedildi |
| 2026-07-28 | D-011 | Uzun pencere trace export için schema v3 araç uygulaması tamamlandı; kapı canlı doğrulama bekliyor | Zaman parçalama, global trace ID tekilleştirme, boşluk ve limit negatif testleri geçti; bilimsel run başlatılmadı |
| 2026-07-28 | D-011 | Uzun pencere trace export canlı doğrulaması geçti; yalnız schema v3 merge kapısı açık kaldı | `ob-trace-chunk-live-001` 49/49 parçayı, 9.441 selected trace'i ve 100.056 spanı hatasız doğruladı |
| 2026-07-28 | D-011 | Schema v3 merge kapısı kapatıldı; P1 deney başlangıç kapılarının tamamı geçti | PR #12 iki commit ile merge edildi; `main` ve `origin/main` `c29e2b2` revisionında senkronlandı |
| 2026-08-02 | D-012 | Normal workload profili, çalışma zamanı seed uygulaması ve bilimsel metadata/receipt mühürleme kararı eklendi | Protokoldeki versioned workload, random seed, UTC lifecycle ve immutable kayıt şartlarını ilk bilimsel run öncesinde uygulanabilir ve bağımsız doğrulanabilir hale getirmek |
| 2026-08-02 | D-013 | Deployment sonrası ConfigMap, pod rollout, Prometheus runtime config ve run-scoped metric kapısı eklendi | `ob-cpu-normal-001` run'ında ConfigMap ile çalışan Prometheus config'i ayrıştı ve zorunlu metric modalitesi oluşmadı |
| 2026-08-02 | D-012 | Final receipt metadata doğrulamasında özgün 1–7 basamaklı UTC lifecycle değerlerinin korunması uygulandı | `ob-cpu-normal-002` ilk finalization denemesinde milisaniyeye kısaltılmış karşılaştırma değerleri metadata başlangıç/bitiş uyuşmazlığı üretti; immutable veri arşivleri değişmeden özgün UTC aktarımıyla doğrulama geçti |
| 2026-08-02 | D-014 | İlk CPU-stress kalibrasyon hedefi `recommendationservice` olarak seçildi | Normal-baseline filtreli CPU, memory, kullanıcı-yolu spanı, çağrı sıklığı, topoloji sadeliği ve log/kod yorumlanabilirliği checkoutservice ile karşılaştırıldı |
| 2026-08-02 | D-012 | Normal-baseline penceresi için tüm 15 deployment'ın pod UID ve restart sayısı başlangıç/bitiş kanıtına eklendi | Ölçüm sırasında sessiz pod değişimi veya restart oluşmadığını yalnız hedef servis için değil tüm deney sistemi için falsifiye edilebilir hale getirmek; süre, workload, fault veya SLO kararını değiştirmez |

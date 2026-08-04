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
| O-003 | Failure manifestation için ana SLO nedir? | Çözüldü: `p1-cpu-001-slo-v1`; `/product/{id}` window-p95 `>345,992 ms` veya global frontend error rate `>0`, ilgili koşul art arda 3 dolu 5 sn pencere. Boş pencere zinciri keser. Üç normal run replay'inde yanlış manifestation 0 | Pilot P1 |
| O-004 | Kaç bağımsız run gerekli? | Pilot varyansı ve olay oranı | Dataset v1 öncesi |
| O-005 | Kullanılacak LLM ve sürüm hangisi? | Erişim, maliyet, tekrarlanabilirlik | LLM aşaması |
| O-006 | Mevcut host nasıl kararlı hale getirilecek veya hangi alternatif host kullanılacak? | Çözüldü: temiz boot, Ethernet kullanımı ve Wi-Fi’nin devre dışı bırakılması altında `P1-HOST-STABILITY-002` geçti | P1 öncesi |
| O-007 | Uzun deney pencerelerinde Jaeger trace verisi kayıpsız nasıl dışa aktarılacak? | Çözüldü: schema v3 ile 49/49 parça doğrulandı; maksimum parça 924/5000 trace | P1 öncesi |
| O-008 | CPU fiziksel-etki coverage kapısı gerçek 5 sn Prometheus scrape aralığıyla nasıl tanımlanmalı? | Çözüldü: D-018 ile her 300 sn fazda beklenen 60 gerçek aralığın en az 48'i (%80) zorunlu kılındı. `ob-cpu-low-002` invalid kaldı; değişiklik yalnız `cpu-recommendation-low-v2` ve yeni `ob-cpu-low-003` için geçerlidir | Sonraki low calibration öncesi |

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
| 2026-08-03 | D-015 | P1-CPU-001 manifestation kuralı fault verisi görülmeden `p1-cpu-001-slo-v1` olarak donduruldu | `/` DNS gecikmesi global latency nüfusunu baskılarken `/product/{id}` hedef recommendationservice ile semantik uyum ve 179/180 pencere kapsaması sağladı. Alternatifler global latency, `/`-hariç tüm rotalar ve sabit yüzde error eşiğiydi. Route kapsamı daha dar ve üç-run üst kuyruğu değişken; buna karşılık normal-p99 + üç ardışık pencere kuralı normal replay'de 0 yanlış manifestation verdi. Global error guard diğer kullanıcı hatalarını korur. Fault duyarlılığı henüz bilinmez; sonuç sonrası eşik gevşetilemez |
| 2026-08-03 | D-016 | İlk düşük CPU kalibrasyon profili `cpu-recommendation-low-v1` olarak fault verisi öncesi donduruldu | Kullanıcı onayıyla recommendationservice için yaklaşık 50m ek talep, 120 sn ramp ve 300 sn sabit evre seçildi. Deployment CPU limitini değiştirmek rollout; node-geneli stress tek-hedef ihlali yaratacağından mevcut konteynerde hash-pinned, zaman-sınırlı Python duty-cycle worker seçildi. Fiziksel kabul için iki 300 sn evrede en az 240 CPU intervali ve steady-baseline mean farkı en az 25m olmalı; throttling raporlanır. Talep yaklaşık olduğundan Prometheus kanıtı zorunlu, komut başarısı yetersizdir. Profil sonucu görülünce değiştirilemez |
| 2026-08-04 | D-017 | P1-CPU-001 SLO pencereleri `normal_baseline_start_utc` noktasına sabitlendi ve cooldown sonuna kadar faz sınırlarında yeniden hizalanmadan sürdürüldü | Kullanıcı açıkça onayladı. Alternatif injection başlangıcında yeniden hizalamaydı; bu seçenek fault zamanını feature üretimine sızdırıp manifestation/lead-time değerini birkaç saniye oynatabilirdi. Sabit grid pre/post karşılaştırılabilirliği ve falsifiye edilebilirliği artırır. Bedeli, injection başlangıcının pencere ortasına düşebilmesi ve ilk fault penceresinin karma içerikli olabilmesidir; gerçek injection UTC ayrıca korunur |
| 2026-08-04 | D-018 | CPU fiziksel-etki coverage kapısı `cpu-recommendation-low-v2` ile her 300 saniyelik baseline ve steady fazında en az 48 gerçek CPU-rate intervali olarak düzeltildi | `ob-cpu-low-002`, Prometheus kaynak serisinin tam 5 sn cadence ile faz başına yaklaşık 60 interval ürettiğini gösterdi; v1'deki 240 interval ulaşılamazdı. Kullanıcı %80 coverage olan 48/60 seçeneğini açıkça onayladı. Alternatif, scrape aralığını 1 sn'ye indirip yeni normal baselines toplamaktı; daha yüksek veri hacmi, ek altyapı değişkeni ve karşılaştırılabilirlik maliyeti nedeniyle seçilmedi. Hedef, +50m talep, +25m kabul büyüklüğü, workload, seed, SLO, 120 sn ramp, 300 sn steady ve cooldown değişmedi. Sınırlılık: %80 kapı kısa eksiklikleri tolere eder; gerçek interval sayısı ve cadence her run'da yine raporlanmalıdır. `ob-cpu-low-002` retroaktif kabul edilmez ve invalid kalır; ilk aday `ob-cpu-low-003` olur |
| 2026-08-04 | D-019 | Fault lifecycle UTC üretimi canonical trailing-`Z` biçimine bağlandı ve verifier geçersiz UTC'yi süre aritmetiğine sokmadan fail-closed raporlayacak | `ob-cpu-low-003` fiziksel etki ve telemetry kapılarını geçmesine rağmen injector `+00:00`, verifier ise `Z` üretti/bekledi; failure-list dönüş değeri `op_Subtraction` hatasına yol açtı ve final receipt oluşmadı. Alternatif olarak mevcut run'ı sonradan finalize etmek reddedildi; sonuç görüldükten sonra kapanış kapısını yeniden çalıştırmak immutable close-run zincirini zayıflatır. `ob-cpu-low-003` invalid kalır. Düzeltme yalnız UTC'nin eşdeğer gösterimini canonical hale getirir; fault, workload, SLO, coverage veya akademik kapsamı değiştirmez. Yeni aday `ob-cpu-low-004` olacaktır |
| 2026-08-04 | D-020 | İlk geçerli düşük CPU kalibrasyonunun tekrarlanabilirliği, koşulları değiştirilmemiş iki bağımsız tekrar (`ob-cpu-low-005`, `ob-cpu-low-006`) ile sınanacak | `ob-cpu-low-004` fiziksel CPU etkisini ve geçerli null manifestation sonucunu yalnız bir run'da gösterdi. Kullanıcı iki tekrarı açıkça onayladı. Alternatif olarak doğrudan severity artırmak reddedildi; tek-run sistem varyansı ile severity etkisini karıştırabilirdi. Her tekrar ayrı run ID, canonical revision, artifact, host ve receipt kapılarıyla yürütülür. Fayda, düşük profil etki/manifestation varyansını ölçmektir. Bedel, iki ek uzun lifecycle ve düşük şiddette yeniden null manifestation üretme olasılığıdır; bu sonuçlar yine geçerli bilimsel kanıttır |

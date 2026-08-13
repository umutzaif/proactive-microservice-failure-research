# Pilot Deney Planı: Online Boutique CPU Stress

## 1. Amaç

Bu pilotun amacı yüksek doğruluklu nihai model üretmek değil, proaktif hata tahmininin veri açısından mümkün olup olmadığını belirlemektir.

Ana soru:

> Kontrollü ve kademeli CPU stress altında, kullanıcıya yansıyan SLO ihlalinden önce tekrar edilebilir log, metric veya trace sinyalleri oluşuyor mu?

## 2. Hipotezler

- H1: CPU stress ramp başladıktan sonra `failure_manifestation` öncesinde latency, queue/retry, span duration veya error eğilimlerinden en az biri düzenli biçimde değişir.
- H2: Bu sinyaller sabit bir 30 saniyelik horizon içinde normal koşullardan olay-bazlı olarak ayrılabilir.
- H3: Enjeksiyon başlangıç zamanı ile manifestation zamanı arasında pozitif ve koşullar arasında değişken bir lead time vardır.

H1 reddedilirse hata profili, hedef servis veya SLO tanımı değiştirilmeden doğrudan ana dataset üretimine geçilmez.

## 2.1 Başlatma durumu - 28 Temmuz 2026

- Telemetri yazılım hattı: **Doğrulandı.** `P1-TELEMETRY-EXPORT-001` tamamlandı, kabul edildi ve PR #10 ile `main` dalına alındı.
- Host stability: **Geçti.** `P1-HOST-STABILITY-002` kapsamında temiz boot altında iki ayrı 30 dakikalık aktif yük gözlemi ve bir 10 dakikalık tam E2E kapanış tamamlandı. Yeni WHEA Event 17, bugcheck veya Kernel-Power Event 41 oluşmadı.
- Ham log, enriched log, metric, trace ve finalization hattı: **Kısa pencerede geçti.** `ob-host-stability-003` koşusunda `close_run=passed` sonucu alındı.
- Uzun pencere trace export: **Geçti.** `P1-TRACE-CHUNK-LIVE-001` koşusunda 49/49 parça doğrulandı; en yoğun parça 924/5000 trace içerdi ve `close_run=passed` sonucu alındı.
- Trace export iyileştirmesi: **Canlı yükte doğrulandı.** Schema v3 zaman parçalama, global trace ID tekilleştirme, sentetik testler, finalization ve offline receipt doğrulaması geçti.
- Schema v3 ana dala alınma durumu: **Tamamlandı.** PR #12 iki commit ile merge edildi; yerel `main` ve `origin/main` `c29e2b2` revisionında senkronlandı.
- `P1-CPU-001`: **planned/başlatılabilir.**

Telemetry merge, host stability, uzun pencere trace export ve schema v3 merge kapıları kapanmıştır. Bilimsel run'lar deney protokolündeki benzersiz run ID, metadata, yük profili, zaman sınırları ve immutable artefact kurallarına göre başlatılabilir.
## 3. Pilot aşamaları

### P0 - Ortam ve gözlemlenebilirlik

- Online Boutique'in sabit bir sürümünü kur.
- Normal kullanıcı yolunu ve servis graph'ını çıkar.
- Log, Prometheus uyumlu metric ve OpenTelemetry trace toplandığını doğrula.
- Run ID'nin üç modalitede izlenebilir olduğunu doğrula.
- Normal yükte 30–60 dakikalık stabilite ölçümü yap.

Çıktı: ortam envanteri, topoloji, telemetri schema örnekleri, normal performans özeti.

### P1 - Hedef servis seçimi

En az iki aday servis için kısa yük testleri yap. Seçim ölçütleri:

- kullanıcı yolunda bulunması,
- CPU baskısının downstream semptom oluşturması,
- normal koşulda stabil olması,
- tek hata hedefinin açıkça etiketlenebilmesi,
- kod ve logların yorumlanabilir olması.

Seçim araştırma karar kaydına işlenir.

### P2 - Fault profile kalibrasyonu

Üç kademeli profil tasarla:

- düşük: semptom oluşturur, SLO ihlali oluşturmayabilir,
- orta: gecikmeli SLO ihlali üretir,
- yüksek: belirgin fakat anlık olmayan ihlal üretir.

Ramp süresi, sabit fault süresi ve kaldırma süresi versioned configuration olarak kaydedilir.

### P3 - Veri toplama

Geçici hedef:

- 3 şiddet x 2 yük seviyesi x en az 2 tekrar = en az 12 fault run,
- her yük seviyesi için en az 3 normal run = en az 6 normal run.

Run sırası randomize edilir. Aynı fault profilleri arka arkaya zorunlu olarak çalıştırılmaz. Başarısız run'lar tekrar edilse bile kayıttan çıkarılmaz.

D-030 ikinci workload kapısı, fault run'larından önce fault'suz 10/15/20-user
kapasite karşılaştırması yapar. Seçilen workload için önce üç geçerli
normal baseline, sonra low/medium/high başına iki fault run toplanır. Seed
`20260810` ile sıra `medium-2, low-2, high-1, high-2, low-1, medium-1` olarak
sonuçlardan önce dondurulmuştur. Kapasite tooling koşuları dataset'e girmez.
Kapasite sonucu `selected_users=null` oldu: 15 ve 20 user request-intensity
kapısını geçti fakat `<=25m` recommendationservice mean-CPU kapısını geçmedi.
Bu nedenle üç normal baseline ve altı fault run'lı conditional plan O-010
çözülene kadar aktive edilmez. O-010, D-033 ile çözüldü: 15-user ikinci workload,
değişmeyen `200m` limit ve `50/100/150m` fault fiziği altında prospektif
`normal mean CPU <=40m` kapısıyla seçildi. Önce `ob-cpu-15u-normal-001/002/003`,
ardından aynı randomize sıra workload'a özgü profillerle yürütülür. Ön-kayıt
canonical `main` üzerine merge edilmeden hiçbir run başlatılmaz.
`ob-cpu-15u-normal-001` bütün host/pod/log/schema-v3/metadata/final receipt ve
bağımsız replay kapılarıyla geçerli tamamlandı; manifestation null, mean CPU
`39,807m` oldu. 15-user normal blok `1/3` tamamlandı; `002/003` öncesinde fault
başlatılmaz.
`ob-cpu-15u-normal-002` aynı koşullarda fault olmadan yürütüldü; host `0/0/0`, pod,
raw/enriched ve schema-v3 bağımsız replay kapıları geçti. Ancak frozen latency SLO'su
üç ardışık 5 saniyelik pencerede aşılarak manifestation ürettiği için run `invalid`
korundu ve dataset'e alınmadı. Geçerli blok `1/3` kalır; yeni benzersiz replacement
ID ile aynı koşullar tamamlanmadan fault başlatılmaz.
`ob-cpu-15u-normal-003` aynı frozen koşullarda bütün host/pod/log/schema-v3,
metadata, final receipt ve bağımsız replay kapılarıyla geçerli tamamlandı;
manifestation null, mean CPU `41,816m` oldu. Bu değer D-033 seçim kapısının run
dışlama kuralına dönüşmediğini değiştirmez. 15-user normal blok `2/3` olur;
`002` yerine yeni benzersiz replacement tamamlanmadan fault başlatılmaz.
`ob-cpu-15u-normal-004`, `002` replacement'ı olarak aynı frozen koşullarda bütün
host/pod/log/schema-v3/metadata/final receipt ve bağımsız replay kapılarıyla geçerli
tamamlandı; manifestation null, mean CPU `22,585m` oldu. Geçerli 15-user normal
seti `001/003/004` ve blok `3/3` tamamlandı; `002` invalid kalır. Randomize fault
sırasındaki ilk öğe `ob-cpu-15u-medium-002` olsa da canonical run-ID/profil bağı
merge edilip canlı preflight geçmeden fault başlatılmaz.
`ob-cpu-15u-medium-002` warm-up ve normal baseline sonrasında, fault worker başlamadan
injector allowlist'inin 15-user profil kimliğini tanımaması nedeniyle `invalid/incomplete`
kapandı; fault uygulanmadı ve ID korunur. D-036 ile injector/metadata profil
sözleşmeleri eşitlenir; merge sonrasında randomize ilk slot aynı koşullarda yeni
`ob-cpu-15u-medium-003` ID ile tamamlanır. Sonraki sıra öğesine geçilmez.
`ob-cpu-15u-medium-003` full fault lifecycle/cooldown ve tanısal `59/59`,
`+99,972m`, manifestation null, host `0/0/0`, log/schema-v3 replay kanıtlarını
üretti; fakat dış 40 dakikalık timeout scientific metadata/final receipt öncesinde
runner'ı sonlandırdı. Run `invalid/incomplete` ve dataset dışı kalır. D-037 ile
dış timeout en az 60 dakika olur; ilk randomize slot `medium-004` ile tamamlanmadan
`low-002`ye geçilmez.
`ob-cpu-15u-medium-004`, D-037 altında 65 dakikalık dış bütçeyle bütün lifecycle,
host/pod, fiziksel-etki, raw/enriched/schema-v3, metadata, final receipt ve bağımsız
replay kapılarını geçti. Coverage `59/59`, CPU farkı `+94,454m`, manifestation null
ve host farkı `0/0/0` oldu. İlk randomize slot tamamlandı; canonical sonuç merge ve
yeni run-ID/profil bağı sonrasında ikinci dondurulmuş slot `low-002` olur.
`ob-cpu-15u-low-002`, Minikube hazır olmadığı için ilk active run-ID kapısında,
warm-up/baseline/fault başlamadan `invalid/incomplete` kapandı. Kanıt korunur ve ID
yeniden kullanılmaz. Cluster ayrı readiness kapısından geçirildikten sonra aynı
frozen ikinci slot yeni `ob-cpu-15u-low-003` ID ile tamamlanır; canonical merge
öncesi yeni fault başlatılmaz.
`ob-cpu-15u-low-003`, active run-ID/workload ve 300+300 sn ön evreleri geçtikten
sonra bounded worker exec anında `server` container bulunamadığı için fault öncesi
`invalid/incomplete` kapandı. Host farkı `0/0/0`; ID ve hata kanıtı korunur. İkinci
randomize slot tamamlanmış sayılmaz. Yeni replacement öncesi hedef pod/container
restart-stability süresi ve exec-yarışı fail-closed politikası ön-kaydedilip canonical
merge edilmelidir.
D-038 ile hedef pod/container warm-up öncesinde 5 saniyede bir 120 saniye gözlenir;
Ready, pod UID, container ID ve restart sayısı değişemez. Worker öncesi aynı kimlik
yeniden doğrulanır ve retry yapılmaz. Bu hazırlık fault lifecycle'a eklenmez; mevcut
300/300/120/300/300 süreleri değişmez. İkinci randomize slot yeni benzersiz
`ob-cpu-15u-low-004` ile, D-038 ve kimlik bağı canonical merge edildikten sonra
tamamlanır.
`ob-cpu-15u-low-004`, D-038 altında 25 stabilite gözlemi/restart `0` ile başladı;
coverage `59/59`, CPU farkı `+49,153m`, manifestation null, host `0/0/0` ve bütün
pod/log/schema-v3/metadata/final receipt/offline replay kapılarıyla geçerli kapandı.
İkinci randomize slot tamamlandı. Canonical sonuç merge ve run-ID bağı sonrasında
üçüncü dondurulmuş slot `ob-cpu-15u-high-001` olur.

## 4. Run zaman çizelgesi

Başlangıç önerisi:

| Evre | Süre | Kullanım |
|---|---:|---|
| Reset/health check | Duruma bağlı | Geçerlilik kontrolü |
| Warm-up | 5 dk | Dataset dışında |
| Normal baseline | 5 dk | Negatif/pre-fault veri |
| CPU ramp | 2–5 dk | Pre-failure gelişim |
| Sabit stress | 5 dk | Manifestation gözlemi |
| Fault removal | Anlık/kontrollü | Recovery başlangıcı |
| Cooldown | 5 dk | Recovery analizi |

Süreler P0 ve ilk iki kalibrasyon run'ından sonra güncellenebilir.

## 5. Pilot özellikleri

Karmaşık embedding yerine önce yorumlanabilir özellikler:

- servis CPU ortalama/maksimum/eğim,
- memory,
- request rate,
- error rate,
- latency mean/p95 ve eğim,
- span duration mean/p95,
- failed span oranı,
- retry/timeout sayısı,
- warning/error log sayısı,
- yeni log template sayısı,
- upstream/downstream servislerde aynı özellikler.

## 6. Pilot analizleri

1. Her run için injection, symptom ve manifestation işaretli zaman serisi grafikleri.
2. Normal ve pre-failure pencerelerin dağılım karşılaştırması.
3. Lead-time dağılımı.
4. Eksiklik ve timestamp-hizalama raporu.
5. Basit rule/logistic/XGBoost baseline ile grouped validation.
6. Hangi özelliklerin yalnızca enjeksiyon sonrasında değil, manifestation öncesinde değiştiğinin kontrolü.

Pilot sırasında LLM ve GAT eğitilmeyecek. Önce veri ve etiket fizibilitesi kanıtlanacak.

## 7. Başarı ve durdurma ölçütleri

### Dataset v1'e geçiş için

- Geçerli fault run oranı kabul edilebilir düzeyde olmalı.
- Manifestation zamanı kuralla ve tekrar edilebilir biçimde saptanabilmeli.
- Fault run'ların anlamlı bölümünde en az 15–30 saniyelik pozitif lead time bulunmalı.
- En az bir basit model olay-bazlı değerlendirmede chance/rule baseline'dan tutarlı biçimde iyi olmalı.
- Sonuç yalnızca tek bir yük veya şiddet profiline bağlı olmamalı.

### Revizyon gerektiren durumlar

- Stress doğrudan anlık çöküş oluşturuyorsa ramp yavaşlatılır.
- Hiç SLO ihlali oluşmuyorsa hedef servis/şiddet değiştirilir.
- Enjeksiyon başlangıcı model için kolay bir yapay işaret bırakıyorsa schedule ve fault aracı gözden geçirilir.
- Pre-failure sinyal yoksa CPU stress yalnızca RCA sınıfı yapılır ve farklı gelişen hata seçilir.

## 8. Pilot teslim paketi

- Ortam ve sürüm manifesti
- Servis topolojisi
- Fault/workload profilleri
- Run manifesti
- Veri kalite raporu
- Normal performans ve SLO önerisi
- Zaman serisi pilot grafikleri
- Basit baseline sonuçları
- Dataset v1'e geçiş kararı ve gerekçesi

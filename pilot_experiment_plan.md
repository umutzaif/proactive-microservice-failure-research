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
`ob-cpu-15u-high-001`, D-038 25 gözlem/restart `0`, coverage `59/58`, CPU farkı
`+135,160m`, throttling `99,790m`, manifestation null ve host `0/0/0` ile bütün
pod/log/schema-v3/metadata/final receipt/offline replay kapılarını geçti. Üçüncü
randomize slot tamamlandı. Canonical sonuç merge ve run-ID bağı sonrasında dördüncü
dondurulmuş slot `ob-cpu-15u-high-002` olur.
`ob-cpu-15u-high-002`, D-038 25 gözlem/restart `0`, coverage `59/59`, CPU farkı
`+145,710m`, throttling `137,848m`, manifestation null ve host `0/0/0` ile bütün
pod/log/schema-v3/metadata/final receipt/offline replay kapılarını geçti. Dördüncü
randomize slot tamamlandı; fault bloğu `4/6` olur. Canonical sonuç merge ve run-ID
bağı sonrasında beşinci dondurulmuş slot `ob-cpu-15u-low-001` olur.
`ob-cpu-15u-low-001`, D-038 25 gözlem/sabit restart `1`, coverage `59/59`, CPU
farkı `+53,044m`, throttling `77,737m`, manifestation null ve host `0/0/0` ile
bütün pod/log/schema-v3/metadata/final receipt/offline replay kapılarını geçti.
Beşinci randomize slot tamamlandı; fault bloğu `5/6` olur. Canonical sonuç merge ve
run-ID bağı sonrasında altıncı ve son slot `ob-cpu-15u-medium-001` olur; yürütme
ayrı sohbetten başlatılır.
`ob-cpu-15u-medium-001` full fault lifecycle, D-038 25 gözlem/sabit restart `3`,
coverage `60/59`, CPU farkı `+100,390m`, manifestation null, host `0/0/0` ve
raw/enriched/schema-v3 replay kanıtlarını üretti. Ancak warm-up UTC süresi
`299,9970699 sn` ile frozen 300 saniye kapısının `0,0029301 sn` altında kaldı;
metadata verifier `warmup_too_short` ile reddetti ve final receipt oluşmadı. Run
`invalid/incomplete` ve dataset dışı korunur; ID yeniden kullanılmaz, eşik
gevşetilmez. Fault bloğu geçerli olarak `5/6` kalır ve kapanmaz; replacement,
metodoloji veya sonraki aşama kararı otomatik verilmez.
D-039 ile warm-up/baseline/cooldown bitiş UTC'leri, kaydedilmiş başlangıçtan en az
300 saniyelik deadline görülmeden üretilemez; verifier eşiği ve bilimsel lifecycle
değişmez. Invalid `medium-001` yerine aynı workload/seed/medium profil/D-038/SLO/
coverage koşulları yeni benzersiz `ob-cpu-15u-medium-005` için ön-kaydedilir.
D-039 kodu, testi ve run-ID bağı canonical `main` üzerine merge edilmeden replacement
fault başlatılmaz. Geçerli fault bloğu bu sırada `5/6` kalır.
`ob-cpu-15u-medium-005`, D-038 25 gözlem/sabit restart `1`, D-039 korumalı
warm-up/baseline/cooldown, coverage `59/59`, CPU farkı `+93,519m`, throttling
`69,644m`, manifestation null ve host `0/0/0` ile bütün pod/log/schema-v3/metadata/
final receipt/offline replay kapılarını geçti. Altıncı geçerli fault slotu tamamlandı;
ikinci-workload normal blok `3/3`, fault blok `6/6` ve geçerli bilimsel run sayısı
`21` olur. Low/medium/high iki-run mean artışları `51,098/93,987/140,435m` ve
manifestation sonucu altı run'da null'dır. Bu kapanış yalnız fiziksel actuation'ın
betimsel tekrarını destekler; model, LLM, GAT veya sonraki metodoloji aşamasına
otomatik geçiş yetkisi vermez.

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

P1-CPU-001 kapanış denetiminde 35 attempt'in 21'i geçerli, 14'ü invalid ve korunmuş
olarak sayıldı. Geçerli set 6 normal ve 15 fault run'dır. İki workload/üç severity
fiziksel actuation tekrarlanabilirliğini destekler; fakat geçerli fault manifestation
`0/15` ve pozitif lead-time örneği `0` olduğu için dağılım karşılaştırması ile
rule/logistic/XGBoost grouped validation bilimsel olarak tanımlanamaz. 21/21 geçerli
run archive/run-ID/UTC/schema-v3/final-receipt replay kapılarını geçmiştir; feature
window üretilmediğinden feature-level missingness henüz ölçülmemiştir. Ayrıntı
`p0-env/artifacts/P1-CPU-001-CLOSURE-001/report.md` içindedir.

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

Mevcut kapanış Dataset v1 geçişini durdurur; CPU stress'i RCA-only yapma veya farklı
gelişen fault seçme kararını otomatik vermez. Bu seçenekler yeni açık akademik karar
ve ayrı ön-kayıt gerektirir.

D-040 kullanıcı onayıyla bu açık kararı kapattı: CPU stress geçmiş sonuçları ve
etiketleri değiştirilmeden RCA-only korunur; sonraki erken-tahmin adayı kademeli
network delay'dir. Bilimsel run'a geçmeden önce `P2-NETWORK-DELAY-DESIGN-001`, iki
workload'ta hedef-edge yoğunluğunu, injector izolasyonunu (`netem`/açık proxy/mesh),
fiziksel etkiyi, cleanup'ı ve yalnız normal kanıttan dondurulacak manifestation
sözleşmesini tamamlar. Bu tasarım kapısı fault, model, LLM veya GAT yetkisi vermez.

`P2-NETWORK-DELAY-DESIGN-001` bu kapsamda tamamlandı. Altı sealed normal run'ın
tamamında ve iki workload'ta görülen `recommendationservice -> productcatalogservice`
edge'i seçildi; ayrıcalıksız digest-pinned Toxiproxy sidecar, `750 ms` hedef delay,
`>=500 ms` ölçülmüş median etki kapısı, normal-veriden dondurulmuş ilk-semptom ve
network-delay SLO'su D-041'e bağlandı. Tooling mock/negatif fixture, Kubernetes render
ve toksicsiz gerçek-imaj API testlerini geçti. Sonraki aşama fault içermeyen canlı
overlay/proxy-overhead ve pod continuity kapısıdır; tasarım sonucu bilimsel run ID
veya fault yürütmesini otomatik yetkilendirmez.

`P2-NETWORK-DELAY-PROXY-LIVE-001`, 15-user yüksek workload'ta valid tamamlandı.
No-toxic proxy base'e göre `+0,3415 ms` target-edge median overhead üretti ve frozen
`<=5 ms` kapısını geçti; iki koşulda coverage `60/60`, proxy SLO manifestation null,
ölçüm içi bütün podlar kararlı, host farkı `0/0/0`, rollback temiz ve offline receipt
`90/90` oldu. Bu D-042 compatibility kanıtıdır; network-delay scientific run'ı veya
fault başlatmayı yetkilendirmez. Sonraki aşama benzersiz run ID içeren ayrı scientific
ön-kayıttır ve yürütme yine ayrıca kullanıcı onayı gerektirir.

D-043 ile bu ayrı ön-kayıt tamamlandı. `ob-netdelay-15u-001`, 15 user/rate 1/seed 1,
aynı target edge, 12 adımlı `0 -> 750 ms` ramp ve `300/300/120/300/300` lifecycle'a
bağlandı. Etki/coverage, first-symptom, manifestation, cleanup, host/pod, schema-v3 ve
offline receipt kapıları sonuçtan önce donduruldu; invalid kanıtın silinmeyeceği ve
ID'nin tekrar kullanılmayacağı kaydedildi. Birleşik verifier `13/13` geçti ve fault
başlatılmadı. Sonraki aşama, bu commit canonical `main`e merge edildikten ve kullanıcı
ayrıca onay verdikten sonra fresh runtime kapılarıyla ilk scientific run'dır.

`ob-netdelay-15u-001` bu sözleşmeyle yürütüldü fakat invalid/incomplete kapandı.
Fresh kapılar, warmup, baseline ve 120,094 saniyelik `0 -> 750 ms` ramp geçti;
PowerShell 7 JSON okuyucusunun `ramp_end_utc` değerini `System.DateTime`a çevirmesi,
locale string dönüşümünde canonical `Z` bilgisini kaybettirdi ve steady deadline
guard fail-closed durdu. Steady/cooldown tamamlanmadı; fiziksel etki ve manifestation
değerlendirilmedi. Emergency cleanup/rollback, host `0/0/0`, raw/enriched/schema-v3
verifier'ları ve invalid offline receipt geçti. ID tekrar kullanılmaz; replacement ve
tooling düzeltmesi bu sonuç kaydından ayrı ön-kayıt/commit gerektirir.

D-044 bu ayrımı uygular: PowerShell 7 typed JSON UTC değeri invariant canonical `Z`
biçimine dönüştürülür, locale string reddedilir. `ob-netdelay-15u-002` ayrı replacement
olarak ön-kaydedilir; D-043 workload/target/ramp/lifecycle ve bütün bilimsel eşikleri
değişmez. Bu tooling/preregistration commit'i fault yürütmez; canonical merge ve yeni
açık kullanıcı onayı gerekir.

`ob-netdelay-15u-002` tam lifecycle ve bilimsel aday kapıları geçti: target-edge
coverage `60/60`, baseline/steady median `5,300/756,702 ms`, fark `+751,402 ms`,
first symptom `13:07:44.987Z` ve latency manifestation `13:08:39.987Z`; pod,
cleanup/rollback, host `0/0/0` ve schema-v3 doğrulandı. Buna rağmen generic close-run
metadata verifier CPU'ya özgü `severity` alanını istedi ve final receipt kapısı
başarısız oldu. Protokol gereği run invalid, modeling dışı ve ID kullanılamazdır.
Invalid receipt çalışma anında geçti; Windows read-only/Git line-ending taşınabilirliği
ayrı tooling sınırlılığı olarak kaydedilir. Replacement/finalizer düzeltmesi ayrı
ön-kayıt ve commit gerektirir.

D-045 bu ayrık commit’i uygular: generic metadata katmanı `fault_class` üzerinden
CPU ve network-delay verifier’larını fail-closed yönlendirir; invalid receipt v2
canonical-JSON hash ile satır-sonu dönüşümlerinden bağımsız doğrulanır. Değişmeyen
replacement `ob-netdelay-15u-003` yalnız ön-kayıtlıdır. Bu commit fault yürütmez;
canonical merge, yeni açık onay ve bütün fresh kapılar gerekir.

`ob-netdelay-15u-003` fresh base deployment, active run-ID/workload ve statik proxy
overlay kapılarını geçti; canlı proxy sözleşmesi rollout sonrasında pod sayısını tam
`1` görmeyince `live_proxy_pod_count_mismatch` ile fail-closed durdu. Warmup ve fault
başlamadı. Rollback ve host `0/0/0` geçti; oluşmayan raw/enriched/metric/trace
modaliteleri invalid-preflight receipt'te açıkça bağlandı ve offline replay `7/7`
geçti. ID kullanılamaz; eşikler değişmez. Replacement ayrı tooling/ön-kayıt ister.

D-046 proxy rollout sonrası `120 sn / 5 sn` bounded tek-Ready-pod convergence kapısını
ve bütün exception yolları için cluster-stop sonrası host-after kaydını ekler. Zero,
multiple, container-not-ready ve pod-not-ready fixture'ları reddedilir. Değişmeyen
`ob-netdelay-15u-004` yalnız ön-kayıtlıdır; merge, yeni açık onay ve fresh kapılardan
önce fault yürütülmez.

`ob-netdelay-15u-004` bounded convergence kapısında 22 gözlem üretti: ilk iki pod
sayısı `2`, sonraki 20 pod sayısı `1`, fakat birleşik Ready sonucu `0/22` idi.
`live_proxy_single_ready_pod_timeout` warmup/fault öncesi fail-closed durdu. Rollback,
finally host-after `0/0/0` ve invalid-preflight receipt `8/8` geçti. Timeout/eşik
değiştirilmez; mevcut özet hangi readiness bileşeninin başarısız olduğunu ayırmadığı
için replacement öncesi ayrı no-fault ayrıntılı tanı gerekir.

No-fault readiness tanısı `ob-network-proxy-readiness-003` ile eksiksiz kapandı.
180 saniye/33 gözlemde proxy `33/33` Ready ve `0` restart; server `30/33` Ready ve
`1` restart idi. Tek canlı all-Ready pod ilk gözlemden `16,616` saniye sonra oluştu.
Olaylar server 8080 probe timeout'unu, proxy logları normal başlangıcı gösterdi;
rollback ve host `0/0/0` geçti. Kalıcı 120 saniyelik failure iki ayrıntılı tanıda
yeniden üretilmedi. `004`te per-container kanıt olmadığından kesin retrospective kök
neden iddia edilmez; eşik değişikliği veya replacement bu tanı sonucunun parçası değildir.

D-047 ayrı replacement kararını kaydeder. `120 sn / 5 sn` convergence ve D-043
workload/target/ramp/lifecycle/fiziksel-etki/manifestation eşikleri değişmez; runner
yalnız pod UID/deletion timestamp/phase/conditions ile container readiness/restart/
state ayrıntısını her gözlemde arşivler. `ob-netdelay-15u-005` yalnız ön-kayıtlıdır;
canonical merge, ayrıca açık kullanıcı onayı ve bütün fresh kapılar olmadan fault
başlatılmaz.

`ob-netdelay-15u-005` aynı dondurulmuş convergence kapısında invalid/incomplete
kapandı. 22 gözlemde ilk pod count 2, sonraki 21 count 1; birleşik Ready `0/22` idi.
Proxy `22/22` Ready ve 0 restart kaldı; yeni server yalnız `1/22` Ready oldu, restart
sayısı `0 -> 4` yükseldi ve son durum CrashLoopBackOff/son termination exit 137 Error
idi. Warmup/fault başlamadı. Rollback, host `0/0/0` ve invalid offline receipt `9/9`
geçti. Exit 137'nin kesin nedeni iddia edilmez; ID kullanılmaz ve replacement ayrı
karar/ön-kayıt gerektirir.

Faultsuz `ob-network-server-termination-001` tanısı doğrudan restart nedenini kapattı:
33 gözlemde proxy `33/33` Ready/0 restart, server en çok 5 restart ve CrashLoopBackOff;
events 5 kez `failed liveness probe, will be restarted` kaydetti. Server probe gRPC
8080, timeout 1 sn, period 5 sn, failure threshold 3 idi. Node pressure önce/sonra
false, container status OOMKilled değil Error/137 idi; rollback/host `0/0/0` geçti.
Metrics API bulunmadığından 1 saniyelik probe timeout'unun altında CPU starvation,
runtime stall veya başka neden ayrıştırılamadı. Replacement/probe/resource değişikliği
bu sonuçta belirlenmez.

O-019 için faultsuz `ob-network-probe-resource-001`, aynı 180/5 saniye penceresinde
13 cAdvisor metric türünü 37 örnekle kapattı. Yeni server/proxy 33/33 Ready ve 0
restart kaldı; 5 readiness ve 1 liveness timeout Killing'e dönüşmedi. CPU mean/max
`32,466/373,423m`, throttled-period `%11,84`, CPU pressure yaklaşık `7,55 sn`;
memory max `33,242/450 MiB`, failcnt/OOM/memory-pressure `0` idi. Restart olmadığı
için CPU gözlemleri liveness kill'in nedeni olarak yorumlanamaz. Ayrıca host WHEA
count `881 -> 879` non-monotonic olduğundan diagnostic invalid/incomplete'tir; ID
kullanılmaz, O-019 açık kalır ve replacement belirlenmez.

D-048, bu ölçüm kusurunu System günlüğünün dairesel retention davranışından ayırır.
Run başında en yüksek System `RecordId` mühürlenir; kapanışta yalnız bu sınırdan sonra
oluşan WHEA 17, Kernel-Power 41 ve bugcheck 1001 olay kimlikleri sayılır. RecordId
gerilerse log clear/reset şüphesiyle fail-closed durulur. Değişmeyen no-toxic
`ob-network-probe-resource-002` 180/5 saniye ve aynı 13 cAdvisor seriyle ön-kayıtlıdır;
henüz yürütülmemiştir. Restart yeniden üretilmezse O-019 nedensel olarak kapanmaz.

`ob-network-probe-resource-002` geçerli tamamlandı. Proxy 33/33 Ready/0 restart iken
server 1/33 Ready, maksimum 5 restart ve beş liveness `Killing` occurrence'ı üretti.
Aynı 180 saniyede 13 cAdvisor türü kapandı: CPU mean/max `40,616/499,307m`, CFS
throttled-period `363/363`, CPU pressure `+21,271 sn`; memory maksimum
`25,46/450 MiB`, failcnt/OOM/memory-pressure `0` idi. Node pressure yoktu, RecordId
host kapısı `0/0/0`, rollback ve 18-file offline replay geçti. Bu kanıt CPU kota
throttling/pressure'ı yakın mekanizma olarak güçlü destekler; tek nihai kök neden veya
replacement resource/probe ayarı bu aşamada belirlenmez.

D-050 resource-first tasarım kapısı, probe'u değiştirmeden yalnız server CPU limitini
`200m -> 500m` yapan overlay'i seçer; request `100m`, memory `220/450Mi`, workload,
proxy ve image sabittir. `ob-network-resource-compat-001` henüz yürütülmemiş no-toxic
adaydır. 120/5 target stability ve 180/5 resource ölçümünde readiness `%100`/restart
`0`, 13/13 metric/en az 175 saniye coverage, throttled-period `<0,50`, CPU pressure
`<10,635359 sn`, memory/node/RecordId-host/rollback/seal kapıları sonuçtan önce
dondurulmuştur. Canonical merge ve ayrı canlı onay scientific fault yetkisi değildir.

İlk `ob-network-resource-compat-001` yürütmesi overlay sonrası canlı deployment JSON
okumasında stdout/stderr içine karışan JSON dışı satır nedeniyle fail-closed durdu.
Stability/measurement/fault başlamadı. Rollback doğrulaması aynı parser kusuruyla
eksik kaldı; Minikube bağımsız olarak stopped, RecordId host farkı `0/0/0` ve 4/4
offline seal geçti. Run invalid/incomplete ve ID kullanılamaz; D-050 koşul/eşikleri
değişmez, replacement ayrı commit gerektirir.

D-051, JSON get çağrılarını wrapper stdout/stderr birleşiminden doğrudan kubectl stdout
kanalına taşır; native stderr parser'a katılmaz ve nonzero exit fail-closed kalır.
D-050 koşulları değişmeyen `ob-network-resource-compat-002` yürütmesinde fresh
Git/ID/host, base deployment, aktif run-ID ve workload kapıları geçti. Overlay rollout
sonrası doğrudan kubectl çıktısındaki JSON dışı `k...` satır parser'ı durdurdu;
stability/measurement/fiziksel etki başlamadı ve toxic/fault uygulanmadı. Rollback
JSON'u aynı hata nedeniyle üretilemedi; bağımsız verifier bunu eksik artifact olarak
reddetti. Minikube stopped, RecordId host `0/0/0`, 4/4 offline seal geçti. Run
invalid/incomplete ve ID kullanılamaz; eşikler değişmez, yeni replacement bu sonuç
commit'inde belirlenmez.

D-052, native JSON çağrılarında stdout ve stderr'i OS dosya yönlendirmesiyle fiziksel
olarak ayırır; yalnız stdout parse edilir, stderr diagnostic logda korunur ve nonzero
exit/boş stdout fail-closed kalır. D-050 koşul ve eşikleri değişmeyen benzersiz
`ob-network-resource-compat-003` ayrı kontrollü commit ile ön-kayıtlıdır. Canonical
merge ve ayrı canlı onay sonrasında yürütüldü. Base, aktif run-ID ve workload geçti;
ilk canlı JSON çağrısında `KJson` parametresinin PowerShell otomatik `$Args`
değişkeniyle çakışması helper'a boş argüman aktardı. Stability/measurement/fiziksel
etki başlamadı, rollback JSON'u oluşmadı ve verifier eksik artifact'i reddetti.
Minikube stopped, host `0/0/0`, seal/replay `4/4` geçti. Run invalid/incomplete ve ID
kullanılamaz; koşul/eşik değişmez, yeni replacement sonuç commit'inde belirlenmez.

D-053, `KJson` dizi parametresini PowerShell otomatik `$Args` değişkeninden ayırıp
`$KubectlArguments` olarak adlandırır; test eski adı yasaklar ve helper aktarımını
zorunlu kılar. D-050 koşul/eşikleri değişmeyen benzersiz
`ob-network-resource-compat-004` ayrı kontrollü commit ile ön-kayıtlıdır. Canonical
merge ve ayrı canlı onay sonrasında yürütüldü. 23 stability ve 34 measurement örneği
aynı UID/Ready/restart 0 ile geçti; 13/13 metric 180 saniye, throttling `18/1127`
(`%1,597`), CPU pressure `+0,535 sn`, memory/OOM/node/host temiz ve rollback geçti.
Ancak verifier hard-coded `ob-network-resource-compat-002` run-ID yazdı ve provenance
eşleşmesini gate etmedi. 19/19 seal/replay geçmesine rağmen run fail-closed invalid;
ID kullanılamaz ve fiziksel başarı scientific valid run yerine geçmez.

D-054, runner'ın başlangıçta immutable `run-manifest.json` yazmasını; verifier'ın
zorunlu expected run ID, artifact klasör adı ve manifest ID'sini eşleştirmesini sağlar.
Telemetry ID, workload, 500m/100m ve no-fault sözleşmesi de manifestten doğrulanır.
Positive ve iki negative fixture kapıyı sınar. D-050 koşulları değişmeyen benzersiz
`ob-network-resource-compat-005` ayrı commit ile ön-kayıtlıdır; canonical merge ve
ayrı canlı onay sonrasında geçerli tamamlandı. 23 stability + 34 measurement örneği
aynı UID/Ready/restart 0; 13/13 metric 180 saniye; throttling `16/1154` (`%1,386`),
CPU pressure `+0,498235 sn`; memory/OOM/node/host temiz ve rollback geçti. Expected,
klasör ve manifest `005` provenance eşleşmesi ile 19/19 seal/replay geçti. D-050/O-020
compatibility kapısı kapanır; bu sonuç scientific fault veya sonraki aşamaya otomatik
geçiş değildir.

D-055, valid 500m compatibility sonucunu scientific runner'a taşır. Yeni
`ob-netdelay-15u-006`; 500m/100m resource, RecordId host, native JSON ve run-manifest
kapılarını ekler. Workload 15/1/1, target, ramp, lifecycle, effect/SLO, schema-v3 ve
receipt eşikleri değişmez. Bu yalnız tooling/ön-kayıttır; fault canonical merge ve
ayrı açık canlı onay olmadan başlamaz.

`ob-netdelay-15u-006` deploy/run-ID/workload/convergence sonrası statik verifier'ın
resource overlay base dosyasını çözmemesi nedeniyle fault/warmup öncesi invalid kapandı.
Rollback, host `0/0/0` ve 6/6 seal geçti; ID kullanılamaz, eşikler değişmez.
Yeni `ob-netdelay-15u-007` yalnız statik verifier'a source design kökünü verir; deployed
500m overlay ve bütün scientific koşullar değişmez. Merge ve ayrı canlı onay gerekir.

`ob-netdelay-15u-007`, canlı onay sonrası runner'ın non-interactive `ShouldProcess`
girişinde preflight/cluster/lifecycle başlamadan invalid kapandı. Minikube stopped,
host `0/0/0` ve 5/5 diagnostic seal/replay geçti. ID kullanılamaz; koşul ve eşikler
değişmez. Replacement entrypoint sözleşmesini fixture ile sabitleyen ayrı commit ister.

D-057 replacement `ob-netdelay-15u-008`, mandatory `ExecutionApproved` kapısını korur;
`ConfirmImpact=Low` ve subprocess `-WhatIf` fixture'ı ile non-interactive giriş yolunu
sabitleyip bütün 500m bilimsel koşulları değiştirmez. Merge + ayrı canlı onay gerekir.

`ob-netdelay-15u-008` tam lifecycle'ı geçerli tamamladı: D-038 25/restart 0, coverage
60/60, median `3,238 -> 755,233 ms`, effect `+751,995 ms`, latency manifestation
`18:25:43.328Z`, host `0/0/0` ve bütün raw/enriched/schema-v3/final replay kapıları
geçti. İlk geçerli network-delay dataset adayıdır; tek run otomatik sonraki aşama veya
tekrarlanabilirlik iddiası değildir. pwsh 7 UTC-ms portability tanısı ayrı tooling
değerlendirmesi gerektirir.

D-058 ile sonraki kapı kabul edildi: raw UTC verifier önce Windows PowerShell 5.1 ve
pwsh 7 eşdeğerlik fixture'ını ve immutable `008` replay'ini geçer. Ardından `008`
randomize edilmemiş pilot olarak tutulur ve seed `20260821` ile dondurulan dört eşlenmiş
no-toxic kontrol/fault bloğu yürütülür. Sıra `F-C, F-C, C-F, C-F`dir. Her slot ayrı
canonical merge, runtime onayı ve fresh geçerlilik kapılarına bağlıdır. Dört geçerli
çift kapanmadan varyans özeti veya sonraki örnek büyüklüğü dondurulmaz; Dataset v1,
model, LLM veya GAT aşamasına otomatik geçilmez.

Aşağıdaki D-059/D-060 akışı tarihsel planı açıklar; D-066 sonrasında yürütme yetkisi
değildir ve kalan slotları başlatamaz.

D-059 ilk çizelge slotunu `ob-netdelay-15u-repeat-001` olarak aynı frozen 500m fault
sözleşmesine bağlar. Tooling/ön-kayıt merge edilmeden ve ayrı canlı onay verilmeden
fault başlamaz. Geçerli veya invalid kapanış raporu akademik-konum şemasını ve ana tez
değer eşlemesini içerecek; sıradaki `control-001` kararı sonuçtan etkilenmeyecektir.

`ob-netdelay-15u-repeat-001` geçerli tamamlandı: D-038 25/restart 0, coverage 60/60,
fiziksel etki `+749,623 ms`, ilk semptom `29,397 sn`, latency manifestation
`104,397 sn`, host `0/0/0` ve raw/enriched/schema-v3/final receipt geçti. İlk blok
fault slotu `1/2` tamamlandı. Sonuç şemalı raporla kapandı; sıradaki değişmez slot
`control-001`dir ve ayrı tooling/merge/runtime kapıları olmadan başlamaz.

D-060, `control-001` için injection olmayan matched-interval metadata'sını, dört temiz
toxic snapshotını, `>=48/48` coverage ve null manifestation kapısını dondurur. Latency
farkına başarı eşiği konmaz. Runner/analyzer/verifier ayrı committe uygulanıp fixture
testleri ve canonical merge geçmeden canlı kontrol başlamaz.

Mentorun 2026-08-21 dönütü D-061–D-066 ile ileriye dönük yeni kapılar oluşturur.
D-058'in kalan 750ms paired slotları ve uygulanmamış D-060 control koşusu yürütülmez;
`008/repeat-001` geçerli fakat yalnız exploratory pilot olarak korunur. Yeni P2 yolu:

1. Aktif 500m deployment ve normal kuyruklardan fault/headroom hesabını mühürle.
2. 500m/100m profili altında iki workload için normal baseline'ları sıfırdan topla.
3. Liveness/readiness/health path'inin injected delay dışında kaldığını statik ve
   canlı preflight kanıtıyla doğrula.
4. `25/50/100/250/500 ms` x iki workload ladder hücrelerini, hücre başına üç geçerli
   bağımsız tekrar hedefiyle ön-kaydet; aynı run pencerelerini bağımsız sayma.
5. En az bir hücrede 2/3 manifestation ve en az 15 saniye lead-time görülmeden
   confirmatory toplama/model aşamasına geçme.
6. Confirmatory hedefi, aynı pozitif incident'larda model-vs-rule baseline için 60
   bağımsız pozitif incident ve false-alarm tahmini için ayrıca 60 bağımsız normal
   kontroldür; ladder bu sayılara katılmaz.
7. `2026-09-15` tarihine kadar geçiş hücresi bulunmazsa network delay erken-tahmin
   adayı durdurulur ve yeni fault sınıfı için açık araştırma kararı gerekir.

### D-061 headroom karar-destek kapısının mevcut durumu

`P2-NETWORK-DELAY-HEADROOM-001`, D-061 hesabının girdilerini sonuç üretmeden önce
makine-okunur biçimde tanımlar. Aktif kaynak sözleşmesi 500m/100m, workload'lar 10u ve
15u, ladder `25/50/100/250/500ms`, frozen latency eşiği `594,664ms`dir. D-063 nedeniyle
200m normal run'lar ve 750ms fault baseline pencereleri uygun girdi değildir; güncel
uygun yeni 500m normal sayısı workload başına `0/3`tür. Dolayısıyla sayısal headroom
sonucu henüz üretilemez.

D-067 ladder ile eşlenmiş no-toxic proxy overlay'i ve küçük örneklem için run-level
maximum + ön-kayıtlı ölçüm payını seçer. Pay `max(5ms, üç run özetinin max-min aralığı)`;
seed `20260821` sırası `15u-001,15u-002,10u-001,10u-002,15u-003,10u-003`tür. Bu
seçimler sonuç görülmeden dondurulmuştur; fault yetkisi vermez.

D-067 runner/tooling'i P2 headroom normallerini eski P1 CPU normal runner'ından ayırır.
Pre/post `toxics=[]`, 120 saniye hedef pod stabilitesi, canlı 500m/100m server ve 100m
proxy kaynak sözleşmesi, 60/48 product window coverage, null manifestation, pod/host,
schema-v3, rollback ve final receipt kapıları zorunludur. İlk immutable sıra slotu
`ob-netdelay-500m-normal-15u-001`dir; aktif run/workload bağı ayrı committe yapılır.

İlk slotun bilimsel penceresi tamamlanmış olsa da kapanışta PowerShell `$Host`
değişken çakışması scientific metadata ve final receipt'i engelledi; bu nedenle D-068
ile immutable invalid kapatıldı ve tanısal `299,901ms` headroom girdisi değildir.
Yalnız bu operasyonel değişken adı düzeltildikten ve regresyon testi geçtikten sonra,
aynı dondurulmuş koşullar altında yeni `ob-netdelay-500m-normal-15u-004` ID'si ilk
slotu telafi eder. Sonraki beş run'ın randomize sırası değişmez.

`15u-004` bilimsel pencere ve metadata üretimini tamamladı ancak bağımsız metadata
verifier'ın eski ID allowlist'i final receipt öncesi kimliği reddetti. D-069 bu koşuyu
da immutable invalid tutar; tanısal `605,978ms` kullanılmaz. Yeni `15u-005` telafisinden
önce runner/verifier kalan run-ID kümeleri çapraz regresyon testine bağlanır ve verifier
başarısız kontrolü açıkça raporlar. Bilimsel koşullar ve sonraki randomize sıra değişmez.

`15u-005` metadata 15/15 geçtikten sonra shared finalizer'ın top-level `random_seed`
beklentisinde invalid kapandı. D-070 seed'i normal metadata ve receipt zincirinde açıkça
eşler; tanısal `1082,282ms` kullanılmaz. İlk slot aynı koşullarda `15u-006` ile telafi edilir.

`ob-netdelay-500m-normal-15u-006` tüm bilimsel ve operasyonel kapanış kapılarını geçerek
ilk geçerli 15u normal girdiyi verdi: run-level maksimum `539,155ms`, coverage 60/60,
manifestation null ve final receipt replay geçti. Güncel uygunluk 15u `1/3`, 10u `0/3`;
headroom hesabı ve akademik severity kararı hâlâ blokludur.

D-067 etkili sıranın sonraki slotu `ob-netdelay-500m-normal-15u-002`dir. Workload,
topoloji, kaynaklar, süreler, coverage, manifestation ve kapanış ölçütleri değişmez;
aktif run bağı ayrı immutable committe yapılır. `15u-006` sonucu bu koşunun eşiklerini
veya kabul ölçütlerini değiştirmez.

`ob-netdelay-500m-normal-15u-002` de tüm kapanış kapılarıyla geçerli tamamlandı;
run-level maksimum `374,397ms`, coverage 60/60 ve manifestation null. Güncel 15u
uygunluğu `2/3`tür. `15u-006` ile iki-run betimsel spread `164,758ms` olsa da D-067
max/range hesabı üç geçerli run gerektirdiğinden ara headroom sonucu üretilmez.

D-067 etkili sıranın sonraki slotu `ob-netdelay-500m-normal-10u-001`dir. Aktif
loadgenerator `ob-default-10u-1r-v1` profiline (10 user/rate1/seed1) bağlanır; proxy
topolojisi, 500m/100m/100m kaynak sözleşmesi, süreler ve tüm kapanış ölçütleri değişmez.

`ob-netdelay-500m-normal-10u-001` tüm kapanış kapılarıyla geçerli tamamlandı;
run-level maksimum `612,248ms`, coverage 60/60 ve manifestation null. Maksimum frozen
`594,664ms` eşiğini aşsa da üç ardışık ihlal oluşmadı. Güncel uygunluk 10u `1/3`,
15u `2/3`; headroom ve severity kararı blokludur.

PR #87 merge sonrası D-067 etkili sıranın sonraki slotu
`ob-netdelay-500m-normal-10u-002`dir. `ob-default-10u-1r-v1`, no-toxic overlay,
500m/100m/100m kaynak sözleşmesi, 300/300 süreleri ve bütün kapanış kapıları aynıdır.
Bu normal run ladder/fault yetkisi değildir ve pencere sayısı bağımsız incident sayılmaz.

`ob-netdelay-500m-normal-10u-002` base deployment availability kapısında warm-up
öncesi invalid kapandı. Recommendationservice availability timeout verdi; best-effort
rollback rollout da timeout olduktan sonra Minikube durdu, host farkı 0/0/0 kaldı.
10u uygunluğu `1/3` değişmez. Timeout/probe/resource veya bilimsel eşik gevşetilmez;
yeni replacement'tan önce ayrı no-fault readiness tanısı ya da fresh stability kanıtı gerekir.
Bu tanı/replacement sırası D-071 önerisidir ve otomatik akademik karar değildir.

Kullanıcı 2026-08-27'de D-071'in yalnız faultsuz base readiness/stability tanısını
onayladı. `ob-network-base-readiness-001`, mevcut base manifest ve 10u workload ile,
proxy/resource overlay ve toxic olmadan 900 sn / 5 sn convergence; Available sonrasında
180 sn / 5 sn sabit UID/server readiness/restart kanıtı toplar. Dataset/headroom dışıdır.
Başarı bile replacement yetkisi vermez; yeni normal için yeni ID ve ayrı D-067 ön-kaydı gerekir.

İlk tanı `ob-network-base-readiness-001`, Docker Linux engine bulunmadığı için Minikube
başlamadan invalid/incomplete kapandı. Deployment veya recommendationservice gözlemi
başlamadı; host `0/0/0` ve dört dosyalık diagnostic seal/replay geçti. ID kullanılmaz.
Erken hata yolundaki bitişik PowerShell `throw` tokenization kusuru testle düzeltilir;
Docker readiness sonrası aynı D-071 koşulları yeni `ob-network-base-readiness-002` ile
telafi edilir. Bu operasyonel telafi replacement normal run yetkisi değildir.

`ob-network-base-readiness-002` için Docker Engine `29.7.2`, contract testi ve `WhatIf`
geçti; Minikube node containerı oluştu fakat Kubernetes API server süreci hiç başlamadı
ve `K8S_APISERVER_MISSING` ile preflight kapandı. Deployment, workload, convergence ve
stability pencereleri başlamadı; toxic/fault yoktur. Cluster stopped, host `0/0/0` ve
dört çekirdek dosyalık SHA replay geçti. Semantik readiness verifier'ın observation ve
assessment yokluğunda geçmemesi beklenen fail-closed sonuçtur. `002` kullanılmaz;
D-067 sayımı 15u `2/3`, 10u `1/3` kalır. Sonraki tanı veya normal replacement otomatik
yetkili değildir.

D-073 kapsamında kullanıcı yalnız faultsuz `ob-k8s-bootstrap-001` altyapı tanısını
onayladı. Eski profile/container/volume/log metadata korunur; exact profile silme ve
container/volume yokluğu doğrulanır. Değişmeyen v1.34.0, 4 CPU, 6144 MiB, 32 GiB ve
containerd ile temiz cluster başlatılıp 180/5 saniye system-only stability gözlenir.
Online Boutique, workload, toxic ve fault uygulanmaz. Sonuç application veya normal
replacement yetkisi vermez ve D-067 sayımını değiştirmez.

`ob-k8s-bootstrap-001` geçerli tamamlandı. Exact profile silme sonrası container/volume
yokluğu geçti; aynı v1.34.0/4 CPU/6144 MiB/32 GiB/containerd clean cluster başladı ve
180/5 saniyede 30/30 system örneği sağlıklı kaldı. Host `0/0/0`, cluster stop, semantic
verifier ve 12/12 SHA replay geçti. Stale karışık state hipotezi desteklenir ama tek
kök neden kanıtlanmaz. D-067 15u `2/3`, 10u `1/3` kalır; recommendationservice tanısı
ve replacement normal run hâlâ ayrı karar/onay ister.

D-074 kapsamında yeni benzersiz `ob-network-base-readiness-003`, D-073 sonrasında hâlâ
eksik olan application-level recommendationservice readiness/stability gözlemi için
ön-kaydedilir. D-071'in base manifest + 10u, overlay/toxic yok, 900/5 convergence ve
Available sonrası 180/5 sabit UID/server Ready/restart koşulları değişmez. Canlı tanı
yalnız canonical merge ve ayrı runtime onayıyla yürütülebilir. Başarı bile replacement
normal veya fault yetkisi vermez; D-067 sayımı değişmez.

`ob-network-base-readiness-003`, canonical merge ve runtime kapılarından sonra Minikube
API server süreci altı dakika içinde hiç oluşmadığı için `K8S_APISERVER_MISSING` ile
invalid/incomplete kapandı. Deployment, 10u workload, convergence ve stability gözlemi
başlamadı; cluster stopped, host `0/0/0` ve dört çekirdek dosyanın SHA replay'i geçti.
ID kullanılmaz. D-073 tarihsel kanıtı korunur; sonraki tanı/replacement ayrı karar ister.

D-076 `ob-minikube-state-postmortem-001`, iki host-side Minikube root'u ayrıştırmak ve
D-075 sonrası durmuş repository-local profile'ın erişilebilir postmortem kanıtını silmeden
toplamak için ön-kayıtlıdır. External/resolved/expected root, exact container/volume,
profile config, host-side lastStart ve Docker/Minikube logları kaydedilir. Root mismatch,
Docker yokluğu, eksik exact profile/container veya running container artifact öncesi
fail-closed kapıdır. Profile delete/start, bootstrap, application/workload/fault yoktur;
canonical merge ve ayrı runtime onayı gerekir.

İlk D-076 runtime çağrısı Docker kapalıyken artifact oluşturmadan durdu; ID kullanılmadı.
Windows PowerShell 5.1 native stderr'i beklenen `docker_engine_not_ready` kapısından önce
terminating `NativeCommandError` yaptı. D-077, stdout/stderr/exit code'u geçici dosyalarda
ayıran ortak capture helper'ı ve success/nonzero fixture'larıyla hata taksonomisini düzeltir.
D-076 kapsamı, kimliği ve ayrı runtime kapısı değişmez.

D-076 runtime'ı canonical `8f88f70` revisionında read-only tamamlandı. Resolved ve
expected repository-local state root eşleşti; Docker `29.7.2`, exact container `exited`,
restart `0`, `OOMKilled=false`, exit `130`; exact volume, profile config ve lastStart
kaynakları yakalandı. Minikube last-start logu `K8S_APISERVER_MISSING` ve API server
sürecinin hiç görünmediğini korudu. Hiçbir profile/container/cluster/application/workload/
fault mutasyonu yapılmadı; semantic verifier ve 9/9 SHA replay geçti. Çıktı provenance'ı
kapatır fakat tek kök neden veya sonraki runtime yetkisi vermez; D-067 sayımı değişmez.

D-079 `ob-k8s-bootstrap-observe-001`, D-076'nın stopped-state live-journal sınırını
prospektif olarak kapatır. Preserved repository-local profile silinmez; exact container
başlangıçta stopped olmalıdır. Değişmeyen v1.34.0/4 CPU/6144 MiB/32 GiB/containerd start
çağrısı sırasında en çok 420/5 saniye container/control-plane process örneklenir; live
container görülürse stop öncesi kubelet, containerd ve CRI kanıtı alınır. Start sonucu
ne olursa olsun profile stop edilir. Application/workload/proxy/toxic/fault yoktur;
canonical merge ve ayrı runtime onayı gerekir ve D-067 sayımı değişmez.

D-079 canonical `92fda127187dffdb82cff3ebd2c2975585b36c23` revisionında geçerli
operasyonel tanı olarak tamamlandı. 58 örnekte live container görüldü; kubelet eksik
`/etc/kubernetes/bootstrap-kubelet.conf` nedeniyle restart döngüsündeydi, control-plane
container'ları oluşmadı ve Minikube `K8S_APISERVER_MISSING` ile kapandı. Profile capture
sonrasında stopped, host `0/0/0`, semantic verifier ve 13/13 SHA replay geçti. Bu yakın
mekanizma benzersiz kök neden değildir. `start_exit_code=null` ve CRI capture'ın help çıktısı
üretmesi açık tooling sınırlamalarıdır. Dataset/D-067/application/replacement/fault yetkisi
oluşmadı; D-067 15u `2/3`, 10u `1/3` kaldı.

İlk D-079 runtime çağrısı `ConfirmImpact=High` non-interactive `ShouldProcess` null-reference
hatasıyla artifact ve Minikube başlangıcı öncesinde durdu; ID kullanılmadı. D-080 yalnız
`ConfirmImpact=Low` seçer ve mandatory `ExecutionApproved` ile `WhatIf` kapılarını korur.
Kubernetes/resource/süre/profile/ölçüm ve yorum sözleşmeleri değişmez.

D-081 `ob-k8s-bootstrap-state-consistency-001`, preserved profile'ı değiştirmeden D-079'un
gösterdiği existing-config restart dalını prospektif sınar. Marker/kubeconfig/manifest/etcd/
kubeadm state'i first-live ve final-live sınırlarında; non-null subprocess exit code ile exact
CRI sürümü/container listesi ayrıca yakalanır. Koşullar D-079 ile aynıdır; runtime canonical
merge sonrasında ayrı açık onay ister ve Dataset/D-067/application/replacement/fault yetkisi
üretmez.

D-081 runtime canonical `934ca07` revisionında ilk live inspect parse hatasıyla state snapshot
ve assessment öncesi invalid/incomplete durdu. İlk seal child-process dosya kilidine takıldı;
process kapanınca 7/7 replay geçti. Profile stopped ve host `0/0/0`; ID kapalı, D-067 değişmez.

D-082 `ob-k8s-bootstrap-state-consistency-002`, raw inspect'i parse öncesi korur ve shape'i
fail-closed doğrular; Minikube child/redirect handle'larını stop/seal öncesinde kesin kapatır.
Diğer D-081 koşulları değişmez. Runtime'da iki state capture shell parse hatasıyla boş
kaldı; verifier bunu yakalamadı. `002` invalid/incomplete ve kapalıdır; replacement yoktur.

D-083 offline tooling, complex native argüman sınırını iki PowerShell runtime'ında test
eder; runner ve verifier state capture exit/stdout/path semantiğini ayrı ayrı fail-closed uygular.
Sealed invalid `002` negative fixture olarak korunur. Yeni diagnostic ID veya runtime yoktur.

D-084 `ob-k8s-bootstrap-state-consistency-003`, D-083 kapılarıyla aynı preserved profile ve
v1.34.0/4 CPU/6144 MiB/32 GiB/containerd/420/5 koşullarında planned replacement'tır.
Runtime geçerli tamamlandı: iki live boundary'de existing-state marker'ları present, essential
kubelet/control-plane dosyaları missing; CRI empty ve K8S_APISERVER_MISSING. ID kapalı, D-067
değişmez; clean bootstrap/application/replacement ayrı karardır.

D-085 `ob-k8s-bootstrap-recovery-001`, korunmuş D-084 kanıtından sonra exact profile metadata,
volume ve lastStart kaydını alıp yalnız ayrı runtime onayıyla exact profile delete + yokluk
doğrulaması yapacak planlı clean-bootstrap recovery tanısıdır. Cluster sözleşmesi D-073 ile
aynıdır (v1.34.0/4 CPU/6144 MiB/32 GiB/containerd/180/5); application/workload/fault ve
Dataset/D-067 bağlantısı yoktur. Merge runtime veya delete yetkisi değildir.

D-085 runtime canonical `82f7faf` üzerinde geçerli tamamlandı. Exact delete/yokluk sonrası
clean bootstrap ve 31/31 system stability geçti; bir node Ready ve 8/8 kube-system pod Running.
Profile stopped, container exit 130/OOMKilled=false, host `0/0/0`, semantic verifier ve 12/12
replay geçti. ID kapalı, D-067 değişmez; application readiness ayrı aşamadır.

D-086 `ob-network-base-readiness-004`, D-085 sonrasında eksik kalan application-level
recommendationservice readiness/stability gözlemini kapalı `003` kimliğini kullanmadan,
değişmeyen D-071/D-074 base + 10u, 900/5 + 180/5 ve no-overlay/no-toxic/no-fault
sözleşmesiyle ön-kaydeder. Repository hazırlığı runtime değildir; canlı yürütme canonical
merge sonrasında ayrı açık onay ister. Sonuç D-067 15u `2/3`, 10u `1/3` sayımını değiştirmez.

`ob-network-base-readiness-004` canonical `64bfad6` runtime'ında Kubernetes başladı fakat
worktree-local ignored upstream source bulunmadığından base apply öncesi invalid/incomplete
kapandı. Application/workload/readiness başlamadı; stop, host `0/0/0` ve dört dosyalık
seal/replay geçti. ID kapalıdır ve D-067 değişmez.

D-087 `ob-network-base-readiness-005`, aynı application koşullarını korur ve cluster start
öncesine exact Online Boutique source HEAD `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`
kapısı ekler. Runner source fetch/copy yapmaz. Source hazırlığı, canonical merge ve runtime
ayrı onaylıdır; application eşiği veya D-067 sayımı değişmez.

`ob-network-base-readiness-005`, canonical `8c37880` ve exact source üzerinde source/start/
base apply kapılarını geçti. İlk readiness snapshot'ında erken container status nesnesindeki
eksik `containerID` doğrudan StrictMode erişimini durdurdu. Base + 10u uygulanmış olsa da
observation/assessment oluşmadı; stop, host `0/0/0` ve dört dosyalık replay geçti. ID
invalid/incomplete ve kapalıdır; D-067 değişmez.

D-088 `ob-network-base-readiness-006`, conditions/containerStatuses/containerID yokluğunu
null/gözlenmemiş olarak koruyan Pending ve ContainerCreating fixture'lı dönüşümü ön-kaydeder.
Pinned source, base + 10u, 900/5 + 180/5, no-overlay/no-toxic/no-fault ve bütün kapanış
kapıları değişmez. Canonical merge runtime değildir; yeni açık onay gerekir.

`ob-network-base-readiness-006` canonical `fc180c8` üzerinde availability, 60 observation
ve 32 stability sample tamamladı; assessment tek UID/restart 0/all Ready/no bad state ile
`fresh_base_stability_supported` üretti. Semantic verifier `$host`/`$Host` çakışmasında
durdu ve runner child exit'i reddetmeden completed marker'ına devam etti. Bu nedenle ID
invalid/incomplete ve kapalıdır; stop, host `0/0/0` ve 13-file replay geçse de D-067 değişmez.

D-089 `ob-network-base-readiness-007`, alias-safe `$hostEvidence`, PS5.1/7 sentetik valid
fixture ve nonzero child verifier exit'inde seal + fail-closed kapısını ön-kaydeder. Diğer
source/application/900/5 + 180/5/no-fault koşulları değişmez; merge runtime değildir.

`ob-network-base-readiness-007` canonical `9c6feb9` üzerinde geçerli tamamlandı. Availability,
40 observation ve 33 stability sample toplandı; stability boyunca tek UID, sabit restart `2`,
all Ready ve no bad state görüldü. İki restart convergence öncesi/sırasındaydı; stability
penceresinde yenisi olmadı. Semantic verifier, stop, host `0/0/0` ve 13-file replay geçti.
D-090 bu kanıtı Dataset-dışı operational sonuç olarak kapatır; D-067 15u `2/3`, 10u `1/3`
kalır ve normal replacement/fault ayrıca karar ve onay ister.

D-091, geçersiz/kapalı `ob-netdelay-500m-normal-10u-002` yuvasını yalnız yeni
`ob-netdelay-500m-normal-10u-004` ile telafi eder. Özgün randomize sıra değişmez ve
`10u-003` final slot kalır. 10u/rate1/seed1, no-toxic, 500m/100m/100m, 120/5,
300/300, 60/48, null manifestation ve kapanış kapıları değişmez. Bu repository hazırlığıdır;
canonical merge sonrasında ayrıca açık runtime onayı gerekir ve fault yetkisi yoktur.

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

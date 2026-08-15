# Datasheet 01 — Proje Mimarisi

## 1. Sistem neyi araştırıyor?

Araştırmanın savunulabilir çekirdeği üç aşamalıdır:

1. Hata gerçekleşmeden önceki telemetri pencerelerinden temporal bir hata
   adayı üretmek.
2. Bu adayı zaman damgalı kanıtlarla LLM'e doğrulatmak.
3. Kök neden servisini graph tabanlı yöntemlerle sıralamak.

Repository'nin mevcut kodu yalnızca bu çalışmanın güvenilir veri üretebilmesi
için gereken operasyon katmanını uygular.

## 2. Katmanlar

```mermaid
flowchart TB
    subgraph Research["Akademik sözleşme"]
        RD["research_decisions.md"]
        EP["experiment_protocol.md"]
        DC["dataset_card.md"]
        PP["pilot_experiment_plan.md"]
        RR["results_registry.md"]
    end

    subgraph Platform["Çalıştırma platformu"]
        DD["Docker Desktop"]
        MK["Minikube"]
        K8S["Kubernetes v1.34.0"]
        OB["Online Boutique v0.10.6"]
        DD --> MK --> K8S --> OB
    end

    subgraph Observe["Observability"]
        LOG["kubectl logs"]
        PROM["Prometheus / cAdvisor"]
        OTEL["OpenTelemetry Collector"]
        JAEGER["Jaeger"]
        OB --> LOG
        OB --> OTEL --> JAEGER
        K8S --> PROM
    end

    subgraph Evidence["Kanıt ve arşiv"]
        RAW["raw logs"]
        DERIVED["enriched NDJSON"]
        METRIC["Prometheus query_range JSON"]
        TRACE_RAW["Jaeger raw API JSON"]
        TRACE_SELECTED["selected complete traces"]
        RECEIPT["finalization receipt"]
        LOG --> RAW --> DERIVED
        PROM --> METRIC
        JAEGER --> TRACE_RAW --> TRACE_SELECTED
        RAW --> RECEIPT
        DERIVED --> RECEIPT
        METRIC --> RECEIPT
        TRACE_SELECTED --> RECEIPT
    end

    Research -. "kuralları belirler" .-> Platform
    Research -. "geçerlilik kuralları" .-> Evidence
```

## 3. Kontrol düzlemi ve veri düzlemi

### Kontrol düzlemi

Deneyi nasıl çalıştıracağımızı belirleyen dosyalardır:

- `p0-env/config/versions.yaml`
- `p0-env/config/online-boutique/*.yaml`
- `p0-env/scripts/*.ps1`
- run metadata ve profile dosyaları

### Veri düzlemi

Çalışan sistemden elde edilen kanıttır:

- Kubernetes log satırları
- Prometheus zaman serileri
- Jaeger trace/span kayıtları
- parsed/enriched loglar
- manifestler ve receipt'ler

Kontrol düzlemindeki bir değişiklik `deployment_revision` veya Git revision ile
izlenmeden veri düzlemine karıştırılamaz.

## 4. Güven sınırları

```mermaid
flowchart LR
    subgraph Mutable["Değişebilir çalışma alanı"]
        CONFIG["YAML config"]
        SCRIPT["PowerShell scripts"]
        CLUSTER["Running cluster memory/disk"]
    end

    subgraph Sealed["Proje seviyesinde mühürlü"]
        ARCHIVE["SHA-256 manifestli arşiv"]
        READONLY["Windows read-only files"]
        RECEIPT["Final receipt"]
    end

    subgraph Versioned["Git ile sürümlenen"]
        CODE["Scripts + configs"]
        REPORT["Küçük raporlar"]
        REGISTRY["results_registry.md"]
    end

    CONFIG --> CLUSTER
    SCRIPT --> CLUSTER
    CLUSTER --> ARCHIVE --> READONLY --> RECEIPT
    CONFIG --> CODE
    SCRIPT --> CODE
    RECEIPT -. "özet/hash" .-> REPORT --> REGISTRY
```

Windows read-only + SHA-256, proje seviyesinde değişmezlik sağlar; gerçek
donanım veya cloud WORM object lock değildir. Bu sınır raporlarda açıkça
belirtilir.

## 5. Neden Prometheus ve Jaeger içinde bırakmak yeterli değil?

Prometheus ve Jaeger deployment'larında kalıcı volume yoktur. Pod, cluster
veya host yeniden başlarsa veri kaybolabilir. Ayrıca aynı `run_id` ile
loadgenerator yeniden trafik üretirse eski run kontamine olur.

Bu nedenle run kapanırken:

- API yanıtları cluster dışına alınır,
- tam UTC sınırı kaydedilir,
- checksum manifesti üretilir,
- bağımsız verifier çalışır,
- bilimsel run ise sürümlü workload profili ile lifecycle/host-health metadata'sı doğrulanır,
- normal-baseline ölçüm penceresinin iki ucunda 15 deployment'ın pod UID ve toplam restart sayısı karşılaştırılır; değişiklik run'ı lifecycle belirsizliği nedeniyle reddeder,
- doğrulanmış metadata ve workload profili receipt dizinine checksum ile mühürlenir,
- sonra final receipt üretilir.

Normal workload'un tekrarlanabilirlik zinciri şöyledir:

`versioned JSON profile -> Kubernetes env -> Python random + Faker seed -> Locust -> scientific metadata verifier -> final receipt`

Sabit seed, kullanıcı davranışı için kullanılan sözde-rastgele üreticileri kontrol eder;
eşzamanlı isteklerin ağ ve scheduler kaynaklı tamamlanma sırasını deterministik yapmaz.
Bu nedenle profil ayrıca çalışan image, Locust/Faker sürümleri ve workload kodu
SHA-256 değerini sabitler.

Observability etkin run kimliği deployment sonrasında ayrı bir kapıyla doğrulanır:

`versioned run ID -> ConfigMap -> pod-template annotation/rollout -> canlı pod -> Prometheus runtime config -> run-scoped metric query`

Collector ve Prometheus pod-template annotation'ları run ID taşır. Kimlik değişikliği
Kubernetes rollout'unu tetikler; `verify-active-run-id.ps1` ConfigMap, canlı pod ve
Prometheus runtime API katmanlarının aynı kimliği taşıdığını doğrular. Kapı ayrıca
beklenen kimlikle gerçek metric serisi oluşmadan geçmez. Bu kontrol, yalnız YAML
dosyasının doğru olmasını çalışan process'in doğru config'i yüklediğiyle karıştırmayı
önler.

Frontend DNS A/B tooling'i, upstream checkout'u değiştirmeden `p0-env` Docker
context'inde bir patch uygular ve yerel image üretir. Test scripti loadgenerator'ı
geçici durdurur, ayrı istemci poduyla A/B/A ölçer ve `finally` bloğunda upstream
image, environment, replica ve pod durumunu geri yükler. Script yürütme başarısı
nedensel sonuç anlamına gelmez: cold-start ve DNS-cache carry-over nedeniyle
mevcut A/B attempt'leri invalid/inconclusive tutulur ve image bilimsel deployment'a
otomatik taşınmaz.

İkinci DNS A/B tasarımı, sıra/cold-start karışmasını azaltmak için upstream kontrol
ve patched treatment frontend'lerini aynı anda iki bağımsız deployment/service
olarak çalıştırır. Ayrı istemci podu sabit seed ile randomize edilen altı eşlenmiş
turda her varyanta on eşzamanlı `/` isteği gönderir. Warm-up batch'leri analizden
dışlanır; kabul ölçütleri sonuçtan önce `P1-FRONTEND-DNS-AB-002/preregistration.md`
içinde dondurulur. Geçici kaynaklar test sonunda silinir ve bu tooling çıktısı
bilimsel dataset'e otomatik girmez.

Lifecycle metadata'sı UTC değerlerini 1–7 kesir basamağıyla korur. Arşiv manifestleri
milisaniyeye normalize edebilse de scientific metadata verifier'a finalizer parametresi
olarak özgün UTC değeri aktarılır; farklı hassasiyetteki metinsel zamanlar doğrudan
eşit kabul edilmez.

Fault injector lifecycle UTC'lerini canonical trailing-`Z` biçiminde üretir.
Scientific metadata verifier geçersiz veya offset biçimli zamanı failure olarak
kaydeder, fakat null/çoklu çıktıyı duration aritmetiğine sokmaz. Böylece biçim
kusuru anlaşılır bir fail-closed sonucu verir; final receipt üretmeden run'ı
geçerli göstermez.

Hedef-servis seçimi, geçerli scientific metadata'daki normal-baseline UTC sınırını
okuyan `analyze-target-service-candidates.py` ile yeniden üretilebilir. Araç warm-up'ı,
health-check ve OTLP exporter spanlarını dışlar; cAdvisor CPU sayaç farklarını geçen
zamana bölerek millicore üretir ve adayların memory/trace/error özetini versioned JSON
olarak yazar. Invalid metadata analiz girdisi olarak reddedilir.

Normal SLI dağılımı `analyze-normal-slo-candidates.py` ile üç geçerli run'ın mühürlü
selected trace ve scientific metadata dosyalarından yeniden üretilir. Araç yalnız
frontend server spanlarını alır; health/telemetry trafiğini ve lifecycle sonundaki
eksik beş saniyelik kuyruğu dışlar. Her run için 60 eşit pencerenin p95 latency ve
error rate değerlerini yazar. Çıktı SLO kanıt adayıdır; araştırma kararını otomatik
olarak dondurmaz.

Route-specific karar desteği `analyze-route-specific-slo-candidates.py` ile aynı
mühürlü girdilerden global, exact `/` hariç ve normalize `/product/{id}` kullanıcı
nüfuslarını ayrı ayrı üretir. Her nüfus için boş pencereleri saklar; boş pencereye
latency uydurmaz ve yalnız dolu pencerelerin dağılımını hesaplar. Böylece route
kapsamı ile ölçüm yoğunluğu birlikte görülebilir. Çıktı bir SLO kararı değildir;
route nüfusunu değiştirmek Research Decision Log'da açık karar gerektirir.

Dondurulmuş pilot manifestation sözleşmesi
`p0-env/config/slo/p1-cpu-001-slo-v1.json` içinde makine-okunur ve sürümlüdür.
`verify-frozen-slo-on-normal-baselines.py`, bu sözleşmeyi route-specific normal
pencerelere yeniden uygular; boş pencereyi gözlenmemiş sayıp streak'i sıfırlar ve
her run için yanlış manifestation arar. Bu replay normal uyumluluğunu sınar;
fault duyarlılığını veya araştırma hipotezini kanıtlamaz.

İlk CPU fault yolu deployment'ı değiştirmez. Sürüm/hash sabitli
`cpu-recommendation-low-v1.json`, mevcut recommendationservice konteynerinde
`cpu-duty-worker.py` kodunu `invoke-cpu-stress.ps1` ile çalıştırır. Worker duty-cycle
talebini iki dakika ramp eder, beş dakika sabit tutar ve toplam süre sınırında
kendi kapanır. Injector yalnız yürütme kanıtı üretir; `analyze-cpu-fault-effect.py`
arşivlenmiş Prometheus CPU counter'larından baseline/steady farkını doğrulamadan
fault uygulanmış sayılmaz. Fault scientific metadata verifier profil, SLO, worker,
injector kanıtı, UTC evreleri, pod restart/UID ve host delta kapılarını uygular.
Final receipt fault profili, SLO ve injector kanıtının kopyalarını SHA-256 ile
mühürler; offline verifier bu ek dosyaları tekrar denetler.

D-038 hedef stabilite sınırı `verify-target-pod-stability.ps1` ile warm-up öncesinde
çalışır. Verifier hedef podu 5 saniyede bir 120 saniye gözler; tek pod, Ready durumu,
beklenen container, pod UID, container ID ve restart sayısının değişmemesini ister ve
read-only kanıt üretir. `run-low-cpu-calibration.ps1` bu kapıyı lifecycle'dan önce
çağırır; `invoke-cpu-stress.ps1` worker exec'ten hemen önce canlı kimliği kanıtın final
snapshot'ıyla karşılaştırır. Retry yoktur. Stabilite kanıtının SHA-256 değeri injector
execution evidence içine girerek mevcut final receipt zincirine bağlanır. Böylece
hazırlık süresi artar fakat 300/300/120/300/300 bilimsel lifecycle değişmez.

D-039 minimum faz süresi sınırı `phase-duration.ps1` ile uygulanır. Runner,
warm-up, normal baseline ve cooldown için kaydedilmiş başlangıç UTC'sinden 300
saniyelik deadline hesaplar; deadline görülmeden canonical bitiş UTC'si üretmez.
Bu katman verifier toleransı eklemez ve lifecycle süresini değiştirmez; işletim
sistemi sleep çağrısının birkaç milisaniye erken dönmesini fail-safe biçimde
absorbe eder. `test-phase-duration.ps1` erken dönüş negatifini ve runner'daki üç
guard bağını doğrular.

`cpu-recommendation-low-v2.json`, injector veya deney şiddetini değiştirmez;
yalnız fiziksel-etki coverage sözleşmesini gerçek 5 saniyelik Prometheus scrape
cadence'ine uyarlar. Her 300 saniyelik baseline ve steady fazında beklenen 60
gerçek CPU-rate intervalinden en az 48'i zorunludur. Analyzer query-step ile
interpolasyon yapmaz; yalnız arşivlenmiş kaynak örnek çiftlerini sayar. `v1`
tarihsel immutable sözleşme olarak kalır ve `ob-cpu-low-002` invalid sonucunu
korur; orchestrator'ın sonraki varsayılanı `ob-cpu-low-003` + `v2`dir.

`cpu-recommendation-low-v3.json`, fault şiddetini değiştirmeden lifecycle zaman
kaynağını ayrıştırır. `cpu-duty-worker.py` canonical UTC taşıyan `started` ve
`completed` olayları üretir; `worker-lifecycle.ps1` bu iki olayı, UTC duvar saati
süresini ve monotonic süreyi doğrular. `invoke-cpu-stress.ps1` bilimsel injection
sınırlarını worker olaylarından alırken dış `kubectl exec` UTC değerlerini ayrı
tanısal alanlarda korur. Böylece taşıma gecikmesi telemetry ile hizalanan fault
penceresine eklenmez, fakat inceleme kanıtından da kaybolmaz.

`cpu-recommendation-low-v4.json` ve `worker-source-hash.ps1`, metin worker'ın
kimliğini working-tree satır sonundan ayırır. Kaynak önce UTF-8 BOM'suz/LF
canonical byte dizisine çevrilir ve SHA-256 bunun üzerinden hesaplanır. Profil
ile injector evidence normalizasyon yöntemini birlikte taşır; verifier ikisini
karşılaştırır. Böylece Windows CRLF ve Linux LF checkout aynı kaynak için aynı
hash'i üretirken gerçek içerik değişikliği bütünlük kapısında reddedilir.

Injector worker JSON olaylarını `Generic.List[object]` içinde toplar ve
`worker-lifecycle.ps1` resolver'ına açık `.ToArray()` dönüşümüyle verir. Bu sınır
Windows PowerShell 5.1'in `@($genericList)` array-subexpression binder kusurunu
önler. Regression fixture üretimdeki koleksiyon tipini aynen kurar; yalnız normal
PowerShell array fixture'ına güvenmez.

CPU calibration orchestrator, açık `FaultProfileRelative` parametresiyle
sürümlenmiş low, medium veya high profili okur; metadata profil kimliği ve operator
notunu dosyadan türetir. Injector ve scientific metadata verifier profil-ID
başına severity, requested mCPU, minimum fiziksel artış ve coverage sözleşmesini
kapalı bir haritada doğrular. Böylece yeni severity desteği önceki kontrolleri
gevşetmez; high yalnız requested 150m ve minimum 75m fiziksel etkiyi değiştirir.

Fiziksel-etki analyzer'ı aynı pod/container için birden fazla cAdvisor counter
serisi bulunduğunda baseline ve steady fazlarının ikisini de kapsayan tam olarak
bir CPU serisi ister. Sıfır veya birden fazla lifecycle-kapsayan seri fail-closed
reddedilir; seriler toplanmaz ve yalnız en uzun seri olduğu için seçilmez.
Throttling, seçilen CPU serisinin aynı cgroup `id` değerine bağlanır. Bu sınır,
warm-up öncesi container restart kalıntısının aktif ölçüm serisini gölgelemesini
önlerken gerçek çoklu-seri belirsizliğini görünür tutar.

`detect-fault-manifestation.py`, fault run selected trace katmanını dondurulmuş
SLO sözleşmesiyle değerlendirir. Tek zaman grid'i `normal_baseline_start_utc`
noktasında başlar ve cooldown sonuna kadar faz sınırlarında yeniden hizalanmaz.
Dedektör ürün latency ve global error streak'lerini ayrı yürütür, boş nüfus
penceresinde ilgili streak'i keser ve ilk tamamlanan üçüncü ihlal penceresinin
bitişini manifestation zamanı yapar. Bu çıktı scientific metadata ve final
receipt içine hash ile bağlanır; operatörün elle zaman seçmesi engellenir.

`run-low-cpu-calibration.ps1` bu bileşenleri fail-closed sırayla bağlayan lifecycle
orchestrator'dır. Temiz Git revision ve boş artifact yollarıyla başlar; warm-up,
baseline, injection ve cooldown UTC'lerini/pod snapshot'larını kaydeder; log ve
telemetry arşivlerini doğrular; fiziksel etki ile manifestation analizlerini
çalıştırır; post-host kapısı için cluster'ı durdurur. Yalnız effect, pod continuity,
host delta, metadata ve offline receipt kapılarının tamamı geçerse run valid olur.
Hata halinde `finally` cluster'ı durdurur ve kısmi kanıtı silmez.

D-030 workload kapasite yolu bilimsel fault veri yolundan ayrıdır.
`set-workload-profile.ps1`, sürümlü aday JSON'daki profile ID, user ve spawn-rate
değerlerini loadgenerator patch'ine exact-match ile bağlar.
`run-workload-capacity.ps1` fault uygulamadan active run-ID, 300 saniye warm-up,
300 saniye measurement, 15-pod continuity, immutable log/schema-v3 telemetry ve
post-stop host kapılarını toplar. `analyze-workload-capacity.py` request-intensity,
frozen-SLO streak ve recommendationservice CPU headroom'unu sealed telemetry'den
yeniden hesaplar; `select-workload-capacity.py` yalnız ön-kayıtlı D-030 eşiklerini
uygular. Bu tooling artifact'ları `dataset_inclusion=false` taşır ve bilimsel
normal/fault run yerine geçmez.

D-031 sonrasında kapasite assessment'ı yalnız pod-stability boolean'ı değil,
measurement öncesi/sonrası tüm 15 pod UID/restart snapshot'ını saklar. CPU
headroom hesabı kaydedilmiş recommendationservice podu için measurement'ın iki
ucunu kapsayan tam olarak bir cAdvisor counter serisi ister; eski kısa seri veya
gerçek çoklu-seri belirsizliği fail-closed reddedilir.

Kapasite runner'ı tarihsel 10-user profilindeki `normal_baseline_seconds` ile yeni
aday profillerdeki `measurement_seconds` alanlarını aynı internal measurement
süresine normalize eder ve değer `300` saniye değilse durur. Bu uyumluluk katmanı
tarihsel workload dosyasını veya receipt hash'lerini geriye dönük değiştirmez.

`analyze-workload-resource-budget.py`, D-030'un mühürlü 10/15/20-user özetleri,
sürümlü high fault profili ve üç-run high özetinden O-010 için salt karar desteği
üretir. Araç request-intensity enterpolasyonunu ve normal CPU + high etki bütçesini
hesaplar, fakat doğrusal/toplamsal varsayımları deneysel kanıt olarak etiketlemez;
workload, eşik, fault profili veya CPU limiti seçmez. Böylece D-030 sonucu
retroaktif değiştirilmeden yeni preregistration seçenekleri yeniden hesaplanabilir.

D-033 ikinci bilimsel workload'u `ob-second-15u-1r-v1` ile kapasite-decision
profilinden ayrı kimlikte tutar. Workload'a özgü low/medium/high fault profilleri
kaynak 10-user profillerindeki injector, hedef, limit, lifecycle, SLO ve fiziksel
etki sözleşmesini aynen taşır; yalnız profil kimliği ve workload bağı değişir.
`invoke-cpu-stress.ps1` ile scientific metadata verifier aynı 10-user/15-user
profil allowlist sözleşmesini uygular. `test-second-workload-injector-profiles.ps1`,
üç 15-user profilini gerçek fault oluşturmayan `-WhatIf` yolunda kabul ettirir ve
değiştirilmiş fiziksel-etki eşiğini negatif fixture ile reddettirir. Böylece profil
dosyasının statik eş-fizik testi ile injector'ın çalışma zamanı kabul kapısı ayrı
ve tamamlayıcı doğrulama sınırlarıdır.
Uzun fault runner lifecycle'ı ölçümden sonra schema-v3 export, offline verifier,
scientific metadata ve final receipt kapanışını aynı fail-closed zincirde yürütür.
Dış orchestrator timeout'u bu zincirin parçası değildir fakat zinciri yarıda
kesmemesi için en az 60 dakika ayrılır. Timeout'a uğrayan run, fiziksel etki ve
telemetry tanısal olarak doğrulansa bile eksik metadata/receipt nedeniyle
retroaktif valid yapılmaz.
`test-second-workload-profiles.py` izin verilen bağlam alanlarını çıkardıktan sonra
profil çiftlerinin eşitliğini denetler. Bu ayrım kapasite tooling kanıtının bilimsel
dataset provenance'ıyla karışmasını önler.

D-034 ile workload runtime güven zinciri
`versioned workload -> kustomization -> loadgenerator deployment -> Ready pod -> scientific metadata`
olarak genişletilir. `verify-active-workload-profile.ps1` users, spawn rate, profil
kimliği ve seed'in dört katmanda eşleşmesini ister. Fault orchestrator aynı workload
dosyasından metadata üretir; fault metadata verifier profil içindeki workload bağını
metadata ile karşılaştırır. Yanlış 10u/15u eşleştirmesi final receipt öncesinde
fail-closed reddedilir.

`run-scientific-normal-baseline.ps1`, kapasite tooling yolundan ayrı scientific
normal kontrol düzlemidir. Akış `clean revision -> active run/workload -> warm-up ->
15-pod baseline snapshotları -> immutable log/telemetry -> normal SLO -> cluster stop
-> host delta -> scientific metadata -> final receipt -> offline verify` sırasını
izler. Script fault profili veya injector çağrısı içermez. `<=40m` workload seçim
provenance'ında kalır; normal CPU gözlemi raporlanır fakat sonuç-sonrası run dışlama
kuralı yapılmaz.

`analyze-frontend-root-critical-path.py`, normal `/` trace'lerinde frontend server
spanıyla aynı trace'deki en uzun spanı karşılaştırır; paralel spanları toplamaz ve
sonucu nedensel kanıt değil kritik-yol adayı olarak etiketler. Bu sınır, trace'de
görünmeyen uygulama/DNS beklemelerinin yanlışlıkla downstream servise yüklenmesini
önler.

D-040 sonrasında CPU stress telemetry ve injection-target kanıtları RCA değerlendirmesi
için korunur; proactive prediction sınıfı olarak yeni pencere üretmez. Kademeli
network delay ayrı bir P2 tasarım sınırıdır: önce sealed normal trace'lerden hedef
caller-to-callee edge seçimi, ardından injector izolasyonu ve cleanup tooling'i,
sonra ayrı sürümlü fault/SLO profili ve bilimsel run ön-kaydı gelir. Mevcut workload
podları capability'leri düşürür ve repository `NET_ADMIN`/`netem` injector içermez;
bu nedenle pod-ağında `tc`, açık proxy ve service-mesh seçenekleri güvenlik ve
karıştırıcı değişken açısından karşılaştırılmadan çalışma deployment'ına eklenmez.
Bu akış P1 receipt'lerini veya CPU etiketlerini değiştirmez.

D-041 ile tasarım/tooling sınırı somutlaştı. `analyze-network-delay-edge-candidates.py`
sealed normal trace'lerde caller client spanlarını callee parent-child bağıyla ve
5 saniyelik baseline pencereleriyle çıkarır. Seçilen
`recommendationservice -> productcatalogservice` edge'i için
`config/network-delay-design` overlay'i aynı pod network namespace'indeki
digest-pinned Toxiproxy sidecar'a yalnız `PRODUCT_CATALOG_SERVICE_ADDR` üzerinden
yönlendirir; sidecar privilege yükseltmez ve bütün capability'leri düşürür.
`manage-network-delay-proxy.py` bu aşamada toxic oluşturamaz, yalnız temiz durumu
doğrular veya `/reset` sonrası API state'ini geri okur. Birleşik tasarım verifier'ı
edge/SLO normal replay'lerini, profil-overlay bağını, fiziksel-etki kontratını ve
scientific-run yetkisizliğini tek receipt'e bağlar. Overlay henüz canlı deployment'a
uygulanmamıştır; bir sonraki mimari sınır fault içermeyen proxy-overhead/pod continuity
doğrulamasıdır.

## 6. Mimarinin şu anda uygulamadığı parçalar

Şu bileşenler tasarım belgelerinde vardır fakat kodlanmamıştır:

- network-delay canlı no-toxic overlay, proxy-overhead ve pod continuity kapısı,
- network-delay scientific run ön-kaydı ve fault lifecycle yürütücüsü,
- 5 saniyelik feature window üretimi,
- grouped train/validation/test split,
- rule/logistic/XGBoost/GRU modelleri,
- LLM verifier,
- graph RCA ve GAT.

Bu ayrım önemlidir: observability pipeline'ın çalışması, araştırma hipotezinin
kanıtlandığı anlamına gelmez.

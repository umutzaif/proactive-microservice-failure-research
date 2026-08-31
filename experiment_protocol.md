# Deney Protokolü

Bu belge tüm pilot ve ana deneylerde değişmeden uygulanacak kuralları tanımlar. Bir değişiklik önce `research_decisions.md` içine gerekçeli karar olarak işlenmelidir.

## 1. Deney birimi

Bağımsız deney birimi bir `run`dır. Her run temiz başlangıç, sabitlenmiş iş yükü, tek bir hata yapılandırması ve kontrollü toparlanma içerir.

Zorunlu run evreleri:

1. reset ve health check,
2. warm-up,
3. normal baseline,
4. fault ramp/enjeksiyon,
5. manifestation gözlemi,
6. fault removal,
7. recovery/cooldown.

## 2. Run kimliği ve değişmez kayıtlar

Her run için benzersiz `run_id` üretilir ve bütün telemetriye eklenir.

Zorunlu metadata:

```yaml
run_id: ob-cpu-cart-001
system: online-boutique
code_revision: "<git sha>"
deployment_revision: "<config sha>"
fault_class: cpu_stress
target_service: "<service>"
fault_profile: "<profile id>"
workload_profile: "<profile id>"
random_seed: 1
warmup_start: "<UTC ISO-8601>"
injection_start: "<UTC ISO-8601>"
injection_end: "<UTC ISO-8601>"
first_symptom: null
failure_manifestation: null
recovery_time: null
operator_notes: ""
```

Saatler UTC ve ISO-8601 biçiminde kaydedilir. Sistem saati kayması run öncesinde kontrol edilir.

## 3. Normal koşul ve iş yükü

- İş yükü profili versioned yapılandırma olmalıdır.
- Warm-up sırasında üretilen örnekler modele verilmez.
- Normal run'lar da fault run'larla aynı süre ve yük dağılımını mümkün olduğunca izler.
- Ana deneyde yük seviyesi hata sınıfıyla karışmamalıdır; her hata sınıfında birden fazla yük seviyesi bulunur.

## 4. Fault injection

- Bir run içinde yalnızca bir birincil enjekte hata bulunur.
- Hedef servis, şiddet, ramp süresi ve süre açıkça kaydedilir.
- Ani ve kademeli profiller ayrı tutulur.
- Injection komutunun başarı kodu yeterli değildir; hedef servis üzerindeki fiziksel etki metrikle doğrulanır.
- Başarısız veya kısmi enjeksiyonlar silinmez; `invalid_run` gerekçesiyle kaydedilir.

### Mentor-gated fault fizibilitesi, örneklem ve takvim kapısı

Yeni bir fault profili canlı sistemde uygulanmadan önce ön-kayıt aşağıdaki alanları
makine-okunur biçimde içermelidir:

- aktif deployment CPU/memory request-limit değerleri ve sistem revisionı;
- en az üç geçerli normal run için hedef metrik dağılımı;
- önerilen fault büyüklüğü ve beklenen fiziksel etki;
- normal üst kuyruk ile frozen SLO arasındaki headroom;
- belirsizlik/güvenlik payı ve hesabı yeniden üreten komut;
- neden bu büyüklüğün ölçülebilir semptom veya manifestation bölgesine girmesinin
  makul olduğuna ilişkin falsifiye edilebilir kabul ölçütü.

Bu hesap eksikse, aktif deployment ile uyuşmuyorsa veya SLO etkisini makul biçimde
desteklemiyorsa fault başlatılmaz. Injector'ın teknik olarak çalışması bu kapının
yerine geçmez.

Network-delay erken-tahmin taraması yalnız `25/50/100/250/500 ms` merdiveninde ve
iki onaylı workload düzeyinde yürütülür. `750 ms` tarihsel koşular exploratory pilot
olarak korunur; yeni ladder hücrelerine veya confirmatory örnek sayısına katılmaz.
Her hücrede sonuç görülmeden önce üç bağımsız geçerli tekrar hedeflenir. Aynı run'ın
5 saniyelik pencereleri bağımsız incident değildir.

Recommendationservice server CPU limitinin `500m` olduğu yeni sistem profili için
eski `200m` altı normal baseline'lar doğrudan karşılaştırmada kullanılamaz. Ladder'dan
önce iki workload altında yeni 500m normal baseline'lar benzersiz run ID'leriyle
sıfırdan toplanır. Delay yalnız kullanıcı isteği hedef edge'ine uygulanmalı; readiness,
liveness ve health path'inin toxic/proxy etkisi dışında kaldığı preflight ve runtime
kanıtıyla gösterilmelidir. Bu ayrım kanıtlanmazsa fault başlamaz.

Confirmatory aşamada önerilen model ile rule baseline aynı pozitif incident'lar üzerinde
eşlenmiş olarak karşılaştırılır. İki taraflı `alpha=0,05`, güç `0,80`, en küçük anlamlı
fark `25` yüzde puanı ve discordant-pair oranı `0,45` varsayımları yaklaşık 57 olay
gerektirir; çalışma hedefi `60` bağımsız pozitif incident'tır. False-alarm/hour ve
negatif davranış için ayrıca `60` bağımsız normal kontrol hedeflenir; normal kontroller
McNemar güç hesabına girmez. Ladder taraması bu sayılara katılmaz. Hedef ancak yeni
prospektif araştırma kararıyla değiştirilebilir.

Takvim kapısı `2026-09-15`tir. O tarihe kadar herhangi bir workload-delay hücresinde
üç geçerli tekrarın en az ikisi frozen SLO manifestation ve en az 15 saniye pozitif
lead-time üretmezse network delay erken-tahmin adayı olarak durdurulur. Yeni fault
sınıfı ayrı headroom hesabı, normal baseline, araştırma kararı ve ön-kayıt gerektirir.

### Kademeli network-delay ön-kayıt kapısı

Network delay scientific run'ından önce caller-to-callee hedef edge, yön, injector
mimarisi, privilege/izolasyon sınırı, delay rampı, steady süre, cleanup doğrulaması,
fiziksel-etki metriği/coverage eşiği ve manifestation sözleşmesi ayrı sürümlü profilde
dondurulur. Injector başarı kodu fiziksel etki değildir; hedef edge trace/RPC latency
değişimi veya eşdeğer sealed ölçüm bağımsız doğrulanır. Birden fazla edge'e belirsiz
etki, residual delay, hedef/pod kimliği değişimi ya da cleanup kanıtı yokluğu run'ı
invalid yapar. CPU SLO'su network delay'e otomatik taşınmaz ve fault sonucu görülerek
eşik seçilemez.

D-041 kapsamında ilk sürüm `recommendationservice -> productcatalogservice`
downstream yönüne sabitlenmiştir. Toxiproxy sidecar ayrıcalıksız çalışır ve yalnız
caller'ın `PRODUCT_CATALOG_SERVICE_ADDR` adresini değiştirir. `750 ms` yapılandırılmış
delay tek başına etki kanıtı değildir: baseline ve steady'nin her birinde en az 48
dolu 5 saniyelik hedef-edge penceresi ve steady-baseline median caller client-span
latency farkı en az `500 ms` olmalıdır. Cleanup, `/reset` sonrasında API'den
`enabled=true` ve `toxics=[]` geri okunarak doğrulanır. Bilimsel ön-kayıttan önce
fault içermeyen canlı overlay, proxy overhead ve pod continuity kapısı geçmelidir.

Bu canlı kapı D-042 ile 15-user workload altında geçti: base/proxy hedef-edge
coverage `60/60`, median overhead `+0,3415 ms` ve ön-kayıtlı üst sınır `5 ms`,
proxy SLO manifestation null, host farkı `0/0/0` ve rollback/final receipt geçerlidir.
Bu compatibility sonucu scientific fault sonucu değildir. Sonraki network-delay
run'ı ayrı benzersiz kimlik ve ön-kayıtla bağlanır; `750 ms` toxic'in gerçek fiziksel
etkisi yalnız o run'ın baseline/steady trace ölçümüyle kabul veya reddedilir.

D-043 ile ilk run `ob-netdelay-15u-001` olarak, `ob-second-15u-1r-v1` (15 user,
spawn rate 1, seed 1) workload'una ön-kaydedilmiştir. Toxic `0 ms` ile oluşturulur ve
120 saniyede 12 deadline-bound 10 saniyelik adımla `750 ms`ye çıkarılır; steady 300
saniyedir. `300/300/120/300/300` lifecycle, D-041 etki/ilk-semptom/SLO eşikleri,
schema-v3 boundary-crossing politikası ve invalid veriyi benzersiz ID altında koruma
değişmezdir. Canonical merge ayrı runtime onayı değildir; fresh host/cluster/run-ID,
proxy clean ve 120 saniyelik target-stability kapıları geçmeden toxic oluşturulmaz.

Invalid `ob-netdelay-15u-001` sonrası D-044, JSON lifecycle UTC type boundary'sini
canonical `Z` helper'ıyla bağlar; canonical guard veya minimum süre gevşetilmez.
Değişmeyen replacement `ob-netdelay-15u-002` ayrı ön-kayıttır ve merge sonrasında
yeniden açık runtime onayı gerektirir.

`ob-netdelay-15u-002` normal final-receipt dispatch kapısında invalid kapanmıştır.
D-045 ile CPU ve network-delay metadata doğrulaması fault class’a göre ayrılır;
invalid receipt v2 canonical-JSON hash ile Git checkout satır-sonlarından bağımsızdır.
Koşulları değişmeyen `ob-netdelay-15u-003` ayrı ön-kayıttır. Merge ve açık kullanıcı
onayı fresh runtime kapılarının yerine geçmez.

`ob-netdelay-15u-003` rollout sonrası pod termination penceresinde warmup/fault öncesi
invalid kapanmıştır. D-046, proxy selector kümesini `120 sn / 5 sn` bounded pencereyle
tam bir Ready pod ve iki Ready container'a bağlar; timeout fail-closed'dur. Koşulları
değişmeyen `ob-netdelay-15u-004` ayrı ön-kayıttır ve yeniden açık onay gerektirir.

`ob-netdelay-15u-004` aynı bounded kapıda invalid kapanmıştır; warmup/fault başlamamış
ve ID kullanımı sona ermiştir. D-047 kapının `120 sn / 5 sn` eşiğini değiştirmez,
yalnız her polling gözlemine pod conditions ve container readiness/restart/state
ayrıntısını ekler. Koşulları değişmeyen `ob-netdelay-15u-005` ayrı ön-kayıttır;
canonical merge ve yeniden açık runtime onayı gerekir.

### Network-delay resource compatibility kapısı

D-049 tanısı sonrası scientific replacement'tan önce D-050 ayrı no-toxic resource
compatibility kapısını zorunlu kılar. Yalnız recommendationservice server CPU limiti
`200m -> 500m` değişebilir; CPU request, memory, image, workload, proxy ve probe
değişemez. `ob-network-resource-compat-001`, 120 saniye/5 saniye target stability ve
180 saniye/5 saniye resource penceresi kullanır. Server/proxy readiness `%100`, restart
`0`, 13/13 cAdvisor türü/en az 175 saniye coverage, CFS throttled-period fraction
`<0,50`, CPU-pressure waiting delta `<10,635359 sn`, memory/OOM/node/RecordId-host,
rollback, manifest ve offline replay kapılarının tamamı zorunludur. Toxic/fault
yasaktır. Başarısız sonuç korunur; eşikler gevşetilmez ve aynı ID tekrarlanmaz.
Geçiş scientific fault, replacement, model, LLM veya GAT yetkisi değildir.
Bu kapı `ob-network-resource-compat-005` ile geçerli kapandı: lifecycle, 13/13 metric,
fiziksel etki, run-manifest provenance, host, rollback ve 19/19 seal/replay geçti.
Sonuç no-toxic compatibility kanıtıdır; scientific network-delay run'ı ayrı karar ve
ayrı canlı onay gerektirir.
D-055 scientific replacement'ta 500m/100m resource overlay, RecordId host sınırı,
native JSON izolasyonu ve immutable run manifesti fault öncesi zorunludur.
`ob-netdelay-15u-006` fault öncesi compositional overlay kaynak çözümleme hatasıyla
invalid kapandı ve yeniden kullanılamaz. D-056 replacement `ob-netdelay-15u-007` için
statik proxy doğrulamasını `network-delay-design` kaynağında, deploy/canlı 500m kapısını
`network-delay-resource-compatibility` çıktısında bağımsız uygular. D-043
ramp/lifecycle/effect/SLO, schema-v3, cleanup ve receipt kapıları aynen korunur.
`ob-netdelay-15u-007` non-interactive `ShouldProcess` girişinde preflight öncesi invalid
kapandığı için kullanılamaz. D-057 replacement `ob-netdelay-15u-008`, mandatory
`ExecutionApproved` ile `ConfirmImpact=Low` ve doğrulanan `-WhatIf` no-mutation
sözleşmesini birlikte kullanır; bilimsel koşullar ve bütün kapılar değişmez.
`ob-netdelay-15u-008` bu sözleşmeyle geçerli tamamlandı: D-038, 60/60 coverage,
`+751,995 ms` fiziksel etki, latency manifestation, cleanup/rollback, host `0/0/0`,
schema-v3 ve final receipt replay kapıları geçti. Canonical verifier runtime Windows
PowerShell'dir; pwsh 7 JSON UTC milisaniye cast farkı bilimsel eşik veya arşiv
değiştirilmeden portability sınırlılığı olarak raporlanır.

### Network-delay tekrarlanabilirlik ve shell-portability kapısı

D-058 altında yeni network-delay slotundan önce aynı raw arşiv Windows PowerShell 5.1
ve pwsh 7 ile aynı timestamp sınır sonucunu üretmelidir. Metadata UTC alanları JSON
runtime'ının otomatik `DateTime` dönüşümünden alınmaz; ham JSON'daki tekil canonical
`Z` string invariant `DateTimeOffset` olarak ayrıştırılır. Pozitif sınır fixture'ı iki
runtime'da geçmeli, sınır-sonrası negatif fixture iki runtime'da fail-closed kalmalıdır.

Bağımsız deney birimi run'dır. `ob-netdelay-15u-008` randomize edilmemiş pilot olarak
ayrı tutulur. Dört yeni eşlenmiş blok, D-058 seed'i ve immutable çizelgesiyle iki
`fault-control` ve iki `control-fault` sırası kullanır. Kontrol aynı proxy overlay,
workload, kaynak ve lifecycle altında toxic oluşturmadan yürütülür. Bir blok içindeki
ikinci slot, ilk slotun cleanup/rollback/host ve proxy-clean kapıları geçmeden başlamaz.
Invalid run silinmez veya aynı ID ile tekrarlanmaz; replacement ayrı prospektif karar
ister. Dört geçerli çift sonrasında run-arası varyans ölçülür ve nihai örnek büyüklüğü
hedeflenen güven aralığı, equivalence veya power iddiasına göre ayrıca dondurulur.

D-059 ilk randomize slotu `ob-netdelay-15u-repeat-001` olarak bağlar. Bu slot yalnız
fault koşuludur; `008` pilotunun bilimsel koşulları değişmez. Canonical merge ve ayrı
runtime onayı olmadan yürütülemez. Geçerli sonuç tek başına blok kapanışı değildir;
ön-kayıtlı sonraki slot `ob-netdelay-15u-control-001` olarak kalır.

`ob-netdelay-15u-repeat-001` bu sözleşmeyle geçerli tamamlandı: D-038 25/restart 0,
coverage 60/60, `+749,623 ms` etki, latency manifestation, cleanup/rollback, host
`0/0/0`, pwsh 5.1/7 raw eşdeğerliği ve final receipt geçti. İlk blok yalnız fault
slotu `1/2` tamamlanmış durumdadır; sonuç kontrol ölçütlerini değiştirmez.

D-060 kontrol slotunda 120/300 saniyelik fault fazlarının karşılığı
`matched_ramp_interval/matched_steady_interval`dır; injection alanı kullanılamaz ve
`scientific_fault_started=false` kalır. Toxic pre/mid/post/cleanup snapshotlarında boş
olmalı; latency farkı eşiksiz betimlenmeli; geçerli kontrol frozen SLO'da manifestation
üretemez. Coverage, pod, host, telemetry, rollback ve receipt kapıları değişmez.

## 5. Failure manifestation ve SLO

Ana SLO pilot normal veriden sonra dondurulur. Aday tanım:

- belirli süre boyunca p95 latency eşiğinin aşılması veya
- belirli süre boyunca error-rate eşiğinin aşılması.

Bir manifestasyon kuralı örneği:

```text
p95_latency > normal_p99_threshold for 3 consecutive 5-second windows
OR
error_rate > fixed_threshold for 3 consecutive 5-second windows
```

Eşikler test verisine bakılarak seçilemez. Validation öncesinde protokole işlenir.

### P1-CPU-001 için dondurulmuş pilot kuralı

Fault verisi görülmeden önce `p1-cpu-001-slo-v1` şu OR kuralını dondurur:

- normalize `/product/{id}` frontend isteklerinde 5 saniyelik pencere-p95 latency
  `> 345,992 ms` değerini art arda üç dolu pencerede aşarsa veya
- tüm frontend kullanıcı isteklerinde 5 saniyelik error rate `> 0` değerini
  art arda üç dolu pencerede aşarsa,

üçüncü ihlal penceresinin bitişi `failure_manifestation` olur. Boş pencere gözlem
yokluğudur; sıfır değer atanmaz ve ardışıklık zincirini keser. Kuralın makine-okunur
tek kaynağı `p0-env/config/slo/p1-cpu-001-slo-v1.json` dosyasıdır. Eşik veya nüfus
fault sonucuna bakılarak değiştirilemez; değişiklik yeni sürüm ve açık kararla yapılır.
Beş saniyelik pencereler `normal_baseline_start_utc` noktasına sabitlenir ve faz
sınırlarında yeniden hizalanmadan `cooldown_end_utc` noktasına kadar kesintisiz
ilerler. Enjeksiyon başlangıcına göre yeni grid kurulmaz. Yalnız tam pencereler
değerlendirilir; manifestation üçüncü ardışık ihlal penceresinin UTC bitişidir.

## 6. Telemetri gereksinimleri

### P1-CPU-001 fiziksel CPU etkisi coverage kapısı

`cpu-recommendation-low-v2`, doğrulanmış 5 saniyelik Prometheus scrape cadence'i
altında her 300 saniyelik normal-baseline ve steady fazında beklenen 60 gerçek
CPU-rate intervalinin en az 48'ini (%80) zorunlu kılar. Query step daha küçük
seçilerek ara örnek üretilmiş sayılmaz; yalnız kaynak serideki ardışık gerçek
örneklerden hesaplanan interval sayılır. Ayrıca steady-baseline ortalama CPU farkı
en az 25 mCPU olmalıdır. Coverage ve büyüklük kapılarından biri geçmezse run
kanıtıyla birlikte invalid saklanır.

Bu sürümleme `ob-cpu-low-002` sonucunu geriye dönük değiştirmez. `v1` ve 240
interval sözleşmesi tarihsel doğrulama için korunur; düzeltilmiş kapı yalnız yeni
run ID `ob-cpu-low-003` ve `v2` profilinde uygulanır.

`cpu-recommendation-low-v3`, şiddet veya süre sözleşmesini değiştirmez. Fault
fazının UTC başlangıç/bitişi worker'ın canonical `started`/`completed` olaylarından
alınır; dış `kubectl exec` başlangıç/bitişi yalnız tanısal taşıma kanıtıdır. Worker
UTC farkı ve monotonic elapsed ayrı ayrı 420 +/- 5 saniye olmalıdır. Bu kapılardan
biri geçmezse run invalid korunur; tolerans sonuç görüldükten sonra gevşetilemez.

`cpu-recommendation-low-v4`, worker kaynak metninin SHA-256 hesabını platformdan
bağımsızlaştırır: metin UTF-8 BOM'suz ve LF satır sonlu canonical byte dizisine
dönüştürüldükten sonra hashlenir. Profil ve injector kanıtı normalizasyon adını
taşır. Hash kapısı kaldırılmaz; farklı kaynak içeriği reddedilir. v3 ve invalid
`ob-cpu-low-007` geriye dönük değiştirilmez.

`cpu-recommendation-medium-v1`, yalnız requested CPU severity'yi 50m'den 100m'ye
çıkarır. Fiziksel kabul steady-minus-baseline en az 50m; coverage her 300 saniyelik
fazda en az 48 gerçek intervaldir. Ramp 120 sn, steady 300 sn, cooldown 300 sn;
target, workload, seed, SLO, UTC ve receipt kapıları low profil ile aynıdır.

`cpu-recommendation-high-v1`, yalnız requested CPU severity'yi 100m'den 150m'ye
çıkarır. Fiziksel kabul steady-minus-baseline en az 75m; coverage her 300 saniyelik
fazda en az 48 gerçek intervaldir. Ramp 120 sn, steady 300 sn, cooldown 300 sn;
target, workload, seed, SLO, D-026 lifecycle-seri seçimi, UTC ve receipt kapıları
medium profil ile aynıdır. Throttling raporlanır fakat manifestation değildir.

### Logs

- UTC timestamp, service, pod/instance, severity, message/template, trace ID (varsa), run ID.
- Ham loglar immutable olarak saklanır; parsed sürüm ayrı üretilir.

### Metrics

- CPU, memory, request rate, error rate, latency quantiles, restart/health göstergeleri.
- Scrape interval ve missingness kaydedilir.

### Traces

- Trace/span ID, parent span, caller/callee service, start/end time, status ve duration.
- Sampling oranı sabitlenir ve kaydedilir.

## 7. Veri kalite kapıları

Bir run ancak aşağıdakiler sağlanırsa modellemeye alınır:

- zorunlu evre zamanları mevcut,
- hedef fault etkisi doğrulanmış,
- kritik modalitelerde kabul edilebilir eksiklik,
- run ID ile modaliteler eşleşiyor,
- zaman sırası mantıklı,
- servis/topoloji kimlikleri çözümlenebilir.

Her dışlama gerekçesi kayıt altına alınır. Sonuçları iyileştirmek için sonradan keyfî run silinemez.

## 8. Pencereleme ve etiketleme

- Varsayılan pencere: 5 saniye.
- Varsayılan gözlem: 150 saniye.
- Ana horizon: 30 saniye.
- Gözlem bitişi `t` olan örnek, `failure_manifestation` `(t, t+H]` içindeyse ilgili hata sınıfını alır.
- Manifestasyon sonrası pencereler proactive prediction dataset'ine girmez.
- Aynı run içindeki aşırı örtüşen örnekler effective sample size'ı şişirmeyecek biçimde seyreltilir veya olay-bazlı değerlendirilir.

## 9. Veri bölme ve leakage kontrolleri

- Group key: `run_id`.
- Preprocessing parametreleri yalnızca train kümesinde öğrenilir.
- Template vocabulary, normalization, calibration ve threshold seçimi test verisine bakmadan yapılır.
- Aynı fault profile + target service kombinasyonlarının dağılımı raporlanır.
- Kod sürümü veya deployment değişmişse split ve drift analizinde açıkça gösterilir.

## 10. Model ve deney tekrarlanabilirliği

Her deney şunları kaydeder:

- experiment ID,
- code/config revision,
- dataset version ve split manifest,
- feature version,
- model ve hyperparameter'lar,
- random seed'ler,
- donanım ve çalışma süresi,
- LLM model/version, prompt hash, temperature ve token kullanımı,
- çıktı artefact yolları.

Ana sonuçlar en az üç seed ile veya deterministik modelse bootstrap confidence interval ile raporlanır.

## 11. Raporlama kuralları

- Window-level ve event-level metrikler karıştırılmaz.
- En iyi threshold yalnızca validation setinden seçilir.
- Başarısız koşular ve negatif sonuçlar sonuç kaydında tutulur.
- Accuracy tek başına ana metrik olamaz.
- LLM değerlendirmesinde cevabın yanında evidence correctness raporlanır.

# D-081 preserved bootstrap state-consistency diagnostic boundary

`ob-k8s-bootstrap-state-consistency-001` is a separately approval-gated operational
diagnostic. It preserves the stopped profile and the D-079 runtime/resource/time contract,
captures the existing-config decision inputs and bootstrap state at live boundaries, and
requires non-null process exit, semantic verification, host closure and SHA replay. It must
not delete/reset the profile, deploy the application, start workload, create toxic/fault, or
enter Dataset v1/D-067 accounting. Canonical merge is not runtime authorization.

D-082 replacement `ob-k8s-bootstrap-state-consistency-002` keeps this entire boundary and
adds raw inspect-before-parse plus mandatory child-process wait/refresh/dispose before sealing.
The invalid `001` is immutable and cannot be reused. Merge remains separate from runtime approval.

D-082 runtime is invalid/incomplete because both mandatory state captures exited `2` with empty
stdout. File existence or a printed verifier success cannot substitute for successful capture
semantics. The sealed evidence is retained, `002` is closed, and no replacement is authorized.

D-083 tooling requires native argument-boundary preservation and validates each state capture at
both production and independent-verifier layers: zero exit, nonempty payload, and one status line
for every frozen path. A verifier helper name must not collide with default PowerShell aliases.
Offline tooling completion does not authorize a new diagnostic identity or runtime.

D-084 preregisters unique replacement `ob-k8s-bootstrap-state-consistency-003` with unchanged
D-081/D-082 machine and scientific conditions plus every D-083 fail-closed capture assertion.
The ID is invalidated by any failed or incomplete mandatory capture. Canonical merge remains
separate from explicit live-runtime approval.

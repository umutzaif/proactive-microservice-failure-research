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

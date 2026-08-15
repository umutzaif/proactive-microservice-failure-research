# Dataset Card

## 1. Kimlik

- Geçici ad: **Proactive Microservice Failure Dataset v0**
- Durum: Pilot öncesi taslak
- Ana sistem adayı: Online Boutique
- Üretim biçimi: Açık benchmark üzerinde kontrollü fault injection
- Amaç: Pre-failure classification, LLM evidence verification ve root-cause service ranking
- Geçerli bilimsel run sayısı: **21**. 10-user seviyesinde üç normal baseline ile low, medium ve high CPU-stress profillerinin üçer geçerli adayı; 15-user seviyesinde üç geçerli normal baseline ve low, medium, high CPU-stress profillerinin ikişer geçerli adayı bulunur. Invalid attempt'ler korunur ve dataset'e alınmaz. D-030 fault'suz kapasite koşuları karar desteğidir ve bu sayıya/dataset'e girmez.

## 2. Amaçlanan kullanım

Dataset aşağıdaki araştırma görevleri için tasarlanır:

- belirli horizon içinde oluşacak fault class tahmini,
- aday tahminin log/metric/trace/code kanıtlarıyla doğrulanması,
- root-cause service sıralaması,
- unseen severity, workload ve service genellemesi.

Amaçlanmayan kullanımlar:

- gerçek üretim ortamlarında güvenlik-kritik otomatik müdahale,
- insan denetimi olmadan recovery yürütme,
- çoklu eşzamanlı hata analizi,
- propagation path ground truth iddiası.

## 3. Veri kaynakları

| Modalite | Ham içerik | Minimum alanlar |
|---|---|---|
| Log | Servis/pod çalışma olayları | timestamp, service, instance, severity, message/template, trace_id, run_id |
| Metric | Servis ve kaynak zaman serileri | timestamp, service, metric_name, value, run_id |
| Trace | Dağıtık istek yolları | trace_id, span_id, parent_id, caller, callee, timestamps, status, run_id |
| Topoloji | Static deployment ve dynamic call graph | node IDs, directed edges, observation interval |
| Kod | İlgili servis/kural parçaları | repository revision, file, line/function locator |
| Metadata | Deney ve fault tanımları | run schema in experiment protocol |

## 4. Etiketler

### Run-level

- `fault_class`
- `target_service`
- `fault_profile`
- `workload_profile`
- `injection_start/end`
- `first_symptom`
- `failure_manifestation`
- `recovery_time`
- `valid_run` ve dışlama gerekçesi

### Window-level

- `observation_start/end`
- `prediction_horizon`
- `future_fault_class`
- `time_until_manifestation` yalnızca analiz alanı; ilk modelde hedef değil
- `root_cause_service`
- modalite missingness göstergeleri

## 5. İlk sınıf tasarımı

| Sınıf | Prediction görevi | RCA görevi | Not |
|---|---|---|---|
| normal | Evet | Hayır | Fault koşularındaki pre-fault normal dönemler dikkatle örneklenir |
| cpu_stress | Hayır (P1 sonrası) | Evet | P1'de geçerli manifestation `0/15`; immutable kanıt RCA-only korunur |
| network_delay | Aday | Evet | `001` incomplete ve `002` receipt-gate invalid korunur. `002`de +751,402 ms etki ve latency manifestation gözlendi fakat final receipt başarısız olduğundan hiçbirisi dataset/modeling örneği değildir |
| service_degradation | Pilot sonrası | Evet | Doğal öncül sinyali olan mekanizma seçilmeli |
| pod_kill | Hayır/negatif kontrol | Evet | Ani hata; predictive başarı iddiasına dahil edilmez |

## 6. Toplama hedefi

Pilot hedefi:

- 10–15 CPU-stress fault run,
- 5–10 eşlenmiş normal run,
- en az 3 şiddet profili,
- en az 2 yük seviyesi.

Dataset v1 geçici hedefi:

- tahmin edilen her hata sınıfı için 40–50 bağımsız geçerli run,
- benzer sayıda normal kontrol run'ı,
- birden fazla hedef servis ve yük seviyesi.

Nihai sayı pilot varyansı, geçerli-run oranı ve confidence interval genişliğine göre belirlenecek.

## 7. Bölme

- Train/validation/test yalnızca run düzeyinde ayrılır.
- Varsayılan oran pilot sonrası belirlenecek; küçük run sayısında grouped cross-validation tercih edilebilir.
- Ayrı challenge split'leri: unseen severity/workload ve unseen service.

## 8. Bilinen yanlılıklar ve tehditler

- Sentetik fault injection gerçek üretim arızalarının tüm çeşitliliğini temsil etmez.
- Benchmark topolojisi gerçek büyük ölçekli sistemlerden küçüktür.
- Workload generator davranışı sınıflarla istemeden korelasyon kurabilir.
- Injection schedule modele sızabilecek periyodik izler oluşturabilir.
- Enjeksiyon hedefini root cause etiketi kabul etmek karmaşık/çoklu arızalarda yetersizdir.
- Trace sampling eksik yayılım izlenimi yaratabilir.
- Aynı log template'lerinin train/test'te bulunması unseen-fault genellemesi anlamına gelmez.
- Kod bağlamı, benchmark kodunda gerçek iş kurallarının sınırlı olması nedeniyle yapay derecede kolay olabilir.

## 9. Kalite ve sürümleme

- Ham veri değişmez ve checksum'lı saklanır.
- İşlenmiş dataset semantik sürüm numarası alır: `v0.x` pilot, `v1.0` dondurulmuş ana dataset.
- Her sürümde run manifest, schema, preprocessing revision ve split manifest yayımlanır.
- Dışlanan run'lar ve gerekçeleri sürüm notlarında bulunur.

## 10. Etik, güvenlik ve lisans

- Dataset sentetik kullanıcı yükü içermeli; kişisel veri toplamamalıdır.
- Benchmark, bağımlılık ve model lisansları dağıtımdan önce doğrulanmalıdır.
- Loglarda token, parola veya secret bulunmadığı otomatik taramayla kontrol edilmelidir.
- LLM'e gönderilen bağlam secret taramasından sonra oluşturulmalıdır.

## 11. Doldurulacak pilot bulguları

- Seçilen servis: `recommendationservice`; ilk CPU-stress kalibrasyon hedefi. Karar `ob-cpu-normal-002` normal-baseline karşılaştırmasına dayanır ve fault yanıtını henüz kanıtlamaz.
- Ana pilot SLO tanımı: `p1-cpu-001-slo-v1` ile fault verisi görülmeden donduruldu. `/product/{id}` window-p95 `>345,992 ms` veya global frontend error rate `>0`; ilgili koşul art arda üç dolu 5 saniyelik pencerede sürerse manifestation oluşur. Boş pencere gözlem yokluğudur ve zinciri keser.
- Normal latency/error dağılımı: 180 tam 5 saniyelik pencerede pencere-p95 latency p99 = 4.279,712 ms; 2.219 frontend kullanıcı isteğinde trace-derived hata = 0. Ayrıntı: `p0-env/artifacts/P1-SLO-CANDIDATE-001/report.md`.
- Frontend DNS A/B durumu: `P1-FRONTEND-DNS-AB-001` cold-start ve DNS-cache/sequence carry-over nedeniyle `invalid/inconclusive`; dataset'e alınmaz, patch bilimsel deployment'a kabul edilmedi.
- İzole DNS A/B durumu: `P1-FRONTEND-DNS-AB-002` geçerli negatif tooling sonucu; treatment 6/6 turda hızlı olsa da preregistered maksimum oran kapısı `0,722 > 0,25` ile başarısız. Dataset'e alınmaz ve patch kabul edilmez.
- Route-specific SLI karar desteği: `/product/{id}` ailesi üç geçerli normal run'da 1.066 istek ve 179/180 dolu 5 saniyelik pencere üretti; birleşik pencere-p95 p99 `345,992 ms`, maksimum `451,162 ms`, hata 0. Bu analiz tek başına karar değildi; değer daha sonra açık kullanıcı onayı ve D-015 ile donduruldu.
- İlk düşük fault profili: `cpu-recommendation-low-v1`; recommendationservice için yaklaşık 50m ek CPU talebi, 120 sn ramp ve 300 sn steady. Dataset dahil edilmesi komut başarısına değil Prometheus'ta en az 25m steady-baseline mean artışı, yeterli interval, lifecycle, host ve close-run kapılarına bağlıdır.
- `ob-cpu-low-001`: injector başlamadan PowerShell parameter-binding hatasıyla `invalid/incomplete`; fault uygulanmadı, dataset'e alınmaz, kanıt korunur ve run ID yeniden kullanılmaz.
- `ob-cpu-low-002`: tam lifecycle ve +50,591m fiziksel CPU artışı gözlendi; ancak preregistered 240 interval kapısına karşı 5 sn scrape nedeniyle 59/60 interval bulundu. Run retroaktif kabul edilmez, dataset'e alınmaz; manifestation null ve tüm artifact'lar korunur.
- Sonraki düşük profil sürümü: `cpu-recommendation-low-v2`; gerçek 5 sn scrape cadence'inde 300 sn faz başına beklenen 60 intervalin en az 48'ini (%80) zorunlu kılar. CPU şiddeti, +25m fiziksel artış kapısı, workload, seed, SLO ve lifecycle değişmemiştir. `ob-cpu-low-003` bu yeni sözleşmeye bağlanmıştır; henüz toplanmamıştır.
- `ob-cpu-low-003`: v2 coverage (59/60), +48,890m CPU artışı, pod/host ve schema-v3 telemetry kapıları geçti; manifestation oluşmadı. Injector UTC'yi `+00:00` yazarken verifier canonical `Z` bekledi ve hata raporlama tür kusuru nedeniyle final receipt üretilemedi. Run invalid kalır, dataset'e alınmaz ve retroaktif finalize edilmez.
- `ob-cpu-low-004`: ilk geçerli düşük CPU-stress kalibrasyon adayı. Coverage 59/60, baseline `9,551m`, steady `58,014m`, fark `+48,463m`; host/pod/telemetry ve offline final receipt kapıları geçti. 205 tam 5 sn pencerede manifestation oluşmadı. Bu düşük şiddette geçerli negatif manifestation bulgusudur; SLO eşiğini sonradan değiştirmez.
- Düşük şiddet tekrarlanabilirlik planı: kullanıcı onayıyla `ob-cpu-low-005` ve `ob-cpu-low-006`, `ob-cpu-low-004` ile aynı `cpu-recommendation-low-v2`, workload, seed, SLO ve lifecycle altında iki bağımsız tekrar olarak ön-kaydedildi. Her run ayrı canonical revision, artifact yolu, host ve receipt kapılarıyla kapanacaktır.
- `ob-cpu-low-005`: ilk bağımsız tekrar geçerli tamamlandı. Coverage 59/60, baseline `11,300m`, steady `63,351m`, fark `+52,050m`; host/pod/telemetry ve offline final receipt kapıları geçti. 205 tam pencerede manifestation yine oluşmadı. `ob-cpu-low-006` tamamlanmadan üç-run tekrarlanabilirlik sonucu dondurulmaz.
- `ob-cpu-low-006`: physical-effect (60/60 interval, `+48,899m`), host/pod ve schema-v3 telemetry kapıları geçti; 207 tam pencerede manifestation null kaldı. Worker monotonic süresi `420,000 sn` iken transport-inclusive outer exec aralığı steady fazını `305,313 sn` gösterdi ve `300±5 sn` metadata kapısı reddetti. Final receipt oluşmadığı için invalid kalır ve dataset'e alınmaz.
- `ob-cpu-low-007`: active run-ID, 5 dk warm-up ve 5 dk baseline sonrasında injector'ın pre-execution worker hash kapısında `invalid/incomplete` kapandı; fault uygulanmadı. Profil LF byte hash'i ile Windows checkout CRLF byte hash'i farklıydı. Host delta `0/0/0`; kanıt korunur, dataset'e alınmaz, v3 geriye dönük değiştirilmez ve run ID yeniden kullanılmaz.
- `ob-cpu-low-008`: v4 hash, warm-up, baseline ve 420 saniyelik worker geçti; ancak Windows PowerShell 5.1 `Generic.List[object]` koleksiyonunu `@($events)` yoluyla resolver'ın `object[]` parametresine bağlayamadı. Cooldown/archive/receipt tamamlanmadığı için invalid kalır ve dataset'e alınmaz; pod/host stabil, kanıt korunur.
- `ob-cpu-low-009`: coverage `59/59`, baseline `13,138m`, steady `63,672m`, fark `+50,534m`; host/pod/telemetry/final receipt/offline verifier geçti. 206 tam pencerede latency ihlali yoktu; tek izole global-error penceresi üçlü streak oluşturmadı ve manifestation null kaldı. Üçüncü geçerli düşük-şiddet adayıdır.
- Düşük-şiddet üç-run özeti: 004/005/009 CPU artışı ortalama `50,349m`, sample SD `1,801m`, CV `%3,576`, aralık `48,463–52,050m`; üçünde de manifestation null. Bu fiziksel actuation tekrarlanabilirliğidir, pre-failure tahmin başarısı veya yeni severity yetkisi değildir.
- İlk medium profil ön-kaydı: `cpu-recommendation-medium-v1`, recommendationservice için `+100m` talep ve en az `+50m` fiziksel etki; ramp/steady/cooldown `120/300/300 sn`. Workload, seed, SLO, hedef ve coverage değişmedi.
- `ob-cpu-medium-001`: coverage `59/59`, baseline `10,161m`, steady `112,071m`, fark `+101,910m`; host/pod/telemetry/final receipt/offline verifier geçti. 206 tam pencerede latency veya global-error ihlali oluşmadı ve manifestation null kaldı. İlk geçerli medium adayıdır; tek run medium tekrarlanabilirliğini kanıtlamaz ve high severity ya da post-hoc SLO değişikliği yetkisi oluşturmaz.
- Medium tekrar planı: `ob-cpu-medium-002` ve `ob-cpu-medium-003`, D-025 ile `ob-cpu-medium-001` koşulları değiştirilmeden iki bağımsız tekrar olarak ön-kaydedildi. Her run ayrı canonical revision, artifact, host-health, active run-ID ve receipt kapılarıyla kapanır. Üç geçerli medium aday oluşmadan medium varyans özeti dondurulmaz; plan high severity veya farklı workload yetkisi vermez.
- `ob-cpu-medium-002`: worker, host, pod ve schema-v3 telemetry kapıları geçti; ancak aynı pod/container'a ait warm-up içinde biten eski cAdvisor serisi lifecycle'ı kapsayan aktif seriyi analyzer'da ezdi ve fiziksel-etki sonucu `0/0` interval oldu. Final receipt oluşmadığı için invalid kalır ve dataset'e alınmaz. Salt-okunur tanısal replay aktif seride `59/59` ve `+100,828m` buldu; bu sonuç run'ı retroaktif geçerli yapmaz. D-026 lifecycle'ı kapsayan tek-seri seçimini yalnız sonraki yeni run ID için fail-closed uygular.
- `ob-cpu-medium-003`: D-026 sonrasında coverage `59/59`, baseline `11,517m`, steady `114,559m`, fark `+103,042m`; host/pod/telemetry/final receipt ve bağımsız offline verifier geçti. 205 tam pencerede latency veya global-error ihlali oluşmadı ve manifestation null kaldı. İkinci geçerli medium adaydır; invalid `002` tekrarlanabilirlik setine katılmaz ve D-025 üç-valid-run özeti henüz tamamlanmamıştır.
- D-027 medium tamamlama planı: invalid `ob-cpu-medium-002` yerine yeni `ob-cpu-medium-004`, değişmeyen `cpu-recommendation-medium-v1`, workload, seed, SLO, hedef ve tüm geçerlilik kapılarıyla üçüncü geçerli aday olarak ön-kaydedildi. D-026 lifecycle-kapsayan tek cAdvisor seri seçimi uygulanır. Geçerli sonuç D-025 betimsel üç-run özetini mümkün kılabilir; plan high severity veya farklı workload yetkisi vermez.
- `ob-cpu-medium-004`: coverage `59/59`, baseline `16,867m`, steady `110,861m`, fark `+93,994m`; host/pod/telemetry/final receipt ve bağımsız offline verifier geçti. 205 tam pencerede latency ihlali yoktu; tek izole global-error penceresi üçlü streak oluşturmadı ve manifestation null kaldı. Üçüncü geçerli medium adaydır.
- Medium üç-run özeti: `001/003/004` CPU artışı ortalama `99,649m`, sample SD `4,930m`, CV `%4,947`, aralık `93,994–103,042m`; üçünde de manifestation null. Invalid `002` hesaplamaya katılmaz. Bu, sabit koşullarda fiziksel actuation ve null manifestation için betimsel tekrarlanabilirliktir; pre-failure tahmin, high severity veya farklı workload sonucu değildir.
- İlk high profil ön-kaydı: `cpu-recommendation-high-v1`, recommendationservice için `+150m` talep ve en az `+75m` fiziksel etki; ramp/steady/cooldown `120/300/300 sn`. Workload, seed, SLO, hedef, coverage ve D-026 lifecycle-seri seçimi değişmez. İlk aday `ob-cpu-high-001`; merge, temiz preflight ve ayrı yürütme onayı öncesi başlamaz. Null manifestation geçerli olabilir; profil farklı workload/service veya model eğitimi yetkisi vermez.
- `ob-cpu-high-001`: coverage `59/59`, baseline `11,564m`, steady `158,153m`, fark `+146,589m`; throttling `13,236m`; host/pod/telemetry/final receipt ve bağımsız offline verifier geçti. 205 tam pencerede yalnız bir latency ihlali oluştu, üçlü streak olmadığı için manifestation null kaldı. İlk geçerli high adaydır; tek run high tekrarlanabilirliğini veya workload/service/SLO değişikliğini kanıtlamaz.
- High tekrar planı: `ob-cpu-high-002` ve `ob-cpu-high-003`, D-029 ile `ob-cpu-high-001` koşulları değiştirilmeden iki bağımsız tekrar olarak ön-kaydedildi. Her run ayrı canonical revision, artifact, host-health, active run-ID ve receipt kapılarıyla kapanır. Üç geçerli high aday oluşmadan varyans özeti dondurulmaz; plan farklı workload/service, SLO değişikliği veya model eğitimi yetkisi vermez.
- `ob-cpu-high-002`: coverage `59/59`, baseline `13,375m`, steady `157,193m`, fark `+143,819m`; throttling `14,891m`; host/pod/telemetry/final receipt ve bağımsız offline verifier geçti. 205 tam pencerede latency veya global-error ihlali oluşmadı ve manifestation null kaldı. İkinci geçerli high adayı ve ilk bağımsız tekrardır; `003` tamamlanmadan üç-geçerli-run özeti yapılmaz.
- `ob-cpu-high-003`: coverage `59/58`, baseline `13,299m`, steady `163,715m`, fark `+150,416m`; throttling `47,804m`; host/pod/telemetry/final receipt ve bağımsız offline verifier geçti. 206 tam pencerede dört latency ihlali vardı; maksimum streak iki olduğu için dondurulmuş üçlü kuralı karşılamadı ve manifestation null kaldı. Üçüncü geçerli high adayıdır.
- High üç-run özeti: `001/002/003` CPU artışı ortalama `146,941m`, sample SD `3,313m`, CV `%2,254`, aralık `143,819–150,416m`; üçünde de manifestation null. Bu sabit koşullarda fiziksel actuation ve null manifestation için betimsel tekrarlanabilirliktir; pre-failure tahmin, model başarısı, SLO değişikliği veya yeni kapsam sonucu değildir.
- D-030 kapasite planı: 10-user kontrol ile 15/20-user adayları fault uygulanmadan, seed `20260810` ile `20 -> 10 -> 15` sırasında karşılaştırılır. Seçim active run-ID, pod/host/schema-v3 telemetry, frozen-SLO false manifestation, `>=1,30x` frontend request-intensity ve recommendationservice mean CPU `<=25m` kapılarına bağlıdır. Tooling koşuları dataset'e girmez. Aday seçilirse üç normal baseline ve önceden randomize edilmiş altı fault run ayrıca toplanır.
- `ob-capacity-20u-001`: fault'suz ilk kapasite attempt'i; active run-ID, log, schema-v3 telemetry, host `0/0/0` ve null manifestation kanıtları geçti. Pod-stability false sonucunun bileşen snapshot'ları ilk runner tarafından yazılmadı ve CPU özeti birden fazla cAdvisor serisiyle kontamine oldu. Invalid korunur, seçimde/dataset'te kullanılmaz ve D-031 düzeltmesiyle retroaktif kabul edilmez.
- `ob-capacity-10u-001`: active run-ID ve 300 saniye warm-up geçti; canonical 10-user profilinin `normal_baseline_seconds` alanı ilk runner'ın beklediği `measurement_seconds` adından farklı olduğu için measurement başlamadan kapandı. Invalid/incomplete korunur ve dataset/seçimde kullanılmaz. D-032 tarihsel profili değiştirmeden iki alanı 300 saniyelik tek internal sözleşmeye normalize eder.
- `ob-capacity-10u-002`: geçerli fault'suz kapasite kontrolü; frontend user-server span rate `2,492375/s`, recommendationservice mean CPU `26,011m`, p95 `116,334m`; frozen-SLO manifestation null, pod ve host `0/0/0` kapıları ile schema-v3 telemetry geçti. D-030 aday oranlarının aynı-gün paydasıdır; bilimsel dataset'e girmez.
- `ob-capacity-15u-001`: geçerli fault'suz kapasite kanıtı; request rate `3,532528/s` ve 10-user oranı `1,417334x` ile yoğunluk kapısını geçti. Recommendationservice mean CPU `35,890m` olduğu için ön-kayıtlı `<=25m` headroom kapısını geçmedi. SLO null, pod/host/schema-v3 telemetry geçti; aday seçilmez ve dataset'e girmez.
- `ob-capacity-20u-002`: D-031 uyumlu geçerli fault'suz kapasite kanıtı; request rate `4,755222/s` ve 10-user oranı `1,907908x`; recommendationservice mean CPU `43,015m`, p95 `152,573m`. SLO null, pod/host/schema-v3 telemetry geçti fakat `<=25m` CPU kapısı geçmedi. D-030 selector `selected_users=null` üretti; hiçbir ikinci workload aktive edilmedi ve tooling kanıtı dataset'e girmez.
- D-033 ikinci-workload ön-kaydı: `ob-second-15u-1r-v1`, D-030'u geriye dönük değiştirmeyen prospektif `normal mean CPU <=40m` kapısıyla seçildi. `ob-capacity-15u-001` yalnız seçim kanıtıdır; dataset'e girmez. Bilimsel blok üç yeni normal baseline ve workload'a özgü, fiziksel koşulları değişmeyen low/medium/high profillerinin ikişer randomize tekrarından oluşur. İlk normal aşağıda tamamlanmıştır; kalan run'lar yalnız bütün geçerlilik kapıları geçerse geçerli bilimsel run sayısına eklenir.
- `ob-cpu-15u-normal-001`: ilk geçerli 15-user bilimsel normal baseline. Fault yok; host `0/0/0`, pod lifecycle, raw/enriched log, schema-v3 telemetry, scientific metadata, final receipt ve bağımsız replay kapıları geçti. 533.101 metric sample, 3.851 selected trace, 46.830 span ve 26.421 enriched log üretildi; 60 tam SLO penceresinde manifestation null. Recommendationservice mean/p95 CPU `39,807/166,516m`. Tek run tekrarlanabilirlik değildir; `002/003` beklenir.
- `ob-cpu-15u-normal-002`: invalid fault'suz normal girişimi; dataset'e dahil edilmez. Host `0/0/0`, pod lifecycle ve bağımsız raw/enriched/schema-v3 replay kapıları geçti; 516.271 metric sample, 3.800 selected trace, 45.980 span ve 26.227 enriched log korundu. Frozen `345,992 ms` latency eşiği 30/31/32 numaralı pencerelerde art arda aşıldı ve `2026-08-11T19:10:07.812Z` manifestation üretti. Mean CPU `43,612m` raporlanır fakat D-033 seçim eşiği run dışlama kuralı değildir. Geçerli bilimsel run sayısı ve 15-user normal blok ilerlemesi değişmez.
- `ob-cpu-15u-normal-003`: ikinci geçerli 15-user bilimsel normal baseline. Fault yok; host `0/0/0`, pod lifecycle, raw/enriched log, schema-v3 telemetry, scientific metadata, final receipt ve bağımsız replay kapıları geçti. 524.692 metric sample, 3.765 selected trace, 45.877 span ve 26.016 enriched log üretildi; 60 tam SLO penceresinde manifestation null ve maksimum latency/error serisi `1/0`. Recommendationservice mean/p95 CPU `41,816/178,013m`; 40m seçim kapısı run dışlama kuralı değildir. Geçerli blok `2/3` olur.
- `ob-cpu-15u-normal-004`: `002` için yeni benzersiz replacement ve üçüncü geçerli 15-user bilimsel normal baseline. Fault yok; host `0/0/0`, pod, raw/enriched, schema-v3 telemetry, metadata, final receipt ve bağımsız replay kapıları geçti. 495.764 metric sample, 3.743 selected trace, 45.864 span ve 25.876 enriched log üretildi; 60 tam SLO penceresinde manifestation null, maksimum latency/error serisi `1/0`. Recommendationservice mean/p95 CPU `22,585/101,196m`. Geçerli normal seti `001/003/004`, blok `3/3`; `002` invalid kalır.
- `ob-cpu-15u-medium-002`: randomize fault serisinin ilk girişimi `invalid/incomplete`; dataset'e dahil edilmez. Warm-up ve normal baseline tamamlandı, fakat injector allowlist'i ön-kayıtlı 15-user profil kimliğini tanımadığı için bounded worker başlamadan fail-closed durdu ve fault uygulanmadı. `run-error.json` korunur, ID yeniden kullanılmaz. Profil fiziği/eşikleri değişmeden D-036 düzeltmesi sonrası `ob-cpu-15u-medium-003` replacement olur.
- `ob-cpu-15u-medium-003`: D-036 sonrası fault lifecycle ve cooldown tamamlandı; tanısal replay coverage `59/59`, CPU farkı `+99,972m`, host `0/0/0`, manifestation null ve raw/enriched/schema-v3 bütünlüğü geçti. Ancak dış runner 40 dakikada scientific metadata/final receipt öncesi sonlandırıldı ve tam-run pod-after kanıtı metadata'ya yazılmadı. Bu nedenle `invalid/incomplete`, dataset dışı ve retroaktif valid yapılamaz; aynı randomize slot D-037 ile en az 60 dakikalık dış timeout altında yeni `medium-004` ID ile tekrarlanır.
- `ob-cpu-15u-medium-004`: D-037 altında 65 dakikalık dış bütçeyle runner `43,7` dakikada kapandı. Coverage `59/59`, mean CPU `32,664m -> 127,119m`, fark `+94,454m`; host `0/0/0`, pod, raw/enriched, schema-v3 telemetry, metadata, final receipt ve bağımsız replay kapıları geçti. 205 tam SLO penceresinde manifestation null kaldı. İlk randomize slotun geçerli bilimsel adayıdır; tek run medium tekrarlanabilirliği veya model başarısı kanıtlamaz.
- `ob-cpu-15u-low-002`: ikinci randomize slotun ilk girişimi `invalid/incomplete`; dataset'e dahil edilmez. Minikube hazır olmadığı için runner ilk active run-ID kapısında, warm-up/baseline/fault başlamadan fail-closed durdu. `run-error.json` korunur, ID yeniden kullanılmaz; aynı frozen koşullar yeni `ob-cpu-15u-low-003` replacement ile tamamlanır.
- `ob-cpu-15u-low-003`: active run-ID/workload ile 300 sn warm-up ve 300 sn baseline geçti; bounded worker başlarken Kubernetes `server` container'ını bulamadı. Fault uygulanmış kabul edilmez; `invalid/incomplete`, dataset dışı ve ID kullanılamaz. Host farkı `0/0/0` idi. Yeni replacement öncesi hedef pod/container restart-stability ve exec-yarışı kapısı ön-kaydedilmelidir; akademik fault koşulları değiştirilmez.
- D-038/`ob-cpu-15u-low-004` ön-kaydı: hedef pod/container warm-up öncesinde 120 sn boyunca 5 sn cadence ile değişmeyen Ready/pod UID/container ID/restart koşulunu sağlamalı ve worker öncesi aynı kimlik tekrar doğrulanmalıdır. Retry yoktur. Aynı `cpu-recommendation-low-15u-v1`, workload, seed, SLO, 300/300/120/300/300 lifecycle, `+25m` ve 48/48 fiziksel-etki kapıları değişmez. Tooling testi dataset'e girmez; `low-004` yalnız bütün bilimsel kapıları geçerse geçerli run sayısına eklenir.
- `ob-cpu-15u-low-004`: D-038 25 gözlem/restart `0`; coverage `59/59`, mean CPU `20,319m -> 69,472m`, fark `+49,153m`; host `0/0/0`, pod, raw/enriched, schema-v3, metadata, final receipt ve bağımsız replay kapıları geçti. 205 tam SLO penceresinde manifestation null kaldı. İkinci randomize slotun geçerli bilimsel adayıdır; tek run low tekrarlanabilirliğini kanıtlamaz.
- `ob-cpu-15u-high-001`: D-038 25 gözlem/restart `0`; coverage `59/58`, mean CPU `36,646m -> 171,806m`, fark `+135,160m`; 143 throttling intervali ve `99,790m` ortalama eşdeğer gözlendi. Host `0/0/0`, pod, raw/enriched, schema-v3, metadata, final receipt ve bağımsız replay kapıları geçti. 205 tam SLO penceresinde manifestation null kaldı. Üçüncü randomize slotun geçerli bilimsel adayıdır; tek run high tekrarlanabilirliğini kanıtlamaz.
- `ob-cpu-15u-high-002`: D-038 25 gözlem/restart `0`; coverage `59/59`, mean CPU `36,479m -> 182,190m`, fark `+145,710m`; 144 throttling intervali ve `137,848m` ortalama eşdeğer gözlendi. Host `0/0/0`, pod, raw/enriched, schema-v3, metadata, final receipt ve bağımsız replay kapıları geçti. 205 tam SLO penceresinde manifestation null kaldı. Dördüncü randomize slot ve ikinci geçerli high adayıdır; blok bitmeden nihai varyans yorumu yapılmaz.
- `ob-cpu-15u-low-001`: D-038 25 gözlem ve sabit restart `1`; coverage `59/59`, mean CPU `38,294m -> 91,337m`, fark `+53,044m`; 144 throttling intervali ve `77,737m` ortalama eşdeğer gözlendi. Host `0/0/0`, pod, raw/enriched, schema-v3, metadata, final receipt ve bağımsız replay kapıları geçti. 205 tam SLO penceresinde manifestation null kaldı. Beşinci randomize slot ve ikinci geçerli low adayıdır; son medium slot beklenir.
- `ob-cpu-15u-medium-001`: son randomize slot girişimi `invalid/incomplete`; dataset'e dahil edilmez ve ID yeniden kullanılamaz. D-038 25 gözlem/sabit restart `3`, coverage `60/59`, mean CPU `19,709m -> 120,099m`, fark `+100,390m`, host `0/0/0`, pod/raw/enriched/schema-v3 replay ve manifestation null tanısal olarak geçti. Ancak canonical warm-up UTC süresi `299,9970699 sn` ile frozen 300 saniye kapısının `0,0029301 sn` altında kaldı; metadata verifier `warmup_too_short` dedi ve final receipt oluşmadı. Ön-finalization `valid_run=true` ara alanı receipt başarısızlığını geçersiz kılamaz. Geçerli bilimsel run sayısı `20`, fault bloğu `5/6` kalır; eşikler gevşetilmez ve sonraki aşamaya geçilmez.
- `ob-cpu-15u-medium-005`: D-039 replacement'ı ve ikinci geçerli 15-user medium adayı. D-038 25 gözlem/sabit restart `1`; D-039 warm-up/baseline/cooldown `300,0175/300,0160/300,0119 sn`; coverage `59/59`, mean CPU `41,102m -> 134,621m`, fark `+93,519m`, throttling `69,644m`. Host `0/0/0`, pod, raw/enriched, schema-v3, metadata, final receipt ve bağımsız replay kapıları geçti. 205 tam SLO penceresinde manifestation null kaldı. Geçerli bilimsel run sayısı `21`, ikinci-workload fault bloğu `6/6` olur.
- İkinci-workload fault blok özeti: low/medium/high fiziksel CPU artışı ortalamaları sırasıyla `51,098/93,987/140,435m`; sample SD `2,751/0,661/7,460m`; CV `%5,384/%0,704/%5,312`. Her severity iki geçerli run içerir ve altısında da manifestation null'dır. Bu fiziksel actuation için betimsel tekrar kanıtıdır; pozitif SLO olayı, pre-failure tahmin veya sonraki aşama yetkisi değildir.
- Telemetri örnekleme oranları: 21/21 geçerli run raw/enriched log, schema-v3
  metric/trace, run-ID/UTC, final receipt ve offline replay kapılarını geçti.
  Canonical feature-window tablosu henüz üretilmediği için feature-level modalite
  missingness oranı raporlanamaz.
- Geçerli run oranı: P1-CPU-001 altında `21/35 = %60`; 14 invalid attempt kanıtıyla
  korunur ve dataset'e alınmaz.
- Gözlenen pre-failure sinyaller: Geçerli 15 fault run'da manifestation `0/15` ve
  pozitif lead-time örneği `0`; bu nedenle pre-failure sınıf ayrımı değerlendirilmedi.
- Seçilen final window/horizon: D-006'nın 5 saniye pencere ve ana 30 saniye horizon
  pilot varsayımı değişmedi; pozitif manifestation olmadığı için Dataset v1 feature
  sözleşmesi olarak dondurulmadı.
- Dataset v1 için run sayısı gerekçesi: P1 fiziksel actuation fizibilitesini iki
  workload ve üç severity altında destekledi; ancak olay oranı sıfır olduğu için
  O-004 sayısal Dataset v1 hedefi mevcut CPU etiketiyle çözülemez. Dataset v1'e
  geçilmez; yeni fault/target/severity/SLO tasarımı açık karar ve ayrı ön-kayıt ister.
- P2 network-delay `ob-netdelay-15u-001` ve `002` invalid kalır ve Dataset v1/modeling
  kapsamına alınmaz. D-045 fault-class-aware receipt düzeltmesi ile koşulları
  değişmeyen `ob-netdelay-15u-003` yalnız ön-kaydedilmiştir; henüz veri üretmemiştir.
- `ob-netdelay-15u-003` preflight'ta `live_proxy_pod_count_mismatch` ile invalid/
  incomplete kapandı. Warmup ve fault başlamadı; raw/enriched/metric/trace üretilmedi.
  Bu yokluk invalid-preflight receipt ile doğrulandı; rollback ve host `0/0/0` geçti.
  Run Dataset v1/modeling dışıdır ve ID yeniden kullanılamaz.
- D-046, koşulları değişmeyen `ob-netdelay-15u-004` replacement'ını bounded tek-Ready-
  pod convergence ve exception host-after kapanışıyla yalnız ön-kaydeder. Henüz veri
  üretmemiştir ve canonical merge/açık onay olmadan çalıştırılamaz.
- `ob-netdelay-15u-004` D-046 penceresinde invalid/incomplete kapandı: 22 gözlemde
  pod sayısı `2 -> 1` yakınsadı fakat Ready true `0/22` kaldı. Warmup/fault ve bütün
  veri modaliteleri başlamadı; rollback, host `0/0/0` ve invalid receipt `8/8` geçti.
  Dataset/modeling dışıdır ve ID kullanılamaz.
- `ob-network-proxy-readiness-001/002/003` fault'suz operasyonel tanılardır ve Dataset
  v1'e alınmaz. Tamamlanan `003`, 33 gözlemde proxy `33/33` Ready/0 restart ve server
  `30/33` Ready/1 restart gösterdi; rollback ve host `0/0/0` geçti. Bu kanıt
  `ob-netdelay-15u-004` için bilimsel outcome veya model örneği üretmez.
- `ob-netdelay-15u-005` D-047'nin ayrıntılı bounded preflight kapısında invalid/
  incomplete kapandı. Proxy `22/22` Ready ve 0 restart iken server yalnız `1/22`
  Ready oldu, restart `0 -> 4` yükseldi ve son durum CrashLoopBackOff idi. Warmup,
  fault ve raw/enriched/metric/trace modaliteleri başlamadı; run Dataset v1/modeling
  dışıdır ve ID kullanılamaz. Exit `137` tek başına OOM/kök neden etiketi oluşturmaz.
- `ob-network-server-termination-001` faultsuz operasyonel tanıdır ve Dataset v1'e
  alınmaz. Kubernetes events server'ı başarısız 1 saniyelik gRPC liveness probe
  sonrasında 5 kez restart ettiğini; node pressure false ve status OOMKilled olmadığını
  gösterdi. Metrics API yokluğu nedeniyle probe timeout'unun alt nedeni etikete
  dönüştürülmez.

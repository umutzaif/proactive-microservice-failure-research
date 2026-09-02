# Dataset Card

## 1. Kimlik

- Geçici ad: **Proactive Microservice Failure Dataset v0**
- Durum: Pilot öncesi taslak
- Ana sistem adayı: Online Boutique
- Üretim biçimi: Açık benchmark üzerinde kontrollü fault injection
- Amaç: Pre-failure classification, LLM evidence verification ve root-cause service ranking
- Geçerli bilimsel run sayısı: **23**. P1 CPU setinde 21 geçerli run bulunur. Buna ek olarak `ob-netdelay-15u-008` ve `ob-netdelay-15u-repeat-001` geçerli 750ms exploratory network-delay pilotlarıdır. Bu iki koşu yeni mentor-gated ladder veya confirmatory örnek sayısına katılmaz. Invalid attempt'ler korunur ve dataset'e alınmaz.

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
| network_delay | Aday | Evet | `008` ve `repeat-001` geçerli 750ms exploratory pilotlardır; yeni `25/50/100/250/500 ms` iki-workload ladder'ına veya confirmatory örnek sayısına katılmaz. Diğer invalid attempt'ler korunur |
| service_degradation | Pilot sonrası | Evet | Doğal öncül sinyali olan mekanizma seçilmeli |
| pod_kill | Hayır/negatif kontrol | Evet | Ani hata; predictive başarı iddiasına dahil edilmez |

## 6. Toplama hedefi

Network-delay ladder tarama hedefi:

- `25/50/100/250/500 ms` x iki workload hücresi;
- hücre başına sonuç görülmeden önce belirlenmiş üç bağımsız geçerli tekrar;
- 500m sistem profili altında iki workload için sıfırdan toplanmış normal baseline'lar;
- en az bir hücrede 3 tekrarın en az 2'sinde manifestation ve en az 15 saniye
  pozitif lead-time; aksi durumda `2026-09-15` takvim kapısı uygulanır.

Confirmatory çalışma hedefi:

- aynı pozitif incident'larda proposed-model-vs-rule-baseline eşlenmiş karşılaştırması
  için 60 bağımsız pozitif incident;
- false-alarm/hour ve negatif davranış için ayrıca 60 bağımsız normal kontrol;
- run/incident bağımsız birimdir; aynı run içindeki pencereler örnek sayılmaz;
- ladder ve tarihsel 750ms exploratory koşuları confirmatory sayıya katılmaz.

Pozitif-incident hedefi `alpha=0,05`, güç `0,80`, 25 yüzde puanı en küçük anlamlı
iyileşme ve 0,45 discordant-pair oranı varsayımlarına dayanır. Normal kontroller
McNemar hesabına girmez. Değişiklik yeni prospektif karar ve hesap gerektirir.

## 7. Bölme

- Train/validation/test yalnızca run düzeyinde ayrılır.
- Varsayılan oran pilot sonrası belirlenecek; küçük run sayısında grouped cross-validation tercih edilebilir.
- Ayrı challenge split'leri: unseen severity/workload ve unseen service.

## 8. Bilinen yanlılıklar ve tehditler

- Sentetik fault injection gerçek üretim arızalarının tüm çeşitliliğini temsil etmez.
- Benchmark topolojisi gerçek büyük ölçekli sistemlerden küçüktür.
- Workload generator davranışı sınıflarla istemeden korelasyon kurabilir.
- Injection schedule modele sızabilecek periyodik izler oluşturabilir.
- Sistem resource profili değiştiğinde eski normal baseline'ı yeni treatment ile
  karşılaştırmak configuration confounding oluşturur.
- Readiness/liveness yolunun injected delay ile kesişmesi probe restartını scientific
  manifestation ile karıştırabilir; health path fault etkisinin dışında tutulmalıdır.
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
- Telemetri örnekleme oranları: 22/22 geçerli run (21 P1 CPU + 1 P2 network-delay)
  raw/enriched log, schema-v3
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
- `ob-netdelay-15u-007` runner'ın `ShouldProcess` girişinde, cluster/preflight/lifecycle
  başlamadan invalid/incomplete kapandı. Ham/enriched/metric/trace/lifecycle verisi
  üretilmedi; Minikube stopped, host `0/0/0` ve diagnostic seal/replay `5/5` geçti.
  Dataset v1/modeling dışıdır, ID kullanılamaz ve bilimsel eşikler değerlendirilmedi.
- `ob-netdelay-15u-008` ilk geçerli network-delay dataset adayıdır. D-038 25 gözlem/
  restart 0; 60/60 baseline ve steady coverage; median `3,238 -> 755,233 ms`, fiziksel
  etki `+751,995 ms`; ilk semptom `18:24:33.328Z`, latency manifestation
  `18:25:43.328Z` oldu. Host `0/0/0`, pod/cleanup/rollback, raw/enriched/schema-v3 ve
  final receipt replay geçti. 5 boundary-crossing trace hamda korunup selected dışıdır.
  Tek run tekrarlanabilirlik veya model başarısı sağlamaz. Raw verifier Windows
  PowerShell'de canonicaldır; pwsh 7 UTC milisaniye string-cast davranışı bilinen
  portability sınırlılığıdır ve veri/eşik değiştirilmeden raporlanır.
- D-058 tekrarlanabilirlik pilotu: `008` randomize edilmemiş fizibilite kanıtı olarak
  ayrı tutulur. Dört yeni eşlenmiş no-toxic kontrol/fault bloğu seed `20260821` ile
  `fault-control, fault-control, control-fault, control-fault` sırasına dondurulmuştur.
  Bağımsız birim run'dır; aynı run'ın 60 penceresi örnek büyüklüğünü 60 yapmaz. Dört
  geçerli çift yalnız varyans, false-manifestation ve sıra etkisi için pilot kanıtıdır;
  nihai örnek büyüklüğü ve Dataset v1 geçişi ayrıca akademik karar gerektirir.
- `ob-netdelay-15u-repeat-001`, D-058 çizelgesindeki ilk randomize fault slotu olarak
  D-059 ile ön-kaydedildi. Koşullar `008` ile aynıdır; henüz canlı run değildir. Tek
  başına tekrarlanabilirlik sağlamaz ve sonraki slot `control-001` olarak sabittir.
- `ob-netdelay-15u-repeat-001` geçerli tamamlandı: coverage `60/60`, median edge
  latency `5,548 -> 755,171 ms`, etki `+749,623 ms`, ilk semptom `29,397 sn`, latency
  manifestation `104,397 sn`, host `0/0/0`, cleanup/rollback ve bütün replay kapıları
  geçti. `008` ile iki etki ortalaması `750,809 ms`, sample SD `1,677 ms`, CV yaklaşık
  `%0,223`tür. Bu ilk fault tekrarının betimsel kanıtıdır; paired blok `1/2`dir.
- D-060 `control-001` sözleşmesi: aynı overlay/workload/resource/lifecycle altında toxic
  yoktur; matched interval latency farkı yalnız betimseldir. Geçerli kontrol için
  coverage, dört temiz toxic snapshotı, null manifestation, pod/host/telemetry/receipt
  kapıları gerekir. Sözleşme runner veya canlı veri değildir.
- `ob-network-server-termination-001` faultsuz operasyonel tanıdır ve Dataset v1'e
  alınmaz. Kubernetes events server'ı başarısız 1 saniyelik gRPC liveness probe
  sonrasında 5 kez restart ettiğini; node pressure false ve status OOMKilled olmadığını
  gösterdi. Metrics API yokluğu nedeniyle probe timeout'unun alt nedeni etikete
  dönüştürülmez.
- `ob-network-probe-resource-001` faultsuz fakat host-health kanıtı non-monotonic
  (`WHEA 881 -> 879`) olduğu için invalid/incomplete diagnostictir ve Dataset v1'e
  alınmaz. Restart yeniden üretilmedi; OOM/failcnt/memory-pressure 0, CPU throttling
  ve pressure betimsel gözlemleri nedensel etiket değildir.
- Değişmeyen `ob-network-probe-resource-002`, RecordId host kapısıyla geçerli
  tamamlanmış tanıdır: beş liveness kill ile %100 ölçülmüş CFS throttled-period ve
  CPU pressure eşzamanlı, OOM/memory/node pressure yoktur. Diagnostic kanıtı
  fault/modeling örneği değildir.
- D-050 `ob-network-resource-compat-001` yalnız no-toxic resource compatibility
  ön-kaydıdır. İlk yürütme JSON parser preflight'ında invalid/incomplete kapandı;
  stability/measurement/fault verisi üretmedi. Scientific network-delay
  fault/modeling örneği olarak Dataset v1'e alınmaz.
- D-051 `ob-network-resource-compat-002` replacement'ı da canlı deployment JSON
  ayrıştırmasında invalid/incomplete kapandı. Run-ID/workload kapıları geçti fakat
  stability, resource ölçümü ve fiziksel etki başlamadı; toxic/fault uygulanmadı.
  Dört dosyalık immutable kapanış kanıtı korunur, Dataset v1'e alınmaz.
- D-052 `ob-network-resource-compat-003` replacement'ı `KJson` argüman bağlama
  preflight'ında invalid/incomplete kapandı. Stability/resource/fiziksel-etki verisi
  üretmedi ve toxic/fault uygulanmadı; immutable kapanış kanıtı Dataset v1 dışıdır.
- D-053 `ob-network-resource-compat-004` no-toxic run'ında lifecycle, 13/13 metric,
  fiziksel etki, host ve rollback kapıları geçti; ancak verifier hard-coded `002`
  run-ID raporladı ve provenance eşleşmesini sınamadı. Bu nedenle 19/19 mühürlü kanıt
  korunur fakat run invalid kalır ve Dataset v1'e alınmaz.
- D-054 `ob-network-resource-compat-005` geçerli no-toxic compatibility kanıtıdır:
  lifecycle, 13/13 metric/180 sn, fiziksel etki, provenance, host, rollback ve 19/19
  seal/replay geçti. Fault uygulanmadığı için Dataset v1 failure/modeling örneği
  değildir; yalnız 500m altyapı compatibility kararını destekler.
- `ob-netdelay-15u-006` compositional overlay verifier preflight'ında fault/warmup
  başlamadan invalid kapandı; altı mühürlü kapanış kanıtı korunur, Dataset v1'e alınmaz.
- D-071 `ob-network-base-readiness-001`, `10u-002` sonrasında mevcut base manifest ve
  10u workload altında faultsuz readiness/stability tanısıdır. Proxy/resource overlay,
  toxic, warm-up, baseline ve bilimsel pencere yoktur. Sonuç ne olursa olsun Dataset v1,
  D-067 headroom ve bağımsız incident sayımına alınmaz; yalnız taze operasyonel
  readiness/stability desteği olarak yorumlanır ve nedensel etiket üretmez.
- `ob-network-base-readiness-001`, Docker engine yokken Minikube başlamadan invalid
  kapandı; Dataset v1'e alınmaz ve ID kullanılmaz. Host `0/0/0` ile dört dosyalık seal
  korunur. D-072 `ob-network-base-readiness-002`yi aynı dataset-dışı/no-fault sınırla
  ön-kaydeder; replacement da model veya headroom örneği değildir.
- `ob-network-base-readiness-002`, Docker hazır olmasına rağmen Minikube API server
  süreci hiç oluşmadığı ve `K8S_APISERVER_MISSING` verdiği için deployment/workload
  öncesi invalid kapandı. Fault ve bilimsel pencere başlamadı; host `0/0/0`, cluster
  stopped ve dört çekirdek dosyalık SHA replay geçti. Readiness observation/assessment
  üretilmediğinden Dataset v1, D-067 headroom veya incident sayımına alınmaz; ID tekrar
  kullanılmaz.
- D-073 `ob-k8s-bootstrap-001`, yalnız stale Minikube profile/volume hipotezini aynı
  cluster kaynak sözleşmesiyle temiz bootstrap üzerinden sınayan operasyonel tanıdır.
  Application/workload/toxic/fault ve bilimsel pencere yoktur; sonucu Dataset v1,
  D-067 headroom veya incident sayımına hiçbir durumda alınmaz.
- `ob-k8s-bootstrap-001` geçerli tamamlandı: exact stale profile yokluğu ardından aynı
  cluster sözleşmesinde clean start ve 30/30 system stability örneği geçti; host `0/0/0`,
  cluster stop, semantic verifier ve 12/12 SHA replay doğrulandı. Bu yalnız operasyonel
  bootstrap kanıtıdır ve recommendationservice etiketi ya da model örneği değildir.
- D-074 `ob-network-base-readiness-003`, D-073 clean-bootstrap kanıtı sonrasında eksik
  recommendationservice application-level readiness/stability gözlemini değişmeyen D-071
  koşullarıyla hedefleyen ön-kayıttır. Canlı veri değildir; çalıştırılsa da sonucu Dataset v1,
  D-067 headroom veya incident sayımına girmez ve normal/fault yetkisi üretmez.
- `ob-network-base-readiness-003`, API server süreci hiç oluşmadan
  `K8S_APISERVER_MISSING` ile invalid/incomplete kapandı. Application/workload/readiness
  gözlemi üretmedi; host `0/0/0`, cluster stopped ve dört çekirdek dosyanın SHA replay'i
  geçti. Dataset v1/D-067/incident sayımına alınmaz ve ID yeniden kullanılmaz.
- D-076 `ob-minikube-state-postmortem-001`, D-075 sonrası yalnız state-root provenance
  ve durmuş profile metadata/log kanıtını read-only topladı. Repository-local root eşleşti;
  exact container `exited`, exact volume/profile config/lastStart mevcuttu ve loglar
  `K8S_APISERVER_MISSING` sonucunu korudu. Semantic verifier ile 9/9 SHA replay geçti.
  Application, workload, fault veya bilimsel pencere yoktur; sonuç Dataset v1, D-067
  headroom ve incident sayımına alınmaz ve tek kök neden kanıtı değildir.
- D-079 `ob-k8s-bootstrap-observe-001`, korunmuş durmuş profile'ın bootstrap başlangıcında
  58 process örneği ve live kubelet/containerd kanıtı üreten geçerli operasyonel tanıdır.
  `K8S_APISERVER_MISSING` öncesinde kubelet'in eksik `bootstrap-kubelet.conf` nedeniyle
  restart ettiği gözlendi; bu benzersiz kök neden değildir. `start_exit_code=null` ve CRI
  capture'ın liste yerine help çıktısı üretmesi kayıtlı kanıt sınırlamalarıdır. Application,
  workload, proxy/toxic, bilimsel pencere ve fault içermediğinden Dataset v1, D-067 headroom
  ve incident sayımına alınmaz.
- D-081 `ob-k8s-bootstrap-state-consistency-001`, D-079 sonrası planned operasyonel
  state-consistency tanısı olarak çalıştırıldı fakat ilk live inspect parse hatasında
  snapshot/assessment öncesi invalid/incomplete kapandı. Application/workload/fault yoktur;
  7/7 seal replay geçti. Dataset v1, D-067 headroom ve incident sayımına alınmaz.
- D-082 `ob-k8s-bootstrap-state-consistency-002`, invalid `001`in koşulları değişmeyen
  operational replacement'ı olarak koştu; zorunlu state capture'lar `exit_code=2` ve boş
  stdout ürettiği için invalid/incomplete kapandı. Application/workload/fault içermez ve
  Dataset v1, D-067 headroom veya incident sayımına alınmaz.
- D-084 `ob-k8s-bootstrap-state-consistency-003`, aynı koşullarda planned operational
  replacement olarak geçerli tamamlandı. Partial-state tutarsızlığını iki live boundary'de
  doğruladı; application/workload/fault içermez ve Dataset v1, D-067 headroom veya incident
  sayımına alınmaz.
- D-085 `ob-k8s-bootstrap-recovery-001`, D-084 sonrası exact profile clean reconstruction
  recoverability tanısı olarak geçerli tamamlandı: 31/31 system stability, host/verifier ve
  12/12 replay geçti. Application/workload/fault içermez ve Dataset v1, D-067 headroom veya
  incident sayımına alınmaz.
- D-086 `ob-network-base-readiness-004`, kapalı D-075 `003` kimliği yerine D-085 sonrası
  application-level recommendationservice readiness/stability boşluğunu aynı D-071/D-074
  koşullarıyla hedefleyen ön-kayıttır. Sonucu ne olursa olsun Dataset v1, D-067 headroom
  veya incident sayımına alınmaz; normal replacement veya fault yetkisi üretmez.
- `ob-network-base-readiness-004`, worktree-local pinned upstream source eksikliği nedeniyle
  base apply öncesinde invalid/incomplete kapandı. Application/workload/readiness başlamadı;
  dört dosyalık kapanış korunur, ID kapalıdır ve Dataset v1/D-067 sayımına alınmaz.
- D-087 `ob-network-base-readiness-005`, aynı Dataset-dışı application tanısını yalnız exact
  upstream source revision preflight ekleyerek ön-kaydeder. Başarı veya başarısızlık Dataset
  v1, D-067 headroom ya da incident örneği oluşturmaz.
- `ob-network-base-readiness-005`, source/start/base apply sonrasında erken pod status'ta
  `containerID` yokluğu nedeniyle observation öncesi invalid/incomplete kapandı. Base + 10u
  uygulanmış olsa da readiness sonucu yoktur; dört dosyalık kapanış Dataset v1/D-067 dışıdır.
- D-088 `ob-network-base-readiness-006`, eksik erken pod alanlarını null observation olarak
  koruyan deterministic fixture'lı replacement ön-kaydıdır. Sonucu Dataset v1, D-067
  headroom veya incident sayımına girmez.
- `ob-network-base-readiness-006` olumlu `fresh_base_stability_supported` assessment üretti,
  fakat zorunlu semantic verifier `$Host` alias çakışmasında durduğu ve runner child exit'i
  reddetmediği için invalid/incomplete kaldı. 13 dosyalık kanıt korunur; assessment Dataset
  v1, D-067 headroom veya incident örneği değildir.
- D-089 `ob-network-base-readiness-007`, alias-safe verifier ve zorunlu child exit-code
  kapısıyla aynı Dataset-dışı tanıyı ön-kaydeder. Sonucu Dataset v1/D-067'e girmez.
- `ob-network-base-readiness-007` geçerli operational diagnostic olarak tamamlandı:
  availability, 33 stability sample, tek UID, stability boyunca sabit restart `2`, all Ready,
  semantic verifier, host ve 13-file replay geçti. Convergence sırasındaki iki restart
  korunur. Sonuç Dataset v1, D-067 headroom veya incident sayımına alınmaz.
- D-091 `ob-netdelay-500m-normal-10u-004` yalnız geçersiz `10u-002` D-067 yuvasının
  prospektif no-fault telafisidir. Ön-kayıt Dataset örneği değildir; canlı başarı dahi
  tek başına Dataset v1, headroom/severity veya fault yetkisi üretmez.
- D-092 `ob-netdelay-500m-normal-10u-004` runtime'ını `deploy_base` sınırında
  invalid/incomplete kapatır. Bilimsel pencere/fault yoktur; rollback, profile stop ve
  host-after doğrulanmamıştır. Kanıt Dataset v1 ve D-067 sayımlarına alınmaz.
- D-093 `ob-docker-disk-recovery-001`, 15 GiB host-free preflight'lı system-only recovery
  preregistration'ıdır. Çalıştırılsa da application/workload/fault örneği değildir ve
  Dataset v1, D-067 headroom veya incident sayımına alınmaz.
- D-094 aynı kimliği 15 GiB gate, exact delete/yokluk, 31/31 system stability, host,
  verifier ve 12-file replay ile geçerli operational recovery olarak kapatır. Application,
  workload veya fault olmadığı için Dataset v1 ve D-067 sayımlarına alınmaz.
- D-095 `ob-network-base-readiness-008`, D-094 clean reconstruction sonrasında application
  readiness/stability durumunu değişmeyen D-089 sözleşmesiyle yeniden doğrulayan ön-kayıttır.
  Sonucu ne olursa olsun Dataset v1, D-067 headroom veya incident sayımına alınmaz;
  replacement normal veya fault yetkisi üretmez.

# Dataset Card

## 1. Kimlik

- Geçici ad: **Proactive Microservice Failure Dataset v0**
- Durum: Pilot öncesi taslak
- Ana sistem adayı: Online Boutique
- Üretim biçimi: Açık benchmark üzerinde kontrollü fault injection
- Amaç: Pre-failure classification, LLM evidence verification ve root-cause service ranking
- Geçerli bilimsel run sayısı: **8**. `ob-cpu-normal-002`, `ob-cpu-normal-003` ve `ob-cpu-normal-004` geçerli normal baseline adaylarıdır. `ob-cpu-low-004`, `ob-cpu-low-005` ve `ob-cpu-low-009` geçerli düşük CPU-stress kalibrasyon adaylarıdır. `ob-cpu-medium-001` ve `ob-cpu-medium-003`, tüm fiziksel-etki, lifecycle, host-health, log, metric, schema v3 trace, final receipt ve offline doğrulama kapılarını geçen orta şiddetli CPU-stress kalibrasyon adaylarıdır. Invalid attempt'ler korunur ve dataset'e alınmaz.

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
| cpu_stress | Evet | Evet | İlk pilot sınıfı; kademeli profil tercih edilir |
| network_delay | Evet | Evet | Delay ramp ve kullanıcı etkisi ayrı kaydedilir |
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
- Telemetri örnekleme oranları:
- Geçerli run oranı:
- Gözlenen pre-failure sinyaller:
- Seçilen final window/horizon:
- Dataset v1 için run sayısı gerekçesi:

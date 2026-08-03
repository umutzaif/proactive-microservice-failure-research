# Dataset Card

## 1. Kimlik

- Geçici ad: **Proactive Microservice Failure Dataset v0**
- Durum: Pilot öncesi taslak
- Ana sistem adayı: Online Boutique
- Üretim biçimi: Açık benchmark üzerinde kontrollü fault injection
- Amaç: Pre-failure classification, LLM evidence verification ve root-cause service ranking
- Geçerli bilimsel run sayısı: **3**. `ob-cpu-normal-002`, `ob-cpu-normal-003` ve `ob-cpu-normal-004` tüm lifecycle, host-health, log, metric, schema v3 trace, final receipt ve offline doğrulama kapılarını geçti; normal baseline adaylarıdır. `ob-cpu-normal-001` run-scoped metric sample bulunmadığı için `invalid` korunur ve dataset'e alınmaz.

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
- Telemetri örnekleme oranları:
- Geçerli run oranı:
- Gözlenen pre-failure sinyaller:
- Seçilen final window/horizon:
- Dataset v1 için run sayısı gerekçesi:

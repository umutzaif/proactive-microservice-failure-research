# PROJE DEVİR DOSYASI  
## Mikroservis Mimarilerinde LLM Destekli Hata Yayılımı, Erken Hata Tahmini ve Kök Neden Analizi

Bu belge, başka bir ChatGPT projesinde çalışmaya kaldığım yerden devam edebilmek için hazırlanmıştır. Yalnızca nihai fikri değil, bu fikre hangi düşünsel ve literatür adımlarıyla ulaşıldığını da içerir. Yeni konuşmada bu belgeyi temel bağlam olarak kullan.

---

# 1. Başlangıç Konusu

Gönüllü staj kapsamında verilen akademik proje başlığı:

**“Mikroservis Mimarilerinde LLM Destekli Hata Yayılımı ve Kök Neden Analizi”**

İlk problem tanımı şuydu:

- Dağıtık mikroservis mimarilerinde bir serviste oluşan hata diğer servislere yayılabilir.
- Kullanıcının gördüğü hata ile gerçek kök neden aynı serviste olmayabilir.
- Amaç, cascade failure / failure propagation davranışını anlamak ve kök nedeni bulmaktır.
- LLM’lerin log analizindeki anlamsal gücü, geleneksel APM/trace/RCA yöntemleriyle kıyaslanacaktır.

İlk anahtar kelimeler:

- microservice root cause analysis LLM
- automated log analysis AI
- distributed tracing LLM
- software failure propagation AI
- AIOps microservices

---

# 2. İlk Kavramsal Çerçeve

Başlangıçta düşünülen temel yaklaşım:

1. Bir mikroservis sistemi kurulacak veya hazır bir benchmark kullanılacak.
2. Kontrollü hatalar enjekte edilecek.
3. Log, metric ve trace verileri toplanacak.
4. Geleneksel yöntemler ile LLM tabanlı RCA karşılaştırılacak.
5. Root cause accuracy, Top-k, MRR, F1, false positive ve analiz süresi ölçülecek.

Bu aşamada konu daha çok **reaktif RCA** idi; yani hata gerçekleştikten sonra kök nedeni bulmaya odaklanıyordu.

---

# 3. İlk Büyük Fikir Değişimi: “Hata Anını Değil, Hatanın Hikâyesini Dinlemek”

Daha sonra şu fikir ortaya çıktı:

> Bir hatayı yalnızca oluştuğu anda incelemek yerine, hata oluşmadan önce sistemin hangi davranış örüntülerinden geçtiğini öğrenmek gerekir.

Örnek hata gelişimi:

- latency artmaya başlar
- retry sayısı yükselir
- queue büyür
- bağlantı havuzu dolar
- downstream servislerde gecikme oluşur
- sonunda timeout meydana gelir

Buradaki kritik düşünce:

> Hata bir “an” değil, zamansal olarak gelişen bir “durum evrimi”dir.

Bu fikir, klasik RCA’den **predictive/proactive RCA** yönüne geçişi başlattı.

---

# 4. Literatürden İncelenen Temel Çalışmalar

## 4.1 LLM4Log: A Systematic Review of Large Language Model-based Log Analysis

Bu çalışma LLM tabanlı log analizini uçtan uca sınıflandırdı:

- logging statement generation
- log parsing
- log representation
- anomaly detection
- failure prediction
- root cause analysis
- log summarization

Bu çalışmadan çıkarılan ana dersler:

- LLM’ler logların anlamsal içeriğini ve farklı kaynaklardan gelen kanıtları birleştirmede güçlüdür.
- Ancak context limit, latency, cost, privacy ve hallucination riskleri vardır.
- LLM’lerin doğrulanabilir, yapılandırılmış ve kanıta dayalı çıktılar vermesi gerekir.
- LLM nihai karar verici olmaktan çok anlamsal yorumlayıcı ve kanıt değerlendirici olarak kullanılmalıdır.

---

## 4.2 From Distributed Tracing to Proactive SLO Management

Bu mini-review şu konuları ele aldı:

- SLO violation prediction
- tail latency prediction
- partial trace / prefix-based early warning
- bottleneck ranking
- what-if estimation
- causal and graph-based models
- earliness–accuracy trade-off

Bu çalışmadan çıkarılan ana ders:

> Hata veya SLO ihlali tamamen gerçekleşmeden, kısmi trace geçmişinden erken uyarı üretilebilir.

Buradan şu kavramlar alındı:

- prediction horizon
- early warning lead time
- false alarm rate
- coverage
- precision under early warning constraints
- prefix-based prediction

Ancak bu literatürün çıktısı çoğunlukla “SLO ihlali olacak mı?” sorusuydu. Bizim hedefimiz daha geniş:

- hangi hata sınıfı yaklaşıyor?
- hangi servis kök neden?
- hata hangi servislere yayılacak?
- ne kadar sürede oluşacak?

---

## 4.3 A Survey on Intelligent Network Operations and Performance Optimization Based on LLMs

Bu çalışma LLM’lerin:

- fault diagnosis
- predictive analysis
- causal inference
- intelligent monitoring
- automated network operation
- performance optimization

alanlarındaki kullanımını derledi.

Bu makale doğrudan yöntem vermedi; fakat LLM tabanlı operasyonel analiz ve AIOps kullanımının genel motivasyonunu güçlendirdi.

---

## 4.4 MULAN: Multi-modal Causal Structure Learning and Root Cause Analysis for Microservice Systems

MULAN, bizim fikrimize en yakın ve kritik çalışmalardan biridir.

Temel yapısı:

1. Logları template ve frekanslarla zaman serisi temsiline dönüştürür.
2. Log ve metric modalitelerini contrastive learning ile birlikte işler.
3. Modality-invariant ve modality-specific temsiller öğrenir.
4. KPI-aware attention ile hangi modaliteye daha çok güvenileceğini belirler.
5. Nedensel graph oluşturur.
6. Random Walk with Restart ile root cause sıralaması yapar.

MULAN’dan çıkarılan ana dersler:

- Geçmiş log ve metrikleri kullanmak tek başına özgün değildir.
- Log + metric + causal graph + RCA literatürde vardır.
- Bizim farkımız, geçmiş veriyi yalnızca causal graph oluşturmak için değil, **gelecekte oluşacak hata sınıfını önceden tahmin etmek** için kullanmak olmalıdır.
- Bu tahmin daha sonra RCA aşamasına ek kanıt olarak aktarılmalıdır.

---

## 4.5 GALR: Graph-Based Root Cause Localization and LLM-Assisted Recovery for Microservice Systems

Bu çalışma doğrudan dosya olarak aktarılmadı; ancak literatür incelemesinde öne çıktı.

Önemli yaklaşımı:

- Servis call graph oluşturur.
- LLM her servis için şu olasılık üçlüsünü üretir:

  `[Anormal, Normal, Belirsiz]`

- Bu semantik olasılıkları GAT attention mekanizmasına bias olarak verir.
- GAT hata yayılımını ve root cause’u değerlendirir.
- RAG ve playbook doğrulamasıyla recovery planı üretir.
- LLM tek başına karar vermez; graph ve doğrulama mekanizmalarıyla sınırlandırılır.

GALR’dan çıkan ilk fikir:

> LLM’in semantik çıktısı graph modelinin düğüm özelliklerinden biri olabilir.

İlk başta GALR’ın üçlü vektörüne dördüncü parametre eklemek düşünüldü:

`[Anormal, Normal, Belirsiz, X hatası oluşma ihtimali]`

Fakat daha sonra bunun matematiksel olarak zayıf olabileceği fark edildi. Çünkü ilk üç değer LLM semantiğinden, dördüncü değer ise ayrı bir temporal modelden gelecekti.

Bu yüzden nihai yaklaşımda iki temsil ayrı tutulacaktır:

- Temporal failure forecast representation
- LLM semantic verification representation

Sonra bunlar fusion/GAT aşamasında birleştirilecektir.

---

## 4.6 BRIDGE: Big Data-Powered Large Language Models for Real-Time Multi-Modal Decision Support in Industrial Time Series

BRIDGE doğrudan mikroservis RCA çalışması değildir; ancak ortak ana fikir açısından önemlidir.

Birleştirdiği bileşenler:

- time-series forecasting
- graph topology
- anomaly detection
- LLM-based explanation
- multimodal alignment
- real-time inference

Ana ders:

> Zaman serisi modeli, graph modeli ve LLM aynı bütünleşik mimaride birlikte kullanılabilir.

BRIDGE’in bizim fikrimize yakın tarafı:

- temporal modeling
- graph topology
- multimodal fusion
- LLM explanation

Farkı:

- BRIDGE’in odağı endüstriyel zaman serisi karar desteğidir.
- Bizim odağımız mikroservislerde failure forecasting + root cause + propagation’dır.

---

# 5. Nihai Fikre Ulaşırken Yapılan Kritik Ayrımlar

## 5.1 LLM doğrudan hata tahmin modeli olmak zorunda değildir

Bir süre LLM’in son 30 logu okuyarak gelecekteki hatayı tahmin etmesi düşünüldü.

Daha sonra şu ayrım netleşti:

- Sayısal ve kalibre edilmiş hata olasılığı ayrı bir temporal modelden gelmelidir.
- LLM ise tahminin log, kod, iş kuralı ve servis topolojisi açısından mantıklı olup olmadığını değerlendirmelidir.

Yani:

> Temporal model örüntüsel kanıt üretir.  
> LLM semantik ve mantıksal kanıt üretir.  
> Graph modeli topolojik ve yayılımsal kanıt üretir.

---

## 5.2 “Son 30 log” ifadesi teknik olarak zaman penceresi olmalıdır

Ham 30 log satırı kullanılmamalıdır; çünkü servislerin log yoğunluğu farklıdır.

Daha doğru yaklaşım:

- son 30 zaman penceresi
- son 30 olay penceresi
- örneğin 30 × 5 saniye = 150 saniyelik geçmiş

Her pencere içinde:

- log template frekansları
- severity sayıları
- embeddings
- latency
- retry
- error rate
- CPU
- memory
- queue length
- trace özellikleri

bulunabilir.

---

## 5.3 LLM’in rolü: aday hata doğrulayıcı

Temporal model çıktı örneği:

```json
{
  "predicted_failure": "inventory_underflow",
  "confidence": 0.78
}
```

Belirli bir eşik aşılırsa bu aday LLM’e gönderilir.

Başlangıç eşiği:

`0.50`

Ancak deneylerde 0.40, 0.50, 0.60, 0.70 gibi farklı eşikler test edilmelidir.

LLM’in görevi:

> “Bu hata adayı, son loglar, metrik eğilimleri, ilgili kod, iş kuralları ve servis graph’ı tarafından destekleniyor mu?”

LLM çıktısı:

- supported
- uncertain
- contradicted

olmalıdır.

LLM’den sahte bir yüzde istenmemelidir.

---

## 5.4 Kod farkındalıklı değerlendirme

Örnek:

- Depo servisinde stok 17 → 13 → 9 → 5 düşüyor.
- Saatlik talep yaklaşık 4.
- Kodda stok sıfıra düştüğünde veya talep stoktan yüksek olduğunda sınır kontrolü yok.
- Temporal model “inventory_underflow” tahmini yapıyor.
- LLM logları ve kodu birlikte okuyup bu tahminin haklılığını açıklıyor.
- Talep hızı sabit kalırsa 30–90 dakika içinde hata oluşabileceğini koşullu olarak ifade ediyor.

Bu aşamada çalışma sıradan log analizi olmaktan çıktı ve şu fikre dönüştü:

> Code-aware, temporally grounded, graph-supported proactive RCA.

---

# 6. Nihai Tez Problemi

Mikroservis sistemlerinde bir hata oluşmadan önce log, metric ve trace verilerinde belirli zamansal örüntüler ortaya çıkar. Ancak klasik RCA yöntemleri çoğunlukla hata anındaki veya hata sonrasındaki telemetriye dayanır.

Nihai problem:

> Yaklaşan hata sınıfını hata oluşmadan önce tahmin etmek; bu tahmini LLM ile log, kod, iş kuralı ve topoloji açısından doğrulamak; ardından graph tabanlı modelle kök nedeni ve hata yayılım yolunu belirlemek.

---

# 7. Nihai Algoritmik Mimari

## Aşama 1 — Veri toplama

Her servis için:

- logs
- metrics
- traces
- service dependencies
- relevant code
- business rules

toplanır ve ortak zaman eksenine hizalanır.

---

## Aşama 2 — Zaman penceresi oluşturma

Her servis için son 30 pencere:

`X_i(t) = [x_i(t-29), ..., x_i(t)]`

şeklinde hazırlanır.

---

## Aşama 3 — Temporal failure classifier

LSTM, GRU, Transformer veya xLSTM gibi bir model şu dağılımı üretir:

`[P(F1), P(F2), ..., P(Fm), P(normal)]`

En yüksek olasılıklı hata sınıfı adaydır.

---

## Aşama 4 — Eşik kapısı

Eğer:

`max P(Fx) > θ`

ise aday LLM doğrulamasına gönderilir.

Aksi halde sistem gözlemlemeye devam eder.

---

## Aşama 5 — LLM doğrulaması

LLM’e:

- temporal model tahmini
- güven skoru
- son 30 pencere
- önemli loglar
- metric özeti
- ilgili servis kodu
- iş kuralları
- dependency graph

verilir.

LLM şu çıktıyı üretir:

```json
{
  "candidate_failure": "...",
  "verdict": "supported | uncertain | contradicted",
  "evidence": [],
  "code_evidence": "...",
  "assumptions": [],
  "estimated_time_range": []
}
```

---

## Aşama 6 — Time-to-failure

Sayısal time-to-failure tercihen ayrı bir regresyon head/model tarafından üretilir.

LLM bu sayıyı açıklayabilir, varsayımları belirtir ve koşullu yorumlar üretir.

---

## Aşama 7 — Graph oluşturma

Her servis bir node, servis çağrıları edge olur.

Node feature’ları:

- temporal class probabilities
- LLM verdict
- LLM semantic embedding
- time-to-failure
- metric features
- log features

---

## Aşama 8 — GAT tabanlı RCA

GAT:

- root cause service score
- affected service scores
- propagation edge scores

üretir.

---

## Aşama 9 — Nihai karar

Nihai alarm şu üç kanıtın uyumuna göre oluşur:

1. Temporal model skoru eşik üstünde
2. LLM “supported” diyor
3. Graph/RCA modeli aday servis ve yayılımı destekliyor

---

## Aşama 10 — Gerçek hata sonrası doğrulama

Hata gerçekten oluştuğunda:

- tahmin edilen hata sınıfı
- tahmin edilen servis
- tahmini time-to-failure
- tahmin edilen propagation path
- gerçek olay

karşılaştırılır.

Bu sayede proaktif tahmin ile reaktif RCA aynı çerçevede değerlendirilir.

---

# 8. Tezin Temel İddiası

> Hata öncesi zamansal örüntülerden üretilen hata adayları, LLM tabanlı semantik ve kod farkındalıklı doğrulama ile filtrelenip graph tabanlı RCA modeline aktarıldığında, mikroservis sistemlerinde erken hata uyarısı, kök neden lokalizasyonu ve hata yayılımı analizinin doğruluğu ve açıklanabilirliği artırılabilir.

---

# 9. Olası Başlıklar

## İngilizce

**LLM-Validated Temporal Failure Forecasting and Graph-Based Root Cause Analysis for Microservice Architectures**

Alternatif:

**A Gated Temporal–Semantic Graph Framework for Proactive Failure Prediction and Root Cause Analysis in Microservice Systems**

## Türkçe

**Mikroservis Mimarilerinde LLM ile Doğrulanan Zamansal Hata Tahmini ve Çizge Tabanlı Kök Neden Analizi**

---

# 10. Özgün Katkı Çekirdeği

Özgünlük tek tek kullanılan araçlarda değildir.

Literatürde zaten:

- failure prediction
- LLM log analysis
- graph RCA
- multimodal RCA
- proactive SLO prediction

vardır.

Özgünlük şu ardışık ilişkidedir:

> Temporal model aday hata üretir → LLM kod/log/topoloji ile adayı doğrular → Graph modeli kök neden ve yayılımı belirler → Gerçek hata sonrası tahmin doğrulanır.

---

# 11. Deney Konusunda Varılan Son Nokta

Sıfırdan mikroservis sistemi yazmak yerine önce hazır dataset/benchmark kullanmak daha mantıklı bulundu.

Potansiyel kaynaklar:

- Online Boutique
- Train Ticket
- Product Review
- DeathStarBench
- Alibaba Microservice Traces

Ancak tek bir dataset’in şu alanların hepsini içermesi düşük ihtimaldir:

- pre-failure logs
- metrics
- traces
- fault type
- root cause label
- fault timestamp
- propagation path
- source code
- business rules

Bu yüzden en mantıklı strateji:

1. Hazır dataset ile temporal prediction + graph RCA + LLM log validation
2. Eksik etiketler için hazır benchmark üzerinde sınırlı fault injection
3. Mikroservis mimarisini sıfırdan yazmamak
4. Mümkünse Online Boutique / Train Ticket / DeathStarBench gibi açık sistemleri kullanmak

---

# 12. Planlanan Araştırma Soruları

## RQ1
Son gözlem pencerelerinden yaklaşan hata sınıfı ne doğrulukla tahmin edilebilir?

## RQ2
LLM doğrulaması temporal modelin false positive oranını azaltır mı?

## RQ3
Kod bağlamı ve iş kuralları LLM doğrulamasını iyileştirir mi?

## RQ4
Temporal + LLM özelliklerinin GAT’a eklenmesi root cause accuracy’yi artırır mı?

## RQ5
Önerilen model failure propagation path’i ne doğrulukla çıkarabilir?

## RQ6
Hangi confidence threshold en iyi earliness–accuracy dengesini sağlar?

## RQ7
Eksik log, eksik trace ve topology drift performansı nasıl etkiler?

---

# 13. Planlanan Ablation Karşılaştırmaları

- Temporal only
- Temporal + LLM
- Temporal + Graph
- Temporal + LLM + Graph
- Without code context
- Without trace
- Without metrics
- Without log semantics
- Without time-to-failure
- Static graph vs dynamic graph

---

# 14. Kritik Metodolojik Uyarılar

1. Hata tahmin modeli hata anına ait logları görmemelidir.
2. Data leakage engellenmelidir.
3. Aynı hata olayının komşu pencereleri train ve test’e dağılmamalıdır.
4. LLM’in yüzdeleri kalibre edilmiş olasılık gibi kullanılmamalıdır.
5. LLM çıktıları structured JSON ve evidence citation içermelidir.
6. Graph yalnızca görselleştirme değil, model girdisi ve doğrulama katmanı olmalıdır.
7. Time-to-failure için LLM yerine ayrı regresyon modeli daha güvenilir olabilir.
8. LLM’in rolü classifier’ı tekrar etmek değil, onu semantik olarak doğrulamaktır.
9. “Hallucination detection” yerine “cross-model evidence consistency” ifadesi daha doğrudur.
10. Hazır dataset seçimi yapılmadan nihai mimari dondurulmamalıdır.

---

# 15. Yeni ChatGPT Projesinde Nasıl Devam Edilmeli?

Yeni asistan bu projeyi şu sırayla sürdürmelidir:

1. Uygun açık dataset ve benchmarkları karşılaştır.
2. Her dataset için şu tabloyu doldur:
   - logs
   - metrics
   - traces
   - fault labels
   - root cause labels
   - fault timestamps
   - propagation labels
   - code availability
3. Tezin uygulanabilir en küçük kapsamını belirle.
4. İlk prototip için hata sınıflarını sınırla.
5. Temporal classifier mimarisini seç.
6. LLM verification prompt ve output schema tasarla.
7. Graph node/edge feature’larını tanımla.
8. GAT loss function ve output task’larını belirle.
9. Deney, baseline ve ablation planını oluştur.
10. Son olarak tez önerisi / akademik makale şablonuna dönüştür.

---

# 16. Çalışma Tarzı Notu

Bu projede kullanıcı akademik fikri birlikte olgunlaştırmak istiyor.

Yeni asistan:

- fikri hemen “harika ve özgün” ilan etmemeli,
- literatürde karşılığı olup olmadığını sorgulamalı,
- teknik olarak zayıf yerleri açıkça belirtmeli,
- her modülün rolünü ayırmalı,
- algoritma, veri, deney ve ölçüm boyutlarını ayrı ayrı düşünmeli,
- gereksiz flow chart kullanmamalı,
- gerekirse adım adım ve öğretici ilerlemeli,
- “LLM her şeyi yapsın” yaklaşımından kaçınmalı,
- model bileşenlerini ölçülebilir araştırma sorularına bağlamalıdır.

---

# 17. Tek Paragraflık Hızlı Bağlam

Bu proje, mikroservis sistemlerinde hata oluşmadan önceki log, metric ve trace pencerelerinden yaklaşan hata sınıfını tahmin eden bir temporal model; bu tahmini ilgili kod, iş kuralları, son loglar ve servis topolojisiyle doğrulayan bir LLM; ardından temporal ve semantik kanıtları graph attention ağıyla birleştirerek root cause service, propagation path ve affected services çıktıları üreten bütünleşik bir proactive RCA çerçevesi geliştirmeyi amaçlamaktadır. Hata gerçekten oluştuğunda önceki tahmin gerçek olayla karşılaştırılarak class accuracy, time-to-failure, root cause accuracy, propagation similarity ve cross-model evidence consistency ölçülecektir. Çalışmanın özgün katkısı LLM, temporal model ve graph RCA’yı yalnızca yan yana kullanmak değil; temporal aday üretimi → LLM doğrulaması → graph tabanlı kök neden/yayılım → gerçek olay sonrası doğrulama şeklinde katmanlı ve ölçülebilir bir karar yapısı kurmaktır.

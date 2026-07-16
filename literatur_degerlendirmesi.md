# Mikroservis LLM-RCA Projesi: Literatür Değerlendirmesi

Tarih: 15 Temmuz 2026

## 1. Yönetici özeti

Literatür havuzu mevcut araştırma yönünü destekliyor, ancak önerilen mimarinin bütününü henüz doğrulamıyor. Temporal model, LLM ve graph bileşenlerini yan yana kullanmak tek başına özgün bir katkı değildir. Savunulabilir katkı; hata gerçekleşmeden önce üretilen, zaman ufku açıkça tanımlanmış bir hata adayının kanıta dayalı LLM doğrulamasından geçirilmesi ve bu doğrulamanın kök neden/yayılım modeline ölçülebilir biçimde aktarılmasıdır.

En yakın yöntemsel çalışmalar MULAN ve GALR'dır. MULAN log ve metriklerden ortak bir causal graph öğrenip RCA yapar; ancak çevrimdışı ve reaktiftir. GALR log, metrik, trace graph ve LLM semantiğini GAT içinde birleştirir; fakat esas görevi hata sonrası root-cause localization ve recovery'dir. Bu nedenle projenin farkı ancak pre-failure prediction, leakage-free horizon ve gerçek early-warning değerlendirmesiyle korunabilir.

En önemli deneysel sonuç şudur: İlk prototipte aynı anda failure class prediction, time-to-failure, root cause, affected services, propagation path, code-aware LLM verification ve recovery üretmeye çalışmak aşırı kapsamlıdır. Minimum savunulabilir kapsam üç görevle sınırlandırılmalıdır:

1. belirli bir horizon içinde hata sınıfı tahmini,
2. LLM doğrulamasının false-positive oranına etkisi,
3. root-cause service sıralaması.

Propagation path ve recovery ikinci aşama/gelecek çalışma olmalıdır; çünkü eldeki çalışmaların çoğunda propagation ground truth yoktur.

## 2. Çalışmaların proje açısından sınıflandırılması

| Çalışma | Durum ve ağırlık | Projeye katkısı | Kritik sınırlılık / karar |
|---|---|---|---|
| [MULAN](papers/mulan.pdf) | WWW 2024, hakemli konferans; çekirdek yöntem | Log + metric, contrastive representation, KPI-aware causal graph fusion, RWR ile RCA | Doğrudan özgünlük tehdidi. Ancak yalnızca 4, 5 ve 5 hata olayıyla değerlendirilmiş; çevrimdışı/reactive ve trace/kod yok. |
| [GALR](papers/electronics-15-00243-v2.pdf) | Electronics 2026, hakemli dergi; en yakın bütünleşik yöntem | Trace call graph + metric/log + LLM semantic prior + GAT + RAG recovery | En güçlü özgünlük tehdidi. Pre-failure forecasting yapmıyor. Tek-düğüm/tek-hata ve injection-time anchored windows kullanıyor; propagation ground truth yok. |
| [Between Promise and Pain](papers/a2.pdf) | APSys 2025, hakemli workshop/konferans; güçlü negatif kanıt | Tool-augmented LLM agent'ların mikroservis RCA davranışlarını sistematik olarak sınar | LLM'in otonom RCA için kırılgan olduğunu gösteriyor. Bizim gated verifier rolünü destekler; temporal reasoning ve state grounding zorunlu. |
| [Multi-Dataset LLM Agent Benchmark](papers/2606.29193v1.pdf) | arXiv 2026 ön baskı; dataset/ölçüm açısından çok önemli | AIOps2025 + RCA100 üzerinde location, type, evidence coverage ve reasoning efficiency ölçümü | Sonuçtan çok gerekçelendirme sürecini ölçmemiz gerektiğini gösterir. Dataset erişimi ve lisansı ayrıca doğrulanmalı. |
| [LLM4Log](papers/2604.16359v2.pdf) | arXiv 2026 ön baskı; kapsamlı sistematik derleme | 145 çalışma; log pipeline, verification, grounding, drift, reproducibility | Arka plan ve taksonomi için ana kaynak. Tek başına yöntem kanıtı değildir. |
| [AIOps in the Era of LLMs](papers/3746635.pdf) | ACM makalesi, DOI 10.1145/3746635; geniş derleme | 183 çalışma üzerinden LLM4AIOps görevleri ve değerlendirme boşlukları | Genel konumlandırma için güçlü; mikroservis-proaktif RCA özelinde doğrudan baseline değildir. |
| [Proactive SLO mini-review](papers/fcomp-8-1783945.pdf) | Frontiers in Computer Science 2026, hakemli mini-review | Prefix prediction, early-warning horizon, lead time, calibration, trace veri sorunları | Proaktif iddiayı kurmak için temel kaynak. SLO violation prediction ile fault-class prediction ayrımı korunmalı. |
| [Comprehensive RCA Survey](papers/2408.00803v1.pdf) | arXiv 2024 ön baskı; DOI alanı placeholder | RCA yöntemleri, modaliteler ve benchmark haritası | Literatür keşfi için yararlı; nihai akademik iddialarda daha güçlü birincil kaynaklarla desteklenmeli. |
| [AI Assistants for Incident Lifecycle](papers/2410.04334v1.pdf) | arXiv 2024 ön baskı, SLR | Prevention/detection/containment/post-incident görev ayrımı | Projenin incident lifecycle içindeki yerini açıklamak için yararlı; yöntemsel temel değil. |
| [Network Operations LLM Survey](papers/A_Survey_on_Intelligent_Network_Operations_and_Performance_Optimization_Based_on_Large_Language_Models.pdf) | IEEE Communications Surveys & Tutorials 2025; güçlü derleme | Fault diagnosis, causal inference ve operasyon bağlamı | Mikroservis odağından uzak; motivasyon/related work için ikincil kaynak. |
| [Observability in Microservices](papers/Observability_in_Microservices_An_In-Depth_Exploration_of_Frameworks_Challenges_and_Deployment_Paradigms.pdf) | IEEE Access 2025, hakemli derleme | Logs-metrics-traces toplama ve deployment araçları | Veri toplama altyapısı için yararlı; algoritmik özgünlük sağlamaz. |
| [Failure Propagation Simulator](papers/Microservice_Failure_Propagation_Simulator_Survey_and_Gaps.pdf) | IEEE ICEI 2026 konferans makalesi | RCA, chaos engineering ve propagation simulation boşluğunu birleştirir | Propagation etiketi üretme fikri için yararlı; henüz uygulanmış ve doğrulanmış bir dataset sağlamıyor. |
| [LLMDebug](papers/LLMDebug_Prompt-Engineered_Large_Language_Models_for_Automated_Root_Cause_Analysis_in_Microservices_Architectures.pdf) | IEEE AAIML 2026 konferans makalesi | Prompting + RAG + multi-agent RCA yaklaşımı | Bildirilen %89.3 accuracy dikkatle ele alınmalı; dataset/kod/reproducibility netleşmeden güçlü kanıt sayılmamalı. Bizim verifier yaklaşımından farklı. |
| [BRIDGE](papers/v1_covered_b222a3e9-65b1-4e94-b9bf-a01ae90bb0f7.pdf) | Research Square 2026 preprint | Graph encoder + xLSTM + LLM alignment bütünleşmesi | Doğrudan mikroservis RCA değildir. 78M örneğin bir bölümü proprietary, 8xA100 gereksinimi ve iddialı latency/accuracy sonuçları nedeniyle prototip mimarisi olarak kopyalanmamalı. |

## 3. En yakın çalışmaların ayrıntılı etkisi

### 3.1 MULAN

MULAN üç dataset kullanır:

- Product Review: 234 pod, 6 sunucu, yalnızca 4 sistem hatası;
- Online Boutique: 5 sistem hatası;
- Train Ticket: 5 sistem hatası.

Üçünde de yalnızca log ve metric modaliteleri vardır. Sonuç metrikleri PR@K, MAP@K ve MRR'dır. Product Review'da MULAN'ın tüm metriklerde 1.0 vermesi ilk bakışta güçlü görünse de yalnızca dört hata olayı nedeniyle istatistiksel güven sınırlıdır. Online Boutique'te MRR 0.900, Train Ticket'ta 0.381'dir. Bu değişkenlik, dataset/topoloji etkisinin yüksek olduğunu gösterir.

Proje kararı: MULAN mutlaka baseline veya en azından doğrudan karşılaştırılan yöntem olmalıdır. Bizim katkımız "multimodal graph RCA" olamaz. Ayrım, geçmiş pencerelerden gelecekteki hata sınıfını tahmin etmek ve bu tahmini LLM doğrulamasına sokmaktır.

### 3.2 GALR

GALR üç dataset raporlar:

- Customer Service: 23.183 trace, 67 servis, 24 injected fault;
- Power Grid Resource: 19.872 trace, 89 servis, 32 injected fault;
- SockShop: 8.981 trace, 15 servis, 30 injected fault.

Altı hata tipi vardır: network delay, network loss, CPU stress, memory stress, pod failure ve pod kill. Her trace en fazla bir injected fault içerir ve hata tek servis instance'ına karşılık gelir. Eğitim/test oranı 6:4'tür. Yazarlar injection time ile hizalamanın gecikmeli ve kaskat etkileri tam temsil etmeyebileceğini açıkça kabul eder.

Proje kararı: GALR'a karşı farkımızı "LLM + GAT" üzerinden kuramayız; bu zaten yapılmıştır. Fark ancak gerçek pre-failure window, fixed prediction horizon, calibrated temporal output ve post-event verification üzerinden kurulabilir. Ayrıca propagation iddiası için GALR'ın eksik bıraktığı bağımsız yol etiketleri gerekir.

### 3.3 LLM-agent değerlendirmeleri

Multi-Dataset Benchmark, AIOps2025 içinde 400 vaka, 9 fault category, 18 fault type ve toplam 1.878 evidence entry raporlar. Modalite dağılımı metric %50.8, log %40.0, trace %9.2'dir. Değerlendirme yalnızca nihai cevabı değil şunları ölçer:

- Location Accuracy,
- Type Accuracy,
- evidence-point coverage,
- reasoning-trace efficiency.

Between Promise and Pain ise agent'ların eski logları aktif hata sanması, yanlış servis adları kullanması, gereksiz/zararlı aksiyonlara yönelmesi ve doğru semptomu bulsa bile gerçek yapılandırma kök nedenini kaçırması gibi davranışlar gösterir.

Proje kararı: LLM çıktısında yalnızca `verdict` yeterli değildir. Her kararın zaman damgalı evidence ID'larına bağlanması, kanıtın hangi modaliteden geldiğinin belirtilmesi ve desteklenmeyen gerekçelerin ölçülmesi gerekir. LLM'e sistem üzerinde otonom değişiklik yapma yetkisi verilmemelidir.

## 4. Dataset açısından sonuç

Hazır datasetlerden hiçbiri mevcut hedeflerin tamamını tek başına sağlamıyor.

| İhtiyaç | Hazır dataset durumu | Sonuç |
|---|---|---|
| Hata öncesi log + metric + trace | Kısmen mevcut; zaman hizalama kalitesi değişken | Ham telemetri ve injection schedule kontrol edilmeli |
| Fault class label | Fault injection datasetlerinde mevcut | İlk prototip 3-4 hata tipiyle sınırlandırılabilir |
| Root-cause service | Enjeksiyon hedefinden türetilebilir | Tek-hata senaryosunda güvenilir; çoklu hata için yetersiz |
| Time-to-failure | Genellikle hazır değil | Injection time ile "failure manifestation time" ayrılmalı |
| Propagation path | Genellikle yok | Trace değişiminden türetilirse ground truth değil proxy olur |
| Source code | Online Boutique, Train Ticket, SockShop, DeathStarBench'te mevcut | Code-aware deney için açık benchmark gerekli |
| Business rules | Hazır etiket olarak yok | Elle seçilmiş sınırlı servis/kurallar üzerinden oluşturulmalı |

En uygun ilk tercih, açık kaynak kodu ve kontrollü fault injection olanağı nedeniyle Online Boutique veya Train Ticket üzerinde yeni ve sınırlı bir veri toplama koşusudur. MULAN ile doğrudan karşılaştırma kolaylığı açısından Online Boutique/Train Ticket avantajlıdır. Daha küçük operasyonel yük istenirse SockShop uygulanabilir, ancak GALR ile çakışma daha belirgin olur.

Alibaba trace verisi gerçekçilik sağlar fakat log, kod, business rule ve güvenilir fault labels eksikliği nedeniyle ana deney dataset'i olmaya uygun değildir. En fazla dış geçerlilik veya topology-drift yan deneyi için kullanılmalıdır.

## 5. Önerilen minimum araştırma kapsamı

### Girdiler

- log template frekansları ve severity sayıları,
- CPU, memory, latency, request/error rate,
- trace-derived service dependency graph,
- yalnızca LLM doğrulaması sırasında getirilen ilgili kod parçaları.

### Hata sınıfları

İlk prototipte semantik ve telemetrik olarak ayrılabilir 3 hata sınıfı seçilmelidir:

- CPU stress,
- network delay,
- pod/service failure.

Memory stress dördüncü sınıf olabilir. Network loss ile network delay'i aynı ilk deneyde kullanmak sınıf ayrımını gereksiz zorlaştırabilir.

### Görevler

1. `Will fault F occur in service S within horizon H?`
2. LLM: `supported / uncertain / contradicted`, evidence ID listesiyle.
3. Root-cause service ranking.

Time-to-failure regresyonu, affected-service prediction ve propagation-path reconstruction temel sistem doğrulandıktan sonra eklenmelidir.

## 6. Deney tasarımına zorunlu eklemeler

- Bölme pencere bazında değil, fault-run/incident bazında yapılmalı.
- Aynı servis + aynı injection configuration örnekleri train ve test arasında kontrol edilmeli.
- Her örnek için observation end time, prediction horizon ve fault manifestation time saklanmalı.
- Injection komutunun başladığı an otomatik olarak failure time kabul edilmemeli.
- Temporal model için AUROC yanında AUPRC, macro-F1, Brier score/ECE ve lead time raporlanmalı.
- RCA için Top-1, Top-3 ve MRR kullanılmalı.
- LLM için verdict accuracy yanında false-positive reduction, abstention/uncertain rate, evidence precision/recall ve faithfulness ölçülmeli.
- Prompt ve LLM modeli sabitlenmeli; temperature, context budget, token maliyeti ve latency raporlanmalı.
- Code-aware katkı, aynı kodun ilgisiz/yanlış sürümü verilerek yapılan karşı-olgusal kontrolle sınanmalı.
- Graph katkısı, static dependency graph, trace-derived dynamic graph ve graph'sız model arasında karşılaştırılmalı.

## 7. Revize araştırma soruları

- RQ1: Belirli bir prediction horizon altında yaklaşan hata sınıfı olay-bazlı ayrımda ne ölçüde tahmin edilebilir?
- RQ2: Kanıta bağlı LLM doğrulaması temporal modelin false-positive oranını, recall ve lead time'ı ne ölçüde değiştirir?
- RQ3: Kod bağlamı, yalnızca log/metric/topoloji bağlamına kıyasla doğrulama doğruluğunu artırır mı; yanlış veya ilgisiz kod verildiğinde model bu bağlamı reddedebilir mi?
- RQ4: Temporal olasılıklar ve LLM verdict/evidence özellikleri root-cause service sıralamasını graph-only baseline'a göre artırır mı?
- RQ5: Performans unseen service, unseen fault configuration ve topology drift altında ne kadar korunur?

Propagation path, time-to-failure ve eksik-modalite dayanıklılığı ilk makalenin temel RQ'ları yerine genişletme deneyleri olarak tutulmalıdır.

## 8. Nihai hüküm

Araştırma fikri uygulanabilir, fakat mevcut geniş haliyle değil. Literatür, LLM + multimodal telemetry + graph RCA kombinasyonunun artık özgün sayılamayacağını gösteriyor. Savunulabilir ve ölçülebilir katkı şudur:

> Olay-bazlı ve leakage-free pre-failure pencerelerinden üretilen kalibre edilmiş hata adaylarının, zaman damgalı log/kod/topoloji kanıtlarına bağlı bir LLM tarafından doğrulanması ve bu doğrulamanın root-cause service sıralamasına ölçülebilir katkısının sınanması.

Bu tanım, çalışmayı GALR ve MULAN'dan ayırırken deney kapsamını yönetilebilir tutar. Propagation path iddiası ancak bağımsız ground-truth üretilebildiğinde yeniden eklenmelidir.

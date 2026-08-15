# Araştırma Kararları Kaydı

Bu belge akademik kararların, gerekçelerinin ve değişiklik geçmişinin tek kaynağıdır. Operasyonel uygulama bu kararları sessizce değiştiremez.

## Durum etiketleri

- **Kabul edildi:** Araştırma tasarımının bağlayıcı parçası.
- **Pilot varsayımı:** Pilot veriden sonra onaylanacak veya değiştirilecek.
- **Ertelendi:** İlk çalışma kapsamı dışında.
- **Açık:** Karar için kanıt veya kullanıcı seçimi gerekiyor.

## D-001 - Araştırmanın çekirdek iddiası

- Durum: **Kabul edildi**
- Karar: Hata öncesi telemetriden üretilen kalibre edilmiş hata adaylarının, kanıta bağlı LLM doğrulamasıyla filtrelenmesinin erken uyarı false-positive oranına ve root-cause service sıralamasına etkisi ölçülecek.
- Gerekçe: MULAN ve GALR nedeniyle `LLM + multimodal telemetry + graph RCA` birleşimi tek başına özgün değildir. Ayrım pre-failure horizon, leakage-free değerlendirme ve doğrulamanın ölçülebilir etkisidir.

## D-002 - İlk çalışma kapsamı

- Durum: **Kabul edildi**
- Dahil:
  - belirli horizon içinde fault-class prediction,
  - evidence-grounded LLM verification,
  - root-cause service ranking.
- Ertelendi:
  - recovery planı,
  - propagation-path ground truth ve tahmini,
  - affected-services tahmini,
  - çoklu eşzamanlı hata,
  - LLM tabanlı sayısal time-to-failure.

## D-003 - Deney platformu

- Durum: **Pilot varsayımı**
- Birincil tercih: Online Boutique.
- Yedekler: SockShop, ardından Train Ticket.
- Pilot kabul ölçütü: Seçili serviste kontrollü CPU stress uygulanabilmeli; log, metric ve trace aynı zaman ekseninde toplanabilmeli; kullanıcıya yansıyan failure/SLO zamanı enjeksiyon zamanından ayrı kaydedilebilmeli.

## D-004 - İlk hata sınıfları

- Durum: **Pilot varsayımı**
- Erken tahmin adayları: CPU stress, kademeli network delay, gelişen service degradation.
- RCA kontrol senaryosu: Ani pod kill/failure.
- Kural: Doğal öncül sinyali bulunmayan ani hata “erken tahmin edildi” şeklinde raporlanamaz.

## D-005 - Zaman tanımları

- Durum: **Kabul edildi**
- `injection_start`: Pertürbasyonun başladığı zaman.
- `first_symptom`: Önceden tanımlanmış ilk telemetri semptomu.
- `failure_manifestation`: Kullanıcıya yansıyan hata veya SLO ihlalinin ilk zamanı.
- `recovery_time`: Sistemin kararlı normal duruma dönüş zamanı.
- Kural: `injection_start`, otomatik olarak `failure_manifestation` kabul edilmeyecek.

## D-006 - Pencere ve horizon

- Durum: **Pilot varsayımı**
- Pencere: 5 saniye.
- Gözlem: 30 pencere / 150 saniye.
- Ana prediction horizon: 30 saniye.
- Duyarlılık analizi: 15 ve 60 saniye.

## D-007 - Veri bölme

- Durum: **Kabul edildi**
- Ayrım birimi: Bağımsız fault run/incident.
- Yasak: Aynı koşudan türetilen komşu pencerelerin train, validation ve test kümelerine dağılması.
- Ek testler: unseen severity/workload ve mümkünse unseen service.

## D-008 - LLM rolü

- Durum: **Kabul edildi**
- LLM sınıflandırıcının yerine geçmez; temporal adayın kanıtlarla desteklenip desteklenmediğini değerlendirir.
- Çıktı: `supported`, `uncertain`, `contradicted`.
- Zorunlu alanlar: evidence ID, counter-evidence, assumptions, missing information.
- Yasak: LLM çıktısındaki serbest yüzdeyi kalibre edilmiş olasılık kabul etmek; otonom recovery eylemi yürütmek.

## D-009 - Model ilerleme sırası

- Durum: **Kabul edildi**
- Temporal: rule baseline -> logistic/XGBoost -> GRU -> gerekirse daha karmaşık model.
- RCA: anomaly/trace ranking -> tabular node ranker -> GCN -> GAT.
- Kural: Basit baseline geçilmeden daha karmaşık mimari ana model ilan edilmeyecek.

## D-010 - Birincil metrikler

- Durum: **Kabul edildi**
- Prediction: event-level AUPRC, macro-F1, false alarms/hour, event detection rate, lead time, Brier/ECE.
- LLM: false-positive reduction, recall değişimi, abstention rate, evidence precision/recall, latency ve maliyet.
- RCA: Top-1, Top-3 ve MRR.

## D-011 - Bilimsel deney başlangıç kapıları

- Durum: **Kabul edildi**
- P1-CPU-001 ancak dört bağımsız kapının tamamı geçildikten sonra başlatılabilir:
  1. **Telemetry merge kapısı - GEÇTİ:** `P1-TELEMETRY-EXPORT-001` bileşenleri PR #10 ile `main` dalına alındı; yerel `main` ve `origin/main` `f650bdd` revisionında senkronlandı.
  2. **Host stability kapısı - GEÇTİ:** `P1-HOST-STABILITY-002` kapsamında temiz boot sonrasında iki ayrı 30 dakikalık aktif yük gözlemi ile bir 10 dakikalık tam E2E kapanış tamamlandı. Yeni WHEA Event 17, bugcheck veya Kernel-Power Event 41 oluşmadı. Son koşunun log, metric, trace ve finalization doğrulamaları geçti.
  3. **Uzun pencere trace export kapısı - GEÇTİ:** `P1-TRACE-CHUNK-LIVE-001` kapsamında 30 dakikadan uzun gerçek yükte 49/49 parça doğrulandı. Maksimum parça 924/5000 trace içerdi; global trace ID tekilleştirmesi, finalization ve offline receipt doğrulaması geçti.
  4. **Schema v3 merge kapısı - GEÇTİ:** İki commit PR #12 ile `main` dalına merge edildi; yerel `main` ve `origin/main` `c29e2b2` revisionında senkronlandı.
- Pipeline'ın işlevsel olarak doğrulanması tek başına host kararlılığı veya uzun pencere veri bütünlüğü kanıtı değildir.
- Dört başlangıç kapısının tamamı geçmiştir. `P1-CPU-001`, protokoldeki benzersiz run ID, metadata, yük profili ve kontrollü fault koşulları korunarak başlatılabilir.
- `P1-HOST-STABILITY-001`, önceki boot dönemindeki WHEA ve bugcheck kanıtıyla `invalid` olarak korunur; `P1-HOST-STABILITY-002` bu kaydı silmez.
- Açık kapılar sırasında üretilen telemetry yalnızca tooling veya altyapı doğrulaması olarak etiketlenir ve bilimsel dataset'e alınmaz.

## D-012 - Normal baseline workload tekrarlanabilirliği ve metadata mühürleme

- Durum: **Kabul edildi mevcut protokolün teknik uygulaması**
- `P1-CPU-001` normal baseline workload'u, repository içinde sürümlenen bir JSON profil ile sabitlenir. Profil; image, kullanıcı sayısı, spawn rate, bekleme dağılımı, task ağırlıkları, seed, Locust/Faker sürümleri ve `locustfile.py` SHA-256 değerini içerir.
- Aynı pozitif seed hem Python `random` hem Faker üreticisine çalışma zamanında uygulanır. Seed'in yalnız metadata'ya yazılması yeterli kabul edilmez.
- Bilimsel metadata; run kimliği, kod/config revisionları, workload profile kimliği/hash'i, UTC evreleri ve run öncesi/sonrası host-health sayaçlarını içerir. Geçerli metadata ve profil final receipt içine kopyalanıp checksum ile mühürlenir.
- Alternatifler: Upstream loadgenerator'ı seedsiz kullanmak reddedildi; özel image üretmek bu aşamada gereksiz bakım ve supply-chain yüzeyi oluşturduğu için ertelendi.
- Fayda: Aynı deney girdisinin sonradan bağımsız olarak incelenmesi ve metadata ile gerçek deployment arasındaki uyuşmazlıkların reddedilmesi.
- Bedel: Aynı seed eşzamanlı isteklerin tamamlanma sırasını deterministik yapmaz; Faker tekrar üretilebilirliği aynı sürüm ve aynı çağrı sırasına bağlıdır. Bu sınırlılık workload profilinde açıkça tutulur.
- Bu karar workload ve kanıt bütünlüğünü uygular; run süresini, fault protokolünü, SLO'yu veya akademik kapsamı değiştirmez.

## D-013 - Deployment sonrası etkin run-ID kapısı

- Durum: **Kabul edildi mevcut protokolün teknik geçerlilik kapısı**
- Karar: Bilimsel lifecycle, collector ve Prometheus için beklenen run ID'nin ConfigMap, pod rollout ve runtime kanıtları aynı anda doğrulanmadan başlatılmaz. Prometheus'ta beklenen kimlikle gerçek metric serisi oluşması zorunludur.
- Gerekçe: `ob-cpu-normal-001`, ConfigMap güncel olduğu halde Prometheus process'i eski config'i bellekte tuttuğu için run-scoped metric üretmeden tamamlandı ve `invalid` oldu.
- Alternatifler: Operatörün elle rollout restart yapmasına güvenmek kırılgan olduğu için tek başına reddedildi. Yalnız ConfigMap metnini kontrol etmek çalışan process durumunu kanıtlamadığı için reddedildi. Her run için yeni observability image üretmek gereksiz bakım maliyeti nedeniyle seçilmedi.
- Uygulama: Run ID, collector ve Prometheus pod-template annotation'ına eklenir; değişiklik otomatik rollout tetikler. Bağımsız verifier ConfigMap, canlı pod annotation, Prometheus runtime config ve run-scoped metric query katmanlarını sınar.
- Fayda: Yanlış run-ID ile sessiz metric kaybı bilimsel pencere başlamadan reddedilir; operatörün doğru komutu hatırlamasına bağımlılık azalır.
- Bedel ve sınırlılık: Kapı deployment süresini en fazla tanımlı metric bekleme timeout'u kadar uzatır. Collector için doğrudan etkin-config API'si bulunmadığından ConfigMap + yeni pod annotation + Ready durumu birlikte dolaylı runtime kanıtıdır.
- Bu karar workload, süre, fault sınıfı, SLO veya akademik kapsamı değiştirmez.

## D-014 - İlk CPU-stress hedef servisi

- Durum: **Kabul edildi pilot kalibrasyon kararı**
- Karar: İlk CPU-stress kalibrasyon hedefi `recommendationservice` olarak seçildi.
- Gerekçe: Geçerli `ob-cpu-normal-002` normal-baseline penceresinde recommendationservice ortalama 11,962 mCPU, p95 41,982 mCPU ve 1.078 kullanıcı-yolu spanı üretti; checkoutservice karşılıkları 1,225 mCPU, 7,074 mCPU ve 340 spandır. Recommendationservice 539 düzenli `ListRecommendations` çağrısı ve basit ProductCatalog bağımlılığıyla fault etkisini zaman içinde ölçmek için daha güçlü adaydır.
- Alternatif: `checkoutservice`, daha geniş downstream kullanıcı etkisi ve zengin JSON logları nedeniyle değerlendirildi; ancak aynı workload'ta yalnız 26 `PlaceOrder` çağrısı bulunması ilk CPU ramp kalibrasyonunda seyrek örnekleme riski oluşturdu.
- Fayda: Daha yoğun normal trafik, ölçülebilir CPU sinyali ve daha basit causal yol; hedef etkisi ile downstream semptom ayrımını kolaylaştırır.
- Bedel ve sınırlılık: Karar tek geçerli normal baseline'a dayanır ve fault yanıtını kanıtlamaz. Servis içindeki seed edilmemiş Python `random.sample` öneri içeriğine değişkenlik ekler. İlk kalibrasyon semptom veya gecikmeli SLO etkisi üretmezse hedef karar protokole göre yeniden açılır.
- Karar workload profilini, SLO'yu, fault şiddetini veya run zaman çizelgesini değiştirmez.

## D-021 - Fault lifecycle UTC kaynağı

- Durum: **Kabul edildi; yalnız yeni `cpu-recommendation-low-v3` ve yeni run ID için geçerli**
- Karar: Bilimsel fault başlangıç/bitiş UTC değerleri, worker'ın canonical `started` ve `completed` olaylarından alınır. Dış `kubectl exec` taşıma UTC değerleri tanısal kanıt olarak ayrıca korunur fakat fault fazını tanımlamaz. Worker duvar saati ve monotonic süreleri ayrı ayrı `420 +/- 5` saniye kapısından geçmelidir.
- Gerekçe: `ob-cpu-low-006` worker'da `420,000` saniye sürmesine rağmen taşıma ek yükü outer exec aralığını `425,313` saniyeye çıkardı; dış çağrı zamanı gerçek fiziksel etkinin sınırı değildir.
- Alternatifler: Toleransı post hoc genişletmek, sonucu gördükten sonra kabul kuralını değiştireceği için reddedildi. Yalnız monotonic süre kullanmak UTC ile telemetry hizalamasını kanıtlamadığı için reddedildi. Yalnız worker UTC kullanmak saat sıçramasını yakalamadığı için tek başına yetersiz görüldü.
- Fayda: Fault fazı gerçek worker etkinliğiyle hizalanır; taşıma gecikmesi ayrıca görünür kalır ve iki bağımsız saat ölçümü birbirini sınar.
- Bedel ve sınırlılık: Worker sistem UTC saatine güvenir; bu nedenle canonical biçim, sıra, wall-duration ve monotonic-duration kapılarının birlikte geçmesi gerekir. `ob-cpu-low-006` retroaktif kabul edilmez ve invalid kalır.

## D-022 - Worker kaynak hash canonicalization

- Durum: **Kabul edildi teknik tekrarlanabilirlik kapısı; yalnız yeni `cpu-recommendation-low-v4` ve yeni run ID için geçerli**
- Karar: Worker kaynak metni SHA-256 öncesinde UTF-8 BOM'suz ve LF satır sonlu canonical byte dizisine dönüştürülür; normalizasyon yöntemi profil ve injector kanıtında açıkça yazılır.
- Gerekçe: `ob-cpu-low-007` profilindeki LF byte hash'i ile Windows checkout'un CRLF byte hash'i farklı olduğu için injector fault başlamadan fail-closed durdu. Kaynak semantiği aynıydı fakat platforma bağlı working-tree byte dizisi farklıydı.
- Alternatifler: Hash kontrolünü kaldırmak bütünlük kapısını yok edeceği için reddedildi. Yalnız `.gitattributes` kullanmak mevcut checkout ve harici kopyalarda örtük davranışa güvendiği için tek başına seçilmedi. v3 hash'ini değiştirmek immutable ön-kaydı retroaktif değiştireceği için reddedildi.
- Fayda: Aynı kaynak metni Windows/Linux checkout'larında aynı kimliğe sahip olur; gerçek içerik değişikliği yine hash'i değiştirir ve reddedilir.
- Bedel ve sınırlılık: Normalizasyon yalnız metin worker için tanımlıdır; binary injector'larda raw-byte hash gerekir. `ob-cpu-low-007` invalid kalır ve yeniden kullanılmaz.

## D-023 - Worker lifecycle event koleksiyonu dönüşümü

- Durum: **Kabul edildi teknik fail-closed düzeltmesi; bilimsel sözleşme değişmez**
- Karar: Injector'ın `Generic.List[object]` event koleksiyonu lifecycle resolver'ın `object[]` parametresine açık `.ToArray()` ile aktarılır ve test aynı canlı koleksiyon şeklini kullanır.
- Gerekçe: `ob-cpu-low-008` hash ve 420 saniyelik worker yürütmesini geçti; Windows PowerShell 5.1 `@($events)` array-subexpression dönüşümünde `Argument types do not match` vererek lifecycle kanıtını reddetti.
- Alternatifler: Resolver tipini belirsiz bırakmak hata yüzeyini gizlediği için seçilmedi. 008'i sonradan finalize etmek immutable lifecycle zincirini ihlal edeceği için reddedildi.
- Fayda: Test verisi ile canlı injector koleksiyon şekli eşleşir; started/completed UTC ve süre kanıtı kayıpsız resolver'a ulaşır.
- Bedel ve sınırlılık: Düzeltme PowerShell koleksiyon bağlamaya özgüdür; worker, fault şiddeti, süre, SLO ve kabul eşiklerini değiştirmez. `ob-cpu-low-008` invalid kalır.

## D-024 - İlk orta şiddetli CPU profili

- Durum: **Kabul edildi; fault sonucu görülmeden ön-kayıtlı kalibrasyon kararı**
- Karar: `recommendationservice` için `cpu-recommendation-medium-v1`; 100m ek CPU talebi, 120 sn ramp, 300 sn steady, 300 sn cooldown ve en az 50m steady-minus-baseline fiziksel etki kapısı kullanılır. Workload, seed, SLO, hedef, coverage ve lifecycle kapıları değişmez.
- Gerekçe: Üç geçerli düşük run 50,349m ortalama fiziksel artışı %3,576 CV ile tekrarladı fakat hiçbirinde SLO manifestation oluşmadı. Yalnız talebi iki katına çıkarmak severity etkisini diğer değişkenlerden ayırır ve 200m limit altında headroom bırakır.
- Alternatifler: 75m daha güvenli fakat yeniden null manifestation riski yüksek; 125m daha güçlü fakat throttling/limit etkisini severity ile karıştırma riski daha yüksek olduğu için ilk medium kalibrasyonda seçilmedi.
- Fayda: Düşük profile göre kontrollü tek-değişken karşılaştırması ve gecikmeli SLO manifestation olasılığını sınama.
- Bedel ve sınırlılık: İlk run yine null olabilir; 200m limit nedeniyle throttling artabilir. Sonuç high severity'yi, SLO değişikliğini veya dataset kabulünü otomatik yetkilendirmez.

## D-025 - Orta şiddetli CPU kalibrasyonu bağımsız tekrarları

- Durum: **Kabul edildi; ilk medium sonucu sonrasında koşulları değiştirmeyen tekrar kararı**
- Karar: Geçerli `ob-cpu-medium-001`, aynı `cpu-recommendation-medium-v1`, workload, seed, SLO, hedef, lifecycle ve geçerlilik kapılarıyla iki bağımsız run (`ob-cpu-medium-002` ve `ob-cpu-medium-003`) kullanılarak tekrarlanır. Her run ayrı canonical revision, artifact, host-health ve receipt zinciriyle kapanır.
- Gerekçe: `ob-cpu-medium-001` requested 100m altında `+101,910m` fiziksel artışı doğruladı fakat manifestation üretmedi. Tek run, medium fiziksel etki ve null manifestation davranışını sistem varyansından ayırmaya yetmez.
- Alternatifler: Doğrudan high severity'ye geçmek tek medium gözlemini genelleyerek severity ile run varyansını karıştıracağı için reddedildi. Tek medium tekrar daha az maliyetli olsa da üç-run betimsel varyans özeti sağlamadığı için seçilmedi.
- Fayda: Üç geçerli aday elde edilirse medium fiziksel actuation varyansı ve manifestation tutarlılığı, düşük şiddet setiyle aynı yöntemle betimsel olarak karşılaştırılabilir.
- Bedel ve sınırlılık: İki uzun lifecycle daha gerekir ve her ikisi de null manifestation üretebilir. Ön-kayıt high severity, farklı workload, SLO değişikliği, model eğitimi veya nedensel genelleme yetkisi vermez.

## D-026 - cAdvisor lifecycle CPU serisi seçimi

- Durum: **Kabul edildi teknik fail-closed düzeltmesi; `ob-cpu-medium-002` invalid kalır**
- Karar: Aynı pod/container için birden fazla cAdvisor CPU counter serisi olduğunda fiziksel-etki analizi, baseline ve steady fazlarının her ikisinde örnek taşıyan tam olarak bir seriyi seçer. Sıfır veya birden fazla uygun seri reddedilir; throttling yalnız seçilen CPU serisinin aynı cgroup `id` değerinden alınır.
- Gerekçe: `ob-cpu-medium-002` arşivinde warm-up sırasında biten 56 örnekli eski container serisi ile lifecycle'ı kapsayan 266 örnekli aktif seri birlikteydi. Önceki son-eşleşme davranışı eski serinin aktif seriyi ezmesine ve `0/0` interval sonucuna yol açtı.
- Alternatifler: Serileri toplamak counter resetlerini ve farklı cgroup yaşamlarını karıştıracağı için reddedildi. En uzun seriyi koşulsuz seçmek ölçüm fazlarını gerçekten kapsadığını kanıtlamadığı için seçilmedi. `002`yi tanısal replay ile retroaktif geçerli yapmak immutable close-run zincirini ihlal edeceği için reddedildi.
- Fayda: Pre-run container restart kalıntıları aktif lifecycle serisini sessizce gölgeleyemez; belirsizlik açık hata olur. Eski-kısa/aktif-uzun pozitif fixture ve iki-tam-seri negatif fixture bağımsız doğrulama sağlar.
- Bedel ve sınırlılık: Seçim lifecycle UTC doğruluğuna bağlıdır. Gerçekten iki tam seri varsa otomatik birleştirme yapılmaz ve run invalid kalır. Fault profili, fiziksel eşik, coverage, workload, seed ve SLO değişmez.

## D-027 - Eksik üçüncü geçerli medium adayının yeni run ile tamamlanması

- Durum: **Kabul edildi ön-kayıt; ayrı yürütme onayı gerekir**
- Karar: Invalid `ob-cpu-medium-002` yerine, D-025 üç-geçerli-run setini tamamlamak amacıyla yeni benzersiz `ob-cpu-medium-004` adayı kullanılır. `cpu-recommendation-medium-v1`, workload, seed, SLO, hedef, süreler, coverage, fiziksel-etki, lifecycle, host ve receipt kapıları değişmez; D-026 seri seçimi uygulanır.
- Gerekçe: `ob-cpu-medium-001` ve `ob-cpu-medium-003` geçerlidir; `002` final receipt oluşmadan fail-closed reddedildiği için tekrarlanabilirlik setine katılamaz. Üçüncü geçerli aday olmadan ön-kayıtlı betimsel medium varyans özeti tamamlanamaz.
- Alternatifler: `002`yi tanısal replay ile sete almak immutable kapanış ilkesini ihlal ettiği için reddedildi. İki geçerli run ile özeti dondurmak D-025 ölçütünü sonuç sonrasında gevşeteceği için reddedildi. Doğrudan high severity'ye geçmek medium varyans belirsizliğini severity etkisiyle karıştıracağı için seçilmedi.
- Fayda: D-025 hedefi yeni ve bağımsız bir lifecycle ile tamamlanabilir; invalid run kayıt ve metodolojik değerini korur.
- Bedel ve sınırlılık: Bir uzun run daha gerektirir ve yine invalid ya da null manifestation olabilir. Ön-kayıt yüksek şiddet, farklı workload, SLO değişikliği, nedensel etki veya model başarısı iddiası oluşturmaz.

## D-028 - İlk yüksek şiddetli CPU profili

- Durum: **Kabul edildi; fault sonucu görülmeden ön-kayıtlı kalibrasyon kararı**
- Karar: `recommendationservice` için `cpu-recommendation-high-v1`; 150m ek CPU talebi, 120 sn ramp, 300 sn steady, 300 sn cooldown ve en az 75m steady-minus-baseline fiziksel etki kapısı kullanılır. Workload, seed, SLO, hedef, coverage, D-026 seri seçimi ve lifecycle kapıları değişmez. İlk aday `ob-cpu-high-001` olur.
- Gerekçe: Üç geçerli medium run 99,649m ortalama fiziksel artışı %4,947 CV ile tekrarladı fakat hiçbirinde SLO manifestation oluşmadı. Yalnız requested severity'yi 150m'ye çıkarmak, diğer değişkenleri sabit tutarken 200m limit altında yaklaşık 33–40m gözlenen headroom bırakır. 75m fiziksel kapı, low/medium profillerindeki requested etkinin en az %50'si sözleşmesini korur.
- Alternatifler: 125m, medium 100m'den zayıf ayrışma ve yeniden null riskini artırdığı için seçilmedi. 175m, normal 10–17m CPU tüketimiyle 200m limite fazla yaklaşarak severity etkisini yoğun throttling ile karıştırabilir. Hedef servisi veya workload'u aynı anda değiştirmek tek-değişken karşılaştırmasını bozacağı için reddedildi.
- Fayda: Üçüncü severity kademesi, sabit bağlamda daha güçlü fakat bounded CPU etkisini ve olası gecikmeli manifestation'ı sınar.
- Bedel ve sınırlılık: High run yine null olabilir veya limit kaynaklı throttling artabilir. Bu profil post-hoc SLO değişikliği, farklı workload/service, model eğitimi veya yüksek şiddetin güvenli olduğu iddiasını yetkilendirmez.

## D-029 - Yüksek şiddetli CPU kalibrasyonu bağımsız tekrarları

- Durum: **Kabul edildi; koşulları değiştirmeyen iki tekrar ön-kaydı**
- Karar: Geçerli `ob-cpu-high-001`, aynı `cpu-recommendation-high-v1`, workload, seed, SLO, hedef, coverage, D-026 seri seçimi, lifecycle ve geçerlilik kapılarıyla iki bağımsız run (`ob-cpu-high-002` ve `ob-cpu-high-003`) kullanılarak tekrarlanır. Her run ayrı canonical revision, artifact, host-health ve receipt zinciriyle kapanır.
- Gerekçe: `ob-cpu-high-001` `+146,589m` fiziksel artış ve tek izole latency ihlaliyle null manifestation sonucunu yalnız bir run'da gösterdi. Tek run high fiziksel etki, throttling ve manifestation davranışını sistem varyansından ayırmaya yetmez.
- Alternatifler: Tek tekrar daha az maliyetli olsa da üç-run betimsel varyans özeti sağlamadığı için seçilmedi. Doğrudan workload veya target değiştirmek severity tekrarlanabilirliğiyle yeni bağlam etkisini karıştıracağı için reddedildi. Tek latency ihlaline dayanarak SLO'yu gevşetmek post-hoc olduğu için reddedildi.
- Fayda: Üç geçerli aday oluşursa high fiziksel actuation, throttling ve manifestation tutarlılığı low/medium setleriyle aynı betimsel yöntemle karşılaştırılabilir.
- Bedel ve sınırlılık: İki uzun lifecycle daha gerekir; sonuçlar invalid veya null olabilir. Ön-kayıt farklı workload/service, SLO değişikliği, model eğitimi, pre-failure başarı veya nedensel genelleme yetkisi vermez.

## D-030 - İkinci workload seviyesi için fault'suz kapasite kalibrasyonu

- Durum: **Kabul edildi; sonuç görülmeden ön-kayıtlı seçim prosedürü**
- Karar: Mevcut 10-kullanıcı referansı, 15 ve 20 eşzamanlı kullanıcı adaylarıyla fault uygulanmadan karşılaştırılır. Image, replica, spawn rate `1/s`, bekleme dağılımı, task ağırlıkları, seed `1`, sampling ve `300 sn warm-up + 300 sn measurement` sabit kalır. Seed `20260810` ile aday sırası `20 -> 10 -> 15` olarak dondurulur.
- Seçim: En yüksek aday; active run-ID, 15-pod lifecycle, schema-v3 telemetry ve host `0/0/0` kapılarını geçer, dondurulmuş SLO'da manifestation üretmez, frontend request yoğunluğunu ölçülen 10-user kontrole göre en az `1,30x` artırır ve recommendationservice ortalama CPU'sunu en fazla `25m` tutarsa seçilir. 20 geçmezse 15 değerlendirilir; ikisi de geçmezse ikinci workload seçilmez ve eşikler gevşetilmez.
- Gerekçe: P3 en az iki workload seviyesi ister; workload fault severity ile karışırsa model trafik yoğunluğunu fault sinyali sanabilir. 25m CPU kapısı, 200m limit ve mevcut +150m high talep sonrasında en az 25m nominal ortalama headroom korur.
- Alternatifler: Kanıtsız doğrudan 20 user seçmek; spawn rate ile user sayısını birlikte değiştirmek; fault sonuçlarına göre workload seçmek ve 25 user gibi daha agresif ilk aday kullanmak reddedildi. Bunlar sırasıyla kararlılık belirsizliği, çoklu-değişken karışması, outcome leakage ve host/headroom riski yaratır.
- Sonraki plan: Seçilen workload için üç geçerli normal baseline toplanır. Ardından low/medium/high profillerinin her biri iki kez, seed `20260810` ile dondurulmuş `medium-2, low-2, high-1, high-2, low-1, medium-1` sırasında yürütülür. Invalid run'lar korunur ve aynı koşullarda yeni ID ile tamamlanır.
- Fayda: İkinci workload kararı fault outcome'undan bağımsız, yeniden hesaplanabilir ve falsifiye edilebilir olur; P3'te severity-workload ayrımı korunur.
- Bedel ve sınırlılık: Üç kapasite koşusu ve en az dokuz sonraki bilimsel run gerekir. Frontend span rate gerçek kullanıcı sayısı değil request-intensity vekilidir. Yerel tek-host sonucu genellenemez. Bu karar model eğitimi, LLM, GAT, SLO veya hedef servis değişikliği yetkisi vermez.
- Sonuç: D-031/032 uyumlu geçerli kontrol ve adaylarda 15-user request oranı `1,417334x`, mean CPU `35,890m`; 20-user oranı `1,907908x`, mean CPU `43,015m` oldu. İki aday request, SLO, pod, host ve telemetry kapılarını geçti fakat `<=25m` CPU kapısını geçmedi. Selector deterministik olarak `selected_users=null` üretti; eşikler değiştirilmedi ve conditional normal/fault planı aktive edilmedi.

## D-031 - Kapasite kanıtında pod snapshot ve tek CPU-serisi kapısı

- Durum: **Kabul edildi teknik geçerlilik düzeltmesi; yalnız yeni run ID'ler için**
- Karar: Kapasite assessment'ı measurement öncesi/sonrası 15 deployment pod UID ve restart snapshot'larını tam olarak saklar. CPU analyzer, kaydedilmiş recommendationservice pod adı için measurement'ın ilk ve son 30 saniyesinde örnek taşıyan tam olarak bir cAdvisor counter serisi ister; sıfır veya birden fazla seri fail-closed reddedilir.
- Gerekçe: `ob-capacity-20u-001` pod-stability false sonucunun bileşen snapshot'larını saklamadı; CPU analizi eski/kısa ve aktif serileri birleştirerek 89 interval ve yorumlanamaz p95 `0m` üretti. Run bu nedenle invalid kalır.
- Alternatifler: Boolean pod sonucuna güvenmek ve CPU serilerini toplamak bağımsız denetimi bozduğu için reddedildi. Eski run'ı yeni analyzer ile kabul etmek immutable kapanışı ihlal edeceği için reddedildi.
- Fayda: Lifecycle kararlılığı hangi bileşenin değiştiğine kadar denetlenebilir; stale-series contamination workload headroom kararını etkileyemez.
- Bedel ve sınırlılık: Yeni 20-user run gerekebilir; gerçek iki tam seri varsa otomatik birleştirilmez. D-030 user adayları, eşikler, SLO ve randomizasyon değişmez.

## D-032 - Kapasite runner'ında workload faz alanı uyumluluğu

- Durum: **Kabul edildi teknik uyumluluk düzeltmesi; yalnız yeni run ID için**
- Karar: Kapasite runner'ı aday profillerdeki `measurement_seconds` veya mevcut 10-user profildeki `normal_baseline_seconds` alanını tek internal measurement süresine normalleştirir; değer tam olarak `300` saniye değilse fail-closed durur. Warm-up, seed ve spawn-rate ayrı profil testinde sabitlenir.
- Gerekçe: `ob-capacity-10u-001`, 300 saniyelik warm-up sonrasında eşdeğer süre alanının farklı adı nedeniyle measurement başlamadan durdu.
- Alternatifler: Mevcut 10-user profilini geriye dönük yeniden adlandırmak receipt hash/provenance zincirini bozacağı için reddedildi. Süreyi varsaymak ise eksik profili sessizce kabul edeceği için reddedildi.
- Fayda: Tarihsel profil değişmeden aynı 300 saniyelik anlamsal sözleşme uygulanır.
- Bedel ve sınırlılık: Bir yeni 10-user run gerekir. D-030 eşikleri, süreleri ve sırası değişmez.

## D-033 - İkinci bilimsel workload ve prospektif CPU rezervi

- Durum: **Kabul edildi; kullanıcı onaylı ve ikinci-workload sonuçları görülmeden ön-kayıtlı**
- Karar: İkinci bilimsel workload `ob-second-15u-1r-v1` olur. Recommendationservice CPU limiti `200m`, low/medium/high talepleri `50/100/150m`, hedef, seed `1`, spawn rate `1/s`, workload davranışı, SLO, sampling ve lifecycle değişmez. Yeni seçim kuralı limitin `%5`i olan `10m` nominal rezervdir; `normal mean CPU <=40m`. `ob-capacity-15u-001` gözlemi `35,890m` ile bu yeni prospektif kuralı geçer. D-030'un `<=25m` sonucu ve `selected_users=null` kaydı geriye dönük değiştirilmez.
- Profil/provenance: Kapasite profili dataset-dışı olduğu için bilimsel run'larda yeniden kullanılmaz. Yeni workload'a özgü `cpu-recommendation-low-15u-v1`, `medium-15u-v1` ve `high-15u-v1` profilleri yalnız profil kimliği/workload bağını değiştirir; fault fiziği kaynak profillerle bağımsız testte eşit olmalıdır.
- Ön-kayıt: Önce `ob-cpu-15u-normal-001/002/003` tamamlanır. Sonra D-030 seed `20260810` sırası değişmeden `medium-2, low-2, high-1, high-2, low-1, medium-1` yürütülür. Invalid run silinmez; yeni benzersiz ID ile aynı koşullarda tamamlanır.
- Gerekçe: `P1-WORKLOAD-RESOURCE-BUDGET-001`, eski `1,30x` yoğunluk ve `<=25m` CPU kapılarının küçük bir adayla birlikte karşılanmasının beklenmediğini gösterdi. 15 user request yoğunluğunu `1,417334x` artırdı, normal SLO/pod/host/telemetry kapılarını geçti ve yeni teorik `%5` rezerv kuralının altında kaldı. Limit veya fault talebini değiştirmek workload dışında ikinci bir değişken yaratırdı.
- Alternatifler: High talebini azaltmak severity'yi workload'lar arasında farklılaştırdığı; CPU limitini artırmak deployment/fault fiziğini değiştirdiği; 20 user yalnız yaklaşık `10,044m` toplamsal kalan bütçe tahmini sunduğu; daha küçük aday eski iki kapının yapısal gerilimini çözmediği için seçilmedi.
- Fayda: İkinci workload tek-değişken karşılaştırmasını, severity eşleşmesini ve P3 challenge tasarımını korur; karar fault sonucu görülmeden mühürlenir.
- Bedel ve sınırlılık: `%5` rezerv yeni bir pilot tasarım kuralıdır ve D-030 sonuçlarından sonra şeffaf biçimde geliştirilmiştir. Ortalama CPU burst/p95 davranışını garanti etmez; high altında throttling artabilir. Her run fiziksel etki, SLO, throttling, pod, host, telemetry ve receipt kapılarından bağımsız geçmelidir. Karar model, LLM, GAT veya SLO değişikliği yetkisi vermez.

## D-034 - İkinci workload runtime ve metadata bağlama kapısı

- Durum: **Kabul edildi D-033'ün teknik geçerlilik uygulaması**
- Karar: Fault orchestrator workload profilini parametre olarak alır; profil ID/seed değerini dosyadan türetir ve fault profilinin workload bağıyla eşleştirir. Active-workload verifier, static kustomization ile canlı loadgenerator deployment/pod ortamındaki `USERS`, `RATE`, `WORKLOAD_PROFILE_ID` ve `WORKLOAD_RANDOM_SEED` değerlerinin tamamını doğrular. Fault metadata verifier yalnız sürümlü 10-user/15-user profil çiftlerini kabul eder ve çapraz bağlamı reddeder.
- Gerekçe: Önceki orchestrator ve verifier `ob-default-10u-1r-v1` değerine sabit bağlıydı; bu durum 15-user metadata üretimini engeller veya yanlış bağlam kabul edilirse provenance'ı bozar. YAML'ın doğru olması çalışan podun doğru profili kullandığını tek başına kanıtlamaz.
- Alternatifler: 15-user değerini yeni scriptte tekrar hard-code etmek yinelenen kaynak oluşturduğu; yalnız metadata alanına güvenmek canlı deployment'ı kanıtlamadığı; verifier'daki workload kontrolünü kaldırmak fail-open olduğu için reddedildi.
- Fayda: Workload kimliği versioned profile -> kustomization -> deployment -> pod -> scientific metadata -> receipt boyunca çapraz doğrulanabilir olur.
- Bedel ve sınırlılık: Static fixture canlı deployment kanıtı değildir; her run öncesi canlı kapı ayrıca geçmelidir. Bu karar workload, fault şiddeti, SLO, süre veya run sırasını değiştirmez ve normal-baseline orchestrator hazırlığını otomatik tamamlamaz.

## D-035 - İkinci workload bilimsel normal-baseline orchestrator'ı

- Durum: **Kabul edildi D-033/D-034 teknik yürütme uygulaması**
- Karar: `run-scientific-normal-baseline.ps1`, yalnız `ob-second-15u-1r-v1` için fault içermeyen 300 sn warm-up + 300 sn baseline lifecycle'ını; active run/workload, 15-pod continuity, immutable log/schema-v3 telemetry, normal SLO, host `0/0/0`, scientific metadata, final receipt ve offline verifier kapılarıyla fail-closed yürütür. Hata halinde kısmi kanıt korunur ve cluster durdurulur.
- Gerekçe: Kapasite runner'ı bilinçli olarak dataset-dışı karar kanıtı üretir; onu bilimsel normal baseline olarak kullanmak provenance ihlalidir. Manuel komut zinciri kapanış veya metadata adımının atlanması riskini artırır.
- Alternatifler: Kapasite artifact'ını yeniden etiketlemek immutable provenance nedeniyle; fault runner'ı `fault=none` ile kullanmak yanlış run_kind/fault metadata üreteceği için; yalnız operatör kontrol listesi ise mekanik kapıları garanti etmediği için reddedildi.
- Fayda: Üç normal run aynı kodlanmış lifecycle ve bağımsız verifier zinciriyle toplanır. Scriptte fault çağrısı bulunmadığı AST/metin testiyle sınanır.
- Bedel ve sınırlılık: Static/WhatIf testleri canlı deployment veya telemetry başarısını kanıtlamaz. D-033 `<=40m` seçim ölçütü yeni normal sonuçlarını post-hoc dışlama kuralı değildir; CPU raporlanır. Runner merge edilmeden run başlayamaz ve üç valid normal tamamlanmadan fault'a geçilemez.
- İlk canlı sonuç: `ob-cpu-15u-normal-001` fault olmadan bütün host/pod/log/schema-v3/metadata/final receipt ve bağımsız replay kapılarını geçti. Recommendationservice mean CPU `39,807m`, frozen-SLO manifestation null oldu. Bu ilk valid 15-user normaldir; D-033 eşiğini değiştirmez, tek başına tekrarlanabilirlik sağlamaz ve `002/003` tamamlanmadan fault yetkisi oluşturmaz.
- İkinci canlı sonuç: `ob-cpu-15u-normal-002` fault olmadan host `0/0/0`, pod ve raw/enriched/schema-v3 replay kapılarını geçti; fakat frozen latency SLO'sunda üç ardışık ihlal `2026-08-11T19:10:07.812Z` manifestation üretti. Run `invalid` ve dataset dışı korunur. Mean CPU `43,612m`, D-033 seçim eşiği post-hoc run dışlama kuralı olmadığı için dışlama gerekçesi değildir. Karar ve eşikler değişmez; geçerli blok `1/3` kalır ve replacement yeni benzersiz ID gerektirir.
- Üçüncü canlı sonuç: `ob-cpu-15u-normal-003` fault olmadan bütün host/pod/log/schema-v3/metadata/final receipt ve bağımsız replay kapılarını geçti. Frozen-SLO manifestation null, mean CPU `41,816m` oldu. D-033 seçim eşiği post-hoc dışlama kuralına çevrilmez; bu ikinci valid 15-user normaldir. Geçerli blok `2/3` olur ve `002` için yeni benzersiz replacement tamamlanmadan fault yetkisi oluşmaz.
- Replacement sonucu: `ob-cpu-15u-normal-004`, invalid `002` yerine aynı frozen koşullarda fault olmadan bütün host/pod/log/schema-v3/metadata/final receipt ve bağımsız replay kapılarını geçti. Manifestation null, mean CPU `22,585m` oldu. Geçerli normal seti `001/003/004`, blok `3/3` tamamlandı; `002` değiştirilmeden invalid kalır. Bu sonuç D-033'ün randomize fault serisi başlangıç kapısını açar fakat canonical run-ID/profil merge ve canlı preflight gereğini kaldırmaz.

## D-036 - İkinci-workload injector profil allowlist eşitlemesi

- Durum: **Kabul edildi; D-033/D-034 teknik uygulama düzeltmesi, akademik koşul değişikliği yok**
- Karar: `invoke-cpu-stress.ps1` allowlist'i, metadata verifier ile aynı ön-kayıtlı `cpu-recommendation-low-15u-v1`, `medium-15u-v1` ve `high-15u-v1` sözleşmelerini kabul eder. 15-user profillerinin target/minimum etki çiftleri sırasıyla `50/25m`, `100/50m`, `150/75m`; coverage `48`, ramp/steady `120/300 sn` olarak değişmeden kalır. Her üç profil gerçek injection oluşturmayan `-WhatIf` pozitif testinden, değiştirilmiş medium minimum-etki profili negatif testten geçmelidir.
- Gerekçe: `ob-cpu-15u-medium-002`, run-ID/workload ve 300+300 sn ön fazları geçtikten sonra worker başlamadan reddedildi. Injector yalnız 10-user profil kimliklerini tanırken metadata verifier 15-user profillerini kabul ediyordu; bu iki uygulama kapısı aynı akademik sözleşmeyi farklı temsil ediyordu.
- Alternatifler: 15-user run'da 10-user profil kimliği kullanmak provenance'ı yanlış göstereceği; injector profil denetimini kaldırmak fail-open davranış yaratacağı; `medium-002`yi düzeltme sonrası yeniden kullanmak immutable run-ID ilkesini ihlal edeceği için reddedildi.
- Fayda: Injector, metadata ve D-033 profil eş-fiziği tek sözleşmede hizalanır; yanlış fizik alanları yine fault başlamadan reddedilir.
- Bedel ve sınırlılık: `medium-002` invalid/incomplete ve dataset dışı kalır; fault uygulanmadığı için medium etkisi hakkında kanıt değildir. Düzeltme merge edilmeden yeni fault başlamaz; aynı randomize slot yeni `ob-cpu-15u-medium-003` ID ile tekrarlanır.

## D-037 - Uzun fault run dış yürütme timeout bütçesi

- Durum: **Kabul edildi operasyonel geçerlilik düzeltmesi; akademik lifecycle değişmez**
- Karar: 15-user fault runner çağrılarında dış komut timeout'u en az 60 dakika olur. Runner içindeki 300 sn warm-up, 300 sn baseline, 120 sn ramp, 300 sn steady ve 300 sn cooldown; fault profili, workload, seed, SLO, coverage, host ve receipt kapıları aynen kalır.
- Gerekçe: `ob-cpu-15u-medium-003` full lifecycle/cooldown'u tamamladı; 22 dakikalık ölçümün ardından schema-v3 export/doğrulama büyük arşiv üzerinde devam ederken dış 40 dakikalık sınır runner'ı scientific metadata/final receipt öncesinde sonlandırdı. Offline telemetry replay tek başına `475,2 sn` sürdü.
- Alternatifler: Lifecycle veya telemetry kapsamını kısaltmak bilimsel sözleşmeyi değiştireceği; incomplete run'ı offline analizle retroaktif kapatmak pod-after provenance ve receipt eksikliğini gizleyeceği; aynı ID'yi kullanmak immutability ilkesini ihlal edeceği için reddedildi.
- Fayda: Bilimsel ölçüm değişmeden kapanış/export/hash zincirine yeterli operasyonel süre verilir.
- Bedel ve sınırlılık: Daha uzun bekleme süresi vardır; timeout artışı başarı garantisi değildir. `medium-003` invalid/incomplete kalır ve aynı randomize slot yeni `ob-cpu-15u-medium-004` ile tamamlanır.
- Uygulama sonucu: `ob-cpu-15u-medium-004`, 65 dakikalık dış bütçe içinde `43,7` dakikada tamamlandı; lifecycle değiştirilmeden coverage `59/59`, fiziksel CPU farkı `+94,454m`, host `0/0/0`, manifestation null ve bütün final receipt/offline replay kapıları geçti. Böylece operasyonel timeout düzeltmesi doğrulandı ve ilk randomize 15-user fault slotu geçerli kapandı; sonuç tek başına medium tekrarlanabilirliği veya model başarısı iddiası değildir.
- Sonraki operasyonel kayıt: `ob-cpu-15u-low-002`, Minikube hazır olmadığı için ilk active run-ID kapısında fault öncesi `invalid/incomplete` kapandı. D-033'ün workload, seed, low profili, lifecycle, SLO ve eşikleri değişmez; ID yeniden kullanılmaz ve cluster readiness sonrası aynı ikinci slot yeni `ob-cpu-15u-low-003` ile tamamlanır.
- Sonraki operasyonel kayıt: `ob-cpu-15u-low-003`, active run-ID/workload ve 300+300 sn ön evreleri geçti; bounded worker exec anında `server` container bulunamadığı için fault öncesi `invalid/incomplete` kapandı. Host farkı `0/0/0` idi. D-033 koşulları değişmez; yeni replacement öncesi hedef pod/container restart-stability süresi ve exec-yarışı politikasına ilişkin açık karar gerekir.

## D-038 - Fault hedefi pod/container stabilite kapısı

- Durum: **Kabul edildi operasyonel geçerlilik düzeltmesi; fault fiziği ve bilimsel lifecycle değişmez**
- Karar: 15-user fault run'larında hedef pod, warm-up öncesinde 5 saniyelik cadence ile 120 saniye gözlenir. Her gözlemde tek hedef pod, `Ready` durumu, beklenen `server` container'ı, pod UID, container ID ve restart sayısı aynı olmalıdır. Worker exec'ten hemen önce canlı kimlik mühürlü final snapshot ile tekrar karşılaştırılır. Farkta otomatik retry yapılmaz; run fault öncesi fail-closed kapanır. Kanıt read-only saklanır, SHA-256 değeri injector execution evidence'a bağlanır.
- Gerekçe: `ob-cpu-15u-low-003` Kubernetes deployment Available ve pod `1/1` iken, recommendationservice kısa süre önce dört restart yaşamıştı; worker exec anında `server` container bulunamadı. Mevcut readiness kapısı yeni restart etmiş container'ın injection anında kararlı olduğunu kanıtlamadı.
- Alternatifler: Kör otomatik exec retry injection başlangıcını belirsizleştireceği; yalnız tek anlık Ready kontrolü aynı yarışı sürdüreceği; stabilite beklemesini baseline sonrasına koymak lifecycle'a yeni boşluk ekleyeceği için reddedildi. Warm-up öncesi pencere ve worker öncesi aynı-kimlik kontrolü seçildi.
- Fayda: Fault hedefi adıyla birlikte gerçek pod/container örneğine bağlanır; warm-up/baseline sırasında restart olursa injection başlamadan reddedilir ve zaman çizelgesi değişmez.
- Bedel ve sınırlılık: Her run'a 120 saniye hazırlık ekler; geçici restartlar daha fazla invalid girişim üretebilir. Kapı altyapının gelecekte kararlı kalacağını garanti etmez ve worker başladıktan sonraki pod/host/fiziksel-etki/final receipt kapılarını kaldırmaz.
- Replacement: Aynı D-033 low koşulları yeni benzersiz `ob-cpu-15u-low-004` ile tamamlanır; D-038 ve run-ID bağı canonical merge edilmeden fault başlamaz.
- Uygulama sonucu: `ob-cpu-15u-low-004`, 25 D-038 gözlemi ve restart `0` ile hedef kimliğini korudu; coverage `59/59`, fiziksel CPU farkı `+49,153m`, host `0/0/0`, manifestation null ve bütün receipt/offline replay kapıları geçti. İkinci randomize slot geçerli kapandı; sonuç tek başına low tekrarlanabilirliği veya model başarısı iddiası değildir.
- Randomize high uygulama sonucu: `ob-cpu-15u-high-001`, 25 D-038 gözlemi/restart `0`, coverage `59/58`, fiziksel CPU farkı `+135,160m`, throttling `99,790m`, host `0/0/0`, manifestation null ve bütün receipt/offline replay kapılarıyla geçerli kapandı. Üçüncü randomize slot tamamlandı; tek run high tekrarlanabilirliği veya model başarısı iddiası değildir.
- İkinci randomize high sonucu: `ob-cpu-15u-high-002`, 25 D-038 gözlemi/restart `0`, coverage `59/59`, fiziksel CPU farkı `+145,710m`, throttling `137,848m`, host `0/0/0`, manifestation null ve bütün receipt/offline replay kapılarıyla geçerli kapandı. Fault bloğu `4/6` oldu; iki high run yalnız betimsel tekrar sağlar, blok tamamlanmadan nihai varyans veya model iddiası yapılmaz.
- İkinci randomize low sonucu: `ob-cpu-15u-low-001`, 25 D-038 gözlemi ve sabit restart `1`, coverage `59/59`, fiziksel CPU farkı `+53,044m`, throttling `77,737m`, host `0/0/0`, manifestation null ve bütün receipt/offline replay kapılarıyla geçerli kapandı. Fault bloğu `5/6` oldu; iki low run yalnız betimsel tekrar sağlar. Son `medium-001` ve blok kapanış denetimi tamamlanmadan nihai varyans veya model iddiası yapılmaz.
- Son randomize medium girişimi: `ob-cpu-15u-medium-001`, D-038 25 gözlem/sabit restart `3`, coverage `60/59`, fiziksel CPU farkı `+100,390m`, host `0/0/0`, manifestation null ve bağımsız raw/enriched/schema-v3 replay kapılarını tanısal olarak geçti. Canonical warm-up UTC süresi `299,9970699 sn` ile frozen 300 saniye kapısından `0,0029301 sn` kısa olduğu için metadata verifier `warmup_too_short` dedi ve final receipt oluşmadı. Run `invalid/incomplete`, dataset dışı ve aynı ID kullanılamaz; ön-finalization `valid_run=true` alanı receipt başarısızlığını geçersiz kılamaz. Eşikler gevşetilmez; geçerli fault bloğu `5/6` kalır ve replacement, metodoloji veya sonraki aşama kararı otomatik verilmez.

## D-039 - Minimum faz süresi deadline kapısı ve medium replacement ön-kaydı

- Durum: **Kabul edildi operasyonel geçerlilik düzeltmesi; bilimsel lifecycle ve eşikler değişmez**
- Karar: Runner'ın warm-up, normal baseline ve cooldown fazları, kaydedilmiş başlangıç UTC'sinden hesaplanan minimum 300 saniyelik deadline görülmeden bitiş UTC'si üretmez. `Start-Sleep 300` tek başına süre kanıtı sayılmaz. Invalid `ob-cpu-15u-medium-001` yerine aynı `ob-second-15u-1r-v1`, seed `1`, `cpu-recommendation-medium-15u-v1`, D-038, SLO, coverage ve 300/300/120/300/300 lifecycle ile yeni benzersiz `ob-cpu-15u-medium-005` ön-kaydedilir.
- Gerekçe: `ob-cpu-15u-medium-001` bütün fiziksel-etki/host/pod/telemetry kapılarını tanısal olarak geçti; fakat warm-up UTC farkı `299,9970699 sn` oldu ve frozen `>=300 sn` metadata kapısı doğru biçimde reddetti. PowerShell sleep dönüşü ile hemen sonraki UTC örneklemesi minimum süreyi garanti etmedi.
- Alternatifler: Verifier'a tolerans eklemek sonuç görüldükten sonra eşiği gevşeteceği; `medium-001`i retroaktif finalize etmek immutable receipt zincirini ihlal edeceği; yalnız sleep süresini keyfi artırmak kaydedilmiş başlangıç UTC'sine bağlı açık bir garanti vermeyeceği için reddedildi. Başlangıç UTC'sine bağlı deadline seçildi.
- Fayda: Mevcut minimum 300 saniye sözleşmesi uygulanabilir ve bağımsız test edilebilir hale gelir; erken scheduler dönüşü geçerli veri görünümü yaratamaz.
- Bedel ve sınırlılık: Fazlar scheduler ve saat davranışına göre birkaç milisaniye veya daha fazla uzayabilir; host UTC geriye giderse bekleme uzar. Bu kapı başarı garantisi değildir ve diğer bilimsel/operasyonel kapıları kaldırmaz.
- Merge kapısı: D-039 kodu, testi, mimari kaydı ve `ob-cpu-15u-medium-005` run-ID bağı canonical `main` üzerine merge edilmeden replacement fault başlatılmaz.
- Uygulama sonucu: `ob-cpu-15u-medium-005`, D-038 25 gözlem/sabit restart `1` ve D-039 warm-up/baseline/cooldown `300,0175/300,0160/300,0119 sn` ile minimum süre kapılarını geçti. Coverage `59/59`, fiziksel CPU farkı `+93,519m`, throttling `69,644m`, host `0/0/0`, manifestation null ve bütün raw/enriched/schema-v3/metadata/final receipt/offline replay kapıları geçti. Run geçerli, bilimsel run sayısı `21` ve fault bloğu `6/6` olur.
- Fault blok kapanış değerlendirmesi: İki geçerli low/medium/high run'ın fiziksel CPU artışı ortalamaları `51,098/93,987/140,435m`; sample SD `2,751/0,661/7,460m`; CV `%5,384/%0,704/%5,312`. Altı run'ın tamamında manifestation null'dır. Bu severity ile artan fiziksel actuation ve severity-içi betimsel tekrar kanıtıdır; pozitif failure manifestation, pre-failure tahmin, model başarısı veya sonraki metodoloji aşamasına otomatik geçiş kararı değildir.

## D-040 - CPU stress'in RCA-only korunması ve network-delay tasarım kapısı

- Durum: **Kabul edildi; kullanıcı onayıyla akademik yön kararı**
- Karar: P1'de geçerli fault manifestation `0/15` üreten CPU stress, mevcut immutable
  kanıtı ve etiketleri değiştirilmeden erken-tahmin sınıfından çıkarılır ve RCA-only
  fault sınıfı olarak korunur. Sonraki erken-tahmin adayı D-004 ile uyumlu kademeli
  network delay'dir. Önce `P2-NETWORK-DELAY-DESIGN-001` karar-desteği/tooling kapısı
  tamamlanır; bu aşama hedef edge, injector yöntemi, delay severity/rampı, SLO,
  bilimsel run ID veya fault yürütmesi yetkilendirmez.
- Gerekçe: İki workload ve üç severity fiziksel CPU actuation'ını tekrarladı; ancak
  sıfır pozitif manifestation/lead-time örneğiyle proactive sınıflandırma ve
  event-based baseline tanımlanamaz. Kademeli network delay literatür ve D-004'te
  önceden adaydır ve injection başlangıcından ayrı kullanıcı etkisi üretme hipotezi
  prospektif sınanabilir.
- Alternatifler: CPU hedef/severity/SLO'sunu sonuç sonrası yeniden ayarlamak post-hoc
  uyarlama riski nedeniyle seçilmedi. Aynı CPU koşularını artırmak fiziksel varyansı
  daraltabilse de sıfır-event sorununu çözme garantisi vermediği için sonraki ana yol
  yapılmadı. Pod kill doğal öncül sinyali olmayan ani RCA kontrolü olduğundan erken
  tahmin adayı seçilmedi.
- Fayda: Negatif CPU sonucu bozulmadan korunur; yeni prediction hipotezi ayrı fault
  sınıfı, ayrı ön-kayıt ve ayrı geçerlilik kapılarıyla falsifiye edilebilir olur.
- Bedel ve sınırlılık: Network delay yeni privilege/izolasyon, cleanup ve fiziksel
  etki kanıtı gerektirir. Mevcut pod güvenlik bağlamı `NET_ADMIN` sağlamaz; `netem`,
  açık proxy ve service-mesh seçenekleri tooling aşamasında karşılaştırılmadan hedef
  veya injector seçilemez.
- Merge/yürütme sınırı: `P2-NETWORK-DELAY-DESIGN-001` çıktıları ve daha sonra ayrı
  bilimsel ön-kayıt canonical `main` üzerine merge edilmeden; temiz host/cluster ve
  açık yürütme onayı alınmadan network delay fault başlatılmaz. Model, LLM ve GAT
  çalıştırılmaz.

## D-041 - Network-delay hedef edge, injector ve prospektif ölçüm sözleşmesi

- Durum: **Kabul edildi; P2 tasarım/tooling kapısı tamamlandı, scientific run yetkisiz**
- Karar: İlk kademeli network-delay adayı yalnız
  `recommendationservice -> productcatalogservice` yönüdür. İzolasyon,
  recommendationservice podunda ayrıcalıksız ve digest-pinned Toxiproxy sidecar ile
  yalnız `PRODUCT_CATALOG_SERVICE_ADDR` üzerinden yapılır. Tasarım hedefi `750 ms`
  downstream latency, `0 ms` jitter, 10 saniyelik ramp adımı ve
  `300/300/120/300/300` lifecycle'dır. Fiziksel kabul, baseline/steady fazlarının
  her birinde en az 48 dolu hedef-edge penceresi ve steady-baseline median caller
  client-span latency farkı `>=500 ms` gerektirir. İlk semptom hedef-edge window-p95
  `>116,942 ms` iki ardışık pencere; manifestation ürün-detay window-p95
  `>594,664 ms` veya global error rate `>0` üç ardışık penceredir.
- Gerekçe: Edge altı geçerli normal run'ın 6/6'sında, iki workload'ta, 3.872 span ve
  en az `%98` pencere coverage'ıyla gözlendi. İlk-semptom eşiği hedef-edge normal
  window-p95 p99'undan; manifestation eşiği ürün-detay normal window-p95 p99'undan
  fault verisi kullanılmadan alındı. Her iki normal replay de yanlış olay üretmedi.
- Alternatifler: `frontend -> productcatalogservice` daha yoğundu fakat doğrudan
  ürün rotasıyla fault etkisini karıştırma ve daha geniş kullanıcı-yolu etkisi
  taşıdı. `tc netem`, mevcut pod sınırında `NET_ADMIN` gerektirdiği; service mesh
  yeni altyapı ve karıştırıcı değişken eklediği için seçilmedi. Açık sidecar proxy,
  edge'e özgü adresleme ile API tabanlı temizleme kanıtını birlikte sağladı.
- Fayda: Injector komut başarısı, ölçülmüş fiziksel etki, ilk semptom ve failure
  manifestation ayrı ve falsifiye edilebilir kapılar olarak kalır; residual toxic
  API geri okumasıyla fail-closed reddedilir.
- Bedel ve sınırlılık: Proxy rollout'u ve kendi overhead'i yeni karıştırıcıdır;
  scientific run öncesi fault içermeyen canlı overlay kontrolünde ölçülmelidir.
  `750 ms` yapılandırma ölçülmüş etki değildir ve `>=500 ms` kapısını garanti etmez.
- Merge/yürütme sınırı: Tasarım çıktıları canonical `main` üzerine merge edilmeden
  canlı overlay kapısı açılmaz. Bu kapı geçmeden benzersiz scientific run ID ve fault
  ön-kaydı oluşturulmaz. Mevcut profilde `scientific_run_authorized=false` ve run ID
  null'dır; model, LLM ve GAT çalıştırılmaz.

## D-042 - No-toxic canlı proxy compatibility kapısının geçmesi

- Durum: **Kabul edildi; operasyonel compatibility gate geçerli, scientific fault yetkisiz**
- Karar: `P2-NETWORK-DELAY-PROXY-LIVE-001`, 15-user workload altında D-041
  Toxiproxy sidecar'ının canlı no-toxic compatibility kanıtı olarak kabul edilir.
  Ölçülen hedef-edge median overhead `+0,3415 ms`, sonuçtan önce dondurulan `<=5 ms`
  sınırının altındadır; base/proxy coverage `60/60`, proxy SLO manifestation yok,
  ölçüm-içi pod sürekliliği ve host/rollback/telemetry/final-receipt kapıları geçmiştir.
- Gerekçe: API'de `toxics=[]` tek başına yeterli değildir. Aynı run-ID ve workload
  altında paired base/proxy trace ölçümü, schema-v3 archive, full-pod snapshot,
  rollback ve offline hash replay'i proxy'nin kendi etkisini bağımsız sınadı.
- Alternatifler: Proxy'yi ilk scientific fault run'ında doğrulamak overhead ile fault
  etkisini karıştıracağı için reddedildi. Yalnız smoke/API testi ölçülmüş kullanıcı
  yolu maliyeti vermediği için yeterli sayılmadı. İki workload'u bu tooling kapısında
  yeniden çalıştırmak, edge'in iki-workload coverage'ı D-041'de zaten sağlandığından
  ek rollout/zaman karıştırıcısına karşı seçilmedi; yüksek yükteki 15-user kontrolü
  kullanıldı.
- Fayda: Ayrıcalıksız edge-izole proxy mimarisinin canlı uygulanabilirliği ve temiz
  geri alınabilirliği, network fault gözlenmeden falsifiye edildi.
- Bedel ve sınırlılık: Base her zaman proxy'den önce geldiği için aynı-host zaman
  drift'i tamamen elenmez; tek compatibility gate population-level overhead kanıtı
  değildir. `+0,3415 ms`, gelecekteki `750 ms` toxic'in ölçülmüş fiziksel etkisi
  veya failure manifestation garantisi değildir.
- Merge/yürütme sınırı: Bu sonuç canonical `main` üzerine merge edilmeden ayrı
  scientific network-delay ön-kaydı hazırlanmaz. Merge sonrasında bile benzersiz
  scientific run ID, host/cluster/run-ID kapıları ve açık kullanıcı yürütme onayı
  olmadan fault başlatılmaz. Model, LLM ve GAT çalıştırılmaz.

## D-043 - İlk scientific network-delay run'ının prospektif ön-kaydı

- Durum: **Kabul edildi; ön-kayıt/tooling tamamlandı, fault yürütmesi yetkisiz**
- Karar: İlk aday `ob-netdelay-15u-001`, `ob-second-15u-1r-v1` workload'u ve yalnız
  `recommendationservice -> productcatalogservice` downstream edge'i için bağlanır.
  Toxiproxy toxic'i 120 saniyede 12 adet 10 saniyelik adımla `0 -> 750 ms` çıkar;
  jitter `0`, toxicity `1`; lifecycle `300/300/120/300/300`dür. Fiziksel etki,
  baseline ve steady'de en az 48 dolu pencere ve median fark `>=500 ms` olmadan
  kabul edilmez. D-041 first-symptom ve SLO eşikleri değiştirilmez.
- Gerekçe: D-042 aynı 15-user workload'ta proxy overhead/continuity kapısını geçti;
  aynı workload'u kullanmak ilk toxic run'da yeni bir yük karıştırıcısı eklemez.
  Deterministik ramp ve ayrı API geri okumaları injection komutu ile ölçülen etkiyi
  birbirinden ayırır.
- Alternatifler: İlk run'da 10-user'a dönmek yeni bir workload karşılaştırması;
  tek adımda 750 ms uygulamak gelişen semptom hipotezini zayıflatacağı; sonucu
  gördükten sonra ramp/eşik ayarlamak post-hoc olacağı için seçilmedi.
- Fayda: Run kimliği, lifecycle, etki/coverage, cleanup ve invalid-preservation
  koşulları sonuç görülmeden bağımsız doğrulanabilir ve falsifiye edilebilir olur.
- Bedel ve sınırlılık: Tek run tekrar kanıtı değildir; yapılandırılmış 750 ms ölçülmüş
  etkiyi veya manifestation'ı garanti etmez. Proxy rollout'u canlı kapılarda tekrar
  doğrulanır.
- Merge/yürütme sınırı: Bu profil ve runner canonical `main` üzerine merge edilse
  dahi fault başlamaz. Ayrı açık kullanıcı onayı ile fresh Git/host/Docker/Minikube,
  deployment/workload/run-ID/Prometheus/collector/proxy/target-stability kapılarının
  tamamı geçmelidir. Model, LLM ve GAT çalıştırılmaz.
- Uygulama sonucu: `ob-netdelay-15u-001` fresh kapılar, warmup, baseline ve 120,094
  saniyelik rampı geçti; ancak PowerShell 7 JSON DateTime dönüşümü steady başlangıç
  UTC'sini locale stringe çevirdi ve canonical-`Z` guard fail-closed reddetti.
  Steady/cooldown tamamlanmadığından run invalid/incomplete; effect/manifestation
  değerlendirilmedi. Emergency cleanup/rollback, host `0/0/0`, sealed telemetry ve
  invalid offline receipt geçti. ID yeniden kullanılmaz, eşikler değişmez.

## D-044 - Network-delay UTC type-boundary koruması ve değişmeyen replacement

- Durum: **Kabul edildi; tooling düzeltmesi ve replacement ön-kaydı, fault yetkisiz**
- Karar: JSON'dan okunan lifecycle UTC değerleri string varsayılmayacak; PowerShell
  7 `System.DateTime`, `DateTimeOffset` ve canonical `Z` stringleri tek bir helper ile
  invariant canonical `Z` biçimine çevrilecek, locale stringler reddedilecektir.
  Replacement `ob-netdelay-15u-002` olur; workload, target, ramp, lifecycle,
  etki/coverage, first-symptom ve manifestation eşikleri D-043 ile aynıdır.
- Gerekçe: `ob-netdelay-15u-001` ramp kanıtında geçerli `Z` UTC bulunduğu halde
  `ConvertFrom-Json` type conversion sonrası `[string]` locale gösterimi üretti.
  Guard'ın gevşetilmesi yerine type boundary açık ve regression-testli yapılır.
- Alternatifler: PowerShell 5.1'e zorlamak runtime bağımlılığını gizleyeceği;
  canonical-`Z` guard'ı kaldırmak belirsiz UTC kabul edeceği; invalid ID'yi yeniden
  kullanmak provenance zincirini ihlal edeceği için reddedildi.
- Fayda: Bilimsel koşullar değişmeden platformlar arası JSON UTC davranışı fail-closed
  ve bağımsız test edilebilir olur.
- Bedel ve sınırlılık: Helper yalnız temsil/binding kusurunu çözer; yeni run'ın
  fiziksel etki, lifecycle veya manifestation geçerliliğini garanti etmez.
- Merge/yürütme sınırı: Düzeltme ve `ob-netdelay-15u-002` bağı canonical `main`e
  merge edilmeden ve kullanıcı ayrıca onay vermeden fault başlatılmaz.
- Uygulama sonucu: `ob-netdelay-15u-002` D-044 UTC sınırını ve tam lifecycle'ı
  geçti; `+751,402 ms` ölçülmüş etki ile latency manifestation üretti. Ancak zorunlu
  generic final receipt, CPU-specific `severity` varsayımı nedeniyle başarısız oldu.
  Bu operasyonel kapı run'ı invalid yapar; pozitif bulgular candidate evidence olarak
  korunur fakat dataset/modeling örneği değildir. ID tekrar kullanılmaz.

## D-045 - Fault-class-aware receipt ve değişmeyen ikinci replacement

- Durum: **Kabul edildi; tooling düzeltmesi ve replacement ön-kaydı, fault yetkisiz**
- Karar: Genel metadata yönlendiricisi `cpu_stress` ve `network_delay` sınıflarını
  açık verifier sözleşmelerine ayırır. Invalid receipt v2, Git satır-sonu dönüşümünden
  bağımsız canonical-JSON SHA-256 kullanır; read-only özniteliği yalnız best-effort
  çalışma-anı sertleştirmesidir. Replacement `ob-netdelay-15u-003` olur ve D-043
  bilimsel koşullarının hiçbiri değişmez.
- Gerekçe: `002`nin tek başarısız kapısı ağ metadata’sının CPU `severity` alanına
  yönlendirilmesiydi. Byte-level JSON hash ve Windows read-only özniteliği Git
  checkout sonrasında taşınabilir bir bütünlük iddiası sağlayamadı.
- Alternatifler: Network metadata’ya sahte `severity` eklemek şema anlamını bozacağı;
  CPU verifier’ını gevşetmek fail-closed sınırını zayıflatacağı; `002`yi yeniden
  kullanmak immutable provenance’ı ihlal edeceği için reddedildi.
- Fayda: Her fault sınıfı kendi fiziksel-etki sözleşmesiyle doğrulanır ve invalid
  receipt farklı checkout satır sonlarında aynı içerik hash’ini üretir.
- Bedel ve sınırlılık: Canonical JSON hash dosya biçimindeki zararsız whitespace
  farklarını bilerek soyutlar; semantik içeriği korur. Yeni run yine bütün fresh
  runtime, lifecycle, telemetry, host ve receipt kapılarını bağımsız geçmelidir.
- Merge/yürütme sınırı: Tooling ve `003` ön-kaydı canonical `main`e merge edilmeden,
  kullanıcı ayrıca onay vermeden ve fresh kapılar geçmeden fault başlatılmaz.
- Uygulama sonucu: `ob-netdelay-15u-003` base deployment, active run-ID/workload ve
  statik overlay kapılarını geçti; rollout sonrası canlı selector birden fazla pod
  gördüğü için `live_proxy_pod_count_mismatch` ile warmup/fault öncesi durdu. Rollback,
  host `0/0/0` ve invalid-preflight receipt geçti. Run invalid/incomplete ve modeling
  dışıdır; ID kullanılamaz. D-043 eşikleri değiştirilmez.

## Açık kararlar

| ID | Soru | Karar için gerekli kanıt | Hedef aşama |
|---|---|---|---|
| O-001 | Online Boutique yerel ortamda sürdürülebilir biçimde çalışıyor mu? | Yazılım smoke testi ve temiz boot host stability tekrarı geçti; uzun pencere trace export kapısı bekleniyor | P1 öncesi |
| O-002 | Hangi servis CPU-stress pilotu için en uygun? | Çözüldü: `ob-cpu-normal-002` normal-baseline karşılaştırmasıyla `recommendationservice` seçildi; checkoutservice alternatif olarak korundu | Pilot P0 |
| O-003 | Failure manifestation için ana SLO nedir? | Çözüldü: `p1-cpu-001-slo-v1`; `/product/{id}` window-p95 `>345,992 ms` veya global frontend error rate `>0`, ilgili koşul art arda 3 dolu 5 sn pencere. Boş pencere zinciri keser. Üç normal run replay'inde yanlış manifestation 0 | Pilot P1 |
| O-004 | Kaç bağımsız run gerekli? | P1'de 21/35 geçerli run ve fiziksel-etki CV'leri ölçüldü; fakat geçerli fault olay oranı `0/15` olduğundan pozitif sınıf için örnek büyüklüğü mevcut CPU etiketiyle belirlenemez | Dataset v1 öncesi; yeni deney tasarımı kararından sonra |
| O-005 | Kullanılacak LLM ve sürüm hangisi? | Erişim, maliyet, tekrarlanabilirlik | LLM aşaması |
| O-006 | Mevcut host nasıl kararlı hale getirilecek veya hangi alternatif host kullanılacak? | Çözüldü: temiz boot, Ethernet kullanımı ve Wi-Fi’nin devre dışı bırakılması altında `P1-HOST-STABILITY-002` geçti | P1 öncesi |
| O-007 | Uzun deney pencerelerinde Jaeger trace verisi kayıpsız nasıl dışa aktarılacak? | Çözüldü: schema v3 ile 49/49 parça doğrulandı; maksimum parça 924/5000 trace | P1 öncesi |
| O-008 | CPU fiziksel-etki coverage kapısı gerçek 5 sn Prometheus scrape aralığıyla nasıl tanımlanmalı? | Çözüldü: D-018 ile her 300 sn fazda beklenen 60 gerçek aralığın en az 48'i (%80) zorunlu kılındı. `ob-cpu-low-002` invalid kaldı; değişiklik yalnız `cpu-recommendation-low-v2` ve yeni `ob-cpu-low-003` için geçerlidir | Sonraki low calibration öncesi |
| O-009 | Fault lifecycle UTC'si dış `kubectl exec` duvar saatinden mi, worker'ın gerçek başlama/tamamlanma olayından mı üretilmeli? | Çözüldü: D-021 ile worker-emitted canonical UTC fault sınırı; outer exec UTC tanısal kanıt; worker wall ve monotonic süreleri ayrı kapılar olarak seçildi | Yeni düşük CPU tekrarı öncesi |
| O-010 | D-030 hiçbir 15/20-user adayı seçmediğinde ikinci workload nasıl tasarlanmalı? | Çözüldü: D-033 ile 15 user, değişmeyen `200m` limit ve `50/100/150m` fault fiziği, yeni deneyler için prospektif `%5` (`10m`) nominal rezerv (`normal mean <=40m`) ve workload'a özgü profiller açıkça onaylandı | P3 ikinci workload öncesi |
| O-011 | P1 CPU'da geçerli fault manifestation `0/15` iken sonraki bilimsel tasarım ne olmalı? | Çözüldü: D-040 ile CPU stress RCA-only korunur; kademeli network delay için önce hedef/injector/SLO karar-desteği ve tooling kapısı tamamlanır | P2 network-delay tasarımı |
| O-012 | İlk network-delay hedefi, injector'u ve ölçüm sözleşmesi nedir? | Çözüldü: D-041 ile recommendationservice -> productcatalogservice, ayrıcalıksız Toxiproxy sidecar, normal-veriden dondurulmuş ilk-semptom/SLO ve bağımsız fiziksel-etki/cleanup kapıları seçildi | P2 canlı no-toxic overlay doğrulaması |
| O-013 | D-041 proxy overlay'i canlı sistemde fault olmadan kabul edilebilir overhead ve cleanup sağlıyor mu? | Çözüldü: D-042; 15-user no-toxic gate valid, median overhead +0,3415 ms <=5 ms, coverage 60/60, SLO manifestation yok, rollback/host/receipt geçti | Ayrı scientific network-delay ön-kaydı |
| O-014 | İlk network-delay scientific run hangi değişmez koşullarla yürütülmeli? | Çözüldü: D-043; `ob-netdelay-15u-001`, 15-user workload, 12-adımlı 0-750 ms ramp, frozen etki/semptom/SLO ve ayrı yürütme onayı | P2 ilk scientific network-delay run |
| O-015 | Invalid ilk network-delay attempt sonrası replacement nasıl güvenle hazırlanmalı? | Çözüldü: D-044; typed UTC canonicalization fixture'ı ve koşulları değişmeyen `ob-netdelay-15u-002` ayrı committe ön-kaydedildi | P2 replacement ön-kaydı |
| O-016 | Network-delay metadata normal final receipt'e nasıl tür-güvenli bağlanmalı? | Çözüldü: D-045; fault-class-aware dispatch, network verifier, canonical-JSON invalid receipt v2 fixture'ı ve değişmeyen `ob-netdelay-15u-003` ayrı committe ön-kaydedildi | P2 receipt tooling/replacement kapısı |
| O-017 | Proxy rollout sonrası tek canlı hedef pod kapısı termination yarışını gevşemeden nasıl beklemeli? | Deployment rollout ardından selector kümesinin tam bir Ready pod, sabit UID/container/restart üretmesini bounded süreyle bekle; timeout/multiple-pod negatif fixture, preflight host-after finally kaydı ve değişmeyen yeni ID ayrı committe doğrulanmalı | P2 live proxy stability/replacement kapısı |

## Değişiklik kaydı

| Tarih | Karar | Değişiklik | Gerekçe |
|---|---|---|---|
| 2026-07-15 | D-001–D-010 | İlk sürüm oluşturuldu | Literatür değerlendirmesi ve kapsam daraltma kararı |
| 2026-07-27 | D-011 | Host stability ve telemetry merge bağımsız deney başlangıç kapıları olarak eklendi | P1-TELEMETRY-EXPORT-001 geçti; P1-HOST-STABILITY-001 WHEA Event 17 nedeniyle başarısız oldu |
| 2026-07-27 | D-011 | Telemetry merge kapısı kapatıldı; yalnız host stability kapısı açık kaldı | PR #10 iki commit ile merge edildi; `main` ve `origin/main` `f650bdd` revisionında senkron |
| 2026-07-28 | D-011 | Host stability kapısı kapatıldı; uzun pencere trace export kapısı eklendi | `P1-HOST-STABILITY-002` temiz boot altında WHEA ve Kernel-Power olayı olmadan geçti; `ob-host-stability-002` Jaeger 5.000 trace sınırında güvenli biçimde reddedildi |
| 2026-07-28 | D-011 | Uzun pencere trace export için schema v3 araç uygulaması tamamlandı; kapı canlı doğrulama bekliyor | Zaman parçalama, global trace ID tekilleştirme, boşluk ve limit negatif testleri geçti; bilimsel run başlatılmadı |
| 2026-07-28 | D-011 | Uzun pencere trace export canlı doğrulaması geçti; yalnız schema v3 merge kapısı açık kaldı | `ob-trace-chunk-live-001` 49/49 parçayı, 9.441 selected trace'i ve 100.056 spanı hatasız doğruladı |
| 2026-07-28 | D-011 | Schema v3 merge kapısı kapatıldı; P1 deney başlangıç kapılarının tamamı geçti | PR #12 iki commit ile merge edildi; `main` ve `origin/main` `c29e2b2` revisionında senkronlandı |
| 2026-08-02 | D-012 | Normal workload profili, çalışma zamanı seed uygulaması ve bilimsel metadata/receipt mühürleme kararı eklendi | Protokoldeki versioned workload, random seed, UTC lifecycle ve immutable kayıt şartlarını ilk bilimsel run öncesinde uygulanabilir ve bağımsız doğrulanabilir hale getirmek |
| 2026-08-02 | D-013 | Deployment sonrası ConfigMap, pod rollout, Prometheus runtime config ve run-scoped metric kapısı eklendi | `ob-cpu-normal-001` run'ında ConfigMap ile çalışan Prometheus config'i ayrıştı ve zorunlu metric modalitesi oluşmadı |
| 2026-08-02 | D-012 | Final receipt metadata doğrulamasında özgün 1–7 basamaklı UTC lifecycle değerlerinin korunması uygulandı | `ob-cpu-normal-002` ilk finalization denemesinde milisaniyeye kısaltılmış karşılaştırma değerleri metadata başlangıç/bitiş uyuşmazlığı üretti; immutable veri arşivleri değişmeden özgün UTC aktarımıyla doğrulama geçti |
| 2026-08-02 | D-014 | İlk CPU-stress kalibrasyon hedefi `recommendationservice` olarak seçildi | Normal-baseline filtreli CPU, memory, kullanıcı-yolu spanı, çağrı sıklığı, topoloji sadeliği ve log/kod yorumlanabilirliği checkoutservice ile karşılaştırıldı |
| 2026-08-02 | D-012 | Normal-baseline penceresi için tüm 15 deployment'ın pod UID ve restart sayısı başlangıç/bitiş kanıtına eklendi | Ölçüm sırasında sessiz pod değişimi veya restart oluşmadığını yalnız hedef servis için değil tüm deney sistemi için falsifiye edilebilir hale getirmek; süre, workload, fault veya SLO kararını değiştirmez |
| 2026-08-03 | D-015 | P1-CPU-001 manifestation kuralı fault verisi görülmeden `p1-cpu-001-slo-v1` olarak donduruldu | `/` DNS gecikmesi global latency nüfusunu baskılarken `/product/{id}` hedef recommendationservice ile semantik uyum ve 179/180 pencere kapsaması sağladı. Alternatifler global latency, `/`-hariç tüm rotalar ve sabit yüzde error eşiğiydi. Route kapsamı daha dar ve üç-run üst kuyruğu değişken; buna karşılık normal-p99 + üç ardışık pencere kuralı normal replay'de 0 yanlış manifestation verdi. Global error guard diğer kullanıcı hatalarını korur. Fault duyarlılığı henüz bilinmez; sonuç sonrası eşik gevşetilemez |
| 2026-08-03 | D-016 | İlk düşük CPU kalibrasyon profili `cpu-recommendation-low-v1` olarak fault verisi öncesi donduruldu | Kullanıcı onayıyla recommendationservice için yaklaşık 50m ek talep, 120 sn ramp ve 300 sn sabit evre seçildi. Deployment CPU limitini değiştirmek rollout; node-geneli stress tek-hedef ihlali yaratacağından mevcut konteynerde hash-pinned, zaman-sınırlı Python duty-cycle worker seçildi. Fiziksel kabul için iki 300 sn evrede en az 240 CPU intervali ve steady-baseline mean farkı en az 25m olmalı; throttling raporlanır. Talep yaklaşık olduğundan Prometheus kanıtı zorunlu, komut başarısı yetersizdir. Profil sonucu görülünce değiştirilemez |
| 2026-08-04 | D-017 | P1-CPU-001 SLO pencereleri `normal_baseline_start_utc` noktasına sabitlendi ve cooldown sonuna kadar faz sınırlarında yeniden hizalanmadan sürdürüldü | Kullanıcı açıkça onayladı. Alternatif injection başlangıcında yeniden hizalamaydı; bu seçenek fault zamanını feature üretimine sızdırıp manifestation/lead-time değerini birkaç saniye oynatabilirdi. Sabit grid pre/post karşılaştırılabilirliği ve falsifiye edilebilirliği artırır. Bedeli, injection başlangıcının pencere ortasına düşebilmesi ve ilk fault penceresinin karma içerikli olabilmesidir; gerçek injection UTC ayrıca korunur |
| 2026-08-04 | D-018 | CPU fiziksel-etki coverage kapısı `cpu-recommendation-low-v2` ile her 300 saniyelik baseline ve steady fazında en az 48 gerçek CPU-rate intervali olarak düzeltildi | `ob-cpu-low-002`, Prometheus kaynak serisinin tam 5 sn cadence ile faz başına yaklaşık 60 interval ürettiğini gösterdi; v1'deki 240 interval ulaşılamazdı. Kullanıcı %80 coverage olan 48/60 seçeneğini açıkça onayladı. Alternatif, scrape aralığını 1 sn'ye indirip yeni normal baselines toplamaktı; daha yüksek veri hacmi, ek altyapı değişkeni ve karşılaştırılabilirlik maliyeti nedeniyle seçilmedi. Hedef, +50m talep, +25m kabul büyüklüğü, workload, seed, SLO, 120 sn ramp, 300 sn steady ve cooldown değişmedi. Sınırlılık: %80 kapı kısa eksiklikleri tolere eder; gerçek interval sayısı ve cadence her run'da yine raporlanmalıdır. `ob-cpu-low-002` retroaktif kabul edilmez ve invalid kalır; ilk aday `ob-cpu-low-003` olur |
| 2026-08-04 | D-019 | Fault lifecycle UTC üretimi canonical trailing-`Z` biçimine bağlandı ve verifier geçersiz UTC'yi süre aritmetiğine sokmadan fail-closed raporlayacak | `ob-cpu-low-003` fiziksel etki ve telemetry kapılarını geçmesine rağmen injector `+00:00`, verifier ise `Z` üretti/bekledi; failure-list dönüş değeri `op_Subtraction` hatasına yol açtı ve final receipt oluşmadı. Alternatif olarak mevcut run'ı sonradan finalize etmek reddedildi; sonuç görüldükten sonra kapanış kapısını yeniden çalıştırmak immutable close-run zincirini zayıflatır. `ob-cpu-low-003` invalid kalır. Düzeltme yalnız UTC'nin eşdeğer gösterimini canonical hale getirir; fault, workload, SLO, coverage veya akademik kapsamı değiştirmez. Yeni aday `ob-cpu-low-004` olacaktır |
| 2026-08-04 | D-020 | İlk geçerli düşük CPU kalibrasyonunun tekrarlanabilirliği, koşulları değiştirilmemiş iki bağımsız tekrar (`ob-cpu-low-005`, `ob-cpu-low-006`) ile sınanacak | `ob-cpu-low-004` fiziksel CPU etkisini ve geçerli null manifestation sonucunu yalnız bir run'da gösterdi. Kullanıcı iki tekrarı açıkça onayladı. Alternatif olarak doğrudan severity artırmak reddedildi; tek-run sistem varyansı ile severity etkisini karıştırabilirdi. Her tekrar ayrı run ID, canonical revision, artifact, host ve receipt kapılarıyla yürütülür. Fayda, düşük profil etki/manifestation varyansını ölçmektir. Bedel, iki ek uzun lifecycle ve düşük şiddette yeniden null manifestation üretme olasılığıdır; bu sonuçlar yine geçerli bilimsel kanıttır |
| 2026-08-06 | D-021 | Fault lifecycle sınırları worker-emitted canonical UTC'ye bağlandı; dış exec UTC ayrıca korunur | `ob-cpu-low-006` gerçek worker süresi geçerken transport-inclusive faz süresi receipt kapısını reddetti. Tolerans gevşetilmedi; wall ve monotonic süreler yeni v3 profilde bağımsız doğrulanır |
| 2026-08-06 | D-022 | Worker source hash'i yeni v4 profilde UTF-8/LF canonicalization sonrası hesaplanır | `ob-cpu-low-007` LF/CRLF working-tree farkı nedeniyle fault öncesi reddedildi. Hash kaldırılmadı, v3 değiştirilmedi; platform bağımsız temsil yeni run ID için sürümlendi |
| 2026-08-06 | D-023 | Worker event Generic.List koleksiyonu resolver'a açık `.ToArray()` ile aktarılır | `ob-cpu-low-008` worker'ı 420 saniye tamamladı fakat PowerShell 5.1 `@($events)` binding kusuru lifecycle kanıtını reddetti; canlı koleksiyon şekli regression testine eklendi |
| 2026-08-06 | D-024 | İlk medium profil 100m ek talep ve en az 50m fiziksel etki kapısıyla donduruldu | Üç geçerli low run fiziksel etkiyi düşük varyansla tekrarladı fakat manifestation üretmedi; yalnız severity iki katına çıkarılarak diğer koşullar sabit tutuldu |
| 2026-08-06 | D-025 | Medium profil için koşulları değişmeyen iki bağımsız tekrar `ob-cpu-medium-002/003` olarak ön-kaydedildi | İlk geçerli medium run fiziksel etkiyi gösterdi fakat tek gözlem tekrarlanabilirlik veya high severity geçişi için yeterli değildir |
| 2026-08-06 | D-026 | CPU effect analyzer lifecycle'ı kapsayan tek cAdvisor counter serisini seçer ve belirsizlikte fail-closed durur | `ob-cpu-medium-002` eski kısa container serisinin aktif seriyi ezmesiyle 0/0 interval üretti; run invalid korundu ve eşikler değişmedi |
| 2026-08-06 | D-027 | Invalid `ob-cpu-medium-002` yerine değişmeyen medium-v1 koşullarıyla `ob-cpu-medium-004` ön-kaydedildi | `001/003` geçerli, `002` invalid olduğu için D-025 üç-geçerli-run seti yeni bağımsız run olmadan tamamlanamaz |
| 2026-08-07 | D-028 | İlk high profil 150m ek talep ve en az 75m fiziksel etki kapısıyla `ob-cpu-high-001` için donduruldu | Üç geçerli medium run düşük varyanslı yaklaşık 100m artış üretti fakat manifestation oluşturmadı; yalnız severity artırıldı ve 200m limit altında headroom korundu |
| 2026-08-07 | D-029 | High profil için koşulları değişmeyen iki bağımsız tekrar `ob-cpu-high-002/003` olarak ön-kaydedildi | İlk geçerli high run güçlü fiziksel etki fakat yalnız tek izole latency ihlali gösterdi; tek run tekrarlanabilirlik için yeterli değildir |
| 2026-08-10 | D-030 | 10/15/20-user fault'suz kapasite karşılaştırması, fail-closed seçim kapıları ve ikinci-workload run planı sonuç öncesi donduruldu | P3 en az iki workload ister; workload severity ile karışmadan ve host/CPU headroom kanıtı olmadan seçilemez |
| 2026-08-10 | D-031 | Kapasite runner'ına tam pod snapshot ve measurement-kapsayan tek CPU-serisi kapısı eklendi | İlk 20-user attempt'inde boolean pod sonucu açıklanamadı ve birden fazla cAdvisor serisi CPU özetini kontamine etti; invalid run retroaktif kabul edilmedi |
| 2026-08-10 | D-032 | 10-user `normal_baseline_seconds` ve aday `measurement_seconds` alanları 300 saniyelik tek kapasite sözleşmesine normalize edildi | İlk 10-user attempt'i measurement başlamadan yalnız alan adı uyumsuzluğuyla durdu; tarihsel profil değiştirilmedi |
| 2026-08-11 | D-033 | 15-user ikinci workload, `%5` nominal CPU rezervi, workload'a özgü eş-fizikli fault profilleri ve üç normal + altı randomize fault run ön-kaydedildi | D-030 eski kapılarla seçim üretmedi; kaynak-bütçesi analizi limit/fault fiziğini değiştirmeden 15-user seçiminin karşılaştırılabilirliği en iyi koruduğunu gösterdi ve kullanıcı açıkça onayladı |
| 2026-08-11 | D-034 | Fault orchestrator ve verifier'lar sürümlü workload profilini runtime/metadata boyunca parametreli ve fail-closed doğrulayacak şekilde genişletildi | 10-user hard-code'u 15-user provenance'ını engelliyordu; static YAML tek başına canlı loadgenerator bağını kanıtlamıyordu |
| 2026-08-11 | D-035 | Fault içermeyen 15-user scientific normal-baseline lifecycle'ı ayrı orchestrator, metadata ve receipt kapılarıyla kodlandı | Kapasite runner'ı dataset-dışıydı; bilimsel normal kontrolü yeniden etiketlemek yerine ayrı provenance ve fail-closed kapanış gerektiriyordu |
| 2026-08-15 | D-040 | CPU stress RCA-only olarak korundu; kademeli network delay için ayrı karar-desteği/tooling kapısı açıldı | P1 fiziksel actuation'ı tekrarladı fakat geçerli fault manifestation `0/15` ve pozitif lead-time `0` kaldı; kullanıcı O-011 yönünü açıkça onayladı |
| 2026-08-15 | D-041 | Network-delay hedef edge, Toxiproxy izolasyonu, fiziksel-etki, ilk-semptom ve manifestation sözleşmeleri fault verisi görülmeden donduruldu | Altı geçerli normal run'ın edge ve route replay'i ile privilege/cleanup/gerçek-imaj tooling kanıtı tasarım kapılarını geçti; scientific run yetkilendirilmedi |
| 2026-08-15 | D-042 | Canlı no-toxic Toxiproxy overlay compatibility kapısı geçerli tamamlandı | 15-user paired base/proxy ölçümünde +0,3415 ms median overhead, 60/60 coverage, null manifestation, stabil podlar, 0/0/0 host farkı, temiz rollback ve 90/90 offline receipt doğrulandı |
| 2026-08-15 | D-043 | İlk scientific network-delay run koşulları ve fail-closed tooling'i ön-kaydedildi | D-041/D-042 kanıtı üzerinde benzersiz run ID, deterministik ramp, frozen etki/SLO ve ayrı runtime onayı bağlandı; fault başlatılmadı |

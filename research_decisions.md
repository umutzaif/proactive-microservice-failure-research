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

## D-046 - Bounded tek-proxy-pod convergence ve değişmeyen replacement

- Durum: **Kabul edildi; tooling düzeltmesi ve replacement ön-kaydı, fault yetkisiz**
- Karar: Proxy rollout sonrasında selector kümesi en çok `120 sn`, `5 sn` cadence ile
  tam bir pod'a yakınsamalı; pod Ready, `server` ve `network-delay-proxy` container'ları
  Ready olmalıdır. Timeout fail-closed'dur. Exception yolunda cluster stop sonrası
  host-after snapshot ve delta zorunlu yazılır. Replacement `ob-netdelay-15u-004`
  olur; D-043 bilimsel koşulları değişmez.
- Gerekçe: Kubernetes rollout tamamlanması eski pod nesnesinin API listesinden aynı
  anda silindiğini garanti etmez. `003` bu termination penceresinde doğru biçimde
  durdu; ölçüm başlamadan bounded convergence beklemek transient rollout durumunu
  bilimsel pod-lifecycle ile karıştırmaz.
- Alternatifler: Pod-count kapısını kaldırmak lifecycle belirsizliği yaratacağı;
  eski pod'u zorla silmek ortamı operatör müdahalesiyle değiştireceği; aynı ID'yi
  tekrar kullanmak provenance'ı ihlal edeceği için reddedildi.
- Fayda: Fault öncesi canlı proxy sözleşmesi tek Ready pod üzerinde deterministik ve
  fixture ile falsifiye edilebilir olur; preflight failure da host delta ile kapanır.
- Bedel ve sınırlılık: Her rollout en çok iki dakika ek bekleme getirebilir; timeout
  yeni run'ı invalid yapar. Bu düzeltme fiziksel etki veya manifestation garantilemez.
- Merge/yürütme sınırı: `004` canonical merge, ayrı açık onay ve fresh kapılar olmadan
  çalıştırılmaz.
- Uygulama sonucu: `ob-netdelay-15u-004` 22 bounded gözlemde pod sayısını `2 -> 1`
  yakınsattı fakat birleşik Ready `0/22` kaldı ve warmup/fault öncesi
  `live_proxy_single_ready_pod_timeout` ile durdu. Rollback, host `0/0/0` ve invalid
  receipt geçti. Run invalid/incomplete, modeling dışı ve ID kullanılamaz; timeout
  sonuçtan sonra değiştirilmez.

## D-047 - Readiness kanıt çözünürlüğü ve değişmeyen replacement

- Durum: **Kabul edildi; tanı kapanışı, observability düzeltmesi ve replacement ön-kaydı; fault yetkisiz**
- Karar: `120 sn / 5 sn` tek-Ready-pod kapısı ve bütün D-043 bilimsel eşikleri
  değiştirilmez. Convergence kanıtı her gözlemde pod UID/deletion timestamp/phase/
  conditions ile container ready/started/restart/state/last-state alanlarını saklar.
  Yeni benzersiz replacement `ob-netdelay-15u-005` olur.
- Gerekçe: Tamamlanan faultsuz `readiness-003`, proxy'yi `33/33` Ready ve `0` restart,
  server'ı `30/33` Ready ve `1` restart gösterdi; tek all-Ready pod `16,616` saniyede
  oluştu. `004`teki birleşik boolean kesin bileşeni ayırmadığından yeniden failure
  halinde falsifiye edilebilir ayrıntı gerekir.
- Alternatifler: Timeout/probe eşiklerini sonuçtan sonra değiştirmek kriter kaymasına;
  `004`ü yeniden kullanmak provenance ihlaline; ayrıntısız tekrar aynı bilgi kaybına
  yol açacağı için reddedildi.
- Fayda: Geçerse aynı dondurulmuş kapı korunur; kalırsa failure pod, condition veya
  container düzeyinde açıklanabilir ve bağımsız yeniden değerlendirilebilir.
- Bedel ve sınırlılık: Convergence JSON'u büyür. Tanı `004`ün kesin retrospective kök
  nedenini kanıtlamaz ve replacement'ın geçerli olacağını garanti etmez.
- Merge/yürütme sınırı: `005` canonical merge, ayrıca açık onay ve fresh runtime
  kapıları olmadan çalıştırılmaz; bu karar fault/model/LLM/GAT yetkisi vermez.
- Uygulama sonucu: `005` 22 gözlemde Ready `0/22` ile aynı bounded kapıda durdu.
  Ayrıntılı kanıt proxy'yi `22/22` Ready/0 restart, yeni server'ı `1/22` Ready ve
  restart `0 -> 4`, final CrashLoopBackOff, son termination exit `137`/Error olarak
  ayırdı. Warmup/fault başlamadı; rollback, host `0/0/0` ve invalid receipt geçti.
  Exit 137 kesin OOM/kök neden kanıtı değildir; run invalid ve ID kullanılamaz.

## D-048 - Host olaylarını System RecordId sınırıyla ölçme ve değişmeyen O-019 tekrarı

- Durum: **Kabul edildi teknik fail-closed düzeltmesi ve faultsuz tanı ön-kaydı**
- Karar: Host-health farkı, dairesel Windows System günlüğündeki provider toplam
  sayılarının çıkarılmasıyla değil, run başlangıcındaki en yüksek `RecordId` sınırından
  sonra oluşan WHEA 17, Kernel-Power 41 ve bugcheck 1001 olay kimlikleriyle ölçülür.
  Kapanış RecordId başlangıçtan küçükse log clear/reset şüphesiyle kapı başarısız olur.
  Değişmeyen 180/5 saniyelik no-toxic ölçüm `ob-network-probe-resource-002` olarak
  prospektif ön-kaydedilir.
- Gerekçe: System log `Circular` ve boyut sınırındadır; eski kayıtların retention ile
  düşmesi `001`de WHEA toplamını `881 -> 879` yaparak yeni olay farkını matematiksel
  olarak anlamsızlaştırdı. RecordId sınırı yeni olay kimliğini doğrudan kanıtlar.
- Alternatifler: Toplam sayımı sürdürmek retention'a duyarlı olduğu için; yalnız UTC
  zaman filtresi saat düzeltmelerine duyarlı olduğu için reddedildi. Logu büyütmek veya
  temizlemek host durumunu değiştirip tarihsel kanıtı etkileyebileceği için seçilmedi.
- Fayda: Yeni host olayları retention'dan bağımsız, tek tek doğrulanabilir ve log
  sıfırlaması fail-closed görünür olur.
- Bedel ve sınırlılık: RecordId yalnız aynı System log nesnesi içinde anlamlıdır;
  sıfırlama halinde run geçerli sayılamaz. Bu karar probe/resource koşullarını,
  scientific threshold'ları veya network-delay replacement yetkisini değiştirmez.

## D-049 - O-019 tanı kapanışı ve replacement tasarımının ayrılması

- Durum: **Kabul edildi; geçerli no-fault diagnostic sonucu**
- Karar: `ob-network-probe-resource-002`, bütün ön-kayıtlı host, lifecycle, coverage,
  rollback ve offline verification kapıları geçtiği için tamamlanmış geçerli diagnostic
  olarak korunur. Beş liveness kill ile `363/363` CFS throttled-period ve `+21,271 sn`
  CPU pressure'ın eşzamanlılığı, CPU quota throttling/pressure'ı güçlü yakın mekanizma
  olarak destekler; OOM/memory/node pressure desteklenmez. Resource/probe replacement
  ayarı bu sonuçtan otomatik türetilmez ve ayrı tasarım kararı gerektirir.
- Gerekçe: `001`de eksik olan restart olayı ve geçerli host kanıtı aynı pencerede
  sağlandı. Bununla birlikte diagnostic gözlemseldir ve tek nihai kök neden ya da
  belirli bir resource artışının bilimsel üstünlüğünü kanıtlamaz.
- Alternatifler: Exit 137'yi OOM saymak kernel/container kanıtıyla desteklenmediği;
  doğrudan CPU limitini artırmak yeni koşulu sonuç commit'inde sessizce belirleyeceği;
  liveness threshold'u gevşetmek semptomu ölçüm mekanizmasıyla karıştıracağı için
  reddedildi.
- Fayda: O-019 kanıta dayalı kapanır, scientific network-delay replacement ile
  altyapı resource/probe tasarımı birbirine karıştırılmaz.
- Bedel ve sınırlılık: Ek bir tasarım/compatibility aşaması gerekir; CPU throttling'in
  uygulama içi nihai kaynağı ve alternatif runtime/scheduling etkileri açık kalabilir.

## D-050 - Network-delay server resource-first compatibility tasarımı

- Durum: **Kabul edildi; ayrı no-fault tasarım/ön-kayıt, henüz yürütülmedi**
- Karar: D-049 sonrası ilk compatibility adayı yalnız recommendationservice server
  CPU limitini `200m -> 500m` yapar. CPU request `100m`, memory `220/450Mi`, image,
  workload, proxy, probe ve security sözleşmeleri değişmez. Benzersiz
  `ob-network-resource-compat-001`, 120/5 saniye stability ardından 180/5 saniye
  no-toxic ölçümle yürütülür. Geçiş için iki container `%100` Ready/restart `0`, 13/13
  cAdvisor türü/en az 175 saniye coverage, throttled-period fraction `<0,50`, CPU
  pressure waiting `<10,635359 sn`, memory/node/host/rollback/seal kapıları gerekir.
- Gerekçe: `002`de 200m kota altında maksimum sample rate `499,307m`, throttled
  period `363/363` ve pressure `21,270718 sn` ile beş liveness kill eşzamanlıydı.
  `500m` gözlenen burst'ü kapsayan en dar yuvarlak adaydır; iki resource metriğinde
  prospektif yarı-azalma koşulu hipotezi falsifiye edilebilir kılar.
- Alternatifler: Probe timeout/threshold değişikliği responsiveness yerine kubelet
  toleransını; request+limit birlikte değişikliği scheduling ve quota'yı karıştırdığı
  için reddedildi. `300m` gözlenen burst'ü kapsamaz; `1000m` gereksiz geniş ilk adımdır.
- Fayda: Resource-quota hipotezi tek değişkenle sınanır; probe semantiği ve scientific
  network-delay eşikleri korunur.
- Bedel ve sınırlılık: 500m daha yüksek host burst'üne izin verir, başarı garantisi
  değildir ve `002` gözlemsel referansına dayanır. Geçse bile scientific replacement
  veya fault yetkisi vermez; canonical merge sonrası ayrı runtime onayı gerekir.
- İlk uygulama sonucu: `ob-network-resource-compat-001`, overlay sonrası canlı JSON
  ayrıştırmasında JSON dışı birleşik kubectl satırı nedeniyle stability/measurement
  öncesi invalid/incomplete kapandı. Rollback doğrulaması aynı parser kusuruyla eksik;
  Minikube stopped, host `0/0/0`, 4/4 seal geçti. ID kullanılmaz; 500m ve eşikler
  değişmez, parser fix/replacement ayrı commit gerektirir.

## D-051 - Kubectl JSON kanal ayrımı ve değişmeyen resource compatibility replacement

- Durum: **Kabul edildi teknik fail-closed düzeltmesi; `001` invalid kalır**
- Karar: JSON get çağrıları `minikube kubectl` stdout/stderr birleşiminden çıkarılıp
  deploy tarafından yapılandırılmış doğrudan `kubectl` stdout kanalından okunur;
  stderr JSON parser'a verilmez. D-050 koşulları değişmeden yeni benzersiz
  `ob-network-resource-compat-002` ön-kaydedilir.
- Gerekçe: `001`de JSON dışı wrapper satırı hem canlı deployment hem rollback JSON
  parse'ını bozdu. Payload ve diagnostic kanalını ayırmak veri formatı sınırını düzeltir.
- Alternatifler: JSON öncesindeki ilk `{` karakterini aramak gerçek bozuk çıktıyı
  gizleyebileceği; stderr'i sessizce yutmak tanıyı kaybettireceği; `001`i tekrar
  kullanmak immutable kimliği ihlal edeceği için reddedildi.
- Fayda: JSON parser yalnız makine-okunur stdout alır; native nonzero exit yine
  fail-closed kalır ve stderr terminal kanıtında görünür.
- Bedel ve sınırlılık: Doğrudan kubectl context'inin deploy tarafından doğru kurulmuş
  olmasına bağlıdır. Replacement canonical merge ve ayrı runtime onayı olmadan
  çalıştırılmaz; D-050 eşikleri/probe/resource/fault yetkisi değişmez.
- Uygulama sonucu: `ob-network-resource-compat-002` base, active run-ID ve workload
  kapılarını geçti; overlay rollout sonrası doğrudan kubectl çıktısındaki JSON dışı
  `k...` satır yine parse'ı durdurdu. Stability/resource ölçümü başlamadı, rollback
  JSON'u oluşmadı; Minikube stopped, host `0/0/0` ve 4/4 seal geçti. Run invalid ve
  ID kullanılamaz. Bu sonuç D-050 koşul/eşiklerini değiştirmez; yeni replacement bu
  sonuç kaydında belirlenmez.

## D-052 - Native JSON süreç kanalı izolasyonu ve değişmeyen ikinci replacement

- Durum: **Kabul edilen teknik fail-closed düzeltmesi; `001` ve `002` invalid kalır**
- Karar: Native JSON komutları stdout ve stderr'i OS dosya yönlendirmesiyle ayıran
  ortak helper üzerinden çalışır. Yalnız stdout JSON parser'a girer; stderr ayrı
  diagnostic logda korunur, boş stdout ve nonzero exit fail-closed olur. D-050
  koşulları değişmeden benzersiz `ob-network-resource-compat-003` ön-kaydedilir.
- Gerekçe: D-051 kaynak-metin testi `2>&1` birleşimini engelledi fakat canlı native
  süreç kanal izolasyonunu sınamadı; `002`de doğrudan kubectl çağrısı yine JSON dışı
  `k...` ile parse'ı durdurdu. Gerçek child-process fixture bu sınırı doğrular.
- Alternatifler: İlk `{` sonrasını parse etmek bozuk çıktıyı gizlediği; stderr'i
  atmak tanı kanıtını kaybettiği; eşikleri/probe'u değiştirmek parser kusuruyla ilgisiz
  bilimsel değişken eklediği için reddedildi.
- Fayda: Makine-okunur payload ile diagnostic kanal fiziksel olarak ayrılır ve hata
  ayrıntısı korunur; nonzero exit sessiz başarıya dönüşmez.
- Bedel ve sınırlılık: Geçici dosya I/O'su ekler ve canlı kubectl/context doğruluğunu
  garanti etmez. `003`, canonical merge ve ayrı runtime onayı olmadan çalıştırılmaz;
  geçiş scientific fault yetkisi değildir.
- Uygulama sonucu: `003` base/run-ID/workload kapılarını geçti; ilk canlı JSON
  çağrısında `KJson` içindeki `[string[]]$Args` otomatik değişken çakışması nedeniyle
  helper boş argümanı reddetti. Stability/ölçüm başlamadı, rollback JSON'u oluşmadı;
  Minikube stopped, host `0/0/0`, seal/replay `4/4` geçti. Run invalid ve ID
  kullanılamaz; D-050 koşul/eşikleri değişmez, replacement bu sonuçta belirlenmez.

## D-053 - PowerShell otomatik Args çakışmasını kaldıran değişmeyen replacement

- Durum: **Kabul edilen teknik binding düzeltmesi; `001/002/003` invalid kalır**
- Karar: `KJson` dizi parametresi `$Args` yerine `$KubectlArguments` adını kullanır;
  runner testi otomatik değişken adını açıkça yasaklar ve doğru helper aktarımını
  zorunlu kılar. D-050 koşulları değişmeden `ob-network-resource-compat-004`
  benzersiz ID ile ön-kaydedilir.
- Gerekçe: `003`te positional argümanlar otomatik `$Args` çakışması nedeniyle boş
  bağlandı; native helper boş çağrıyı doğru biçimde reddetti. Kusur bilimsel tasarımda
  değil çağıran PowerShell binding katmanındadır.
- Alternatifler: Helper'ın boş argümanı kabul etmesi fail-closed sözleşmesini bozacağı;
  çağrıları string birleştirmeye çevirmek quoting/injection riski ekleyeceği; aynı ID'yi
  yeniden kullanmak immutability'yi ihlal edeceği için reddedildi.
- Fayda: Kubectl argüman dizisi açık ve test edilebilir biçimde helper'a aktarılır;
  stdout/stderr izolasyonu korunur.
- Bedel ve sınırlılık: Statik binding testi canlı cluster davranışının yerine geçmez.
  `004` canonical merge ve ayrı runtime onayı olmadan çalıştırılamaz; geçiş scientific
  fault veya sonraki akademik aşama yetkisi değildir.
- Uygulama sonucu: `004` lifecycle, 13/13 metric/180 sn, throttling `18/1127`, CPU
  pressure `+0,534809 sn`, memory/node/host/rollback ve 19/19 seal kapılarını geçti.
  Buna karşın verifier sonucu hard-coded `002` run-ID taşıdı ve provenance eşleşmesini
  gate etmedi. Fiziksel compatibility kanıtı korunur fakat run fail-closed invalid;
  ID kullanılamaz ve D-050 eşikleri sonuçtan sonra değişmez.

## D-054 - Resource compatibility run-manifest provenance kapısı

- Durum: **Kabul edilen fail-closed provenance düzeltmesi; `004` invalid kalır**
- Karar: Runner immutable `run-manifest.json` üretir. Verifier zorunlu
  `ExpectedRunId`, artifact klasör adı ve manifest `run_id` üçlüsünü eşleştirir;
  telemetry ID, workload, 500m/100m ve no-fault sözleşmesini de doğrular. D-050
  koşulları değişmeden `ob-network-resource-compat-005` ön-kaydedilir.
- Gerekçe: `004` bütün fiziksel/lifecycle kapılarını geçmesine rağmen verifier
  hard-coded `002` raporladı ve provenance eşleşmesini gate etmedi. Validity için
  ölçüm doğruluğu ile kimlik doğruluğu bağımsız zorunludur.
- Alternatifler: Klasör adını tek başına güvenilir saymak manifest içeriğini; verifier
  çıktısını sonradan elle düzeltmek immutable receipt'i; `004`ü geriye dönük valid
  yapmak ön-kayıt ve fail-closed ilkesini ihlal edeceği için reddedildi.
- Fayda: Yanlış ID ile doğru görünen receipt üretilemez; positive ve iki negative
  fixture provenance sırasını davranışsal olarak sınar.
- Bedel ve sınırlılık: Yeni manifest artifact'i ve zorunlu verifier parametresi ekler.
  `005` canonical merge ve ayrı runtime onayı olmadan çalıştırılmaz; geçiş scientific
  fault veya sonraki akademik aşama yetkisi değildir.
- Uygulama sonucu: `005` expected/klasör/manifest provenance, lifecycle, 13/13
  metric/180 sn, throttling `16/1154`, CPU pressure `+0,498235 sn`, memory/node/host,
  rollback ve 19/19 seal/replay kapılarını geçti. Valid no-toxic compatibility sonucu
  D-050/O-020'yi kapatır; fault/modeling verisi veya otomatik sonraki-aşama yetkisi
  değildir.

## D-055 - 500m kaynak kapısı sonrası scientific network-delay replacement

- Durum: **Kabul edilen tasarım/ön-kayıt; canlı fault henüz yürütülmedi**
- Karar: Benzersiz `ob-netdelay-15u-006`, valid D-050/D-054 compatibility kanıtıyla
  `network-delay-resource-compatibility` overlay'ini kullanır. Server `500m/100m`;
  workload 15/1/1, target, ramp, lifecycle, effect, SLO ve receipt eşikleri değişmez.
  RecordId host, native JSON, run-manifest ve canlı resource kapıları fault öncesidir.
- Gerekçe: `005` no-toxic compatibility kapılarını geçti; eski scientific runner 200m
  overlay ve toplam host sayımı kullandığı için kanıtı güvenle taşımıyordu.
- Alternatifler: Eski 200m koşulu bilinen karıştırıcıyı, probe değişikliği yeni değişkeni,
  eski ID kullanımı immutability ihlalini doğuracağı için reddedildi.
- Fayda: Scientific fault ile resource/probe kararsızlığı ayrıştırılır; frozen hipotez
  karşılaştırılabilir kalır.
- Bedel ve sınırlılık: 500m yeni deployment revision'dır. Canonical merge ve ayrı canlı
  onay gerekir; bu commit fault, model, LLM veya GAT çalıştırmaz.
- Uygulama sonucu: `006`, compositional overlay verifier'ın base patch yolunu
  çözememesiyle fault/warmup öncesi invalid kapandı; rollback, host 0/0/0 ve 6/6 seal
  geçti. ID kullanılmaz; D-055 koşulları ve eşikleri değişmez.

## D-056 - Compositional overlay doğrulama kaynağının ayrılması

- Durum: **Kabul edilen tooling düzeltmesi/ön-kayıt; canlı fault henüz yürütülmedi**
- Karar: Benzersiz `ob-netdelay-15u-007` için statik proxy doğrulayıcı kaynak patch'in
  bulunduğu `network-delay-design` kökünü okur; deploy ve canlı resource kapısı ise
  değişmeden `network-delay-resource-compatibility` overlay'ini ve `500m/100m` sınırını
  kullanır. D-055 workload, target, ramp, lifecycle, effect, SLO ve receipt eşikleri
  değişmez.
- Gerekçe: Kustomize üst overlay'i base kaynaklarını birleştirir; dosya-tabanlı statik
  doğrulayıcı bu birleşimi kendiliğinden çözmediği için `006` fault öncesi kapandı.
- Alternatifler: Patch'i üst overlay'de kopyalamak iki kaynak doğruluk noktası yaratır;
  verifier'ı kaldırmak güvenlik kapısını zayıflatır; `006`yı tekrar kullanmak immutable
  kimlik kuralını ihlal eder. Bu seçenekler reddedildi.
- Fayda: Kaynak güvenlik sözleşmesi ile deploy edilen kaynak bütçesi ayrı ve bağımsız
  doğrulanırken bilimsel koşullar karşılaştırılabilir kalır.
- Bedel ve sınırlılık: Runner iki açık overlay yolu taşır. `007` canonical merge ve ayrı
  canlı onay olmadan yürütülmez; bu karar model, LLM veya GAT yetkisi değildir.
- Uygulama sonucu: `007`, runner'ın non-interactive `ShouldProcess` girişinde bilimsel
  preflight, cluster ve lifecycle başlamadan null-reference ile invalid kapandı.
  Minikube stopped, host `0/0/0` ve 5/5 diagnostic seal/replay geçti. ID kullanılamaz;
  bilimsel koşullar/eşikler değerlendirilmedi ve değişmez. Replacement ayrı commit ister.

## D-057 - Non-interactive runner onay giriş noktası

- Durum: **Kabul edilen tooling düzeltmesi/ön-kayıt; canlı fault henüz yürütülmedi**
- Karar: Benzersiz `ob-netdelay-15u-008`, zorunlu `ExecutionApproved` kapısını korur;
  `ShouldProcess` için `ConfirmImpact=Low` kullanarak non-interactive otomatik prompt'u
  kaldırır ve `-WhatIf` no-mutation davranışını fixture ile doğrular. D-055/D-056'nın
  bütün bilimsel koşulları ve eşikleri değişmez.
- Gerekçe: `007`, bilimsel preflight başlamadan high-impact confirmation host'u
  bulunmadığı için null-reference üretti. Açık execution switch'i zaten kasıt kapısıdır.
- Alternatifler: `ShouldProcess`i kaldırmak dry-run kabiliyetini; her çağırana
  `-Confirm:$false` yüklemek merkezi güvenceyi kaybettirir. Aynı ID'yi kullanmak
  immutability kuralını ihlal eder. Bu seçenekler reddedildi.
- Fayda: Interactive ve non-interactive çağrı yolları aynı, test edilebilir giriş
  sözleşmesini kullanır; tooling değişikliği bilimsel değişkenlerden ayrılır.
- Bedel ve sınırlılık: `ConfirmImpact` tek başına yetkilendirme değildir; mandatory
  `ExecutionApproved`, canonical merge, ayrı canlı onay ve bütün fresh kapılar sürer.
- Uygulama sonucu: `008`, tam lifecycle, D-038 25/restart 0, coverage 60/60, median
  `3,238 -> 755,233 ms`, fiziksel etki `+751,995 ms`, latency manifestation,
  host `0/0/0` ve raw/enriched/schema-v3/final replay kapılarıyla geçerli tamamlandı.
  İlk geçerli network-delay dataset adayıdır; tek run tekrarlanabilirlik/model başarısı
  veya otomatik sonraki aşama yetkisi değildir. pwsh 7 raw UTC-ms cast farkı arşivi
  değiştirmeyen ayrı bir portability sınırlılığı olarak korunur.

## D-058 - Network-delay portability ve randomize eşlenmiş tekrarlanabilirlik pilotu

- Durum: **İleriye dönük durduruldu; D-061–D-066 mentor kapılarıyla superseded**
- Karar: Önce raw-log UTC verifier'ı Windows PowerShell 5.1 ve pwsh 7 altında ham
  canonical JSON string + invariant `DateTimeOffset` ile eşdeğer çalışmalıdır. Sonra
  `ob-netdelay-15u-008` randomize edilmemiş pilot olarak korunarak dört yeni eşlenmiş
  blok yürütülür. Seed `20260821` ile dondurulan sıra iki `fault-control`, ardından iki
  `control-fault` bloktur; canonical run kimlikleri
  `P2-NETWORK-DELAY-REPEATABILITY-001/randomization-plan.json` içindedir.
- Gerekçe: Tek geçerli fault run'ı fiziksel uygulanabilirliği gösterir fakat run-arası
  varyansı veya sıra/gün/host etkisini ayıramaz. Aynı run içindeki 60 pencere bağımsız
  deney birimi değildir. Eşlenmiş no-toxic kontroller sistem driftini görünür kılar;
  dengeli sıra cold-start ve carryover etkilerini tek yönde yüklemeyi azaltır.
- Alternatifler: Yalnız iki ek fault ile üç-run betimsel özet, kontrolsüz olduğu için
  confirmatory örnek büyüklüğü hesabına temel seçilmedi. Baştan 24/30/60 run dondurmak,
  network-delay run-arası varyansı bilinmediği için gereksiz veya yetersiz örnek riski
  taşır. `008`i geriye dönük randomize sete katmak reddedildi.
- Fayda: Dört çift ilk run-arası varyans, false-manifestation ve sıra etkisi tahminini
  sağlar; sonraki güven aralığı/equivalence/power hedefi gerçek pilot kanıtıyla seçilir.
- Bedel ve sınırlılık: Sekiz yeni uzun lifecycle maliyetlidir; dört çift nihai model
  yeterliliği veya dar oran güven aralığı sağlamaz. Invalid run korunur ve otomatik
  ikame edilmez. Her canlı slot canonical merge, ayrı runtime onayı ve fresh kapılara
  bağlıdır. Dataset v1/model/LLM/GAT geçişi ayrıca akademik karar ister.
- İlk geçerli slotun kapanış raporu araştırmanın mevcut aşamasını şemayla gösterecek;
  yapılan işlem, ölçüm/test ve bunların temel savunma tezindeki değeri açıkça bağlanacaktır.
- D-061–D-066 sonrası dört eşlenmiş `750 ms` bloğun kalan slotları yürütülmez. Tamamlanmış
  `008` ve `repeat-001` geçerli tarihsel pilot kanıtı olarak korunur; yeni ladder veya
  confirmatory örnek sayısına taşınmaz.

## D-059 - İlk randomize network-delay fault slotunun ön-kaydı

- Durum: **Kabul edilen D-058 uygulaması; tooling/ön-kayıt, canlı fault yetkisiz**
- Karar: D-058 immutable çizelgesinin ilk `fault-control` bloğu
  `ob-netdelay-15u-repeat-001` ile başlar. Aktif deployment/observability run-ID,
  fault profili, toxic manager ve scientific runner bu benzersiz kimliğe bağlanır.
  D-041/D-055/D-058 workload, hedef, 500m/100m kaynak, `0->750 ms` ramp,
  `300/300/120/300/300`, `>=500 ms` etki, SLO ve kapanış kapıları değişmez.
- Gerekçe: #81 portability/randomizasyon kararını canonical hale getirdi. İlk slotun
  provenance'ı çalıştırmadan önce tek revisionda dondurulmadan canlı ölçüm yapmak,
  run-ID ile gerçek deployment/telemetry bağını zayıflatır.
- Alternatifler: `008`i tekrar kullanmak immutability'yi; sırayı kontrol ile değiştirmek
  ön-kayıtlı randomizasyonu ihlal eder. Fault sonucunu gördükten sonra profil/eşik
  seçmek post-hoc bias oluşturur; bu seçenekler reddedildi.
- Fayda: İlk bağımsız randomize fault tekrarı pilot `008` ile aynı frozen koşullarda
  karşılaştırılabilir; sonraki `control-001` slotunun yeri sonuçtan etkilenmez.
- Bedel ve sınırlılık: Tek yeni fault run tekrarlanabilirliği kanıtlamaz. Merge canlı
  onay değildir; fresh kapılar ve ayrı runtime onayı gerekir. Invalid sonuç korunur,
  ID kullanılmaz ve replacement/sıra kararı otomatik verilmez.
- Uygulama sonucu: `ob-netdelay-15u-repeat-001`, D-038 25/restart 0, coverage 60/60,
  median `5,548 -> 755,171 ms`, fiziksel etki `+749,623 ms`, ilk semptom
  `29,397 sn`, latency manifestation `104,397 sn`, host `0/0/0` ve bütün
  raw/enriched/schema-v3/final replay kapılarıyla geçerli tamamlandı. `008/repeat-001`
  etki ortalaması `750,809 ms`, sample SD `1,677 ms`, CV yaklaşık `%0,223`tür. Bu ilk
  bağımsız fault tekrarında betimsel tutarlılıktır; blok `1/2` slottadır ve sıradaki
  `control-001` tamamlanmadan eşlenmiş blok veya genel tekrarlanabilirlik kapanmaz.

## D-060 - İlk eşlenmiş no-toxic kontrolün metadata ve geçerlilik sözleşmesi

- Durum: **Uygulanmadan durduruldu; D-061–D-066 ile superseded**
- Karar: `ob-netdelay-15u-control-001`, birinci `fault-control` bloğunun ikinci slotudur.
  Aynı proxy overlay, workload `15/1/seed 1`, 500m/100m kaynak ve toplam
  `300/300/120/300/300` lifecycle kullanılır; toxic oluşturulamaz. 120/300 saniyelik
  fazlar `matched_ramp_interval/matched_steady_interval` olarak adlandırılır, injection
  değildir. Pre/mid/post/cleanup API snapshotlarında `toxics=[]`, baseline/matched
  steady coverage `>=48/48`, frozen SLO'da `failure_manifestation=null`, pod/host/
  telemetry/rollback/receipt kapıları zorunludur. Latency farkı eşiksiz betimseldir.
- Gerekçe: Fault runner semantiğini kontrole taşımak sahte injection metadata'sı ve
  `physical_effect_verified=true` beklentisi üretir. `repeat-001` sonucundan kontrol
  latency eşiği türetmek post-hoc bias olur. Kontrolün görevi sistemin fault yokken
  yanlış manifestation üretip üretmediğini ve paired drift'i ölçmektir.
- Alternatifler: Mevcut fault runner'ı yalnız ramp çağrısını atlayarak kullanmak;
  normal-baseline runner'ı proxy/lifecycle eşleşmesi olmadan yeniden etiketlemek; veya
  `008/repeat-001` dağılımından kontrol eşiği seçmek reddedildi.
- Fayda: Treatment'ın tek farkı toxic varlığı olur; zaman, overlay, workload ve kaynak
  maruziyeti eşlenirken kontrol geçerliliği bilimsel fault etkisiyle karıştırılmaz.
- Bedel ve sınırlılık: Yeni runner, analyzer ve metadata verifier gerekir. Bu karar
  bunları uygulamaz ve canlı onay değildir. Invalid kontrol korunur; tek paired blok
  genel tekrarlanabilirlik veya Dataset v1 yeterliliği sağlamaz.

## D-061 - Fault öncesi nicel headroom ve etki fizibilitesi kapısı

- Durum: **Kabul edildi; tüm yeni fault ön-kayıtları için bağlayıcı**
- Karar: Her yeni fault profili, canlı enjeksiyondan önce aktif servis limit/request
  değerleri, en az üç geçerli normal run dağılımı, önerilen fault büyüklüğü, beklenen
  fiziksel etki, SLO'ya kalan headroom ve belirsizlik payını içeren makine-okunur bir
  fizibilite hesabı taşımalıdır. Hesap, önerilen büyüklüğün SLO bölgesine ulaşmasını
  makul göstermiyorsa veya aktif deployment ile doğrulanamıyorsa fault yetkisizdir.
- Gerekçe: 200m limitli servise 50–150m ek CPU talebi fiziksel olarak tekrarlanmış,
  ancak 35 attempt sonunda geçerli manifestation `0/15` kalmıştır. Basit headroom
  hesabı uzun lifecycle maliyetinden önce düşük etki olasılığını görünür kılabilirdi.
- Alternatifler: Yalnız injector komutuna veya tek normal ortalamaya güvenmek; etkiyi
  canlı koşularla deneme-yanılma yoluyla aramak; sonucu gördükten sonra şiddeti
  artırmak reddedildi.
- Fayda: Uygun olmayan fault büyüklükleri pahalı koşulardan önce elenir; seçimin
  gerekçesi bağımsız olarak yanlışlanabilir olur.
- Bedel ve sınırlılık: Headroom hesabı kuyruklanma ve doğrusal olmayan sistem etkilerini
  kesin tahmin etmez. Bu nedenle enjeksiyonun yerine geçmez; yalnız canlı çalıştırma
  öncesi zorunlu bir uygunluk kapısıdır.

## D-062 - İki-workload network-delay merdiveni

- Durum: **Kabul edildi; yeni P2 tasarımının bağlayıcı fault ekseni**
- Karar: Erken-tahmin adayı network delay, `25/50/100/250/500 ms` seviyelerinde ve
  iki onaylı workload düzeyinde sürümlü hücreler olarak incelenir. Her hücre aynı
  hedef edge, jitter `0`, lifecycle, SLO, telemetri ve cleanup sözleşmesini korur.
  `750 ms` altındaki `008` ve `repeat-001` yalnız tarihsel exploratory pilotlardır.
- Gerekçe: Tek `750 ms` noktası doğrudan manifestation üretmiş ve lead-time geçiş
  bölgesini örneklememiştir. Merdiven, ilk semptom ile manifestation arasındaki
  ölçülebilir bölgeyi ve workload etkileşimini prospektif olarak arar.
- Alternatifler: 750 ms düzeyinde daha fazla tekrar, yalnız tek workload veya sürekli/adaptif
  sonuç-bağımlı şiddet araması; geçiş bölgesi ve post-hoc seçim riski nedeniyle
  reddedildi.
- Fayda: Şiddet-cevap eğrisi, eşik bölgesi ve pozitif lead-time için açık kanıt sağlar.
- Bedel ve sınırlılık: Hücre sayısı ve koşu maliyeti artar. Ladder taraması nihai
  model örneklemi değildir ve sonuç görülerek ara seviyeler eklenemez.

## D-063 - 500m sistem profili için baseline reset ve probe-path ayrımı

- Durum: **Kabul edildi; yeni ladder koşularından önce zorunlu**
- Karar: Recommendationservice server CPU limitinin `200m -> 500m` değişmesi maddi
  sistem değişikliğidir. Eski altı normal baseline yeni 500m treatment/control
  karşılaştırmasında kullanılamaz; aynı 500m/100m resource profili, iki workload ve
  yeni benzersiz run ID'leriyle normal baseline'lar sıfırdan toplanır. Scientific
  network delay yalnız kullanıcı isteği hedef edge'ine uygulanır; readiness/liveness/
  health path'i toxic/proxy gecikmesinin dışında olduğu runtime kanıtıyla doğrulanır.
- Gerekçe: Kaynak limiti normal latency, throttling ve pod davranışını değiştirir.
  Ayrıca önceki restart zinciri network fault'undan önce liveness probe davranışıyla
  karışmıştır.
- Alternatifler: Eski 200m normalleri yeniden kullanmak, istatistiksel düzeltmeyle
  profil farkını gidermek veya probe timeout'unu genişletmek reddedildi. Bunlar sistem
  sürümünü ve fault etkisini birbirine karıştırır.
- Fayda: Normal ve fault koşulları aynı sistem sürümünde karşılaştırılır; probe restartı
  scientific manifestation gibi yorumlanmaz.
- Bedel ve sınırlılık: Altı normal baseline yeniden toplanır ve önceki 200m verisi
  yalnız tarihsel/karşılaştırma dışı kanıt olarak kalır.

## D-064 - Prospektif örneklem büyüklüğü kapısı

- Durum: **Kabul edildi çalışma hedefi; confirmatory collection henüz yetkisiz**
- Karar: Bağımsız birim incident/run'dır; aynı run içindeki 5 saniyelik pencereler
  örnek sayısını artırmaz. Önerilen model ile rule baseline'ın aynı pozitif incident'lar
  üzerindeki eşlenmiş event-level doğruluk karşılaştırmasında iki taraflı
  `alpha=0,05`, güç `0,80`, en küçük anlamlı iyileşme `25` yüzde puanı ve toplam
  discordant-pair oranı `0,45` varsayımıyla McNemar yaklaşımı yaklaşık `57` pozitif
  incident gerektirir; attrition ve invalid run payı için hedef `60` bağımsız pozitif
  incident olarak dondurulur. False-alarm/hour ve negatif sınıf davranışı için ayrıca
  `60` bağımsız normal kontrol run hedeflenir; bu kontroller McNemar güç hesabına girmez.
- Yeniden üretilebilir hesap: `n=((1,959964+0,841621)^2*0,45)/(0,25^2)=56,514`;
  yukarı yuvarlama `57`, operasyonel hedef `60`.
- Gerekçe: En az bir pozitif olay model/baseline karşılaştırması veya belirsizlik
  tahmini için yeterli değildir. Olay-bazlı güç hesabı, pencere düzeyinde sahte örnek
  büyüklüğünü engeller.
- Alternatifler: Eski genel 40–50 run hedefi, pencere sayısını örnek saymak veya pilot
  sonucu görülünce hedef belirlemek reddedildi.
- Fayda: Confirmatory maliyet ve başarı ölçütü baştan görünür olur.
- Bedel ve sınırlılık: Yüzde 25 puan ve 0,45 discordance çalışma varsayımlarıdır.
  Ladder pilotu yalnız nuisance/attrition yeniden tahmini için kullanılabilir; hedefi
  sonuç yönüne göre küçültmek yeni açık karar olmadan yasaktır.

## D-065 - Network-delay takvim ve fault-sınıfı değiştirme kapısı

- Durum: **Kabul edildi bağlayıcı durdurma kuralı**
- Karar: Son tarih `2026-09-15`tir. Bu tarihe kadar ladder taramasında en az bir
  workload-delay hücresinde üç geçerli bağımsız tekrarın en az ikisinde frozen SLO
  manifestation ve en az `15 saniye` pozitif lead-time görülmezse network delay
  erken-tahmin fault adayı olarak durdurulur. Yeni fault sınıfı ayrı araştırma kararı,
  headroom hesabı, normal baseline ve ön-kayıt olmadan başlatılamaz.
- Gerekçe: Açık süre sınırı olmayan negatif pilotlar, veri üretmeyen fault üzerinde
  sınırsız tooling ve koşu maliyeti oluşturabilir.
- Alternatifler: Belirsiz biçimde daha fazla koşu, yalnız fiziksel etkiye dayanarak
  devam veya tarihi sonuçtan sonra seçmek reddedildi.
- Fayda: Kaynak kullanımı ve karar sorumluluğu önceden belirlenir.
- Bedel ve sınırlılık: Takvim operasyonel kesintilere duyarlıdır; tarih değişikliği
  ancak süre dolmadan, sonuçlara bakılmadan ve gerekçeli yeni kararla yapılabilir.

## D-066 - Mentor kapılarının mevcut P2 akışına uygulanması

- Durum: **Kabul edildi; ileriye dönük geçiş kararı**
- Karar: D-058'in kalan 750ms paired slotları ve uygulanmamış D-060 `control-001`
  yürütülmez. `ob-netdelay-15u-008` ve `ob-netdelay-15u-repeat-001` geçerli ama
  exploratory tarihsel kanıttır; ladder, 500m yeni normal baseline veya 60-incident
  confirmatory hedefinin parçası sayılmaz. Sonraki canlı iş yalnız D-061–D-065
  kanıtları ve ayrı sürümlü ladder ön-kaydı tamamlandıktan sonra başlayabilir.
- Gerekçe: Mentor dönütü mevcut tek-nokta tekrar planından daha güçlü prospektif
  tasarım, karşılaştırılabilir baseline, örneklem ve takvim sınırı istemektedir.
- Alternatifler: D-058'i bitirip sonra ladder'a geçmek veya tamamlanmış 750ms koşuları
  yeni plana geriye dönük katmak reddedildi.
- Fayda: Geçmiş kanıt bozulmadan yeni metodolojik standart hemen uygulanır.
- Bedel ve sınırlılık: Hazırlanmış kontrol tooling'i kullanılmayabilir; bu maliyet
  scientific karşılaştırılabilirlik lehine kabul edilir.

## D-067 - 500m network-delay normal topology, belirsizlik ve toplama sırası

- Durum: **Kabul edildi; tooling/merge gerektirir, canlı normal toplama bu aşama için genel onaylı**
- Karar: D-063 yeni normalleri ladder treatment ile aynı no-toxic Toxiproxy overlay
  altında, recommendationservice `500m/100m`, workload `10u/15u`, seed `1` ve
  `300/300` warmup/baseline ile toplar. Her workload için üç bağımsız geçerli run
  gerekir. Seed `20260821` ile sonuç görülmeden dondurulan sıra
  `15u-001,15u-002,10u-001,10u-002,15u-003,10u-003`tür. Her run'ın üst-kuyruk özeti,
  300 saniyelik baseline içindeki nonempty 5 saniye product-detail window-p95 değerlerinin
  maksimumudur. Belirsizlik payı `max(5ms, üç run-level üst-kuyruk özetinin max-min
  aralığı)`; normal üst sınır üç run-level özetin maksimumudur. Headroom ve aday margin formülleri D-061
  profilindeki gibidir; sonuç karar-desteğidir, severity seçimi veya fault yetkisi değildir.
- Gerekçe: Overlay eşleme configuration confounding'i azaltır. Üç run ile bootstrap
  veya parametrik tail çıkarımı zayıftır; run-level maksimum ve gözlenen aralık şeffaf,
  muhafazakâr ve yeniden üretilebilirdir. 5ms tabanı D-042'nin prospektif kabul edilebilir
  proxy-overhead sınırıdır ve sonuçlara göre değiştirilemez. Dengeli randomizasyon gün/sıra
  etkisini workload ile tamamen eşleştirmemeyi amaçlar.
- Alternatifler: Base topology; bootstrap üst güven sınırı; parametrik prediction bound;
  workload'ları blok halinde toplamak veya eski 200m/750ms pencerelerini kullanmak
  reddedildi. İlk üçü küçük-n varsayımı/konfigürasyon farkı, son ikisi sıra etkisi ve
  D-063 leakage riski taşır.
- Fayda: Ladder hücrelerinden önce aynı sistem sürümünde iki workload'un normal kuyruğu
  ve belirsizliği ölçülür; hesap koddan bağımsız olarak savunulabilir.
- Bedel ve sınırlılık: Altı uzun no-fault run gerekir. Maksimum+range yaklaşımı gerçek
  population tail garantisi değildir ve aday gecikmenin frontend latency'ye bire bir
  taşındığını kanıtlamaz.

## D-068 - İlk 500m normalin geçersiz kapanışı ve yeni kimlikli telafisi

- Durum: **Kabul edildi; operasyonel düzeltme ve aynı koşullu telafi run'ı bu aşama için genel onaylı**
- Karar: `ob-netdelay-500m-normal-15u-001`, bilimsel pencere tamamlansa bile
  PowerShell'in case-insensitive, salt-okunur `$Host` yerleşik değişkeniyle kapanış
  değişkeni çakıştığı ve scientific metadata/final receipt üretilmediği için geçersizdir.
  Tanısal `299,901ms` D-067 hesabına alınmaz ve run ID tekrar kullanılmaz. Dondurulmuş
  ilk sıra slotu, yalnız değişken adı düzeltildikten ve regresyon kapısı geçtikten sonra
  aynı workload/topoloji/zamanlama/eşiklerle `ob-netdelay-500m-normal-15u-004` olarak
  hemen telafi edilir; kalan randomize sıra değişmez.
- Gerekçe: Eksik kapanış kapısını sonradan bilimsel geçerli saymak fail-closed sözleşmesini
  bozar. Aynı slotu yeni kimlikle telafi etmek, invalid kanıtı korurken workload sıra
  dengesini mümkün olduğunca sürdürür.
- Alternatifler: `15u-001`i tanısal veriye dayanarak geçerli saymak; aynı ID'yi yeniden
  kullanmak; slotu atlayıp sıraya devam etmek; eşik/topolojiyi değiştirmek reddedildi.
- Fayda: Kanıt soyu ve falsifiye edilebilir kapanış korunur; teknik hata akademik
  sonuç veya eşik değişikliği gibi yorumlanmaz.
- Bedel ve sınırlılık: Ek bir uzun no-fault run gerekir ve takvim etkisi tamamen yok
  edilemez; bu koşu yalnız üç geçerli 15u tekrardan biri olabilir.

## D-069 - İkinci kapanış hatası ve çapraz kimlik sözleşmesi kapısı

- Durum: **Kabul edildi; aynı koşullu yeni kimlikli telafi bu aşama için genel onaylı**
- Karar: `ob-netdelay-500m-normal-15u-004`, metadata verifier'ın runner'dan ayrı
  eski allowlist'i nedeniyle final receipt öncesi reddedildiğinden geçersizdir;
  tanısal `605,978ms` hesaba alınmaz ve ID tekrar kullanılmaz. İlk slot aynı koşullarda
  `ob-netdelay-500m-normal-15u-005` ile telafi edilir. Canlıdan önce runner ve metadata
  verifier'ın tüm kalan etkili run ID'lerini birlikte kabul ettiğini statik regresyon
  testi kanıtlar; verifier başarısız kontrol adlarını çıktılar.
- Gerekçe: İki yürütme bileşenindeki çoğaltılmış kimlik sözleşmesi sessiz drift üretti.
  Çapraz kontrol yalnız bu operasyonel uyumsuzluğu kapatır; bilimsel tasarımı değiştirmez.
- Alternatifler: `15u-004`ü sonradan receipt üreterek geçerli saymak; verifier'ı kaldırmak;
  aynı ID'yi kullanmak veya sonucu eşiğe göre seçmek reddedildi.
- Fayda: Yeni run başlamadan yürütme ve bağımsız doğrulama aynı kimlik kümesi üzerinde
  fail-closed eşlenir; hata çıktısı hangi kontrolün reddettiğini açıklar.
- Bedel ve sınırlılık: Üçüncü bir 15u denemesi gerekir. Statik eşleme testi diğer runtime
  arızalarını garanti etmez; bütün kapanış kapıları yine canlıda geçmelidir.

## D-070 - Normal metadata/finalizer seed sözleşmesi ve üçüncü telafi

- Durum: **Kabul edildi; aynı koşullu `15u-006` telafisi bu aşama için genel onaylı**
- Karar: `15u-005`, metadata 15/15 geçse de shared finalizer top-level `random_seed`
  beklediği için valid receipt olmadan invaliddir; `1082,282ms` kullanılmaz. Normal
  metadata, hashlenen workload profilindeki seed'i ayrıca top-level `random_seed=1`
  olarak taşır ve verifier bunu kontrol eder. İlk slot aynı koşullarla yeni `15u-006`
  ID'siyle telafi edilir.
- Gerekçe: Receipt/verifier sözleşmesi seed'i karşılaştırır; üretici aynı alanı açıkça
  sağlamalıdır. Bu provenance düzeltmesidir, workload veya akademik eşik değişikliği değildir.
- Alternatifler: Finalizer/verifier seed kontrolünü kaldırmak, eksik alanı null saymak,
  `15u-005`i sonradan geçerli kılmak veya ID'yi yeniden kullanmak reddedildi.
- Fayda: Metadata, workload ve receipt seed soyu aynı kapanış zincirinde doğrulanır.
- Bedel ve sınırlılık: Ek bir uzun koşu gerekir; entegrasyon testi canlı sistemin tüm
  olası arızalarını garanti etmez.
- Uygulama sonucu: `ob-netdelay-500m-normal-15u-006` tüm kapanış kapılarıyla geçerli
  tamamlandı; run-level üst-kuyruk `539,155ms`, coverage 60/60 ve manifestation null.
  Bu yalnız ilk 15u tekrar (`1/3`) olup headroom/severity kararı üretmez.
- İzleyen sonuç: `ob-netdelay-500m-normal-15u-002` de geçerli tamamlandı; run-level
  üst-kuyruk `374,397ms`, coverage 60/60 ve manifestation null. 15u uygunluğu `2/3`;
  iki-run spread `164,758ms` yalnız betimseldir ve D-067 hesabı hâlâ blokludur.
- İlk 10u sonuç: `ob-netdelay-500m-normal-10u-001` geçerli tamamlandı; run-level
  üst-kuyruk `612,248ms`, coverage 60/60 ve manifestation null. Tek maksimum frozen
  eşiği aşsa da üç ardışık ihlal yoktur. Uygunluk 10u `1/3`, 15u `2/3`; karar blokludur.

## D-071 - 10u ikinci normal preflight invalid ve readiness tanı sınırı

- Durum: **Kabul edildi; kullanıcı 2026-08-27'de yalnız ayrı no-fault base readiness/stability tanısını onayladı; replacement yetkisiz**
- Öneri: `ob-netdelay-500m-normal-10u-002`, base deployment availability warm-up
  öncesi timeout verdiği için geçersizdir; 10u sayacına veya headroom hesabına girmez
  ve ID tekrar kullanılmaz. Timeout, probe, kaynak, workload, topoloji veya bilimsel
  eşikler gevşetilmez. Yeni ID'li replacement öncesinde recommendationservice için
  ayrı no-fault readiness tanısı veya fresh stability kanıtı gerekir.
- Gerekçe: Read-only canlı gözlem `0/1`, CrashLoopBackOff, altı restart ve bir saniyelik
  probe timeout'ları gösterdi; ancak bu gözlem runner tarafından mühürlenmediğinden
  kesin kök neden sayılamaz. Aynı koşuyu körlemesine yinelemek host/service kararsızlığını
  bağımsız normal değişkenliğiyle karıştırabilir.
- Alternatifler: Deployment timeout'unu artırmak, probe/resources değiştirmek, aynı ID'yi
  yeniden kullanmak veya koşuyu eksik kanıtla geçerli saymak reddedildi.
- Fayda: Mentor health-path ve fresh-readiness kapıları korunur; operational failure
  akademik normal dağılıma sızmaz.
- Bedel ve sınırlılık: Toplama sırası gecikir. Tanı sonucu bilimsel sözleşme değişikliği
  gerektirirse ayrıca açık araştırma kararı gerekir.
- Uygulama kararı: Benzersiz `ob-network-base-readiness-001`, mevcut base manifest ve
  10u workload bağı değişmeden; proxy/resource overlay ve toxic olmadan yürütülür.
  Mevcut 900 sn deployment availability bütçesi sırasında 5 sn cadence ile convergence,
  Available sonrasında 180 sn / 5 sn sabit UID/server Ready/restart gözlemi toplar.
  Alternatif olarak workload'u kapatmak reddedildi; arızanın görüldüğü base koşulunu
  hafifleterek daha az ilgili kanıt üretirdi. Tek snapshot da geçici restartları kaçıracağı
  için reddedildi. Sonuç yalnız `fresh_base_stability_supported/not_supported` tanısıdır;
  dataset/headroom girdisi veya nedensel kök neden değildir.

## D-072 - İlk D-071 diagnostic preflight invalid ve aynı koşullu replacement

- Durum: **Kabul edildi operasyonel geçerlilik düzeltmesi; D-071 bilimsel sınırı değişmez**
- Karar: `ob-network-base-readiness-001`, Docker Linux engine yokken Minikube ve
  Kubernetes başlamadan invalid/incomplete kapanır; ID kullanılmaz. Dört dosyalık
  diagnostic seal/offline replay ve host `0/0/0` korunur. Bitişik PowerShell `throw`
  tokenization düzeltilip regresyon testiyle yasaklanır. Docker engine readiness
  canlıdan önce ayrıca doğrulanır; aynı 900/5 + 180/5 D-071 koşulları yeni benzersiz
  `ob-network-base-readiness-002` ile yürütülür.
- Gerekçe: `001` recommendationservice readiness hakkında gözlem üretmedi. Aynı ID'yi
  kullanmak provenance'ı; engine hazır değilken tekrar denemek fail-closed preflight'ı
  ihlal eder. Hata aktarım kusuru mühürlü artifact'ı bozmadı fakat kesin hata sınıfını
  runner çıktısında maskeledi.
- Alternatifler: `001`i yeniden kullanmak, Docker yokluğunu service instability saymak,
  tanı süresi/topoloji/workload'u değiştirmek veya mühürlü girişimi silmek reddedildi.
- Fayda: Altyapı önkoşulu service readiness sonucundan ayrılır; erken başarısızlık da
  yeniden oynatılabilir kalır.
- Bedel ve sınırlılık: Ayrı commit ve yeni diagnostic ID gerekir. Docker readiness
  sonraki Kubernetes kararlılığını garanti etmez; `002` bütün tanı kapılarından geçmelidir.
- Uygulama sonucu (2026-08-28): Docker Engine `29.7.2`, contract testi ve `WhatIf`
  geçti; ancak Minikube `K8S_APISERVER_MISSING` ile kapandı ve API server süreci hiç
  oluşmadı. Deployment, workload ve recommendationservice gözlemi başlamadı; fault ve
  bilimsel pencere false kaldı. Cluster stopped, host `0/0/0` ve dört çekirdek dosyanın
  SHA-256 seal/offline replay'i geçti. `002` invalid/incomplete korunur ve yeniden
  kullanılmaz. Bu operasyonel sonuç yeni replacement veya üçüncü tanı kararı vermez.

## D-073 - Stale Minikube state için izole clean-bootstrap tanısı

- Durum: **Kabul edildi; kullanıcı 2026-08-28'de yalnız faultsuz Kubernetes bootstrap tanısını onayladı; application/replacement/fault yetkisiz**
- Karar: Benzersiz `ob-k8s-bootstrap-001`, eski `p0-online-boutique` container/volume/log
  metadata'sını koruduktan sonra yalnız bu profile'ı siler; container ve volume yokluğunu
  doğrular. Aynı Docker + Kubernetes v1.34.0 + 4 CPU + 6144 MiB + 32 GiB + containerd
  sözleşmesiyle temiz profile başlatır ve 180/5 saniye host/kubelet/apiserver/kubeconfig
  kararlılığı toplar. Uygulama manifesti, workload, toxic veya fault uygulanmaz.
- Gerekçe: `002` sırasında profile/SSH state'i 28 Ağustos, persistent `/var` volume ve
  kubeadm/kubelet state'i 15 Temmuz tarihliydi; disk/inode baskısı yoktu ve hiçbir
  control-plane containerı oluşmadı. Stale-state karışımı en güçlü test edilebilir
  hipotezdir fakat salt zaman eşleşmesi nedensellik kanıtı değildir.
- Alternatifler: Volume'u kanıtsız silmek, aynı stale profile'ı yeniden başlatmak,
  Kubernetes sürümü/kaynakları değiştirmek veya doğrudan application/normal run
  başlatmak reddedildi.
- Fayda ve sınırlılık: Temiz-bootstrap karşılaştırması altyapı önkoşulunu uygulamadan
  ayırır. Tek pozitif sonuç stale state'i destekler fakat eşzamanlı temiz rootfs/profile
  etkilerinden dolayı tek nihai nedeni kanıtlamaz; sonuç Dataset v1/D-067 dışıdır.
- Uygulama sonucu: Exact profile silme sonrası container/volume yokluğu geçti. Aynı
  v1.34.0/4 CPU/6144 MiB/32 GiB/containerd sözleşmesindeki clean bootstrap başarılı;
  180/5 saniyede `30/30` host+kubelet+apiserver `Running`, kubeconfig `Configured` oldu.
  Host `0/0/0`, semantic verifier, cluster stop ve 12/12 SHA replay geçti. Sonuç stale
  karışık Minikube state hipotezini destekler fakat volume'u tek neden yapmaz; application,
  recommendationservice readiness, replacement veya fault yetkisi üretmez.

## D-074 - Clean bootstrap sonrası değişmeyen base readiness replacement ön-kaydı

- Durum: **Kabul edildi ön-kayıt; kullanıcı 2026-08-28'de yalnız hazırlık işlemlerini
  onayladı; canlı diagnostic, normal replacement ve fault yetkisiz**
- Karar: `ob-network-base-readiness-002`, application başlamadan invalid kapandığı ve
  D-073 aynı cluster sözleşmesinde clean bootstrap'ı desteklediği için yeni benzersiz
  `ob-network-base-readiness-003` aynı D-071 application koşullarıyla ön-kaydedilir.
  Mevcut base manifest + `ob-default-10u-1r-v1`, overlay/toxic yokluğu, 900/5 convergence,
  Available sonrası 180/5 sabit UID/server Ready/restart, host RecordId, cluster stop,
  semantic verifier ve seal/replay kapıları değişmez.
- Gerekçe: D-073 yalnız Kubernetes önkoşulunu sınadı; recommendationservice readiness
  boşluğu hâlâ açıktır. Doğrudan normal run bu operasyonel kararsızlığı D-067 normal
  dağılımıyla karıştırabilir.
- Alternatifler: Doğrudan replacement normal run; aynı `002` ID'sini kullanmak; timeout,
  probe, resource, topology veya workload'u değiştirmek; clean bootstrap'ı application
  kanıtı saymak reddedildi.
- Fayda: Altyapı bootstrap kanıtı ile application convergence/stability kanıtını ayrı,
  falsifiable katmanlarda tutar ve invalid kanıtı değiştirmeden eksik gözlemi hedefler.
- Bedel ve sınırlılık: Ayrı commit/merge ve canlı runtime onayı gerekir. Başarı yalnız
  `fresh_base_stability_supported` tanısıdır; Dataset v1, D-067 headroom, bağımsız incident,
  replacement normal veya fault yetkisi üretmez ve `10u 1/3`, `15u 2/3` sayımını değiştirmez.

## D-075 - Üçüncü base-readiness girişiminin Kubernetes preflight'ında invalid kapanışı

- Durum: **Kabul edildi operasyonel geçerlilik kaydı; sonraki tanı/replacement kararı açık**
- Sonuç: Canonical `bb98f28` üzerinde Docker `29.7.2`, iki contract testi ve `WhatIf`
  geçti. `ob-network-base-readiness-003` Minikube API server süreci altı dakika içinde
  hiç oluşmadığı için `K8S_APISERVER_MISSING/minikube_start_failed` ile invalid/incomplete
  kapandı; ID yeniden kullanılmaz. Deployment, 10u workload, convergence ve stability
  gözlemi başlamadı; fault ve bilimsel pencere false kaldı.
- Kanıt: Cluster stopped, RecordId host farkı `0/0/0`, dört çekirdek dosya semantic scope
  ve SHA-256 offline replay ile korundu. Readiness observation/assessment oluşmadığından
  recommendationservice sınıflandırması yoktur.
- Yorum sınırı: Sonuç D-073'ün tarihsel clean-bootstrap kanıtını geriye dönük geçersiz
  kılmaz; tek kök neden, application instability veya network-delay etkisi kanıtlamaz.
  D-067 15u `2/3`, 10u `1/3` kalır. Timeout/probe/resource/topology/workload/eşik
  değiştirilmedi; yeni diagnostic, normal replacement veya fault otomatik yetkili değildir.

## D-076 - Minikube state-root provenance ve stopped-profile postmortem

- Durum: **Tamamlandı geçerli read-only operasyonel kanıt; dataset/headroom dışı**
- Karar: Yeni benzersiz `ob-minikube-state-postmortem-001`, D-075 sonrası durmuş exact
  profile için `env.ps1` öncesi dış ve sonrası resolved `MINIKUBE_HOME` değerlerini,
  repository-local expected absolute root'u, container/volume inspect, profile config,
  host-side `lastStart`, Docker ve Minikube last-start loglarını read-only toplar.
- Gerekçe: Aynı `p0-online-boutique` adı iki host-side state-root'ta bulunabilir. D-075
  öncesindeki manuel status kontrolü `Documents/Makale` kökünü sorgularken runner
  repository-local kökü kullandı; profile adı tek başına provenance kanıtı değildir.
- Fail-closed kapılar: Resolved root beklenen canonical path ile eşleşmezse, Docker hazır
  değilse, exact profile/container yoksa veya container running ise artifact oluşmadan
  durur. Runtime içinde profile/container/cluster start/delete/restart/rm ve application,
  workload, proxy/toxic/fault işlemleri yasaktır.
- Alternatifler: Doğrudan `base-readiness-004`, mevcut failure state'ini silip clean
  bootstrap tekrarı, dış root'u örtük kabul etmek veya stopped container'ı journal için
  başlatmak reddedildi; bunlar sırasıyla kararsızlığı normal veriye taşır, kanıtı yok eder,
  provenance'ı belirsiz bırakır veya read-only sınırı bozar.
- Fayda ve sınırlılık: Mevcut failure state'i değiştirmeden state-root bağını makine-
  doğrulanır yapar ve erişilebilir postmortem kanıtı mühürler. Stopped container başlatılmadan
  live kubelet/containerd journal alınamaz; çıktı tek kök neden, Dataset/D-067/incident,
  profile delete/bootstrap retry/application/replacement/fault yetkisi değildir.
- Gerçekleşen sonuç: `ob-minikube-state-postmortem-001`, canonical `8f88f70` revisionında
  repository-local resolved/expected root eşitliğiyle tamamlandı. Docker Engine `29.7.2`,
  exact container `exited`, restart `0`, `OOMKilled=false`, exit code `130`; exact aynı adlı
  volume, profile config ve `lastStart` kaynakları mevcuttu. Minikube last-start kanıtı
  `K8S_APISERVER_MISSING` ve `apiserver process never appeared` sonucunu yeniden gösterdi.
  Profile/container/cluster/application/workload/fault başlatılmadı veya değiştirilmedi;
  semantic verifier ve 9/9 SHA-256 offline replay geçti.
- Yorum sınırı: Bu kanıt D-075'in hangi repository-local state root/container/volume/log
  kümesine ait olduğunu doğrular ve API server yokluğuyla uyumludur. Stopped-container
  postmortem canlı journal sağlamadığı için exit `130`, volume varlığı veya log hata sayıları
  tek başına benzersiz kök neden değildir. D-067 sayımı 15u `2/3`, 10u `1/3` kalır.

## D-077 - D-076 native stdout/stderr/exit-code izolasyonu

- Durum: **Kabul edildi tooling düzeltmesi; D-076 kimliği/koşulları değişmez, runtime yetkisiz**
- Karar: İlk D-076 runtime çağrısı Docker kapalıyken artifact oluşturmadan durdu; ancak
  Windows PowerShell 5.1 native stderr'i `NativeCommandError` olarak terminating yükseltti
  ve beklenen `docker_engine_not_ready` sınıfına ulaşılmadı. Genel
  `Invoke-NativeCommandCapture` helper'ı stdout, stderr ve exit code'u ayrı geçici
  dosyalardan döndürür; D-076 Docker preflight/inspect/log yolları buna bağlanır.
- Gerekçe: Artifact-free fail-closed davranış korunsa da hata taksonomisinin runtime'a göre
  değişmesi makine doğrulamasını ve kullanıcıya açıklamayı bozar. Native stderr, payload
  veya PowerShell error stream'i olarak yorumlanmamalıdır.
- Alternatifler: Docker stderr'ini bastırmak kanıt kaybı; `$ErrorActionPreference` gevşetmek
  geniş kapsamlı hata saklama; ilk çağrıyı invalid diagnostic saymak artifact/manifest
  oluşmadığı için yanlış provenance olurdu.
- Fayda ve sınırlılık: Success-with-stderr ve nonzero-with-stderr fixture'ları iki PowerShell
  runtime'ında aynı sonucu verir; Docker kapalıysa kontrollü kapı korunur. Düzeltme Docker'ı
  başlatmaz, postmortem ID'sini tüketmez ve profile/bootstrap/application yetkisi vermez.
- D-079 hazırlık doğrulaması: Caller `-WhatIf` tercihi helper'ın `finally` temp cleanup'ını
  bastırabildiği için `Remove-Item -WhatIf:$false -Confirm:$false` olarak daraltıldı ve
  no-leak fixture eklendi. Bu yalnız helper'ın kendi iki geçici dosyasını temizler; hedef
  container/profile veya bilimsel koşula dokunmaz. D-079 `Capture` çağrıları ayrıca yalnız
  allowlisted read-only inspect/log/journal komutları için yerel WhatIf izolasyonu kullanır.

## D-079 - Canlı Kubernetes bootstrap observability tanısı ön-kaydı

- Durum: **Tamamlandı; geçerli operasyonel tanı kanıtı, Dataset/D-067 dışı**
- Karar: Yeni benzersiz `ob-k8s-bootstrap-observe-001`, D-076 ile provenance'ı kapanan
  repository-local durmuş profile'ı silmeden, değişmeyen Docker/v1.34.0/4 CPU/6144 MiB/
  32 GiB/containerd sözleşmesiyle başlatma çağrısı sırasında 420/5 saniyelik container ve
  control-plane process gözlemi toplar. Container live olursa stop öncesinde kubelet,
  containerd ve CRI kanıtı yakalanır; her sonuçta start stdout/stderr, last-start log,
  container inspect, RecordId host sınırı, semantic verifier ve SHA replay zorunludur.
- Gerekçe: D-076 doğru state root/container/volume/log kümesini doğruladı fakat stopped
  container live journal vermedi. D-073'ü yeniden clean-bootstrap olarak tekrarlamak veya
  application readiness/normal replacement çalıştırmak bu canlı bilgi açığını kapatmaz.
- Alternatifler: Doğrudan `10u` replacement normal run yüksek invalid-run riski nedeniyle;
  yeni clean delete/bootstrap D-073'ü tekrar edip preserved failure state'ini yok edeceği
  için; probe/resource/topology/eşik değişikliği farklı bilimsel değişken yaratacağı için
  reddedildi.
- Geçerlilik ve yorum sınırı: Exact container başlangıçta stopped değilse, Git kirliyse,
  artifact varsa veya Docker hazır değilse artifact öncesi fail-closed durur. Başarı,
  live-evidence failure, live container oluşmadan failure ve 420 saniyelik client timeout
  önceden tanımlı betimsel sınıflardır. Profile sonunda stop edilir; delete, application,
  workload, proxy/toxic ve fault yasaktır. Çıktı tek kök neden, Dataset/D-067/incident,
  application veya replacement normal yetkisi değildir; D-067 15u `2/3`, 10u `1/3` kalır.
- Gerçekleşen sonuç: Canonical `92fda127187dffdb82cff3ebd2c2975585b36c23`
  revisionında 58 process örneği ve live container gözlemi üretildi. Minikube
  `K8S_APISERVER_MISSING` ile kapandı; kubelet yaklaşık saniyelik restart döngülerinde
  `/etc/kubernetes/bootstrap-kubelet.conf` dosyasını bulamadığını bildirdi ve hiçbir
  control-plane container'ı gözlenmedi. Exact profile capture sonrasında stopped,
  container `OOMKilled=false`, host RecordId sınırı `0/0/0`, semantic verifier ve 13/13
  SHA replay geçti. Bu, API-server yokluğundan önceki yakın mekanizmayı daraltır; dosyanın
  neden üretilmediğini veya benzersiz kök nedeni kanıtlamaz.
- Kanıt sınırlamaları: Runner `start_exit_code=null` kaydetti. Ayrıca mevcut `crictl`
  sürümünde argüman sırası nedeniyle CRI capture container listesi yerine help çıktısı
  üretti. Kubelet/containerd/Minikube günlükleri ile container process örnekleri korunmuş
  ve semantic contract geçmiştir; fakat bu iki kanal gelecekte ayrı bir tooling düzeltmesi
  gerektirir ve mevcut kanıttan daha güçlü nedensel sonuç çıkarılamaz.

## D-080 - D-079 non-interactive ShouldProcess giriş düzeltmesi

- Durum: **Kabul edildi tooling düzeltmesi; D-079 kimliği ve koşulları değişmez**
- Karar: İlk D-079 runtime çağrısı artifact ve Minikube mutationı öncesinde
  `ConfirmImpact='High'` nedeniyle GUI'siz PowerShell hostunda `ShouldProcess` null-reference
  ile durdu. Mandatory `ExecutionApproved` aynen korunarak yalnız `ConfirmImpact='Low'`
  seçilir; `-WhatIf` davranışı ve çift-runtime fixture zorunlu kalır.
- Gerekçe: `ExecutionApproved` kullanıcı yetkisini, `ShouldProcess` dry-run davranışını temsil
  eder. Non-interactive otomatik prompt bilimsel veya güvenlik kapısı değildir ve daha önce
  D-057'de aynı mekanizma doğrulanmıştır.
- Alternatifler: `ShouldProcess`i kaldırmak dry-run yüzeyini; yüksek impact'i koruyup hosta
  özgü confirmation bayrağı istemek tekrarlanabilir entrypoint'i bozar. Seçilen değişiklik
  runtime, kaynak, süre, profile, ölçüm veya yorum sınırını değiştirmez.
- Doğrulama sınırı: İlk çağrı artifact oluşturmadı ve ID tüketilmedi. Canonical merge ve
  aynı açık runtime kapsamı sonrasında `ob-k8s-bootstrap-observe-001` yeniden yürütülebilir;
  application/workload/fault yetkisi oluşmaz.

## D-081 - Preserved bootstrap state-consistency tanısı ön-kaydı

- Durum: **Kabul edildi tooling/ön-kayıt; runtime ayrıca onay-gated**
- Karar: Yeni benzersiz `ob-k8s-bootstrap-state-consistency-001`, D-079'un preserved
  stopped profile koşullarını değiştirmeden Minikube existing-config marker'larını,
  bootstrap/kubelet kubeconfig'lerini, control-plane manifestlerini, etcd state'ini ve
  eski/yeni kubeadm yapılandırmasını first-live/final-live sınırlarında kaydeder. Minikube
  subprocess exit code null olamaz; exact CRI sürümü ile gerçek `crictl ps -a` çıktısı,
  journal, stop, host, semantic verifier ve SHA replay zorunludur.
- Gerekçe: D-079, üç marker mevcutken değişmeyen kubeadm config nedeniyle reconfiguration
  yolunun atlanması ve eksik `bootstrap-kubelet.conf` ile kubelet'in başlatılması zincirini
  destekledi; ancak state tutarsızlığının ilk oluşumunu ve iki tooling kanalını kapatmadı.
- Alternatifler: Clean delete/bootstrap preserved state'i yok eder; application readiness ve
  replacement normal bu altyapı sorusunu çözmez; mevcut D-079'u yeniden kullanmak immutable
  kimlik kuralını bozar.
- Sınırlar: v1.34.0/4 CPU/6144 MiB/32 GiB/containerd, 420/5 ve profile değişmez. Delete,
  application, workload, proxy/toxic, fault ve bilimsel pencere yasaktır. Çıktı tek kök neden,
  Dataset/D-067/incident veya replacement yetkisi değildir; D-067 15u `2/3`, 10u `1/3` kalır.
- Gerçekleşen runtime: Canonical `934ca0713fb2d32a13aabf703fd4d211c5bd8f11`
  revisionında ilk live inspect parse beklenen `State` alanını üretmedi; first-live state
  snapshot ve assessment oluşmadan fail-closed durdu. Minikube child redirect dosyasını ilk
  seal anında kilitledi; process kapanınca 7/7 SHA replay geçti. Profile stopped, host `0/0/0`.
  Run invalid/incomplete, ID kapalıdır; D-081 sorusu ve iki tooling sınırı açık kalır.

## D-082 - D-081 inspect-shape ve child-process kapanış düzeltmesi

- Durum: **Kabul edildi tooling düzeltmesi ve replacement ön-kaydı; runtime ayrıca onay-gated**
- Karar: Yeni benzersiz `ob-k8s-bootstrap-state-consistency-002`, `001` ile aynı profile,
  v1.34.0/4 CPU/6144 MiB/32 GiB/containerd ve 420/5 sözleşmesini korur. İlk inspect capture
  parse öncesi yazılır; tek nesne ve nonempty `State.Status` zorunludur. Minikube child process
  stop/wait/refresh/dispose ile kapatılmadan stop/seal aşamasına geçilemez.
- Gerekçe: `001` inspect şekli kanıtlanmadan property erişiminde durdu ve redirect handle
  kapanmadan ilk seal denendi. Pozitif/negatif inspect fixture'ları ile nonzero-exit/handle-
  release subprocess fixture'ı iki sınırı makine-doğrulanır kapatır.
- Sınırlar: State ölçümleri, CRI, host ve yorum sözleşmesi değişmez. Delete/reset, application,
  workload, proxy/toxic, fault ve Dataset/D-067 yasaktır. `001` invalid kalır; canonical merge
  runtime yetkisi değildir ve `002` tek kök neden veya replacement normal yetkisi vermez.
- Runtime sonucu: Canonical `79e7914` üzerindeki `002`, start exit `105` ve 77 gözlemle live
  container/CRI/K8S_APISERVER_MISSING kanıtı topladı; fakat iki zorunlu state capture shell parse
  hatasıyla `exit_code=2` ve boş stdout üretti. Verifier dosya varlığını başarı sanıp bu
  hatayı yakalamadı; `R` helper adı da PowerShell history aliasıyla çakıştı. Sonuç
  **invalid/incomplete**, ID kapalı ve state-consistency sorusu açıktır. Profile/container
  stopped, OOMKilled=false, host `0/0/0`, 17/17 SHA replay geçti. Yeni replacement yoktur.

## D-083 - D-082 state-capture ve semantic-verifier tooling kapanışı

- Durum: **Kabul edildi tooling düzeltmesi; yeni diagnostic/runtime yok**
- Karar: Native capture, her argümanı Windows command-line kurallarıyla ayrı kaçır; state
  capture runner içinde `exit_code=0`, nonempty stdout ve dokuz preregistered path satırını
  zorunlu kılar. Verifier helper'ı alias-safe ad kullanır ve aynı semantiği bağımsız denetler.
- Gerekçe: D-082'de `Start-Process -ArgumentList`, boşluk içeren `sh -c` programını
  parçaladı; dosya-varlığı denetimi boş/failed capture'ı yanlış başarı saydı ve `R`
  helper'ı PowerShell history aliasıyla çakıştı.
- Alternatifler: Yalnız shell metnini elle quote etmek dar ve kırılgan; yalnız verifier'ı
  düzeltmek hatalı capture'ı runtime'da geç durdurur; mevcut artifact'i yeniden yorumlamak
  prospektiflik ve immutability'yi ihlal eder. Katmanlı runner+verifier kapısı seçildi.
- Trade-off ve sınır: Ortak native helper değişikliği daha geniş regresyon alanı yaratır;
  bu nedenle PowerShell 5.1/7, complex-argument, failed-capture ve sealed-invalid fixture'ları
  zorunludur. `001`/`002` invalid kalır; yeni ID, runtime veya bilimsel sonuç yetkisi yoktur.

## D-084 - State-consistency 003 replacement preregistration

- Durum: **Kabul edildi preregistration; runtime ayrı onay-gated**
- Karar: Yeni benzersiz `ob-k8s-bootstrap-state-consistency-003`, `001/002` ile aynı preserved
  profile, v1.34.0/4 CPU/6144 MiB/32 GiB/containerd ve 420/5 koşullarını korur. D-083 native
  argument, inspect, process-close ve runner+verifier state semantik kapıları zorunludur.
- Gerekçe: D-082 bilimsel soruyu yanıtlamadan tooling nedeniyle invalid oldu; D-083 kusurları
  offline ve iki PowerShell runtime'ında falsifiable olarak kapattı. Yeni kimlik immutability'yi
  korurken aynı sorunun prospektif testine izin verir.
- Alternatifler: `002`yi yeniden kullanmak reddedilir; clean bootstrap/application readiness
  state-consistency sorusunu değiştirir; yalnız offline log yeniden yorumu eksik iki state
  boundary'sini geri getiremez. Koşulları değişmeyen replacement seçildi.
- Trade-off ve sınır: Bir ek operasyonel başlatma maliyeti vardır ve sonuç benzersiz kök neden
  kanıtlamaz. Delete/reset, application, workload, proxy/toxic, fault, Dataset v1 ve D-067
  yasaktır. Merge runtime yetkisi değildir.
- Runtime sonucu: Canonical `168bff3` üzerindeki `003`, 79 sample ve start exit `105` ile
  tamamlandı. İlk/final live boundary'de flags/config/etcd marker'ları ile aynı hashli eski/yeni
  kubeadm YAML present; bootstrap/kubelet conf ve apiserver/etcd manifestleri missing kaldı.
  Minikube existing-config restart'ı seçti, reconfiguration gerekmiyor dedi; CRI listesi boş,
  kubelet missing bootstrap kaydı 470 ve final K8S_APISERVER_MISSING oldu. Profile/container
  stopped, OOMKilled=false, host `0/0/0`, semantic verifier ve 17/17 SHA replay geçti.
- Yorum sınırı: Sonuç **geçerli operational diagnostic** olarak partial-state tutarsızlığını
  iki boundary'de kanıtlar; dosyaların ne zaman/neden kaybolduğunu veya tek kök nedeni kanıtlamaz.
  ID kapalıdır; clean bootstrap/application/replacement/fault yetkisi ve D-067 değişikliği yoktur.

## D-085 - Clean-bootstrap recovery preregistration

- Durum: **Kabul edildi preregistration; profile delete ve runtime ayrı onay-gated**
- Karar: Yeni benzersiz `ob-k8s-bootstrap-recovery-001`, immutable D-084 kanıtı korunduktan
  sonra D-073'ün exact-profile delete, yokluk doğrulaması ve değişmeyen
  v1.34.0/4 CPU/6144 MiB/32 GiB/containerd/180/5 clean-bootstrap sözleşmesini kullanır.
- Gerekçe: D-084 partial existing-state mekanizmasını gösterdi; clean reconstruction'ın aynı
  ortamı operasyonel olarak geri getirip getirmediği ayrı ve falsifiable bir sorudur.
- Alternatifler: Preserved state üzerinde bir başka gözlem aynı mekanizmayı tekrarlar; doğrudan
  application readiness bootstrap recovery kanıtını deployment değişkenleriyle karıştırır;
  normal/fault run'a dönmek geçilmemiş altyapı kapısını atlar. İzole clean bootstrap seçildi.
- Trade-off ve sınır: Exact profile silme geri döndürülemez runtime state değişikliğidir ve ayrı
  açık onay ister. Başarı state'in nasıl bozulduğunu veya tek kök nedeni kanıtlamaz. Application,
  workload, proxy/toxic, fault, Dataset v1, D-067 ve incident sayımı kapsam dışıdır; merge runtime
  veya delete yetkisi değildir.
- Runtime sonucu: Canonical `82f7faf` üzerinde exact delete/yokluk geçti; değişmeyen clean
  bootstrap tamamlandı ve 31/31 sample sağlıklıydı. Bir node Ready, 8/8 kube-system pod Running;
  profile stopped, container exit 130/OOMKilled=false, host `0/0/0`, semantic verifier ve 12/12
  SHA replay geçti. Sonuç geçerli operational recoverability kanıtıdır; origin veya benzersiz
  kök neden kanıtı değildir. ID kapalı, D-067 değişmez.

## D-086 - D-085 sonrası application readiness/stability diagnostic ön-kaydı

- Durum: **Kabul edildi preregistration; kullanıcı 2026-08-31'de yalnız repository
  hazırlığını onayladı, runtime yetkisiz**
- Karar: Yeni benzersiz `ob-network-base-readiness-004`, kapalı D-075 `003` kimliğini
  yeniden kullanmadan, D-085 clean-bootstrap recovery sonrasında eksik kalan
  recommendationservice application readiness/stability gözlemini toplamak üzere
  D-071/D-074 sözleşmesini değişmeden kullanır: base manifest + `ob-default-10u-1r-v1`,
  overlay/toxic yok, 900/5 convergence ve Available sonrası 180/5 sabit UID/server
  Ready/restart, host, stop, semantic verifier ve seal/replay.
- Gerekçe: D-085 Kubernetes recoverability'yi destekler fakat application deployment
  katmanını sınamaz. Doğrudan D-067 normal replacement, bu operasyonel boşluğu normal
  dağılım kanıtıyla karıştırır.
- Alternatifler: `003` ID'sini yeniden kullanmak; clean bootstrap'ı application kanıtı
  saymak; doğrudan replacement normal çalıştırmak; timeout/probe/resource/topology/
  workload/eşik değiştirmek reddedildi.
- Fayda: Kubernetes bootstrap ve application convergence/stability katmanlarını ayrı,
  falsifiable kanıtlarla sınar.
- Trade-off ve sınır: Ayrı canonical merge ve sonrasında ayrı açık runtime onayı gerekir.
  Profile delete/reset kapsam dışıdır. Sonuç Dataset v1, D-067 headroom, incident,
  replacement normal veya fault yetkisi üretmez; D-067 15u `2/3`, 10u `1/3` kalır.
- Runtime sonucu: Canonical `64bfad6` üzerinde Kubernetes başladı; base kustomization'ın
  ignored worktree-local `p0-env/source/microservices-demo/kustomize/base` bağımlılığı
  bulunmadığından apply `base_apply_failed` ile kapandı. Application/workload/readiness
  başlamadı; profile stopped, container exit 130/OOMKilled=false, host `0/0/0` ve dört
  dosyalık seal/replay geçti. `004` invalid/incomplete ve kapalıdır; D-067 değişmez.

## D-087 - Worktree-local pinned source preflight ve application readiness replacement

- Durum: **Kabul edildi preregistration; kullanıcı 2026-09-01'de yalnız repository
  hazırlığını onayladı, source hazırlığı ve runtime yetkisiz**
- Karar: Yeni `ob-network-base-readiness-005`, D-086 `004` kanıtını değiştirmeden aynı
  D-071/D-074/D-086 application sözleşmesini kullanır. Tek prospektif teknik ek,
  cluster başlamadan önce `p0-env/source/microservices-demo` varlığı ve exact
  `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` HEAD revision fail-closed kapısıdır.
- Gerekçe: `004` application davranışı nedeniyle değil, Git tarafından izlenmeyen pinned
  runtime bağımlılığının izole worktree'de bulunmaması nedeniyle application öncesinde
  kapandı. Bu bağımlılık cluster start öncesinde doğrulanmazsa gereksiz mutable runtime
  ve tüketilmiş diagnostic kimliği oluşur.
- Alternatifler: `004` ID'sini kullanmak; ana checkout kaynağına örtük bağlanmak; kaynağı
  runner içinde indirmek/kopyalamak; base manifesti değiştirmek; timeout/probe/resource/
  topology/workload/eşik değiştirmek reddedildi.
- Fayda: Checkout taşınabilirliği ve pinned upstream provenance çalışma öncesinde bağımsız
  doğrulanır; eksik bağımlılık application instability ile karışmaz.
- Trade-off ve sınır: Kaynak hazırlığı ayrı, ağ erişimli ve değiştirici işlemdir; canonical
  merge bunu veya runtime'ı yetkilendirmez. Diğer application koşulları değişmez. Sonuç
  Dataset v1, D-067, incident, replacement normal veya fault yetkisi üretmez; D-067
  15u `2/3`, 10u `1/3` kalır.
- Runtime sonucu: Canonical `8c37880` ve exact source `5b3a712...` üzerinde source
  preflight, Kubernetes start ve base apply geçti. İlk readiness snapshot'ında erken
  container status nesnesinde `containerID` bulunmadığından direct StrictMode erişimi
  fail-closed durdu. Base + 10u uygulandı fakat observation/assessment oluşmadı; profile
  stopped, exit 130/OOMKilled=false, host `0/0/0` ve dört dosyalık replay geçti. `005`
  invalid/incomplete ve kapalıdır; application sonucu ve D-067 değişikliği yoktur.

## D-088 - Erken pod optional-state uyumluluğu ve application readiness replacement

- Durum: **Kabul edildi preregistration; kullanıcı 2026-09-01'de yalnız repository
  hazırlığını onayladı, runtime yetkisiz**
- Karar: Yeni `ob-network-base-readiness-006`, D-087 `005` kanıtını değiştirmeden aynı
  application sözleşmesini kullanır. Pod snapshot dönüşümü eksik `conditions`,
  `containerStatuses` ve `containerID` alanlarını null/gözlenmemiş olarak korur. Pending
  pod ve containerID'siz ContainerCreating fixture'ları deterministic kapıdır.
- Gerekçe: Kubernetes erken lifecycle'da optional alanları henüz üretmeyebilir; bunların
  eksikliği runner hatası değil observation verisi olmalıdır. Ancak eksik alanı Ready veya
  stabil saymak yanlış pozitif üretir; mevcut sınıflandırma kapıları değişmeden kalır.
- Alternatifler: `005` ID'sini kullanmak; StrictMode'u kapatmak; eksik alanlara başarılı
  varsayılan vermek; ilk örnekleri atmak; timeout/probe/resource/topology/workload/eşik
  değiştirmek reddedildi.
- Fayda: Erken pod geçişleri kanıt kaybı veya false success oluşturmadan gözlenebilir;
  application readiness/stability sorusu aynı ölçütlerle sınanır.
- Trade-off ve sınır: Optional alan yokluğu nedenini açıklamaz ve null observation başarı
  değildir. Pinned source ve diğer D-087 koşulları değişmez. Canonical merge runtime
  yetkisi değildir; sonuç Dataset v1, D-067, incident, replacement normal veya fault
  yetkisi üretmez. D-067 15u `2/3`, 10u `1/3` kalır.

## Açık kararlar

| ID | Soru | Karar için gerekli kanıt | Hedef aşama |
|---|---|---|---|
| O-001 | Online Boutique yerel ortamda sürdürülebilir biçimde çalışıyor mu? | Yazılım smoke testi ve temiz boot host stability tekrarı geçti; uzun pencere trace export kapısı bekleniyor | P1 öncesi |
| O-002 | Hangi servis CPU-stress pilotu için en uygun? | Çözüldü: `ob-cpu-normal-002` normal-baseline karşılaştırmasıyla `recommendationservice` seçildi; checkoutservice alternatif olarak korundu | Pilot P0 |
| O-003 | Failure manifestation için ana SLO nedir? | Çözüldü: `p1-cpu-001-slo-v1`; `/product/{id}` window-p95 `>345,992 ms` veya global frontend error rate `>0`, ilgili koşul art arda 3 dolu 5 sn pencere. Boş pencere zinciri keser. Üç normal run replay'inde yanlış manifestation 0 | Pilot P1 |
| O-004 | Kaç bağımsız run gerekli? | D-064 ile model-vs-rule baseline eşlenmiş event-level karşılaştırması için 60 bağımsız pozitif incident; false-alarm tahmini için ayrıca 60 normal kontrol donduruldu. Ladder taraması bu confirmatory sayıya katılmaz | Ladder geçiş bölgesi kanıtlandıktan sonra confirmatory collection |
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
| O-017 | Proxy rollout sonrası tek canlı hedef pod kapısı termination yarışını gevşemeden nasıl beklemeli? | Çözüldü: D-046; 120/5 sn bounded tek-Ready-pod convergence, multiple/zero/not-ready negatif fixture'ları, finally host-after kaydı ve değişmeyen `ob-netdelay-15u-004` ayrı committe ön-kaydedildi | P2 live proxy stability/replacement kapısı |
| O-018 | Tek proxy pod 120 saniye boyunca neden Ready olmadı? | Çözüldü: `005` ve faultsuz server tanısı proxy'yi sürekli Ready/0 restart, server'ı CrashLoopBackOff gösterdi. Events 5 kez başarısız gRPC liveness probe sonrası kubelet restart'ını doğruladı; node pressure false ve OOMKilled yoktu | O-019 altında probe-timeout alt nedeni; replacement henüz belirlenmez |
| O-019 | Server 8080 gRPC liveness probe'u 1 saniyede neden yanıt vermedi? | Çözüldü: geçerli `002`de beş liveness kill ile CFS throttled-period 363/363 ve CPU pressure +21,271 sn eşzamanlı; OOM/memory/node pressure yok. CPU quota throttling/pressure güçlü yakın mekanizmadır, tek nihai neden iddiası değildir | Ayrı resource/probe replacement tasarım kararı; otomatik uygulanmaz |
| O-020 | 500m server CPU limiti no-toxic proxy podunu probe değişmeden kararlı kılıyor ve resource pressure'ı yeterince azaltıyor mu? | Çözüldü: valid `ob-network-resource-compat-005`; 23+34 stabil örnek, 13/13/180 sn, throttling %1,386, pressure +0,498 sn, provenance/host/rollback/19-file seal geçti | D-050 compatibility kapısı kapandı; scientific replacement ayrı açık karar/onay ister |
| O-021 | D-061 headroom hesabında yeni 500m normal baseline topology'si ve küçük örneklem belirsizlik yöntemi ne olmalı? | Çözüldü: D-067 no-toxic proxy overlay ve run-level maximum + `max(5ms, max-min range)` ölçüm payını, seed 20260821 altı-run sırasıyla sonuç görülmeden dondurdu | D-067 tooling ve altı yeni normal collection |

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
| 2026-08-15 | D-048 | Host olay kapısı System RecordId sınırına taşındı ve `ob-network-probe-resource-002` değişmeden ön-kaydedildi | Circular log retention toplam sayımı non-monotonic yaptı; olay kimliği yeni host olayını doğrudan kanıtlar ve reset fail-closed kalır |
| 2026-08-15 | D-049 | O-019 geçerli no-fault diagnostic ile kapatıldı; replacement resource/probe tasarımı ayrıldı | Beş liveness kill, 363/363 throttled CFS period ve CPU pressure eşzamanlı; OOM/memory/node pressure yok; gözlemsel kanıt tek nihai neden veya otomatik ayar yetkisi vermez |
| 2026-08-20 | D-050 | Yalnız server CPU limitini 200m'den 500m'ye çıkaran no-fault compatibility adayı ve kapıları ön-kaydedildi | Probe/request/memory sabit tutularak quota hipotezi; Ready/restart ve en az yarı throttling/pressure azalmasıyla prospektif sınanır |
| 2026-08-21 | D-061–D-066 | Mentor dönütü headroom, delay ladder, 500m baseline reset, health-path ayrımı, 60-incident örneklem ve 2026-09-15 takvim kapısı olarak bağlandı | Pahalı deneme-yanılmayı azaltmak, sistem sürümü karışmasını önlemek, lead-time geçiş bölgesini ölçmek ve veri üretmeyen fault sınıfına açık durdurma sınırı koymak |
| 2026-08-21 | D-061 / O-021 | Headroom karar-destek girdileri makine-okunur donduruldu; eligible yeni 500m normaller `0/3 + 0/3` ve topology/uncertainty seçimi açık tutuldu | Uygun olmayan tarihsel veriden sahte sayı üretmemek ve akademik yöntemi analyzer koduna gizlememek |
| 2026-08-20 | D-051 | Kubectl JSON stdout/stderr kanalları ayrıldı ve değişmeyen `ob-network-resource-compat-002` ön-kaydedildi | `001` wrapper diagnostic satırını JSON'a karıştırdı; payload-only stdout ve ayrı stderr parser sınırını korur |
| 2026-08-21 | D-058 | Raw UTC verifier iki PowerShell runtime'ında eşdeğer hale getirildi ve ilk randomize fault slotu tamamlandı; kalan 750ms bloklar D-061–D-066 ile ileriye dönük durduruldu | Tek geçerli network-delay run'ı run-arası varyans veya sıra/gün etkisini ölçmezdi; mentor kapıları daha sonra ladder, yeni baseline ve prospektif örneklem tasarımını bağladı |
| 2026-08-21 | D-059 | D-058 ilk randomize fault slotu `ob-netdelay-15u-repeat-001` olarak koşullar değişmeden ön-kaydedildi | #81 sonrası aktif deployment, profile, toxic manager ve runner kimliği ilk immutable slota bağlandı; merge canlı fault yetkisi değildir |
| 2026-08-21 | D-060 | `control-001` için no-toxic matched-interval metadata ve geçerlilik sözleşmesi fault sonucundan eşik üretmeden donduruldu | Fault runner semantiği sahte injection/physical-effect beklentisi oluşturur; kontrol aynı maruziyet altında yalnız toxic yokluğu, null manifestation ve drift'i sınamalıdır |
| 2026-08-29 | D-081 | Preserved bootstrap state-consistency tanısı ve iki tooling kapanış kapısı ön-kaydedildi | D-079 existing-config restart dalını daralttı fakat state oluşum zinciri, subprocess exit code ve bağımsız CRI listesi açık kaldı |
| 2026-08-29 | D-082 | Invalid D-081 için inspect-shape kanıtı, kesin child-process/redirect kapanışı ve benzersiz `002` replacement'ı ön-kaydedildi | `001` snapshot öncesi property-shape hatasında durdu ve ilk seal açık redirect handle nedeniyle tamamlanamadı |
| 2026-08-29 | D-082 | `002` runtime invalid/incomplete kapandı; ID yeniden kullanılamaz | Zorunlu state capture'lar shell parse hatasıyla boş kaldı; semantic verifier capture exit/stdout semantiğini denetlemedi ve helper-alias çakışması gözlendi |
| 2026-08-31 | D-083 | Native argüman sınırı, state capture semantiği ve alias-safe verifier offline fixture'larla kapatıldı | D-082'nin iki bağımsız tooling kusuru yeniden runtime yapmadan falsifiable hale getirildi; yeni diagnostic ID veya runtime yetkisi verilmedi |
| 2026-08-31 | D-084 | Benzersiz `ob-k8s-bootstrap-state-consistency-003` aynı koşullar ve D-083 fail-closed kapılarıyla ön-kaydedildi | `001/002` immutable invalid kalır; state-consistency sorusunu değiştirmeden yeniden test etmek için yeni kimlik gerekir; runtime ayrı onaylıdır |
| 2026-08-31 | D-084 | `003` geçerli operational diagnostic olarak partial existing-state tutarsızlığını iki live boundary'de doğruladı | Minikube marker setini existing-config restart için yeterli saydı; essential kubelet/control-plane dosyaları yoktu. Bu yakın mekanizma dosya kaybının nedeni veya benzersiz kök neden değildir |
| 2026-08-31 | D-085 | `ob-k8s-bootstrap-recovery-001` exact-profile clean-bootstrap recovery tanısı olarak ön-kaydedildi | D-084 mekanizma kanıtından sonra recoverability'yi application/workload/fault olmadan sınamak; merge delete veya runtime yetkisi değildir |
| 2026-08-31 | D-085 | Clean-bootstrap recovery geçerli operational diagnostic olarak tamamlandı | Exact delete/yokluk, 31/31 stability, stopped/host/verifier/12-file replay geçti; recoverability desteklenir fakat state origin veya unique cause kanıtlanmaz |

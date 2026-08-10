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

## D-031 - Kapasite kanıtında pod snapshot ve tek CPU-serisi kapısı

- Durum: **Kabul edildi teknik geçerlilik düzeltmesi; yalnız yeni run ID'ler için**
- Karar: Kapasite assessment'ı measurement öncesi/sonrası 15 deployment pod UID ve restart snapshot'larını tam olarak saklar. CPU analyzer, kaydedilmiş recommendationservice pod adı için measurement'ın ilk ve son 30 saniyesinde örnek taşıyan tam olarak bir cAdvisor counter serisi ister; sıfır veya birden fazla seri fail-closed reddedilir.
- Gerekçe: `ob-capacity-20u-001` pod-stability false sonucunun bileşen snapshot'larını saklamadı; CPU analizi eski/kısa ve aktif serileri birleştirerek 89 interval ve yorumlanamaz p95 `0m` üretti. Run bu nedenle invalid kalır.
- Alternatifler: Boolean pod sonucuna güvenmek ve CPU serilerini toplamak bağımsız denetimi bozduğu için reddedildi. Eski run'ı yeni analyzer ile kabul etmek immutable kapanışı ihlal edeceği için reddedildi.
- Fayda: Lifecycle kararlılığı hangi bileşenin değiştiğine kadar denetlenebilir; stale-series contamination workload headroom kararını etkileyemez.
- Bedel ve sınırlılık: Yeni 20-user run gerekebilir; gerçek iki tam seri varsa otomatik birleştirilmez. D-030 user adayları, eşikler, SLO ve randomizasyon değişmez.

## Açık kararlar

| ID | Soru | Karar için gerekli kanıt | Hedef aşama |
|---|---|---|---|
| O-001 | Online Boutique yerel ortamda sürdürülebilir biçimde çalışıyor mu? | Yazılım smoke testi ve temiz boot host stability tekrarı geçti; uzun pencere trace export kapısı bekleniyor | P1 öncesi |
| O-002 | Hangi servis CPU-stress pilotu için en uygun? | Çözüldü: `ob-cpu-normal-002` normal-baseline karşılaştırmasıyla `recommendationservice` seçildi; checkoutservice alternatif olarak korundu | Pilot P0 |
| O-003 | Failure manifestation için ana SLO nedir? | Çözüldü: `p1-cpu-001-slo-v1`; `/product/{id}` window-p95 `>345,992 ms` veya global frontend error rate `>0`, ilgili koşul art arda 3 dolu 5 sn pencere. Boş pencere zinciri keser. Üç normal run replay'inde yanlış manifestation 0 | Pilot P1 |
| O-004 | Kaç bağımsız run gerekli? | Pilot varyansı ve olay oranı | Dataset v1 öncesi |
| O-005 | Kullanılacak LLM ve sürüm hangisi? | Erişim, maliyet, tekrarlanabilirlik | LLM aşaması |
| O-006 | Mevcut host nasıl kararlı hale getirilecek veya hangi alternatif host kullanılacak? | Çözüldü: temiz boot, Ethernet kullanımı ve Wi-Fi’nin devre dışı bırakılması altında `P1-HOST-STABILITY-002` geçti | P1 öncesi |
| O-007 | Uzun deney pencerelerinde Jaeger trace verisi kayıpsız nasıl dışa aktarılacak? | Çözüldü: schema v3 ile 49/49 parça doğrulandı; maksimum parça 924/5000 trace | P1 öncesi |
| O-008 | CPU fiziksel-etki coverage kapısı gerçek 5 sn Prometheus scrape aralığıyla nasıl tanımlanmalı? | Çözüldü: D-018 ile her 300 sn fazda beklenen 60 gerçek aralığın en az 48'i (%80) zorunlu kılındı. `ob-cpu-low-002` invalid kaldı; değişiklik yalnız `cpu-recommendation-low-v2` ve yeni `ob-cpu-low-003` için geçerlidir | Sonraki low calibration öncesi |
| O-009 | Fault lifecycle UTC'si dış `kubectl exec` duvar saatinden mi, worker'ın gerçek başlama/tamamlanma olayından mı üretilmeli? | Çözüldü: D-021 ile worker-emitted canonical UTC fault sınırı; outer exec UTC tanısal kanıt; worker wall ve monotonic süreleri ayrı kapılar olarak seçildi | Yeni düşük CPU tekrarı öncesi |

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

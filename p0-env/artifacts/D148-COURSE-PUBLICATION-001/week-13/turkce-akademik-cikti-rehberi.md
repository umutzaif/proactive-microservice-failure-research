# D148 Türkçe Akademik Çıktı Rehberi
## Deneyden Savunulabilir Bilimsel Sonuca

**Belge türü:** Öğrenme, inceleme ve tez savunması hazırlık rehberi
**Dayanak:** D148 Week 12 venue-neutral akademik makalesi ve kanonik proje kayıtları
**Durum:** Akademik incelemeye hazır; dış gönderime hazır değil

## 1. Bu belge neden var?

Bu rehber, İngilizce akademik makalenin sözcüğü sözcüğüne çevirisi değildir. Amacı, çalışmanın ne yaptığını, hangi sonucu ürettiğini ve hangi iddiaları özellikle üretmediğini Türkçe ve denetlenebilir bir akışla açıklamaktır. Böylece yalnızca sonucu okumak değil, sonucu bir danışmana, jüriye veya teknik incelemeciye gerekçeleriyle savunmak mümkün olur.

Çalışmanın ana sonucu şudur: Test edilen iki workload ve üç CPU-stress severity düzeyinde fault fiziksel olarak uygulanmıştır; ancak 15 geçerli fault run'ın hiçbirinde önceden dondurulmuş servis seviyesi ihlali oluşmamıştır. Kısa gösterimle sonuç **0/15 manifestation** değeridir. Bu sonuç, “CPU fault hiçbir zaman servis bozulması oluşturmaz” demek değildir. Yalnızca bu host, deployment, hedef servis, workload, CPU profilleri ve SLO tanımı altında pozitif olay gözlenmediğini gösterir.

Akademik katkı yalnızca 0/15 sayısı değildir. Asıl katkı; fault isteğini, ölçülen fiziksel etkiyi, kullanıcıya yansıyan servis olayını, run geçerliliğini ve artifact yeniden üretilebilirliğini birbirinden ayıran kanıt zinciridir.

## 2. Çalışmanın büyük resmi

Araştırma Online Boutique adlı mikroservis uygulamasında yürütülmüştür. Hedef bileşen `recommendationservice` servisinin server container'ıdır. Sisteme üç düzeyde CPU yükü verilmiştir: yaklaşık +50, +100 ve +150 mCPU. Aynı fault profilleri 10 ve 15 eşzamanlı kullanıcı workload'larında değerlendirilmiştir.

Araştırma soruları üç parçadır:

1. **Fiziksel etki:** Düşük, orta ve yüksek CPU profilleri gerçekten ölçülebilir ve birbirinden ayrılabilir bir CPU artışı oluşturuyor mu?
2. **Servis manifestation:** Geçerli fault run'larında dondurulmuş SLO olayı oluşuyor mu; oluşuyorsa pozitif lead time var mı?
3. **Kanıt yönetişimi:** Geçerli ve geçersiz denemeler ayrıştırılabiliyor, sonuçlar deterministik olarak denetlenebiliyor ve eksik yeniden üretilebilirlik katmanları açıkça görülebiliyor mu?

Bu sorular birbirine bağlıdır fakat aynı şey değildir. Bir injector komutunun başarılı dönmesi, CPU tüketiminin gerçekten arttığını kanıtlamaz. CPU tüketiminin artması da kullanıcıya yansıyan bir SLO ihlalini kendiliğinden kanıtlamaz. SLO ihlali görülmesi ise run geçersizse bilimsel paydaya eklenemez.

## 3. Temel kavramlar

| Kavram | Bu çalışmadaki anlamı | Neden önemli? |
|---|---|---|
| Attempt | Benzersiz kimlikle başlatılmış deney denemesi | Başlatılan her işin görünür kalmasını sağlar |
| Run | Protokolün ölçüm yaşam döngüsünü izleyen deney yürütümü | Bilimsel değerlendirme birimi için adaydır |
| Valid | Kimlik, host, lifecycle, fiziksel etki ve sonuç kapılarını geçen run | Bilimsel paydaya girebilir |
| Invalid | Zorunlu kapılardan en az birini geçemeyen attempt | Silinmez; fakat etki paydasına eklenmez |
| Fault actuation | Hedef container'da ölçülen CPU artışı | Fault isteğinin fiziksel olarak gerçekleştiğini gösterir |
| SLO manifestation | Önceden dondurulmuş kullanıcıya dönük ihlal olayı | Pozitif incident etiketinin gerçek dayanağıdır |
| Lead time | Uyarı ile doğrulanmış manifestation arasındaki süre | Erken uyarı başarısının temel ölçülerinden biridir |
| Receipt replay | Run arşivinin receipt ve SHA manifestiyle bağımsız doğrulanması | En güçlü artifact provenance katmanını sağlar |

### 3.1 Valid ile başarılı aynı şey değildir

“Valid” sözcüğü deney protokolünün doğru yürütüldüğünü belirtir. Bir fault run valid olabilir ve yine de SLO manifestation üretmeyebilir. Bu durumda run geçerli bir negatif gözlemdir. “Başarılı” sözcüğünü kullanmak yanıltıcı olabilir; çünkü injector, fiziksel etki ve servis sonucu için ayrı başarı ölçütleri vardır.

### 3.2 Invalid veri neden silinmez?

Invalid attempt'ler operasyonel sorunları ve seçim sürecini görünür tutar. Bunları silmek, yalnızca iyi görünen örnekleri bırakma riskini doğurur. Bununla birlikte invalid attempt'leri bilimsel sonuç paydasına katmak da yanlıştır; çünkü bunlar uygun gözlem üretmemiş olabilir. Doğru yaklaşım, invalid kayıtları korumak fakat geçerli treatment sonucu gibi yorumlamamaktır.

## 4. Deney sözleşmesi

### 4.1 Workload

İki sürümlü workload kullanılmıştır: 10 ve 15 eşzamanlı sanal kullanıcı. Her ikisinde Locust 2.43.0, saniyede bir kullanıcı spawn oranı, 1–10 saniye uniform bekleme ve random seed 1 kullanılmıştır. İki workload arasındaki planlı fark kullanıcı sayısıdır.

Her run 300 saniye warm-up ve 300 saniye normal baseline içerir. Fault run'ında bunlara 120 saniye ramp, 300 saniye steady fault ve 300 saniye cooldown eklenir. Böylece değerlendirme, tek bir anlık metrik yerine tanımlı fazlara dayanır.

### 4.2 Treatment ve güvenlik

Hedef container'ın CPU limiti 200 mCPU'dur. Low, medium ve high profilleri yaklaşık +50, +100 ve +150 mCPU ek yük istemiştir. Yük, 100 ms duty-cycle kullanan ve container içinde çalışan Python worker ile üretilmiştir. Worker süresi sınırlıdır; otomatik sonlanma, başlangıç ve tamamlanma olayları zorunludur.

### 4.3 Fiziksel etki kapısı

Prometheus ölçümleri fault'un gerçekten hedefte oluşup oluşmadığını bağımsız olarak sınar. Baseline ve steady fazlarının her birinde, beklenen 60 adet beş saniyelik aralıktan en az 48 bitişik gerçek scrape aralığı bulunmalıdır. Ayrıca steady eksi baseline ortalama CPU artışı low için en az 25, medium için en az 50 ve high için en az 75 mCPU olmalıdır.

Bu kapının mantığı basittir: injector “çalıştım” dese bile yeterli ölçüm coverage'ı veya beklenen CPU artışı yoksa run, fiziksel treatment kanıtı sayılmaz.

### 4.4 Dondurulmuş SLO manifestation

Servis olayı beş saniyelik, çakışmayan pencerelerle değerlendirilmiştir. Manifestation için iki yoldan biri üç ardışık dolu pencerede gerçekleşmelidir:

1. Product-detail ailesi p95 latency değeri 345,992 ms sınırını aşar.
2. Global kullanıcı-route error rate değeri sıfırdan büyük olur.

Boş pencere zinciri keser. Eşik ve ardışık-pencere kuralı sonuçlara bakılmadan önce dondurulmuştur. Bu sayede sonuç görüldükten sonra eşiği değiştirerek pozitif olay üretme olasılığı azaltılmıştır.

## 5. Deney muhasebesi: 35, 21 ve 14 ne demek?

| Grup | Sayı | Bilimsel kullanımı |
|---|---:|---|
| Toplam attempt | 35 | Tüm yürütüm geçmişi ve seçim paydası |
| Valid normal control | 6 | Normal davranışın kabul edilen gözlemleri |
| Valid fault run | 15 | Fiziksel etki ve manifestation paydası |
| Toplam valid | 21 | Kanonik olarak kabul edilen run'lar |
| Invalid attempt | 14 | Operasyonel provenance; treatment sonucu değildir |

`21/35` oranı treatment başarı oranı değildir. Bu oran yalnızca geçerlilik muhasebesidir. On dört invalid attempt'in ikisi invalid normal baseline, beşi actuation öncesinde duran fault attempt'i, yedisi ise daha sonraki lifecycle, fiziksel etki veya finalization sorunlarıdır. Bu açıklama yeni bilimsel etiket üretmez; hataların yaşam döngüsündeki yerini anlaşılır kılar.

**Ne anlama gelir?** Sonuçların hangi gözlemlerden üretildiği izlenebilir. 15 fault run, SLO manifestation için doğru bilimsel paydayı oluşturur.

**Ne anlama gelmez?** 14 invalid kayıt fault'un başarısız olduğu anlamına gelmez; çünkü bazıları treatment'a hiç ulaşmamıştır. Aynı şekilde 21 valid kayıt da pozitif olay demek değildir.

**Nasıl doğrulanır?** `results_registry.md` içindeki kanonik statüler ile Week 12 türetme ve doğrulama script'lerinin ürettiği attempt tablosu karşılaştırılır.

## 6. Fiziksel CPU actuation sonuçları

| Workload | Severity | n | Ortalama mCPU artışı | Örneklem SS | CV | Gözlenen aralık mCPU |
|---|---|---:|---:|---:|---:|---:|
| 10 kullanıcı | Low | 3 | 50,349 | 1,801 | %3,576 | 48,463–52,050 |
| 10 kullanıcı | Medium | 3 | 99,649 | 4,930 | %4,947 | 93,994–103,042 |
| 10 kullanıcı | High | 3 | 146,941 | 3,313 | %2,254 | 143,819–150,416 |
| 15 kullanıcı | Low | 2 | 51,098 | 2,751 | %5,384 | 49,153–53,044 |
| 15 kullanıcı | Medium | 2 | 93,987 | 0,661 | %0,704 | 93,519–94,454 |
| 15 kullanıcı | High | 2 | 140,435 | 7,460 | %5,312 | 135,160–145,710 |

Her iki workload düzeyinde ortalamalar low'dan high'a sıralıdır. Coverage ve magnitude kapılarıyla birlikte bu gözlem, sürümlü profillerin kabul edilen run'larda ayrışan fiziksel actuation ürettiğini betimsel olarak destekler.

**Ne anlama gelir?** Fault mekanizması hedef container'da ölçülebilir bir CPU artışı oluşturmuştur. Low, medium ve high profilleri beklenen sırayı korumuştur.

**Ne anlama gelmez?** Küçük hücrelerde n değeri iki veya üçtür. Standart sapma, CV ve aralık güven aralığı değildir. Tablo istatistiksel anlamlılık, eşdeğerlik, nedensel SLO etkisi veya üretim ortamlarına genelleme kanıtlamaz.

**Nasıl doğrulanır?** Her valid run'ın steady ve baseline CPU özetleri yeniden türetilir; farkların tablo hücreleri ve fiziksel etki eşikleriyle uyumu denetlenir.

## 7. Neden 0/15 bilimsel olarak önemlidir?

On beş geçerli fault run'ın hiçbirinde dondurulmuş SLO manifestation oluşmamıştır. Bu nedenle sonuç `0/15` olarak raporlanır. Bu, treatment fiziksel olarak oluşmasına rağmen hedeflenen kullanıcıya dönük olayın gözlenmediğini gösterir.

Bu negatif gözlem araştırma açısından değerlidir. Pozitif incident yokken injection pencerelerini “pozitif” diye etiketlemek, ölçmek istediğimiz servis olayını treatment işaretiyle değiştirir. Böyle bir relabeling model eğitmeye izin verebilir; fakat model gerçekte SLO olayını değil, injector zamanını öğrenir. Çalışma bu metodolojik hatayı engellemiştir.

**Savunulabilir cümle:** “Test edilen koşullarda, 15 geçerli fault run'ın hiçbirinde dondurulmuş SLO olayı gözlenmedi.”

**Savunulamaz cümle:** “CPU fault'ları servis performansını etkilemez.”

İkinci cümle neden savunulamaz? Çalışma tek host, tek deployment, tek hedef servis, iki workload ve üç profil ile sınırlıdır. Hücre büyüklükleri küçüktür. Ayrıca dondurulmuş SLO daha küçük veya farklı türdeki kullanıcı etkilerini yakalamıyor olabilir.

## 8. Lead time ve model neden hesaplanmadı?

Lead time, erken uyarının doğrulanmış servis olayından ne kadar önce geldiğini ölçer. Paydanın pozitif incident olması gerekir. 0/15 manifestation olduğunda doğrulanmış pozitif interval yoktur; dolayısıyla lead-time dağılımı, recall, precision veya model-versus-rule karşılaştırması hesaplanamaz.

Bu nedenle proje bir tahmin modelinin başarılı ya da başarısız olduğunu iddia etmez. Henüz model eğitilmemiş ve değerlendirilmemiştir. Bu bir eksik hesaplama değil, yanlış bilimsel çıkarımı engelleyen fail-closed karardır.

Gelecekteki confirmatory hedef D-064 altında 60 bağımsız pozitif incident ve ayrıca false-alarm tahmini için 60 bağımsız normal control'dür. Bir run içindeki çok sayıda pencere, bağımsız incident sayısını yapay biçimde büyütmek için kullanılamaz.

## 9. Yeniden üretilebilirlik: 0/21 receipt ne demek?

Çalışmanın tracked-evidence katmanı mevcuttur: kanonik kayıtlar, sürümlü konfigürasyonlar, run raporları, türetilmiş tablolar ve deterministik doğrulayıcılar denetlenebilir. Buna karşın 21 valid run için beklenen bağımsız receipt ve SHA-manifest çiftlerinden hiçbiri mevcut değildir. Bu yüzden receipt düzeyi `0/21` olarak raporlanır.

**Ne anlama gelir?** Repository içindeki iddia ve sayıların tutarlılığı yeniden kontrol edilebilir; fakat özgün run arşivinin eksiksiz byte-level provenance replay'i yapılamaz.

**Ne anlama gelmez?** 0/21, bütün çalışmanın değersiz veya doğrulanamaz olduğu anlamına gelmez. Yeniden üretilebilirliğin farklı katmanları vardır. Tracked katman geçerken daha güçlü receipt katmanı eksik kalabilir.

**Neden önemlidir?** “Reproducible” sözcüğünü tek bir evet/hayır etiketi olarak kullanmak yerine, hangi katmanın geçtiğini ve hangisinin eksik olduğunu açıkça gösterir. Bu dürüst sınır, akademik güvenilirliği artırır.

## 10. Network-delay çalışması neden bu sonuca katılmadı?

D-147, network-delay normal collection çalışmasını 3/6 düzeyinde durdurmuştur. Replacement slot `null` kalmıştır ve yeni bir normal veya bilimsel network-delay sonucu yetkilendirilmemiştir. Bu operasyonel akış CPU çalışmasının sonuçlarıyla birleştirilemez.

Network-delay hazırlığının eksik kalması, CPU çalışmasındaki 0/15 sonucu değiştirmez. Aynı şekilde CPU sonucu da network-delay fault sınıfının etkili veya etkisiz olduğunu göstermez. İki fault sınıfının kanıt ve yetki sınırları ayrıdır.

## 11. Tamamlananlar ve açık kalanlar

| Başlık | Durum | Doğru yorum |
|---|---|---|
| CPU physical actuation | Tamamlandı | İki workload ve üç severity için betimsel olarak sıralı etki var |
| Frozen-SLO manifestation | Tamamlandı | 15 valid fault run'da 0 manifestation |
| Geçerlilik muhasebesi | Tamamlandı | 35 attempt, 21 valid, 14 invalid ayrımı korunuyor |
| Tracked-evidence replay | Tamamlandı | Kanonik kaynaklar ve türetmeler deterministik denetlenebiliyor |
| Receipt-level replay | Açık | Beklenen 21 çiftin 0'ı mevcut |
| Positive lead-time analizi | Yapılamaz | Pozitif manifestation yok |
| Tahmin modeli değerlendirmesi | Yapılmadı | Uygun pozitif incident seti yok |
| Network-delay bilimsel sonucu | Yok | D-147 3/6 düzeyinde durdu; bu makaleye dahil değil |
| Dış gönderim | Yetkisiz | Venue, anonymity, yazar bilgisi ve submission kararı açık |

Mevcut paket **academic_review_ready_but_not_submission_ready** durumundadır. Bu ifade, içerik ve kanıt sınırlarının akademik inceleme için yeterince düzenli olduğunu; fakat konferans veya dergiye doğrudan gönderim için henüz venue-specific biçim, yazar/anonymity kararı, receipt katmanı ve ayrı dış iletişim yetkisi bulunmadığını belirtir.

## 12. Sık yapılan yanlış yorumlar

### 12.1 “Fault komutu geçtiyse deney pozitiftir.”

Yanlıştır. Komut sonucu yalnızca isteğin kabul edildiğini gösterebilir. Fiziksel CPU etkisi Prometheus ölçümleriyle, servis olayı ise dondurulmuş SLO ile ayrı ayrı doğrulanır.

### 12.2 “0/15, CPU fault etkisizdir demektir.”

Yanlıştır. Sonuç yalnızca test edilen kapsam için negatif gözlemdir. İstatistiksel eşdeğerlik veya evrensel etkisizlik kanıtı değildir.

### 12.3 “Invalid attempt'ler kötü sonucu saklamak için çıkarıldı.”

Yanlıştır. Invalid kayıtlar silinmemiştir ve 35 attempt paydasında görünürdür. Ancak protokol kapılarını geçmedikleri için treatment etkisi paydasına alınmazlar.

### 12.4 “Çok sayıda beş saniyelik pencere, çok sayıda bağımsız örnektir.”

Yanlıştır. Aynı run içindeki pencereler ortak host, treatment ve lifecycle koşullarını paylaşır. Bunları bağımsız incident gibi saymak örneklem büyüklüğünü yapay olarak şişirir.

### 12.5 “Verifier geçtiyse özgün runtime tamamen yeniden üretildi.”

Yanlıştır. Verifier tracked dosyaların ve türetmelerin tutarlılığını kanıtlar. Eksik receipt arşivlerini geri getiremez ve özgün çalışma ortamının tam byte-level replay'ini kanıtlamaz.

## 13. Bağımsız doğrulama ve yanlışlama planı

1. `results_registry.md` içinden 35 benzersiz attempt'in 21 valid ve 14 invalid olarak ayrıldığını kontrol edin.
2. On beş valid fault run'ın raporlarında workload, severity, hedef container, lifecycle ve physical-effect kapılarını karşılaştırın.
3. Altı hücrenin CPU farklarını kaynak run özetlerinden yeniden hesaplayın; ortalama, örneklem standart sapması, CV ve aralığı doğrulayın.
4. Frozen SLO eşiklerini `experiment_protocol.md` ile karşılaştırın; sonuç sonrası eşik değişikliği olmadığını kontrol edin.
5. Valid fault raporlarında manifestation sayısının gerçekten 0/15 olduğunu doğrulayın.
6. Receipt envanterinde 21 beklenen çiftin mevcut olmadığını ve bu eksikliğin metadata ile makalede aynı biçimde bildirildiğini kontrol edin.
7. D-147 kaydından network-delay normal collection'ın 3/6 düzeyinde durduğunu ve CPU sonucu ile birleştirilmediğini doğrulayın.
8. Week 12 ve Week 13 verifier'larını temiz checkout'ta çalıştırın. Bir sayı veya sınır değiştirilirse doğrulamanın fail-closed durduğunu gözlemleyin.

Yanlışlama açısından en güçlü test, aynı protokole bağlı kaynaklardan farklı attempt sayısı, farklı manifestation sayısı veya tablo değerleri üretmektir. Böyle bir çelişki bulunursa rehber değil, önce kanonik kaynak ve türetme zinciri incelenmelidir.

## 14. Savunma soruları ve kısa yanıtlar

### Soru 1: Çalışmanın en önemli metodolojik katkısı nedir?

Fault isteği, fiziksel actuation, servis manifestation, run validity ve artifact replay katmanlarını ayrı sözleşmelerle değerlendirmesidir. Böylece injector başarısı yanlışlıkla kullanıcı etkisi olarak etiketlenmez.

### Soru 2: 0/15 neden “başarısız deney” değildir?

Çünkü treatment fiziksel olarak doğrulanmış ve sonuç kapısı önceden tanımlanmıştır. Pozitif olayın oluşmaması, test edilen kapsam için geçerli negatif gözlemdir ve sonraki model iddialarını doğru biçimde sınırlar.

### Soru 3: Neden model eğitmediniz?

Pozitif SLO incident'i yoktur. Injection pencerelerini pozitif diye yeniden etiketlemek hedef kavramı değiştirirdi. Model performansı için prospektif ve bağımsız pozitif incident'ler gerekir.

### Soru 4: 21/35 neyi ölçer?

Geçerlilik muhasebesini ölçer. Treatment success rate veya manifestation rate değildir. Manifestation paydası 15 valid fault run'dır.

### Soru 5: 0/21 receipt varken çalışma nasıl denetlenebilir?

Kanonik kayıtlar, tracked raporlar ve deterministik türetmeler repository katmanında denetlenebilir. Ancak daha güçlü arşiv-provenance replay'i yapılamaz; bu sınırlılık açıkça raporlanır.

### Soru 6: Sonuçları neden genelleyemiyorsunuz?

Çünkü kanıt tek host, tek yerel deployment, tek hedef servis, iki workload ve üç CPU profiliyle sınırlıdır. Üretim cluster'ları, başka servisler ve başka fault sınıfları ölçülmemiştir.

### Soru 7: Network delay neden makalede sonuç değildir?

D-147 normal collection 3/6 düzeyinde durmuştur ve replacement yoktur. Eksik operasyonel hazırlık, bilimsel network-delay sonucu veya CPU kanıtına ek veri olarak yorumlanamaz.

### Soru 8: Gelecekte model değerlendirmek için ne gerekir?

Prospektif olarak yönetilen en az 60 bağımsız pozitif incident, 60 bağımsız normal control, dondurulmuş feature pencereleri ve aynı incident'ler üzerinde proposed-model-versus-rule-baseline eşlenmiş değerlendirmesi gerekir.

## 15. Bu adımdan hangi bilgiyi kazandım?

Bu adım sonunda şu somut bilgileri kazanmış olmalısınız:

1. Bir fault isteğinin, ölçülen fiziksel etkinin ve kullanıcıya yansıyan servis olayının farklı kanıtlar olduğunu açıklayabilirsiniz.
2. `35 attempt = 21 valid + 14 invalid` muhasebesinin neden treatment başarı oranı olmadığını savunabilirsiniz.
3. 0/15 sonucunu kapsamı aşmadan yorumlayabilir ve “etki yoktur” iddiasından ayırabilirsiniz.
4. Pozitif incident olmadan lead time veya model performansı hesaplamanın neden bilimsel olarak geçersiz olduğunu açıklayabilirsiniz.
5. Tracked-evidence doğrulaması ile receipt-level replay arasındaki farkı ve 0/21 sınırlılığını anlatabilirsiniz.
6. D-147 network-delay 3/6 stop kaydının neden CPU makalesine bilimsel sonuç olarak katılamayacağını gösterebilirsiniz.
7. Mevcut paketin neden akademik incelemeye hazır fakat dış gönderime hazır olmadığını gerekçelendirebilirsiniz.

## 16. Sonuç

Çalışma, CPU-stress profillerinin kabul edilen run'larda ölçülebilir ve sıralı fiziksel actuation ürettiğini; buna karşın 15 valid fault run'da dondurulmuş SLO manifestation oluşmadığını göstermektedir. Bu kanıt, tahmin modeli, nedensel etki, istatistiksel eşdeğerlik veya dış geçerlilik iddiası desteklemez.

En güçlü akademik çıktı, sınırı açık bir sonuçtur: Nelerin başarıyla uygulandığı, hangi servis olayının oluşmadığı, invalid attempt'lerin neden kaybolmadan payda dışında tutulduğu ve gelecekteki iddiaların hangi kanıtlar gelene kadar kapalı kaldığı savunulabilir durumdadır.

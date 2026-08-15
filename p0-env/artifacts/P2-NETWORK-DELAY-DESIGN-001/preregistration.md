# P2-NETWORK-DELAY-DESIGN-001 karar-desteği ön-kaydı

## Amaç ve kapsam

Bu aşama bilimsel fault run değildir ve dataset üretmez. Amaç, kademeli network
delay için hedef çağrı kenarını, izolasyon yöntemini, fiziksel-etki ölçümünü ve
failure-manifestation sözleşmesini sonuç görülmeden seçebilecek kanıtı üretmektir.
Bu belge herhangi bir injector komutunu, delay büyüklüğünü veya bilimsel run ID'sini
yetkilendirmez.

CPU stress, P1'de geçerli fault manifestation `0/15` olduğu için erken-tahmin
sınıfından çıkarılıp mevcut kanıtıyla RCA-only sınıf olarak korunur. Eski run'lar,
SLO ve etiketler değiştirilmez.

## Bağlayıcı karar-desteği soruları

1. Hangi caller-to-callee edge, her iki geçerli workload seviyesinde yeterli ve
   düzenli kullanıcı-yolu trafiği taşır?
2. Delay yalnız seçilen edge/yön üzerinde nasıl uygulanır ve kaldırıldığı nasıl
   bağımsız doğrulanır?
3. Injector başarısından ayrı fiziksel etki hangi sealed metric/trace ölçümüyle
   kanıtlanır?
4. Delay rampı, `first_symptom` ve `failure_manifestation` zamanlarını birbirine
   eşitlemeden nasıl kaydeder?
5. Mevcut frozen CPU SLO'su network delay için semantik olarak uygun mu; değilse
   yalnız normal veriyle yeni sürüm nasıl dondurulur?

## Aday edge seçim kapısı

Adaylar sealed geçerli normal run'lardan çıkarılır. Bir edge ancak aşağıdakilerin
tamamını sağlarsa kısa listeye girer:

- iki workload seviyesinde de kullanıcı-yolu trace'lerinde gözlenmesi;
- caller ve callee servis/operation kimliğinin trace'te ayrılabilmesi;
- 5 saniyelik pencerelerde traffic coverage ve normal latency dağılımının
  raporlanabilmesi;
- health-check/telemetry trafiğinden ayrılabilmesi;
- tek edge delay'inin beklenen kullanıcı rotasıyla nedensel bağının açıklanabilmesi.

Mevcut kanıt yalnız başlangıç adayları verir: yoğun
`recommendationservice -> productcatalogservice` çağrıları ve frontend'in yoğun
downstream çağrıları. Bu belge hedef edge seçmez; tüm geçerli normal set üzerinde
yeniden analiz gerekir.

## İzolasyon yöntemi karar kapısı

En az şu seçenekler fault uygulanmadan değerlendirilir:

- pod network namespace'inde `tc netem`: doğrudan fakat `NET_ADMIN`, pod güvenlik
  bağlamı ve hedef-kimlik sürekliliği riski taşır;
- açık proxy/toxic katmanı: delay durumunu sorgulanabilir ve geri alınabilir kılar,
  fakat adres/config rollout'u ve proxy overhead normal kontrolü gerektirir;
- service-mesh fault injection: kapsamlı fakat yeni altyapı ve karıştırıcı değişken
  maliyeti nedeniyle ancak ilk iki seçenek güvenli değilse değerlendirilir.

Seçilen yöntem; privilege yüzeyi, yalnız hedef edge'e izolasyon, deterministik ramp,
UTC lifecycle kanıtı, cleanup doğrulaması, pod continuity, yanlış hedef negatif testi
ve immutable evidence desteğiyle gerekçelendirilir.

## Bilimsel ön-kayıt öncesi zorunlu çıktılar

- iki workload'u kapsayan edge-density ve normal-latency raporu;
- seçilen injector mimarisi ve tehdit/izolasyon analizi;
- fault içermeyen pozitif/negatif tooling testleri;
- fiziksel-etki metriği ile coverage ve minimum-effect eşiğinin normal/kalibrasyon
  kanıtından prospektif seçimi;
- network-delay'e özgü SLO/manifestation normal replay'i;
- lifecycle, target stability, host-health, active run-ID, schema-v3, receipt ve
  cleanup kapılarının makine-okunur sözleşmesi;
- benzersiz run ID, workload, seed, hedef edge, delay rampı ve süreleri içeren ayrı
  bilimsel ön-kayıt.

Bu çıktılar canonical `main` üzerine merge edilmeden ve ayrıca yürütme onayı
verilmeden network delay fault başlatılmaz. Model, LLM veya GAT çalıştırılmaz.

## Bağımsız doğrulama ve falsifikasyon

- Aynı sealed normal girdilerle edge sıralaması yeniden üretilebilmelidir.
- Yanlış edge, eksik workload, birden fazla aktif target veya privilege/cleanup
  belirsizliği fail-closed reddedilmelidir.
- Injector durum kanıtı ile trace/metric fiziksel etki birbirinden bağımsız olmalıdır.
- Cleanup sonrası residual delay negatif kontrolü geçmezse tooling/run invalid
  korunmalı ve aynı run ID yeniden kullanılmamalıdır.

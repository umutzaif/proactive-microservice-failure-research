# P2-NETWORK-DELAY-PROXY-LIVE-001 ön-kaydı

## Amaç ve yetki sınırı

Bu aşama, D-041'de seçilen Toxiproxy sidecar overlay'inin canlı kümede **toxic
oluşturmadan** ölçülebilir overhead, pod sürekliliği ve deterministik rollback
özelliklerini doğrular. Dataset üretmez, scientific run değildir ve network-delay
fault'u başlatmaz. Operasyonel kanıt kimliği `ob-network-proxy-live-001` yalnız bu
kapı için bir kez kullanılır.

## Dondurulmuş koşullar

- workload: `ob-second-15u-1r-v1`; 15 kullanıcı, spawn rate 1, seed 1;
- base warmup: 300 saniye;
- base ölçüm: 300 saniye;
- no-toxic proxy rollout sonrası stabilizasyon: 120 saniye;
- no-toxic proxy ölçümü: 300 saniye;
- hedef edge: `recommendationservice -> productcatalogservice`;
- proxy API durumu: `enabled=true`, `toxics=[]`;
- metric/trace adımı: 5 saniye; schema-v3 trace chunk: 300 saniye.

## Sonuçtan önce dondurulan kabul kapıları

1. Başlangıçta WHEA Event 17, Kernel-Power 41 ve bugcheck snapshot'ı alınır; Docker,
   Minikube, bütün deployment'lar, active run ID, workload ve telemetry hazırdır.
2. Base ve proxy ölçüm pencerelerinin her birinde hedef edge için en az 48 dolu
   5 saniyelik pencere bulunur.
3. Proxy ölçümündeki hedef-edge caller client-span median latency eksi base median
   latency en fazla `5 ms` olur. Bu eşik no-toxic veri görülmeden seçilmiştir.
4. Proxy API her sorguda doğru name/listen/upstream, `enabled=true` ve `toxics=[]`
   döndürür; fault/toxic oluşturma çağrısı yapılmaz.
5. Her ölçüm penceresi içinde recommendationservice pod UID ve bütün container
   restart sayıları sabit kalır. Base-to-proxy UID değişimi beklenen kontrollü
   rollout olarak ayrıca kaydedilir.
6. Dondurulmuş `p2-network-delay-001-slo-v1` proxy ölçümünde failure manifestation
   üretmez; global kullanıcı-route error guard ihlal edilmez.
7. Rollback sonunda recommendationservice yalnız base `server` container'ına,
   `PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice:3550` değerine döner;
   `network-delay-proxy-config` ConfigMap'i ve residual sidecar kalmaz.
8. Host kapanış farkları WHEA Event 17, Kernel-Power 41 ve bugcheck için sıfırdır.

Herhangi bir kapı başarısız olursa kanıt silinmez veya aynı kimlikle tekrarlanmaz;
kapı `invalid` olarak kapanır. Eşik sonuçtan sonra değiştirilmez. Geçiş yalnız canlı
proxy compatibility bilgisidir; scientific run, fault yürütmesi, model, LLM veya
GAT için otomatik yetki vermez.

## Alternatifler ve gerekçe

Yalnız API'de `toxics=[]` kontrolü proxy'nin kullanıcı yoluna eklediği maliyeti
ölçmez. İlk scientific fault run'ında aynı kontrolü yapmak ise proxy overhead ile
fault etkisini karıştırır. Bu nedenle aynı host ve workload altında ardışık base ve
no-toxic proxy pencereleri, trace tabanlı edge ölçümü ve bağımsız rollback kanıtı
birlikte kullanılır. Ardışık tasarım zaman drift'ine açıktır; bu sınırlılık sonuçta
raporlanır ve tek gözlem population truth sayılmaz.

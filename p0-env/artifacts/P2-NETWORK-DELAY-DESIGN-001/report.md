# P2-NETWORK-DELAY-DESIGN-001 kapanış raporu

## Sonuç

Durum: **completed design/tooling gate; dataset dışı; scientific fault yok**.

Altı sealed ve geçerli normal run (`ob-cpu-normal-002/003/004` ve
`ob-cpu-15u-normal-001/003/004`) iki workload düzeyinde yeniden analiz edildi.
`recommendationservice -> productcatalogservice` edge'i 6/6 run'da ve iki
workload'ta gözlendi; 3.872 caller-side client span ve run başına en az `%98`
dolu 5 saniyelik normal-baseline pencere coverage'ı sağladı.

## Dondurulan tasarım

- Hedef: yalnız `recommendationservice -> productcatalogservice` çağrı yönü.
- İzolasyon: recommendationservice pod network namespace'inde ayrıcalıksız,
  digest-pinned Toxiproxy sidecar; yalnız `PRODUCT_CATALOG_SERVICE_ADDR`
  `127.0.0.1:3551` adresine yönlendirilir.
- Profil: `network-delay-recommendation-productcatalog-v1`; downstream latency,
  jitter `0`, toxicity `1`, hedef `750 ms`, 10 saniyelik ramp güncellemesi.
- Lifecycle: `300/300/120/300/300` saniye.
- Fiziksel etki: baseline ve steady için ayrı ayrı en az 48 dolu hedef-edge
  penceresi; steady eksi baseline median caller client-span latency en az `500 ms`.
- İlk semptom: hedef-edge window-p95 `>116,942 ms`, art arda iki dolu 5 saniyelik
  pencere. Eşik altı normal run hedef-edge window-p95 dağılımının p99'udur; altı
  normal replay'in hiçbirinde iki ardışık ihlal oluşmadı.
- Failure manifestation: ürün-detay route window-p95 `>594,664 ms` veya global
  kullanıcı-route error rate `>0`, art arda üç dolu 5 saniyelik pencere. Normal
  replay'de yanlış manifestation `0/6` run'dır.

## Injector ve cleanup doğrulaması

`tc netem`, mevcut pod güvenlik sınırında `NET_ADMIN` gerektirdiği için seçilmedi.
Service mesh daha geniş altyapı ve karıştırıcı değişken eklediği için ilk seçenek
olmadı. Proxy seçimi hedef edge'i ortam değişkeni düzeyinde sınırlar, API'den toxic
durumunu geri okumaya ve `/reset` sonrasında `toxics=[]` kontrolüne izin verir.

Overlay pozitif fixture'ı geçti; privilege/`NET_ADMIN` ve önceden toxic içeren
overlay negatif fixture'ları reddedildi. Cleanup yöneticisi temiz durum, residual
toxic, reset ve yanlış upstream fixture'larında fail-closed çalıştı. Kubernetes
overlay'i uygulanmadan render edildi. Pinned Toxiproxy 2.12.0 imajı geçici localhost
container'ında, toxic oluşturmadan gerçek API üzerinden doğrulandı ve kapatıldı.
İlk `-host=0.0.0.0` denemesi imaj entrypoint'i tarafından yanlış ayrıştırıldığı için
API başlamadı; argümanlar ayrı tokenlara çevrildi ve gerçek-imaj kontrolü geçti.

## Sınırlar ve sonraki kapı

Bu aşama bilimsel run ID üretmez, deployment'a overlay uygulamaz ve fault başlatmaz.
Profilde `scientific_run_authorized=false`, `scientific_run_id=null` kalır. Sonraki
aşama önce fault içermeyen canlı overlay/proxy-overhead ve pod sürekliliği
doğrulamasıdır. Ancak bu kanıt canonical `main` üzerine merge edildikten ve ayrı
aşama açıkça onaylandıktan sonra bilimsel ön-kayıt hazırlanabilir. Model, LLM ve GAT
çalıştırılmadı.

## Bağımsız doğrulama

```powershell
python p0-env/scripts/test-network-delay-edge-candidates.py
python p0-env/scripts/test-network-delay-proxy-overlay.py
python p0-env/scripts/test-network-delay-proxy-manager.py
python p0-env/scripts/test-network-delay-design-verifier.py
python p0-env/scripts/verify-network-delay-design.py --output p0-env/artifacts/P2-NETWORK-DELAY-DESIGN-001/design-verification.json
```

`design-verification.json` 18/18 kapıyı ve `scientific_fault_started=false`
durumunu doğrular. Normal kaynaklar, edge coverage, ilk-semptom normal replay'i,
SLO replay'i, proxy/overlay bağı, fiziksel-etki kontratı ve scientific-run
yetkisizliği birbirinden ayrı kontrollerdir.

# P2-NETWORK-DELAY-PROXY-LIVE-001 kapanış raporu

## Sonuç

Durum: **valid operational compatibility gate; dataset dışı; scientific fault yok**.

`ob-network-proxy-live-001`, `ob-second-15u-1r-v1` altında 15 kullanıcı, spawn
rate 1 ve seed 1 ile bir kez yürütüldü. Base warmup/ölçüm ve no-toxic proxy
stabilizasyon/ölçüm süreleri sırasıyla `300,386 / 300,370 / 120,164 / 300,410`
saniyedir. Toxiproxy API hem ölçüm öncesinde hem sonrasında `enabled=true` ve
`toxics=[]` döndürdü; toxic veya network-delay fault oluşturulmadı.

## Ölçülmüş overhead ve coverage

- target edge: `recommendationservice -> productcatalogservice`;
- base: 760 caller client span, 60/60 dolu 5 saniyelik pencere, median `4,136 ms`,
  p95 `13,685 ms`, p99 `99,223 ms`;
- no-toxic proxy: 786 span, 60/60 dolu pencere, median `4,4775 ms`, p95
  `14,949 ms`, p99 `90,874 ms`;
- paired median overhead: `+0,3415 ms`;
- ön-kayıtlı üst sınır: `<=5 ms`; kapı geçti.

Proxy penceresinde frozen network-delay SLO'su için maksimum latency violation
streak `1`, error violation streak `1` oldu. Her ikisi de gerekli üç ardışık
pencerenin altındadır; failure manifestation oluşmadı.

## Lifecycle, izolasyon ve rollback

Base ve proxy ölçüm pencerelerinin her birinde bütün pod UID/restart snapshot'ları
sabit kaldı. Base-to-proxy geçişinde yalnız recommendationservice pod UID'si
kontrollü rollout ile değişti; server ve `network-delay-proxy` restart sayıları
proxy ölçümünde sıfırdı. Apply çıktısında currencyservice, paymentservice ve
productcatalogservice `configured` görünse de tam pod snapshot karşılaştırmasında
bu deployment'ların pod UID/restart değerleri değişmedi.

Rollback sonunda recommendationservice yalnız `server` container'ına ve
`PRODUCT_CATALOG_SERVICE_ADDR=productcatalogservice:3550` değerine döndü;
`network-delay-proxy-config` ConfigMap'i silindi. Minikube durduruldu. Host olay
farkları WHEA Event 17 / Kernel-Power 41 / bugcheck için `0/0/0` oldu.

## Telemetry ve immutable kanıt

Ham log arşivi 16 dosya içerir ve 17/17 manifest girdisiyle doğrulandı. Enriched
log arşivi 44.860 kaydı, 16 NDJSON dosyası ve 17/17 manifest girdisini run-ID,
sequence ve timestamp hatası olmadan doğruladı. Schema-v3 telemetry arşivi 4.311
metric seri, 877.100 örnek, 28 trace chunk, 6.758 seçili trace ve 83.159 span içerir.
12 boundary-crossing trace politika gereği ayrı tutuldu; run-ID/time/coverage/JSON
failure sayılarının tamamı sıfırdır.

## Sınırlamalar ve sonraki sınır

Base her zaman proxy'den önce ölçüldüğü için aynı-host zaman drift'i tamamen
elenemez. Bu tek 15-user operasyonel gate population-level overhead dağılımı veya
scientific network-delay etkisi değildir. Sonuç D-041 tasarımını canlı ortamda
uygulanabilir kılar; scientific fault'u otomatik yetkilendirmez. Sonraki aşama,
benzersiz scientific run ID ve değişmez workload/seed/target/ramp/lifecycle ile
ayrı bir network-delay scientific run ön-kaydıdır. Fault ancak bu ön-kayıt canonical
`main` üzerine merge edilip host/cluster kapıları yeniden geçtikten ve kullanıcı
ayrıca yürütmeyi onayladıktan sonra başlatılabilir. Model, LLM ve GAT çalıştırılmadı.

# ob-netdelay-15u-008 geçerli bilimsel run raporu

`ob-netdelay-15u-008`, D-055/D-056/D-057 altında workload `ob-second-15u-1r-v1`
(15 kullanıcı, spawn rate 1, seed 1), recommendationservice -> productcatalogservice
hedefi ve 500m/100m server/proxy kaynağıyla tam lifecycle'ı tamamladı. D-038 25
gözlem/restart 0; warmup/baseline/ramp/steady/cooldown süreleri sırasıyla
`300,031/300,007/120,068/300,010/300,002 sn` oldu.

Baseline ve steady coverage `60/60`; median hedef-edge gecikmesi `3,238 -> 755,233 ms`,
ölçülmüş fiziksel etki `+751,995 ms` ve frozen `>=500 ms` kapısı geçti. İlk semptom
`2026-08-20T18:24:33.328Z`, latency manifestation `2026-08-20T18:25:43.328Z` oldu;
204 tam SLO penceresi değerlendirildi. Toxic ramp ve cleanup geri-okuması, pod lifecycle,
base rollback ve RecordId host farkı WHEA17/KP41/bugcheck `0/0/0` geçti.

Immutable arşivlerde raw log 17/17, enriched log 17/17 (57.618 kayıt), schema-v3
telemetry 39/39 (1.095.946 metric sample, 35 chunk, 8.367 raw/8.362 selected trace,
102.228 span, 5 boundary-crossing trace korunup selected katmandan dışlandı) ve final
receipt 7/7 bağımsız replay edildi. Network metadata verifier 21 kontrolle valid verdi.

Taşınabilirlik tanısı: `pwsh 7`, raw verifier'ın JSON UTC stringlerini `DateTime`a
çevirip string cast sırasında milisaniyeyi düşürdüğü için 61 yanlış `after_end` üretti.
Canonical Windows PowerShell replay, immutable `until_utc=18:36:04.674Z` ve en geç log
`18:36:04.6265920Z` ile gerçek ihlal olmadığını doğruladı. Arşiv/eşik değiştirilmedi;
bu shell-portability sınırlılığı sonraki tooling kararından önce giderilmelidir.

Run geçerlidir ve dataset adayıdır; tek run tekrarlanabilirlik, model başarısı veya
sonraki akademik aşamaya otomatik geçiş iddiası oluşturmaz.

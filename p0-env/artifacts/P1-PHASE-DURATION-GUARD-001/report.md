# P1-PHASE-DURATION-GUARD-001

## Amaç

`ob-cpu-15u-medium-001` warm-up UTC sınırının frozen 300 saniyeden `0,0029301`
saniye kısa kalmasına yol açan erken `Start-Sleep` dönüşünü, bilimsel lifecycle
ve verifier eşiğini değiştirmeden önlemek.

## Değişmeyen sözleşme

- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Fault: `cpu-recommendation-medium-15u-v1`; +100m talep, en az +50m etki.
- Lifecycle: 300 warm-up, 300 baseline, 120 ramp, 300 steady, 300 cooldown.
- D-038, coverage, host, pod, schema-v3, metadata ve final receipt kapıları aynıdır.

## Uygulama ve doğrulama

`phase-duration.ps1`, kaydedilmiş faz başlangıç UTC'sinden minimum deadline'ı
hesaplar ve deadline görülmeden bitiş UTC'si döndürmez. Runner üç 300 saniyelik
host-zamanlı fazda bu yardımcıyı kullanır. `test-phase-duration.ps1` kısa pozitif
fixture ile erken dönüşü reddeder; runner'da üç guard çağrısını ve korunmasız
`Start-Sleep -Seconds 300` kalmadığını doğrular.

## Sınırlılık

Host saati geriye giderse bekleme uzayabilir; bu durum kısa ve görünürde geçerli
bir faz üretmek yerine fail-safe davranıştır. Tooling testi bilimsel veri değildir.
Replacement run ancak bu ön-kayıt canonical `main` üzerine merge edildikten sonra
yeni `ob-cpu-15u-medium-005` ID ile başlatılabilir.

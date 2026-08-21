# ob-netdelay-15u-repeat-001 ön-kaydı

Bu run, D-058 randomizasyon çizelgesindeki birinci bloğun ilk `fault` slotudur.
`ob-netdelay-15u-008` randomize edilmemiş pilot olarak ayrı kalır; bu run ilk bağımsız
randomize tekrardır ve tek başına tekrarlanabilirlik iddiası oluşturmaz.

## Değişmeyen bilimsel sözleşme

- workload: `ob-second-15u-1r-v1`, 15 kullanıcı, spawn rate 1, seed 1;
- hedef: `recommendationservice -> productcatalogservice`;
- kaynaklar: server `500m/100m`, proxy `100m` limit;
- lifecycle: `300/300/120/300/300` saniye;
- toxic ramp: `0 -> 750 ms`, 12 adım, jitter 0;
- fiziksel etki: baseline/steady en az `48/48`, median fark `>=500 ms`;
- D-038, frozen SLO/manifestation, schema-v3, boundary trace, cleanup, rollback,
  RecordId host ve final receipt kapıları aynıdır.

Raw UTC verifier Windows PowerShell 5.1 ve pwsh 7 eşdeğerlik kapısını geçmeden run
başlatılamaz. Aktif deployment/observability kimliği ve fault profili
`ob-netdelay-15u-repeat-001` ile fail-closed eşleşir.

## Yürütme ve kapanış sınırı

Bu commit ve merge canlı yürütme onayı değildir. Canonical merge sonrasında fresh
Git/host/cluster/run-ID/workload/proxy-clean/pod kapıları ve ayrı kullanıcı runtime
onayı gerekir. Invalid girişim korunur, ID yeniden kullanılmaz ve D-058 sırası otomatik
değiştirilmez. Geçerli kapanıştan sonra sıradaki slot `ob-netdelay-15u-control-001`dir;
kontrolün eşikleri fault sonucu görülerek değiştirilemez.

İlk run sonuç raporu araştırmanın `P0/P1 -> P2 design -> valid pilot -> randomized
repeatability block -> Dataset v1 decision` konumunu şemayla; yapılan işlem, ölçüm,
test ve temel savunma tezine katkı eşlemesiyle gösterecektir.

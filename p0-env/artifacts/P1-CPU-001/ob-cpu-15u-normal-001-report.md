# ob-cpu-15u-normal-001 Report

## Sonuç

İlk 15-user bilimsel normal baseline geçerli tamamlandı. Fault injection yapılmadı.
Workload `ob-second-15u-1r-v1`, seed `1`, 300 saniye warm-up ve 300 saniye
normal-baseline koşulları altında bütün fail-closed kapılar geçti.

## Kanıt özeti

- Lifecycle: `2026-08-11T18:32:27.903Z` – `2026-08-11T18:42:28.829Z`.
- Active run-ID ve active workload kapıları baseline öncesi/sonrası geçti.
- 15 deployment pod UID/restart snapshot'ı stabil.
- Host farkları WHEA Event 17 / Kernel-Power 41 / bugcheck: `0/0/0`.
- Ham log: 15 dosya; enriched log: 26.421 kayıt; run-ID/JSON/zaman hatası `0`.
- Telemetry schema v3: 533.101 metric sample, 3.851 unique selected trace,
  46.830 span, 21 doğrulanmış chunk; 6 boundary trace dışlandı; run-ID, zaman,
  chunk coverage ve JSON hata sayıları `0`.
- Frozen SLO: 60 tam pencere, manifestation `null`, maksimum latency/error
  streak `1/0`.
- Recommendationservice: 59 CPU intervali, mean `39,807m`, p95 `166,516m`.
- Scientific metadata, final receipt ve cluster kapandıktan sonraki bağımsız raw,
  enriched, telemetry ve finalized-receipt replay'leri geçti.

## Yorum sınırı

Bu run D-033 ikinci workload bloğunun ilk geçerli normal kontrolüdür ve bilimsel
dataset'e dahil edilebilir. Tek run 15-user normal dağılımının tekrarlanabilirliğini
kanıtlamaz; `002/003` tamamlanmalıdır. `<=40m` D-033 workload seçim kapısıdır;
bu run'ın `39,807m` sonucu eşiği değiştirmez ve sonraki run'lar için post-hoc
dışlama kuralına dönüşmez. Sonuç fault duyarlılığı, model, LLM veya GAT başarısı
hakkında kanıt değildir. Üç geçerli 15-user normal tamamlanmadan fault başlamaz.

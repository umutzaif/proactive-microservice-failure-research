# ob-cpu-15u-normal-003 Raporu

## Sonuç

Üçüncü 15-user girişimi ve ikinci geçerli 15-user bilimsel normal baseline başarıyla
tamamlandı. Fault injection yapılmadı. Workload `ob-second-15u-1r-v1`, seed `1`,
300 saniye warm-up ve 300 saniye normal-baseline koşulları altında bütün fail-closed
kapılar geçti.

## Kanıt özeti

- Lifecycle: `2026-08-11T19:29:08.552Z` - `2026-08-11T19:39:08.961Z`.
- Active run-ID ve active workload kapıları baseline öncesi/sonrası geçti.
- 15 deployment pod UID/restart snapshot'ı stabil kaldı.
- Host farkları WHEA Event 17 / Kernel-Power 41 / bugcheck: `0/0/0`.
- Ham log: 15 dosya; enriched log: 26.016 kayıt; bağımsız replay'de hash,
  read-only, run-ID, JSON, sıra ve zaman hata sayıları `0`.
- Telemetry schema v3: 524.692 metric sample, 3.765 unique selected trace,
  45.877 span, 21 doğrulanmış chunk; 3 boundary trace dışlandı. Bağımsız replay'de
  run-ID, zaman, chunk coverage ve JSON hata sayıları `0`.
- Frozen SLO: 60 tam pencere, manifestation `null`, maksimum latency/error ihlal
  serisi `1/0`.
- Recommendationservice: 59 CPU intervali, mean `41,816m`, p95 `178,013m`.
- Scientific metadata, final receipt ve cluster kapandıktan sonraki bağımsız raw,
  enriched, telemetry ve finalized-receipt replay'leri geçti.

## Yorum sınırı

Bu run bilimsel dataset'e dahil edilebilir ve ikinci geçerli 15-user normal
kontrolüdür. D-033 `<=40m` değeri workload seçim kapısıdır; bu run'ın `41,816m`
sonucu post-hoc dışlama nedeni değildir ve eşiği değiştirmez. `ob-cpu-15u-normal-002`
invalid kalır. Üçüncü geçerli normal için yeni benzersiz replacement ID gerekir;
normal blok tamamlanmadan fault injection başlatılmaz. Sonuç model, LLM veya GAT
başarısı hakkında kanıt değildir.

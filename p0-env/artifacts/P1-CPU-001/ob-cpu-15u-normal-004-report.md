# ob-cpu-15u-normal-004 Raporu

## Sonuç

`ob-cpu-15u-normal-004`, `ob-cpu-15u-normal-002` invalid girişiminin yeni ve
benzersiz replacement run'ı olarak geçerli tamamlandı. Fault injection yapılmadı.
Bu sonuçla 15-user bilimsel normal blok üç geçerli run'a ulaştı.

## Kanıt özeti

- Lifecycle: `2026-08-13T11:47:40.642Z` - `2026-08-13T11:57:41.419Z`.
- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate `1/s`, seed `1`.
- Active run-ID ve active workload kapıları baseline öncesi/sonrası geçti.
- 15 deployment pod UID/restart snapshot'ı stabil kaldı.
- Host farkları WHEA Event 17 / Kernel-Power 41 / bugcheck: `0/0/0`.
- Ham log: 15 dosya; enriched log: 25.876 kayıt. Bağımsız replay'de hash,
  read-only, run-ID, JSON, sıra ve zaman hata sayıları `0`.
- Telemetry schema v3: 495.764 metric sample, 3.743 unique selected trace,
  45.864 span ve 21 doğrulanmış chunk; 6 boundary trace politika gereği dışlandı.
  Bağımsız replay'de run-ID, zaman, chunk coverage ve JSON hatası `0`.
- Frozen SLO: 60 tam pencere, manifestation `null`, maksimum latency/error ihlal
  serisi `1/0`.
- Recommendationservice: 59 CPU intervali, mean `22,585m`, p95 `101,196m`.
- Scientific metadata, final receipt ve cluster kapandıktan sonraki bağımsız raw,
  enriched, telemetry ve finalized-receipt replay'leri geçti.

## Yorum sınırı

Bu run üçüncü geçerli 15-user normal kontroldür ve bilimsel dataset'e dahil
edilebilir. `normal-001/003/004` geçerli normal setini oluşturur; `normal-002`
invalid ve dataset dışı kalır. Normal CPU değerleri arasındaki fark doğal varyans
kanıtıdır; hiçbir run silinmez ve eşik post-hoc değiştirilmez.

Normal blok `3/3` tamamlanmıştır. Bu sonuç yalnız ön-kayıtlı randomize 15-user fault
serisinin başlangıç kapısını açar; fault, model, LLM veya GAT başarısını kanıtlamaz.
İlk fault run ancak canonical run-ID/profil bağı merge edilip canlı preflight
kapıları geçtikten sonra yürütülebilir.

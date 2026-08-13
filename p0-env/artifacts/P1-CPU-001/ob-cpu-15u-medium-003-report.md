# ob-cpu-15u-medium-003 Raporu

## Sonuç

`ob-cpu-15u-medium-003` `invalid/incomplete` tamamlandı ve dataset'e alınmaz.
Fault lifecycle ile cooldown tamamlandı; dış yürütme aracı 40 dakikalık timeout'a
ulaşarak runner'ı scientific metadata ve final receipt üretilmeden sonlandırdı.

## Korunan ve bağımsız doğrulanan kanıt

- Worker başladı/tamamlandı olayları `1/1`, heartbeat `84`; canonical worker süresi
  `420,000143 sn`, lifecycle failure `null`.
- Injection sırasında recommendationservice pod UID ve restart `1 -> 1` değişmedi.
- Tanısal fiziksel etki: baseline/steady coverage `59/59`, mean CPU
  `19,370m -> 119,342m`, fark `+99,972m`; ön-kayıtlı `+50m` kapısı geçti.
- Frozen SLO: 206 tam pencere; manifestation `null`.
- Host farkları WHEA / Kernel-Power 41 / bugcheck: `0/0/0`.
- Raw log, 59.452 enriched log ve schema-v3 telemetry replay'leri geçti.
- Telemetry: 1.118.002 metric sample, 8.569 selected trace, 106.506 span,
  35 chunk; 5 boundary trace dışlandı; run-ID/zaman/chunk/JSON hatası `0`.

## Neden retroaktif valid değildir?

Runner zorla sonlandığı için tam-run pod-after snapshot'ı scientific metadata'ya
yazılmadı; scientific metadata ve final receipt oluşmadı. Offline analiz fiziksel
etkiyi gösterse de eksik provenance zincirini sonradan tahmin ederek tamamlayamaz.
Bu nedenle `valid_run=false`, `dataset_inclusion=false` kalır ve ID kullanılmaz.

## Sonraki kapı

Fault lifecycle veya akademik eşikler değişmeden dış runner timeout bütçesi en az
60 dakikaya çıkarılır. Randomize ilk slot yeni benzersiz
`ob-cpu-15u-medium-004` ID ile tekrarlanır; bu slot geçerli tamamlanmadan
`low-002`ye geçilmez.

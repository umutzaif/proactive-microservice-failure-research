# ob-cpu-15u-normal-002 Raporu

## Sonuç

İkinci 15-user bilimsel normal-baseline girişimi `invalid` tamamlandı. Fault injection
yapılmadı ve dataset'e dahil edilmedi. Ana dışlama gerekçesi, frozen SLO altında
üç ardışık 5 saniyelik latency ihlalinin normal koşulda manifestation üretmesidir.

## Kanıt özeti

- Lifecycle: `2026-08-11T19:02:22.799Z` - `2026-08-11T19:12:23.260Z`.
- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate `1/s`, seed `1`.
- Active run-ID ve active workload kapıları baseline öncesi/sonrası geçti.
- 15 deployment pod UID/restart snapshot'ı stabildi.
- Host farkları WHEA Event 17 / Kernel-Power 41 / bugcheck: `0/0/0`.
- Ham log: 15 dosya; enriched log: 26.227 kayıt; bağımsız replay'de hash,
  read-only, run-ID, JSON, sıra ve zaman hata sayıları `0`.
- Telemetry schema v3: 516.271 metric sample, 3.800 unique selected trace,
  45.980 span, 21 doğrulanmış chunk; 5 boundary trace dışlandı. Bağımsız replay'de
  run-ID, zaman, chunk coverage ve JSON hata sayıları `0`.
- Frozen SLO: 60 tam pencere; latency maksimum ihlal serisi `3`, error maksimum
  ihlal serisi `0`; manifestation `2026-08-11T19:10:07.812Z`.
- Eşik `345,992 ms`; 30/31/32 numaralı pencerelerde product-route p95 latency
  sırasıyla `437,251`, `377,047`, `348,500 ms` oldu.
- Recommendationservice: 59 CPU intervali, mean `43,612m`, p95 `152,302m`.

## Geçerlilik yorumu

Host, pod ve arşiv kapılarının geçmesi bu run'ı bilimsel normal yapmaya yetmez.
Normal koşulda frozen manifestation kuralı tetiklendiği için `valid_run=false` ve
`dataset_inclusion=false` kalır; final dataset receipt'i üretilmez. D-033'teki
`<=40m` CPU değeri workload seçim kapısıdır ve sonraki normal run'lar için dışlama
kuralı değildir; bu run'ın invalid olma nedeni CPU mean değildir.

Kanıt silinmez, run ID yeniden kullanılmaz ve sonuç geçerli normal sayısını
artırmaz. 15-user blok `1/3` kalır; üç geçerli normal tamamlanmadan fault injection
başlatılmaz. Yeni tekrar ancak aynı ön-kayıtlı koşullarla yeni benzersiz run ID
bağlandıktan ve canonical `main` üzerine merge edildikten sonra yürütülebilir.

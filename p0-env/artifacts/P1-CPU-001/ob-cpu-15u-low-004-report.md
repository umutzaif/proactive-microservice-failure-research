# ob-cpu-15u-low-004 Raporu

## Sonuç

`ob-cpu-15u-low-004`, D-038 hedef stabilite kapısı altında bütün ön-kayıtlı
geçerlilik kapılarını geçti. 15-user randomize fault sırasının ikinci slotu için
geçerli bilimsel dataset adayıdır. Invalid `low-002/003` korunur ve dataset dışıdır.

## Bilimsel koşullar

- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Fault: `cpu-recommendation-low-15u-v1`; recommendationservice `+50m`.
- Lifecycle: 300 sn warm-up, 300 sn baseline, 120 sn ramp, 300 sn steady,
  300 sn cooldown.
- Fiziksel kapı: baseline/steady fazlarında en az 48 interval ve en az `+25m`.
- D-038: warm-up öncesi 120 sn, 5 sn cadence; worker öncesi aynı pod/container.

## Kanıt ve bağımsız doğrulama

- D-038: 25 gözlem; Ready/pod UID/container ID/restart değişmedi; restart `0`.
- Worker: heartbeat `84`; bounded lifecycle geçti.
- Fiziksel etki: coverage `59/59`; baseline `20,319m`, steady `69,472m`, fark
  `+49,153m`; ön-kayıtlı `+25m` kapısı geçti.
- Pod lifecycle stabil; host WHEA Event 17 / Kernel-Power 41 / bugcheck farkı
  `0/0/0`.
- Frozen SLO: 205 tam pencere; failure manifestation `null`.
- Raw: 15 log, 16 manifest girdisi; hash/zaman hatası `0`.
- Enriched: 59.580 kayıt; JSON/run-ID/sequence hatası `0`.
- Schema v3: 4.112 metric serisi, 1.082.768 sample, 35 trace chunk, 8.603
  selected trace ve 106.861 span. İki boundary trace dışlandı; run-ID/zaman/chunk/
  JSON hatası `0`.
- Final receipt: 7 manifest girdisi; bütün offline replay kapıları geçti.

## Yorum sınırı

Bu run low fault'un fiziksel olarak uygulandığını ve bu örnekte frozen SLO
manifestation oluşmadığını gösterir. Tek başına 15-user low tekrarlanabilirliği,
pre-failure tahmin veya model performansı kanıtlamaz.

## Sonraki kapı

Dondurulmuş üçüncü slot `ob-cpu-15u-high-001`dir. Sonuç ve yeni run-ID bağı
canonical `main` üzerine merge edilmeden fault başlatılmaz.

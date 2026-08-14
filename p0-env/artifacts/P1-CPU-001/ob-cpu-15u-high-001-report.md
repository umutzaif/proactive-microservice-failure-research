# ob-cpu-15u-high-001 Raporu

## Sonuç

`ob-cpu-15u-high-001`, D-038 hedef stabilite kapısı ve bütün ön-kayıtlı bilimsel
geçerlilik kapıları altında tamamlandı. 15-user randomize fault sırasının üçüncü
slotu için geçerli bilimsel dataset adayıdır.

## Bilimsel koşullar

- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Fault: `cpu-recommendation-high-15u-v1`; recommendationservice `+150m`.
- Lifecycle: 300 sn warm-up, 300 sn baseline, 120 sn ramp, 300 sn steady,
  300 sn cooldown.
- Fiziksel kapı: baseline/steady fazlarında en az 48 interval ve en az `+75m`.
- D-038: warm-up öncesi 120 sn, 5 sn cadence; worker öncesi aynı pod/container.

## Kanıt ve bağımsız doğrulama

- D-038: 25 gözlem; Ready/pod UID/container ID/restart değişmedi; restart `0`.
- Worker: heartbeat `83`; bounded lifecycle geçti.
- Fiziksel etki: coverage `59/58`; baseline `36,646m`, steady `171,806m`, fark
  `+135,160m`; ön-kayıtlı `+75m` kapısı geçti.
- Throttling: 143 interval; ortalama `99,790m` eşdeğeri.
- Pod lifecycle stabil; host WHEA Event 17 / Kernel-Power 41 / bugcheck farkı
  `0/0/0`.
- Frozen SLO: 205 tam pencere; failure manifestation `null`.
- Raw: 15 log, 16 manifest girdisi; hash/zaman hatası `0`.
- Enriched: 59.490 kayıt; JSON/run-ID/sequence hatası `0`.
- Schema v3: 4.112 metric serisi, 1.082.723 sample, 35 trace chunk, 8.591
  selected trace ve 106.278 span. İki boundary trace dışlandı; run-ID/zaman/chunk/
  JSON hatası `0`.
- Final receipt: 7 manifest girdisi; bütün offline replay kapıları geçti.

## Yorum sınırı

Bu run high fault'un fiziksel etkisini ve throttling'i gösterir; frozen SLO
manifestation oluşmadı. Tek run high tekrarlanabilirliği, nedensellik, pre-failure
tahmin veya model performansı kanıtlamaz.

## Sonraki kapı

Dondurulmuş dördüncü slot `ob-cpu-15u-high-002`dir. Sonuç ve run-ID bağı
canonical `main` üzerine merge edilmeden fault başlatılmaz.

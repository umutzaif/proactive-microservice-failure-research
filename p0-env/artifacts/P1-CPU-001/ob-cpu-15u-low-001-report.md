# ob-cpu-15u-low-001 Raporu

## Sonuç

`ob-cpu-15u-low-001`, D-038 ve bütün ön-kayıtlı bilimsel geçerlilik kapıları
altında tamamlandı. 15-user randomize fault sırasının beşinci slotu ve ikinci
geçerli low bilimsel dataset adayıdır.

## Bilimsel koşullar

- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Fault: `cpu-recommendation-low-15u-v1`; recommendationservice `+50m`.
- Lifecycle: 300 sn warm-up, 300 sn baseline, 120 sn ramp, 300 sn steady,
  300 sn cooldown.
- Fiziksel kapı: baseline/steady fazlarında en az 48 interval ve en az `+25m`.
- D-038: warm-up öncesi 120 sn, 5 sn cadence; worker öncesi aynı pod/container.

## Kanıt ve bağımsız doğrulama

- D-038: 25 gözlem; Ready/pod UID/container ID/restart değişmedi. Sabit başlangıç
  restart sayısı `1` idi; run içinde yeni restart oluşmadı.
- Worker heartbeat `84`; bounded lifecycle geçti.
- Fiziksel etki: coverage `59/59`; baseline `38,294m`, steady `91,337m`, fark
  `+53,044m`; ön-kayıtlı `+25m` kapısı geçti.
- Throttling: 144 interval; ortalama `77,737m` eşdeğeri.
- Pod lifecycle stabil; host WHEA Event 17 / Kernel-Power 41 / bugcheck farkı
  `0/0/0`.
- Frozen SLO: 205 tam pencere; failure manifestation `null`.
- Raw: 15 log, 16 manifest girdisi; hash/zaman hatası `0`.
- Enriched: 60.150 kayıt; JSON/run-ID/sequence hatası `0`.
- Schema v3: 4.112 metric serisi, 1.082.678 sample, 35 trace chunk, 8.672
  selected trace ve 108.008 span. İki boundary trace dışlandı; run-ID/zaman/chunk/
  JSON hatası `0`.
- Final receipt: 7 manifest girdisi; bütün offline replay kapıları geçti.

## Yorum sınırı

İki 15-user low adayı fiziksel etki ve null manifestation yönünde betimsel tekrar
sağlar. Bu, tek başına nedensellik, pre-failure tahmin veya model performansı
kanıtı değildir; son medium slot ve blok kapanış denetimi beklenir.

## Sonraki kapı

Dondurulmuş altıncı ve son slot `ob-cpu-15u-medium-001`dir. Sonuç ve run-ID bağı
canonical `main` üzerine merge edilmeden fault başlatılmaz. Medium run ayrı sohbette
yürütülür.

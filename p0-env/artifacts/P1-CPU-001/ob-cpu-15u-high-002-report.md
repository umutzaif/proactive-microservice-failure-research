# ob-cpu-15u-high-002 Raporu

## Sonuç

`ob-cpu-15u-high-002`, D-038 ve bütün ön-kayıtlı bilimsel geçerlilik kapıları
altında tamamlandı. 15-user randomize fault sırasının dördüncü slotu ve ikinci
geçerli high bilimsel dataset adayıdır.

## Bilimsel koşullar

- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Fault: `cpu-recommendation-high-15u-v1`; recommendationservice `+150m`.
- Lifecycle: 300 sn warm-up, 300 sn baseline, 120 sn ramp, 300 sn steady,
  300 sn cooldown.
- Fiziksel kapı: baseline/steady fazlarında en az 48 interval ve en az `+75m`.
- D-038: warm-up öncesi 120 sn, 5 sn cadence; worker öncesi aynı pod/container.

## Kanıt ve bağımsız doğrulama

- D-038: 25 gözlem; Ready/pod UID/container ID/restart değişmedi; restart `0`.
- Worker heartbeat `84`; bounded lifecycle geçti.
- Fiziksel etki: coverage `59/59`; baseline `36,479m`, steady `182,190m`, fark
  `+145,710m`; ön-kayıtlı `+75m` kapısı geçti.
- Throttling: 144 interval; ortalama `137,848m` eşdeğeri.
- Pod lifecycle stabil; host WHEA Event 17 / Kernel-Power 41 / bugcheck farkı
  `0/0/0`.
- Frozen SLO: 205 tam pencere; failure manifestation `null`.
- Raw: 15 log, 16 manifest girdisi; hash/zaman hatası `0`.
- Enriched: 59.836 kayıt; JSON/run-ID/sequence hatası `0`.
- Schema v3: 4.118 metric serisi, 1.084.275 sample, 35 trace chunk, 8.598
  selected trace ve 107.222 span. İki boundary trace dışlandı; run-ID/zaman/chunk/
  JSON hatası `0`.
- Final receipt: 7 manifest girdisi; bütün offline replay kapıları geçti.

## Yorum sınırı

İki 15-user high adayı fiziksel etki ve null manifestation yönünde betimsel tekrar
sağlar; yalnız iki run nihai varyans özeti, nedensellik veya model performansı
kanıtı değildir. Ön-kayıtlı blok tamamlanmadan toplu bilimsel yorum yapılmaz.

## Sonraki kapı

Dondurulmuş beşinci slot `ob-cpu-15u-low-001`dir. Sonuç ve run-ID bağı canonical
`main` üzerine merge edilmeden fault başlatılmaz.

# ob-cpu-15u-medium-004 Raporu

## Sonuç

`ob-cpu-15u-medium-004`, D-037 altında en az 60 dakikalık dış yürütme bütçesiyle
tamamlandı ve bütün ön-kayıtlı geçerlilik kapılarını geçti. 15-user randomize fault
sırasının ilk slotu için geçerli bilimsel dataset adayıdır. Invalid `medium-002` ve
`medium-003` kayıtları değiştirilmeden dataset dışında korunur.

## Bilimsel koşullar

- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Fault: `cpu-recommendation-medium-15u-v1`; recommendationservice `+100m`.
- Lifecycle: 300 sn warm-up, 300 sn normal baseline, 120 sn ramp, 300 sn steady,
  300 sn cooldown.
- Fiziksel-etki kapısı: her baseline/steady fazında en az 48 interval ve mean CPU
  farkı en az `+50m`.
- Frozen SLO: `p1-cpu-001-slo-v1`; üç ardışık 5 saniyelik pencere kuralı.

## Kanıt ve bağımsız doğrulama

- Fiziksel etki: coverage `59/59`; baseline `32,664m`, steady `127,119m`, fark
  `+94,454m`; ön-kayıtlı kapı geçti. Throttling serisi mevcuttu.
- Worker: start/completed `1/1`, heartbeat `84`; bounded lifecycle doğrulandı.
- Pod UID/restart değişmedi; host WHEA Event 17 / Kernel-Power 41 / bugcheck
  farkları `0/0/0`.
- Frozen SLO: 205 tam pencere; failure manifestation `null`.
- Raw: 15 log dosyası ve 16 manifest girdisi; timestamp/hash hatası `0`.
- Enriched: 58.944 kayıt; JSON, run-ID ve sequence hatası `0`.
- Schema v3 telemetry: 4.290 metric serisi, 1.090.922 sample, 35 trace chunk,
  8.535 selected trace ve 105.284 span. Altı boundary-crossing trace politika
  gereği dışlandı; run-ID/zaman/chunk/JSON hatası `0`.
- Final receipt: 7 manifest girdisi doğrulandı; raw/enriched/telemetry manifest
  hash bağları, scientific metadata ve read-only koruması bağımsız replay ile geçti.

## Yorum sınırı

Bu run, medium fault'un fiziksel olarak uygulandığını ve bu örnekte frozen SLO
manifestation oluşmadığını gösterir. Tek başına 15-user medium tekrarlanabilirliği,
pre-failure tahmin başarısı, nedensellik veya model performansı kanıtlamaz.

## Sonraki kapı

Randomize sıranın ikinci slotu `low-002`dir. Yeni run-ID/profil bağı canonical
`main` üzerine merge edilip canlı preflight geçmeden fault başlatılmaz.

# ob-cpu-15u-medium-005 geçerli run raporu

## Sonuç

- Durum: `valid`; dataset adayı ve ikinci-workload fault bloğunun altıncı run'ı.
- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Fault: `cpu-recommendation-medium-15u-v1`; recommendationservice üzerinde +100m talep.
- D-038: 25 gözlem, sabit restart `1`, değişmeyen pod UID/container ID.
- D-039 süreleri: warm-up `300,0175 sn`, baseline `300,0160 sn`, cooldown
  `300,0119 sn`. Ramp `120 sn`, steady `299,9420 sn`; worker toleransı geçti.

## Fiziksel etki ve geçerlilik

- Coverage baseline/steady: `59/59`; zorunlu minimum `48/48`.
- Mean CPU: `41,102m -> 134,621m`; fark `+93,519m`, zorunlu minimum `+50m`.
- Throttling: 144 interval, ortalama `69,644m` eşdeğer.
- Pod lifecycle stabil; host WHEA Event 17 / Kernel-Power 41 / bugcheck farkı `0/0/0`.
- Frozen SLO: 205 tam pencere; failure manifestation `null`.

## Immutable arşiv ve bağımsız doğrulama

- Raw log: 15 dosya; manifest/hash/zaman hatası `0`.
- Enriched log: 59.819 kayıt; run-ID/sequence/JSON hatası `0`.
- Schema v3: 4.067 metric seri, 1.081.822 sample, 35 trace chunk,
  8.562 selected trace ve 107.030 span. Boundary-excluded trace `1`;
  chunk coverage, run-ID ve zaman hatası `0`.
- Scientific metadata ve final receipt mühürlendi. Raw, enriched, telemetry ve
  finalized receipt verifier'ları runner içinde ve bağımsız offline replay'de geçti.

## Yorum sınırı

Run ikinci medium tekrarını ve fault bloğunu tamamlar. Manifestation null geçerli
negatif sonuçtur. Bu run tek başına pre-failure sinyal, model başarısı, LLM
doğrulaması veya GAT/sonraki aşama yetkisi değildir.

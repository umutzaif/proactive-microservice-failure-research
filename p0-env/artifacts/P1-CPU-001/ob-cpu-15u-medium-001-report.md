# ob-cpu-15u-medium-001 invalid run raporu

## Sonuc

- Durum: `invalid/incomplete`; dataset'e dahil edilmez ve run ID yeniden kullanilmaz.
- Frozen 300 saniyelik warm-up, canonical UTC sinirlarinda `299,9970699` saniye
  surdu. Scientific metadata verifier `warmup_too_short` ile fail-closed durdu.
- Final receipt olusturulmadi. On finalization `run-assessment.json` icindeki
  `valid_run=true`, final receipt kapisindan onceki ara degerdir ve nihai gecerlilik
  kaniti degildir.
- Esikler sonuctan sonra gevsetilmedi; mevcut run sonradan finalize edilmedi.

## Gecen tanisal kapilar

- Baslangic ve bitis host WHEA Event 17 / Kernel-Power 41 / bugcheck farki: `0/0/0`.
- D-038: 25 gozlem, sabit restart `3`, degismeyen pod UID ve container ID.
- Worker lifecycle: ramp/steady `120/300 sn`; monotonic sure `420,000455 sn`.
- Fiziksel etki: baseline/steady coverage `60/59`; mean CPU
  `19,709m -> 120,099m`, fark `+100,390m`; on-kayitli `+50m` kapisi gecti.
- Pod lifecycle stabil ve frozen SLO manifestation `null`.
- Raw log: 15 dosya; enriched log: 59.280 kayit; bagimsiz verifier'lar gecti.
- Schema v3: 4.085 metric seri, 1.085.134 sample, 35 trace chunk,
  8.471 selected trace ve 106.272 span. Boundary-excluded trace sayisi `3`;
  chunk coverage, run-ID ve zaman hatasi `0`. Bagimsiz replay gecti.

## Kapanis degerlendirmesi

Ikinci workload fault blogu gecerli olarak `5/6` kalir ve kapanmaz. Bu run'in
fiziksel etki ile telemetry bulgulari tanisal invalid-run kanitidir; dataset adayi,
medium tekrari veya model/LLM/GAT asamasina gecis yetkisi degildir. Yeni replacement,
timer/lifecycle uygulama duzeltmesi veya metodoloji karari bu raporla otomatik olarak
verilmez.

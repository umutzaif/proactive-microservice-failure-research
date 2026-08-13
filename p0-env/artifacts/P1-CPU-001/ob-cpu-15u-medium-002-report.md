# ob-cpu-15u-medium-002 Raporu

## Sonuç

`ob-cpu-15u-medium-002` `invalid/incomplete` tamamlandı ve dataset'e alınmaz.
300 saniye warm-up ile 300 saniye normal baseline tamamlandı; bounded worker
başlamadan injector profil sözleşmesi kapısı run'ı reddetti. CPU fault uygulanmadı.

## Kök neden ve korunan kanıt

- Run-ID ve canlı workload kapıları geçti.
- Host başlangıç sayaçları WHEA / Kernel-Power 41 / bugcheck: `881/5/1`.
- `invoke-cpu-stress.ps1` allowlist'i yalnız 10-user profil kimliklerini içerirken
  metadata verifier 15-user profillerini kabul ediyordu.
- `cpu-recommendation-medium-15u-v1` fiziği doğru olmasına rağmen profil kimliği
  injector tarafından tanınmadı.
- `run-error.json` korunur; injection evidence, telemetry veya final receipt yoktur
  çünkü fault öncesi fail-closed durulmuştur.

## Sonraki kapı

Akademik profil, şiddet, lifecycle, workload, seed, SLO ve fiziksel-etki eşiği
değiştirilmez. Injector allowlist'i önceden onaylı üç 15-user profille eşitlenir ve
pozitif/negatif `-WhatIf` regression testleriyle doğrulanır. Düzeltme canonical
`main` üzerine merge edildikten sonra aynı randomize slot yeni benzersiz
`ob-cpu-15u-medium-003` ID ile tekrar edilir.

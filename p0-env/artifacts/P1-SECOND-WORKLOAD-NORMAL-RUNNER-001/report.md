# P1-SECOND-WORKLOAD-NORMAL-RUNNER-001 Report

## Amaç ve kapsam

`ob-cpu-15u-normal-001/002/003` için fault içermeyen scientific normal-baseline
lifecycle'ını tek fail-closed orchestrator içinde yürütmek. Bu doğrulama tooling
kanıtıdır; canlı bilimsel run veya dataset girdisi üretmemiştir.

## Zincir

Runner temiz Git revision ve boş run yollarıyla başlar; active run-ID ile active
15-user workload'u deployment ve Ready pod üzerinde doğrular; 300 saniye warm-up
ve 300 saniye baseline uygular. Baseline öncesi/sonrası 15 pod UID/restart
snapshot'ı alır. Ham/enriched loglar ile schema-v3 metric/trace arşivlerini kapatır,
normal SLO manifestation analizini çalıştırır, cluster'ı durdurur, host event
farklarını hesaplar ve scientific metadata/final receipt/offline verifier zincirini
tamamlar. Hata halinde kısmi kanıt silinmez ve cluster `finally` içinde durdurulur.

## Geçerlilik ve seçim yanlılığı sınırı

Pod continuity, WHEA/KP41/bugcheck `0/0/0`, telemetry/log bütünlüğü, null normal
manifestation, metadata ve receipt kapılarının tamamı zorunludur. D-033 `<=40m`
değeri workload seçim kapısıdır; yeni normal run CPU değeri raporlanır fakat sonucu
gördükten sonra run dışlama kuralına dönüştürülmez.

## Bağımsız doğrulama

- PowerShell AST parse: geçti.
- Fault yolu/terimi yokluğu: geçti.
- Active run/workload, archive, metadata, finalization ve offline gate varlığı: geçti.
- 15-user normal metadata pozitif fixture: geçti.
- 10-user ID + 15-user profil negatif fixture: reddedildi.
- Gerçek `ob-cpu-15u-normal-001` parametreleriyle `-WhatIf`: ShouldProcess noktasına
  ulaştı; cluster, uyku, run veya artifact üretmedi.

## Sonraki kapı

Runner ve bu rapor canonical `main` üzerine merge edilmeden workload binding veya
canlı normal run başlatılmaz. Merge sonrasında profil/run-ID ayrı commit ile
bağlanır, temiz preflight ve canlı active-workload kapısı geçerse ilk normal run
yürütülebilir. Üç geçerli normal tamamlanmadan fault injection yasaktır.

# ob-netdelay-15u-006 invalid/incomplete raporu

Fresh Git/ID/RecordId-host, base deploy, 500m proxy rollout, canlı collector/Prometheus
`006`, workload 15/1/1 ve pod convergence kapıları geçti. Fault/warmup başlamadı.
Statik proxy-overlay verifier compositional resource overlay'in base dosyasını çözmeyip
`recommendation-proxy-patch.json` dosyasını üst klasörde aradığı için fail-closed durdu.

Rollback ve proxy ConfigMap temizliği geçti; Minikube Stopped, RecordId
`137569 -> 137579`, yeni WHEA17/KP41/bugcheck `0/0/0`. Altı kapanış artifact'i
mühürlendi ve bağımsız replay `6/6` geçti. Run invalid/incomplete, ID kullanılamaz;
eşikler değişmez ve replacement ayrı commit gerektirir.

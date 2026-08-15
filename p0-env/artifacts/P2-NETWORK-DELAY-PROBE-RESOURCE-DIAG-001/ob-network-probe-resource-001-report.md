# ob-network-probe-resource-001 invalid/incomplete tanı raporu

Scientific toxic/fault uygulanmadı. No-toxic overlay 180 saniye ve 33 gözlem boyunca
çalıştı. Yeni podda server ve proxy `33/33` Ready, restart `0` kaldı; önceki
CrashLoopBackOff yeniden üretilmedi. Events yeni pod için 5 readiness ve 1 liveness
connection timeout kaydetti, fakat liveness failure threshold 3'e ulaşmadığı için
Killing/restart oluşmadı.

Prometheus cAdvisor arşivi 13 metric türü, her biri eski/yeni pod için 37 örnek içerir.
Yeni server podunda CPU mean `32,466m`, maksimum 5 saniyelik rate `373,423m`; CFS
throttled seconds `10,897791`, throttled-period fraction `%11,84`; CPU pressure
stalled/waiting artışı `7,543533/7,547757 sn` idi. Memory working-set maksimum
`33,242 MiB`, limit `450 MiB`; failcnt, OOM events ve memory pressure artışı `0` idi.

Bu pencere OOM hipotezini desteklemez. CPU throttling/pressure ile tek liveness timeout
birlikte gözlendi; ancak restart oluşmadığından bunların önceki kill zincirinin yeterli
veya nedensel açıklaması olduğu kanıtlanamaz. O-019 açık kalır.

Rollback geçti ve Minikube durduruldu. Kernel-Power 41 ve bugcheck farkları `0` iken
WHEA Event 17 toplamı `881 -> 879` ile `-2` oldu. Bu yeni host olayı değildir fakat
count snapshot'ının monotonluk varsayımını bozar; host-health kanıtı geçersizdir.
Diagnostic bu nedenle invalid/incomplete, Dataset v1/modeling dışıdır; ID tekrar
kullanılmaz. Probe/resource/eşik değiştirilmez ve replacement belirlenmez.

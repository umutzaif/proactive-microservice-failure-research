# ob-network-resource-compat-002 invalid/incomplete raporu

D-051 replacement girişimi fresh Git/ID/RecordId-host ve base deployment
kapılarını geçti. Collector ile Prometheus canlı olarak `ob-netdelay-15u-005`,
workload ise `ob-second-15u-1r-v1` (`15` kullanıcı, spawn rate `1`, seed `1`)
bağını doğruladı. Scientific toxic/fault uygulanmadı.

Resource overlay apply ve rollout sonrasında canlı deployment JSON'u okunurken
doğrudan `kubectl` çıktısındaki JSON dışı `k...` ile başlayan satır
`ConvertFrom-Json` işlemini fail-closed durdurdu. Bu nedenle canlı 500m sözleşmesi,
120 saniyelik target stability, 180 saniyelik resource ölçümü, 13/13 metric coverage
ve fiziksel etki kapıları değerlendirilemedi.

Finally akışı base apply ve rollout'u denedi; rollback JSON doğrulaması aynı parser
hatasıyla kapanamadı ve `rollback.json` oluşmadı. Minikube bağımsız sorguda tamamen
Stopped idi. System RecordId `137470 -> 137471` monoton; yeni WHEA Event 17,
Kernel-Power 41 ve bugcheck sayıları `0/0/0` idi.

Bağımsız compatibility verifier `missing_artifact:rollback.json` ile başarısız oldu.
Dört ham kapanış dosyası SHA-256 manifestiyle mühürlendi; manifest ve offline replay
`4/4` geçti. Run invalid/incomplete, Dataset v1/modeling dışıdır ve ID tekrar
kullanılmaz. D-050 kaynak/probe/workload koşulları ile önceden dondurulmuş eşikler
değiştirilmemiştir. Yeni replacement ancak kök neden tanısı ve ayrı kontrollü
ön-kayıt commit'i ile ele alınabilir.

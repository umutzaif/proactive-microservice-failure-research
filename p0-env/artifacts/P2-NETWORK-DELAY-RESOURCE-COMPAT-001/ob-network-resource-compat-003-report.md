# ob-network-resource-compat-003 invalid/incomplete raporu

D-052 replacement girişimi fresh Git/ID/RecordId-host ve base deployment
kapılarını geçti. Collector ile Prometheus canlı olarak `ob-netdelay-15u-005`,
workload ise `ob-second-15u-1r-v1` (`15` kullanıcı, spawn rate `1`, seed `1`)
bağını doğruladı. Scientific toxic/fault uygulanmadı.

Resource overlay rollout sonrasında ilk canlı deployment JSON çağrısında `KJson`
fonksiyonunun `[string[]]$Args` parametresi PowerShell'in otomatik `$Args` değişkeniyle
çakıştı ve helper'a boş `ArgumentList` aktardı. Helper boş çağrıyı fail-closed
reddetti. Canlı 500m sözleşmesi, 120 saniyelik stability, 180 saniyelik resource
ölçümü, metric coverage ve fiziksel etki değerlendirilemedi.

Finally rollback doğrulaması aynı argüman bağlama kusuruyla kapanamadı;
`rollback.json` oluşmadı. Minikube bağımsız sorguda tamamen Stopped idi. System
RecordId `137476 -> 137512` monoton; yeni WHEA Event 17, Kernel-Power 41 ve bugcheck
`0/0/0` idi.

Bağımsız compatibility verifier `missing_artifact:rollback.json` ile başarısız oldu.
Dört ham kapanış dosyası SHA-256 manifestiyle mühürlendi; manifest doğrulaması ve
bağımsız hash replay `4/4` geçti. Run invalid/incomplete, Dataset v1/modeling dışıdır
ve ID tekrar kullanılmaz. D-050 koşulları/eşikleri değiştirilmemiştir; olası düzeltme
ve yeni benzersiz replacement ayrı kontrollü commit gerektirir.

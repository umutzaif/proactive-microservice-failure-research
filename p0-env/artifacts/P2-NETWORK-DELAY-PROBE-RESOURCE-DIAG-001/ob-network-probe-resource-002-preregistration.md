# ob-network-probe-resource-002 ön-kaydı

Amaç O-019 için önceki liveness-kill olayını aynı anda pod lifecycle, Kubernetes event,
kubelet logu ve server cAdvisor kaynak ölçümleriyle yeniden gözlemlemektir. Bu bir
scientific fault run değildir; toxic uygulanmaz ve Dataset v1/modeling kapsamı dışıdır.

- Benzersiz ID: `ob-network-probe-resource-002`
- Deployment: değişmeyen no-toxic network-delay overlay
- Süre/poll: `180/5` saniye
- Resource ölçümü: mevcut Prometheus service-proxy üzerinden aynı 13 cAdvisor seri
- Host kapısı: başlangıç System `RecordId` sınırından sonra oluşan WHEA 17,
  Kernel-Power 41 ve bugcheck 1001 olaylarının kimlikleri; herhangi biri varsa invalid
- Günlük bütünlüğü: kapanış `RecordId` başlangıçtan küçükse log reset/clear kabul edilir
  ve diagnostic invalid olur
- Kapanış: rollback doğrulanır, Minikube durdurulur, bütün kanıt benzersiz ID altında
  immutable olarak korunur

Probe, resource limit/request, workload, gözlem süresi ve bilimsel eşikler
değiştirilmez. Restart yeniden üretilmezse host kapısı geçse bile O-019 nedensel olarak
kapanmaz; sonuç kanıtın desteklediği sınıfla korunur ve sonraki koşul bu kayıtta
sessizce belirlenmez.

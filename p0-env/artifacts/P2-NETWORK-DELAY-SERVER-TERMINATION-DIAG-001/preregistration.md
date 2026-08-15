# P2-NETWORK-DELAY-SERVER-TERMINATION-DIAG-001 ön-kaydı

- Diagnostic ID: `ob-network-server-termination-001`; benzersizdir ve tekrar kullanılmaz.
- Scientific toxic/fault oluşturulmaz; no-toxic network proxy overlay kullanılır.
- 180 saniye boyunca 5 saniyede bir pod conditions, QoS, container ID, readiness,
  restart, state ve lastState kaydedilir.
- Deployment probe/resource sözleşmesi, ReplicaSet, pod events/describe, server ve
  proxy current/previous logları, node conditions, varsa metrics API ve kubelet
  journal kanıtı kapanır.
- Olasılıklar sonuçtan önce ayrıdır: liveness/probe kill, OOM/resource pressure,
  uygulama çıkışı veya yetersiz kanıt.
- Exit `137` tek başına OOM kabul edilmez. Kesin neden yalnız uyumlu bağımsız kanıtla
  sınıflandırılır; eşikler/probe/resource ayarları sonuçtan sonra değiştirilmez.
- Rollback, Minikube stop ve host WHEA 17 / Kernel-Power 41 / bugcheck farkı zorunludur.
- Diagnostic dataset/modeling dışıdır; replacement run bu tanı sonucuyla aynı committe
  belirlenmez. Model, LLM ve GAT çalıştırılmaz.

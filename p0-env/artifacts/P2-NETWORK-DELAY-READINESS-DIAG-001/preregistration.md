# P2-NETWORK-DELAY-READINESS-DIAG-001 ön-kaydı

Tanısal kimlik `ob-network-proxy-readiness-001`dir. Amaç `ob-netdelay-15u-004`
bounded kapısındaki `Ready=false` sonucunu fault uygulamadan ayrıştırmaktır.

- toxic oluşturulmaz veya ramp uygulanmaz;
- 180 saniye boyunca 5 saniye cadence ile pod phase/conditions, deletion timestamp,
  container ready/started/restart/state/reason ve last-state korunur;
- deployment, ReplicaSet, namespace pod events ve server/proxy current/previous logları
  arşivlenir;
- base rollback, Minikube stop ve host WHEA17/Kernel-Power41/bugcheck farkı zorunludur;
- çıktı scientific dataset/modeling örneği değildir;
- tanı sonucu görülmeden timeout, readiness probe veya yeni scientific run ID seçilmez;
- model eğitimi, LLM doğrulaması ve graph/GAT çalıştırılmaz.

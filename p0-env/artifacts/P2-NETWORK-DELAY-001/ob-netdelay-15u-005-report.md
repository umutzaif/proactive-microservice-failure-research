# ob-netdelay-15u-005 invalid/incomplete preflight raporu

Run canonical `main` revision `92a6d4f22898e2e649d2d4ad893c5285b1139f1f`
üzerinde başlatıldı. Başlangıç host sayaçları WHEA Event 17 / Kernel-Power 41 /
bugcheck için `881/5/1`; Docker `29.6.1`; preregistration verifier `13/13` idi.
Fresh base deployment ve canlı run-ID propagation geçti; Prometheus `4118`
run-scoped series gösterdi ve collector/Prometheus runtime `005` kimliğini doğruladı.

Proxy rollout sonrasındaki dondurulmuş `120 sn / 5 sn` convergence kapısı 22 gözlem
üretti ve `live_proxy_single_ready_pod_timeout` ile fail-closed durdu. İlk gözlemde
iki pod, kalan 21 gözlemde tek pod vardı; birleşik Ready `0/22` kaldı. Yeni poddaki
`network-delay-proxy` `22/22` Ready ve `0` restart idi. `server` yalnız ilk gözlemde
Ready oldu; restart sayısı `0 -> 4` yükseldi, termination kayıtları exit `137` /
reason `Error` gösterdi ve son durum `CrashLoopBackOff` oldu. Pod condition
`ContainersNotReady: [server]` idi.

Bu kanıt failure'ın proxy container'dan değil, tekrarlanan server-container
termination'ından kaynaklandığını ayrıştırır. Ancak exit `137` tek başına OOM veya
altta yatan kesin nedeni kanıtlamaz; böyle bir kök neden iddia edilmez.

Warmup ve fault başlamadı. D-038 target stability, scientific lifecycle ve
raw/enriched log, metric, trace arşivleri reached olmadı; yokluk invalid receipt'te
açıkça bağlanır. Base rollback geçti, proxy ConfigMap silindi, Minikube durduruldu ve
host farkı `0/0/0` oldu. Run invalid/incomplete, Dataset v1/modeling dışıdır; ID
yeniden kullanılmaz ve eşikler sonuçtan sonra değiştirilmemiştir.

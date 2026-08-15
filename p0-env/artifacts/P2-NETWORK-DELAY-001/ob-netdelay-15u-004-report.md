# ob-netdelay-15u-004 invalid/incomplete preflight raporu

## Sonuç

Run `invalid/incomplete` sınıflandırılmıştır. Fault ve warmup başlamamıştır; veri
Dataset v1 veya modelleme kapsamına alınamaz. Aynı run ID yeniden kullanılamaz.

## Kanıt

- PR #63 sonrası canonical revision: `619972a3d90f6dd75c4a6f56df0fd8114cd13b20`.
- Host başlangıç/bitiş sayımları `881/5/1`; fark `0/0/0`.
- Docker `29.6.1`; Minikube temiz stopped durumundan başlatıldı.
- Prereg `13/13`, readiness fixture, canonical UTC ve runner contract geçti.
- Base deployment ve proxy rollout tamamlandı.
- D-046 bounded convergence 22 gözlem aldı: ilk iki gözlemde iki pod, sonraki 20
  gözlemde tek pod vardı; hiçbir gözlemde pod ve iki container birlikte Ready olmadı.
- Son gözlemde tek pod `recommendationservice-6c9559fbd6-285ff`, `ready=false`.
- `live_proxy_single_ready_pod_timeout` fault öncesi fail-closed durdu.
- Proxy-clean, D-038 target-stability ve lifecycle'a ulaşılmadığı için raw/enriched
  log, metric ve trace arşivleri oluşmadı.
- Rollback doğrulandı: yalnız `server` container, doğrudan
  `productcatalogservice:3550`, proxy ConfigMap yok. Minikube durduruldu.

## Yorum sınırı

Bu attempt ağ gecikmesinin fiziksel etkisi veya manifestation hakkında bilgi vermez.
Kanıt tek pod'a yakınsamanın gerçekleştiğini fakat Ready bileşeninin 120 saniyede
geçmediğini gösterir; hangi container/condition'ın neden hazır olmadığını mevcut
özet kanıt ayrıştırmaz. Timeout veya eşikler sonuçtan sonra değiştirilmez. Yeni run
öncesinde ayrı no-fault canlı readiness tanısı ve açık araştırma kararı gerekir.

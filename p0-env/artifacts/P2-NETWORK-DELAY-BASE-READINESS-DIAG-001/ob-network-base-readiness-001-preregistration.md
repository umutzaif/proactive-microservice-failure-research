# ob-network-base-readiness-001 ön-kaydı

## Amaç ve kapsam

Bu faultsuz operasyonel tanı, `ob-netdelay-500m-normal-10u-002` base deployment
availability hatasından sonra recommendationservice için taze readiness/stability
kanıtı toplar. Dataset, D-067 headroom girdisi, normal tekrar veya ladder fault run'ı
değildir. Toxic oluşturulmaz; warm-up, baseline ve bilimsel pencere başlatılmaz.

## Dondurulmuş koşullar

- Tanı kimliği: `ob-network-base-readiness-001`.
- Gate: `P2-NETWORK-DELAY-BASE-READINESS-DIAG-001`.
- Revision: tanı commit'i; çalışma ağacı temiz olmalıdır.
- Deployment: mevcut `p0-env/config/online-boutique` base manifesti. İçindeki
  `ob-default-10u-1r-v1` workload bağı değiştirilmez.
- Proxy/resource overlay ve toxic/fault: yasak.
- Convergence bütçesi: mevcut deploy availability sınırıyla aynı `900 sn`; poll `5 sn`.
- Stability penceresi: recommendationservice Available olduktan sonra `180 sn / 5 sn`.
- Başarı: stability penceresindeki her örnekte tam bir silinmeyen pod, değişmeyen UID,
  `server` container Ready, değişmeyen restart sayısı ve Waiting/Terminated yokluğu.
- Kapanış: deployment/ReplicaSet/pod/probe/events/log/node/kubelet, RecordId host,
  cluster stop, SHA-256 seal ve offline replay kanıtı.

## Yorum sınırı

Başarı yalnız taze base readiness/stability desteğidir; `10u-002` için kök neden,
500m overlay stability'si veya replacement normal run geçerliliği değildir. Başarısızlık
da latency/headroom sonucu değildir. Timeout, probe, resource, workload, topology veya
bilimsel eşik bu tanı sonucuna göre otomatik değiştirilemez. Replacement ancak yeni ID,
değişmeyen D-067 sözleşmesi ve ayrı ön-kayıtla ele alınabilir.


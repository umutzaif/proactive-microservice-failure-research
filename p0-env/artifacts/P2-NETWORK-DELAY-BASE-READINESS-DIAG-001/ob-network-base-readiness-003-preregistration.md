# ob-network-base-readiness-003 replacement ön-kaydı

`ob-network-base-readiness-002`, Docker hazır olmasına rağmen Kubernetes API server
süreci oluşmadan `K8S_APISERVER_MISSING` ile invalid/incomplete kapandı ve ID yeniden
kullanılmaz. D-073 `ob-k8s-bootstrap-001`, aynı cluster sözleşmesinde temiz Kubernetes
bootstrap'ını destekledi; ancak application veya recommendationservice readiness sonucu
üretmedi. Bu replacement yalnız eksik application-level readiness/stability gözlemini
aynı D-071 koşullarında toplar.

Tanı kapsamı değişmez: mevcut `p0-env/config/online-boutique` base manifesti ve
`ob-default-10u-1r-v1` workload bağı; proxy/resource overlay ve toxic/fault: yasak;
900 sn / 5 sn convergence; Available sonrasında 180 sn / 5 sn sabit pod UID, server
Ready ve restart gözlemi; deployment/ReplicaSet/events/log/node/kubelet, RecordId host,
cluster stop, SHA-256 seal ve offline replay.

Başarı ölçütü `fresh_base_stability_supported`; convergence oluşmaması, en az 30 stability
örneğinin tamamlanmaması, server Ready durumunun bozulması, waiting/terminated state,
pod UID veya restart sayısı değişimi `fresh_base_stability_not_supported` sonucudur.
Sonuç görüldükten sonra timeout, probe, resource, topology, workload veya ölçüt değişmez.

Sonuç Dataset v1, değişmeyen D-067 headroom veya bağımsız incident sayımına girmez ve
nedensel kök neden üretmez. Başarı bile replacement normal run veya fault injection
yetkisi değildir; canlı tanı yalnız canonical merge ve ayrı açık runtime onayıyla
çalıştırılabilir.

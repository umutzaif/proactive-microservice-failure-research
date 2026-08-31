# ob-network-base-readiness-004 application-readiness ön-kaydı

D-085 `ob-k8s-bootstrap-recovery-001`, exact-profile clean reconstruction sonrasında
değişmeyen Kubernetes sözleşmesinin sağlıklı kurulabildiğini gösterdi; application,
workload veya recommendationservice readiness sonucu üretmedi. D-075 kapsamında
`ob-network-base-readiness-003` Kubernetes preflight'ında invalid/incomplete kapandı ve
ID yeniden kullanılamaz. Bu yeni diagnostic yalnız eksik application-level
readiness/stability gözlemini aynı D-071/D-074 koşullarında toplar.

Tanı kapsamı değişmez: mevcut `p0-env/config/online-boutique` base manifesti ve
`ob-default-10u-1r-v1` workload bağı; proxy/resource overlay ve toxic/fault: yasak;
900 sn / 5 sn convergence; Available sonrasında 180 sn / 5 sn sabit pod UID, server
Ready ve restart gözlemi; deployment/ReplicaSet/events/log/node/kubelet, RecordId host,
cluster stop, SHA-256 seal ve offline replay.

Başarı ölçütü `fresh_base_stability_supported`; convergence oluşmaması, en az 30
stability örneğinin tamamlanmaması, server Ready durumunun bozulması,
waiting/terminated state, pod UID veya restart sayısı değişimi
`fresh_base_stability_not_supported` sonucudur. Sonuç görüldükten sonra timeout, probe,
resource, topology, workload veya ölçüt değişmez.

Sonuç Dataset v1, değişmeyen D-067 headroom veya bağımsız incident sayımına girmez ve
nedensel kök neden üretmez. Başarı bile replacement normal run veya fault injection
yetkisi değildir. Repository hazırlığı ve canonical merge; cluster, application,
workload veya runtime yetkisi değildir. Canlı tanı yalnız merge sonrasında ayrı açık
runtime onayıyla çalıştırılabilir; profile delete/reset bu tanının parçası değildir.

# ob-network-base-readiness-005 source-gated replacement ön-kaydı

D-086 `ob-network-base-readiness-004`, Kubernetes bootstrap sonrasında base apply
öncesinde worktree-local ignored Online Boutique kaynağı eksik olduğu için
invalid/incomplete kapandı ve ID yeniden kullanılamaz. Yeni `005`, aynı application
readiness/stability sorusunu yalnız pinned source preflight ekleyerek tekrarlar.

Runner cluster başlamadan önce `p0-env/source/microservices-demo` dizisinin varlığını ve
HEAD revisionının `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` olduğunu fail-closed doğrular.
Kaynağın indirilmesi veya kopyalanması bu ön-kaydın ve runtime'ın parçası değildir;
ayrı hazırlık ve bağımsız revision doğrulaması gerekir.

Diğer koşullar değişmez: `p0-env/config/online-boutique` + `ob-default-10u-1r-v1`;
proxy/resource overlay ve toxic/fault: yasak; 900 sn / 5 sn convergence; Available
sonrasında 180 sn / 5 sn sabit pod UID, server Ready ve restart gözlemi; host, cluster
stop, semantic verifier ve seal/replay. Sonuç-sonrası timeout, probe, resource,
topology, workload veya ölçüt değişmez.

Sonuç Dataset v1, D-067 headroom veya incident sayımına girmez; application sonucu
başarı olsa bile replacement normal veya fault yetkisi üretmez. `canonical merge` source
hazırlığı veya runtime yetkisi değildir. Canlı `005` yalnız pinned source ayrı biçimde
hazırlandıktan, merge doğrulandıktan ve yeni açık runtime onayı alındıktan sonra çalışır.

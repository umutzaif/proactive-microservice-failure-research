# ob-network-base-readiness-006 optional-pod-state replacement ön-kaydı

D-087 `ob-network-base-readiness-005`, pinned source, Kubernetes start ve base apply
sonrasında ilk snapshot'ta henüz bulunmayan `containerID` alanına doğrudan StrictMode
erişimi nedeniyle invalid/incomplete kapandı. ID yeniden kullanılamaz. Yeni `006`, aynı
application readiness/stability sorusunu yalnız erken pod state okumasını güvenli hale
getiren teknik düzeltmeyle tekrarlar.

Pod snapshot dönüştürücüsü eksik `conditions`, `containerStatuses` ve `containerID`
alanlarını gözlenmemiş/null olarak korur; veri uydurmaz. Pending pod ve `containerID`
oluşmamış ContainerCreating server fixture'ları PowerShell 5.1/7 uyumlu deterministic
testte geçmelidir. Pinned source kapısı exact
`5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` olarak değişmez.

Diğer koşullar değişmez: base + `ob-default-10u-1r-v1`; proxy/resource overlay ve
toxic/fault: yasak; 900 sn / 5 sn convergence; Available sonrasında 180 sn / 5 sn sabit
pod UID, server Ready ve restart gözlemi; host, stop, semantic verifier ve seal/replay.
Timeout, probe, resource, topology, workload veya sınıflandırma ölçütü değiştirilmez.

Sonuç Dataset v1, D-067 headroom veya incident sayımına girmez ve application başarısı
replacement normal/fault yetkisi üretmez. `canonical merge` runtime değildir; canlı `006`
yalnız merge sonrasında yeni açık runtime onayıyla çalıştırılır.

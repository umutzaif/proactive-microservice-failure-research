# ob-network-base-readiness-009 SSH-key provenance replacement ön-kaydı

D-097, `ob-network-base-readiness-008` koşusunu canonical merge
`63dc70aed38ec0a39dbccb9cede99cf9c3da347d` altında invalid/incomplete ve kapalı korur.
Salt-okunur takipte `Documents\Makale` runtime-state public key fingerprint'i
`SHA256:XncUCIjw5vHqQfhCy9PM5nFy+4p6lwqRkZcgMxas5LQ` iken stopped container içindeki tek
`authorized_keys` fingerprint'i `SHA256:E8X6DYnpxGPJpp3lUOnbtLCow0oNNLC9HomdrrWBEOs`
olarak ölçüldü; exact key eşleşmedi. Container anahtarı `44eb` runtime-state kökündeki
public key ile byte ve fingerprint düzeyinde eşleşti.

D-098 kapsamında yeni benzersiz `ob-network-base-readiness-009`, D-095 application
sözleşmesini değişmeden tekrarlar. Cluster başlamadan explicit runtime-state kökündeki
public key ile stopped exact container `/home/docker/.ssh/authorized_keys` key material'i
karşılaştırılır. Host public key SHA-256 değeri
`86bf057eb0bf9488079879a62c297157bd9e0b2a835b9097dc9d61b79d7e02b1`, fingerprint'i
`SHA256:E8X6DYnpxGPJpp3lUOnbtLCow0oNNLC9HomdrrWBEOs` olmalı ve exact key container listesinde
bulunmalıdır. Private key içeriği artifact'a yazılmaz.

Pinned source `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`, base +
`ob-default-10u-1r-v1`, 900 sn / 5 sn convergence, 180 sn / 5 sn stability,
no-overlay, toxic/fault: yasak, host, stop, semantic verifier ve seal/replay koşulları
değişmez. Minikube start stdout/stderr/exit code D-097 tooling'iyle korunur.

Sonuç Dataset v1, D-067 headroom veya incident sayımına girmez; başarı replacement normal
veya fault yetkisi üretmez. `canonical merge` runtime değildir. Canlı `009` yalnız merge
sonrasında ayrı açık runtime onayıyla yürütülebilir; profile delete/reset kapsam dışıdır.

# ob-network-proxy-readiness-002 incomplete tanı raporu

Fault/toxic uygulanmadı. 180 saniyelik pencere 33 gözlem üretti. Yeni overlay podunda
`network-delay-proxy` `33/33`, `server` `31/33` Ready idi; server yalnız ilk iki
gözlemde Ready değildi. `004`teki kalıcı 120 saniyelik readiness başarısızlığı yeniden
üretilmedi.

Deployment, ReplicaSet ve events arşivlendi. Current pod seçimi sırasında opsiyonel
`deletionTimestamp` alanı bulunmadığı için current/previous log kapanışı tamamlanmadı;
tanı bu nedenle incomplete'tir. Rollback ve host `0/0/0` geçti, Minikube durduruldu.
ID kullanılmaz. Yeni tanı kalan erişimi null-safe yapmalı ve current-run events/log
kapsamını kapatmalıdır.

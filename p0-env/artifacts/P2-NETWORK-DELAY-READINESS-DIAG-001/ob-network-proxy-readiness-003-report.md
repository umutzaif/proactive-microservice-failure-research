# ob-network-proxy-readiness-003 tamamlanmış tanı raporu

Fault/toxic uygulanmadı. 180 saniyelik pencere 33 gözlem üretti. Overlay podunda
`network-delay-proxy` `33/33` Ready ve `0` restart; `server` `30/33` Ready ve en çok
`1` restart idi. İlk gözlemden `16,616` saniye sonra tek canlı podun iki container'ı
birlikte Ready oldu ve pencerenin kalanında Ready kaldı.

Güncel Kubernetes olayları proxy hatası göstermedi. Buna karşılık server için 8080
readiness/liveness timeout ve bir restart kaydedildi. Proxy current logu Toxiproxy'nin
proxy/API listener'larını normal başlattığını gösterdi; previous proxy logunun yokluğu
restart olmamasıyla uyumludur. Server current/previous logları kapatıldı.

`ob-netdelay-15u-004`teki 120 saniyelik kalıcı failure, iki ayrıntılı diagnostic
pencerede yeniden üretilmedi. Kanıt kısa süreli recommendationservice server startup
kararsızlığını gösterir; fakat `004` per-container readiness kaydetmediği için o run'ın
kesin kök nedeni geriye dönük kanıtlanamaz.

Rollback yalnız `server` container'ı ve doğrudan `productcatalogservice:3550`
adresini doğruladı. Host WHEA Event 17 / Kernel-Power 41 / bugcheck farkı `0/0/0`.
Ham kanıtların SHA-256 manifesti aynı immutable klasörde kapatıldı. Tanı geçerli ve
tamamlanmıştır ancak bilimsel dataset/modeling girdisi değildir; ID tekrar kullanılmaz.

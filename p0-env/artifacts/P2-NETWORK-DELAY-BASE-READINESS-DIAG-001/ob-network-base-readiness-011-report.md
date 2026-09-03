# ob-network-base-readiness-011 valid operational diagnostic report

## Status

`ob-network-base-readiness-011`, canonical revision
`5bac21a72253d80ad92a47dcacf39a0c57f2370b` üzerinde **valid** tamamlandı ve kapandı.
Kimlik yeniden kullanılamaz.

## Verified result

Runtime/source/SSH preflight, exact post-`010` stopped state ve source-bound deployment
bundle geçti. Base + 10u workload altında availability ulaşıldı. Toplam 37 gözlemden 34'ü
180 saniyelik stability penceresindeydi. Stability boyunca tek pod UID
`c18ddf4c-c328-4d69-b186-21efd5685b13`, sabit restart count `6`, tüm örneklerde Ready server
ve sıfır bad container state doğrulandı. Restart `6`, stability öncesindeki tarihsel toplamdır;
pencere içinde artmamıştır.

Null-safe capture boş previous logu geçerli zero-byte dosya olarak korudu. Semantic verifier,
host WHEA-17/Kernel-Power-41/BugCheck `0/0/0`, stopped profile, container exit 137/
`OOMKilled=false` ve 16-file SHA-256 replay geçti. Manifest SHA-256:
`ee57798543e59b58139e976f9c342d58520327cacb63f55d069e10deae0ac99a`.

## Interpretation boundary

Sonuç `fresh_base_stability_supported` operational assessment'ını destekler. Önceki
normal koşunun benzersiz nedenini, dış ağ/Wi-Fi etkisini veya 500m no-toxic overlay'i
doğrulamaz. Dataset v1, D-067 headroom ve incident sayımına girmez; D-067 10u `1/3`,
15u `2/3` kalır. Replacement normal veya fault için ayrı karar ve onay gerekir.


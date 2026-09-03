# ob-network-base-readiness-010 source-bound deployment replacement ön-kaydı

D-099, canonical D-098 merge revisionı
`39f00a9317341b41d889fe79c6a5893e564d5954` altında çalışan
`ob-network-base-readiness-009` kanıtını invalid/incomplete ve kapalı korur.

Yeni benzersiz `ob-network-base-readiness-010`, D-098 application sözleşmesini değiştirmeden
tekrarlar. Runner, doğrulanmış pinned source root'taki `kustomize/base` dosyalarını geçici
bir **source-bound temporary deployment bundle** içine kopyalar; canonical overlay'in
namespace, observability ve patch içeriğini bu yerel `upstream-base` kopyasına bağlar.
Checkout-relative `p0-env/source` deploy girdisi olarak kullanılmaz. Bundle source revisionı,
upstream dosya sayısı, üretilen kustomization SHA-256 değeri ve relative-reference=false
kanıtı artifact içinde semantic verifier tarafından denetlenir; geçici bundle finally'de silinir.

Runtime-state/source/`authorized_keys` preflight'ı, pinned source
`5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`, base + `ob-default-10u-1r-v1`,
900 sn / 5 sn convergence, 180 sn / 5 sn stability, no-overlay ve toxic/fault: yasak
sınırları değişmez. Host, profile stop, semantic verifier ve seal/replay zorunludur.

Sonuç Dataset v1, D-067 headroom veya incident sayımına girmez. `canonical merge` runtime,
replacement normal veya fault yetkisi vermez. Canlı `010`, merge sonrasında ayrıca açık
runtime onayı gerektirir; `009` tekrar çalıştırılamaz.

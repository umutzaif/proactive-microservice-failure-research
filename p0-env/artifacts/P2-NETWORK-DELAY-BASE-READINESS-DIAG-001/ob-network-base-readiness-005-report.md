# ob-network-base-readiness-005 invalid preflight report

`ob-network-base-readiness-005`, canonical `8c378800c9c69133600669a2e48926bac19b13f4`
üzerinde exact Online Boutique source revision
`5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` ile çalıştırıldı. Source preflight,
Kubernetes start ve base apply geçti. İlk readiness snapshot'ında erken container status
nesnesinde `containerID` henüz bulunmadığından doğrudan StrictMode erişimi fail-closed
durdu.

Base manifest ve 10u loadgenerator deployment'ı uygulandı; readiness/stability observation
dosyası oluşmadı ve recommendationservice sınıflandırması yoktur. Proxy/toxic, fault ve
bilimsel pencere başlamadı. Runner profile'ı durdurdu; container exit 130,
`OOMKilled=false`; host WHEA17/Kernel-Power41/bugcheck `0/0/0` geçti. Dört çekirdek
dosya SHA-256 seal/replay ile doğrulandı; manifest SHA-256
`9c58f4c9fd9f2ee7a3d07bcebb6092aa8ed24803a1bb4e5cc11968b97d548ab1`.

Bu tooling uyumsuzluğu application instability değildir. ID invalid/incomplete ve kapalıdır;
D-067 15u `2/3`, 10u `1/3` kalır. Replacement, eksik erken pod alanlarını optional
işleyen deterministic fixture, yeni kimlik, canonical merge ve ayrı runtime onayı ister.

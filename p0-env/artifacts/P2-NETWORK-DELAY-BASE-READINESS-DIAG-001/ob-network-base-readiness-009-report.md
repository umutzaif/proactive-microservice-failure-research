# ob-network-base-readiness-009 invalid operational diagnostic report

## Status

`ob-network-base-readiness-009`, canonical revision
`39f00a9317341b41d889fe79c6a5893e564d5954` üzerinde **invalid/incomplete** kapandı.
Kimlik yeniden kullanılamaz.

## Verified boundary

D-098 runtime/source ve SSH public-key congruence preflight'ı geçti. Minikube mevcut
`44eb` profile'ını başarıyla başlattı. Base apply ise overlay içindeki
`../../source/microservices-demo/kustomize/base` yolunu runner'a verilen explicit source
root'a değil, canonical code checkout'una göre çözmeye çalıştı ve `base_apply_failed` verdi.

Base, 10u workload ve readiness/stability gözlemi başlamadı. Scientific window ve fault
başlamadı. Profile kapanışta stopped; container `exit 130`, `OOMKilled=false`; host
WHEA-17/Kernel-Power-41/BugCheck farkları `0/0/0` oldu.

## Evidence and interpretation

Altı içerik dosyası SHA-256 manifesti altında mühürlendi; offline replay geçti. Bu sonuç,
SSH/start kapısının aşıldığını ve deploy girdisi ile explicit source provenance arasında
eksik bir bağ bulunduğunu gösterir. Application readiness sonucu değildir; Dataset v1,
D-067 headroom veya incident sayımına girmez. D-067 10u `1/3`, 15u `2/3` kalır.


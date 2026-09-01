# ob-network-base-readiness-004 invalid preflight report

`ob-network-base-readiness-004`, canonical `64bfad6dae654f7ebd4d5f3a1a9c67ec14e301a0`
üzerinde çalıştırıldı. Kubernetes v1.34.0 clean recovered profile başarıyla başladı;
ancak base kustomization'ın Git tarafından izlenmeyen
`p0-env/source/microservices-demo/kustomize/base` bağımlılığı bu izole worktree'de
bulunmadığından apply `base_apply_failed` ile kapandı.

Application manifesti uygulanmadı; workload, convergence, stability, proxy/toxic,
fault ve bilimsel pencere başlamadı. Recommendationservice sonucu yoktur. Runner
profile'ı durdurdu; container exit 130, `OOMKilled=false`; host RecordId farkı
WHEA17/Kernel-Power41/bugcheck `0/0/0` geçti. Dört çekirdek dosya SHA-256 seal ve
offline replay ile doğrulandı; manifest SHA-256
`d5a37e7296f41861d6b347504f5df6775dfcb0bbd1f1d6855b67a4304264bf73`.

Bu kanıt application instability veya bilimsel sonuç değildir. ID kapalıdır ve yeniden
kullanılamaz; D-067 15u `2/3`, 10u `1/3` kalır. Yakın operasyonel neden worktree-local
pinned source bağımlılığının eksikliğidir; sonraki replacement ayrı preregistration,
canonical merge ve runtime onayı gerektirir.

# ob-network-base-readiness-008 D-094 sonrası application-readiness ön-kaydı

D-094 `ob-docker-disk-recovery-001`, canonical merge
`09bf0e077f291318df561f16e48d38cc805ebcd7` ile kapandı. Exact profile delete ve
değişmeyen clean bootstrap sonrasında system katmanı 31/31 healthy sample, bir Ready node,
8/8 Running kube-system, host `0/0/0`, semantic verifier ve 12-file replay kapılarını geçti.
Bu kanıt application, workload veya proxy readiness değildir.

Yeni benzersiz `ob-network-base-readiness-008`, kapalı `007` kimliğini yeniden kullanmadan
D-089'un application sözleşmesini değişmeden tekrarlar: pinned Online Boutique source
`5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`, mevcut base manifest,
`ob-default-10u-1r-v1`, 900 sn / 5 sn convergence ve Available sonrasında
180 sn / 5 sn tek pod UID, server Ready ve sabit restart gözlemi.

Proxy overlay uygulanmaz; toxic/fault: yasak. Scientific window, telemetry export,
manifestation analizi ve normal final receipt başlatılmaz. Timeout, probe, resource,
topology, workload, disk gate ve bilimsel eşikler değiştirilmez. Profile delete/reset bu
diagnostic'in kapsamında değildir. Host RecordId sınırı, profile stop, semantic verifier
ve seal/replay zorunludur.

Sonuç Dataset v1, D-067 headroom veya incident sayımına girmez; başarı yeni replacement
normal veya fault yetkisi üretmez. `canonical merge` runtime değildir; canlı `008` yalnız
merge sonrasında bu görevde verilecek ayrı açık runtime onayıyla çalıştırılır.

## D-096 portability/provenance düzeltmesi

D-094 runtime-state ve pinned source ignored, checkout-local dizinlerdir; temiz canonical
worktree bunları otomatik paylaşmaz. Runner bu nedenle iki açık, zorunlu girdi alır:
runtime-state root ve Online Boutique source root. Her iki yol absolute resolved biçimde
manifest ve `preflight-provenance.json` içine yazılır.

Cluster başlamadan önce D-094 bağı `09bf0e077f291318df561f16e48d38cc805ebcd7`, exact
`p0-online-boutique` config'i, v1.34.0/4 CPU/6144 MiB/32 GiB/containerd, stopped container
`exit 130`/`OOMKilled=false`, exact volume ve pinned source revision doğrulanır. Eksik veya
farklı girdi artifact oluşturmadan fail-closed durur. D-096 `008` kimliğini, application
ölçütlerini veya bilimsel kapsamı değiştirmez; canonical merge yine runtime yetkisi değildir.

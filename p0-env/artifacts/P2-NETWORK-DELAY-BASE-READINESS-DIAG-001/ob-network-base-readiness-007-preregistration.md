# ob-network-base-readiness-007 verifier-closure replacement ön-kaydı

D-088 `ob-network-base-readiness-006` application observation'larını tamamladı ve
`fresh_base_stability_supported` assessment üretti; ancak semantic verifier `$Host`
değişken çakışmasında durdu ve runner child exit code'u denetlemedi. Zorunlu verifier
kapısı geçmediği için `006` invalid/incomplete ve kapalıdır. Yeni `007` aynı application
sorusunu yalnız verifier kapanış kusurlarını düzelterek tekrarlar.

Verifier host kanıtını alias-safe `$hostEvidence` değişkeninde işler. Sentetik geçerli
artifact fixture'ı Windows PowerShell 5.1 ve PowerShell 7'de success marker üretmelidir.
Runner semantic verifier child exit code'unu zorunlu kontrol eder; nonzero durumda
kanıtı seal eder, `semantic_verifier_failed` ile kapanır ve `completed` üretemez.

Pinned source `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb`, optional pod-state fixture'ları,
base + 10u, toxic/fault: yasak, 900 sn / 5 sn convergence, 180 sn / 5 sn stability,
host, stop, semantic verifier ve seal/replay koşulları değişmez. Timeout, probe,
resource, topology, workload ve sınıflandırma ölçütü değiştirilmez.

Sonuç Dataset v1, D-067 headroom veya incident sayımına girmez; başarı replacement
normal/fault yetkisi üretmez. `canonical merge` runtime değildir; canlı `007` yalnız
merge sonrasında yeni açık runtime onayıyla çalıştırılır.

# ob-network-base-readiness-006 invalid verifier-closure report

`ob-network-base-readiness-006`, canonical `fc180c8498af3807cc404592a868ab53700131ab`
ve pinned source `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` üzerinde çalıştırıldı.
Availability sağlandı; 60 observation ve 32 stability örneği toplandı. Assessment tek
pod UID, restart `0`, bütün stability örneklerinde server Ready ve bad container state
yokluğuyla `fresh_base_stability_supported` üretti.

Zorunlu semantic verifier, PowerShell'in salt-okunur `$Host` değişkeniyle case-insensitive
çakışan `$host` atamasında durdu. Runner child verifier exit code'unu kontrol etmediği için
seal ve yanıltıcı `completed` marker'ına devam etti. Bu nedenle olumlu assessment tanısal
olarak korunur fakat diagnostic valid sayılamaz. Profile stopped; container exit 137,
`OOMKilled=false`; host WHEA17/Kernel-Power41/bugcheck `0/0/0` geçti. On üç çekirdek
dosyanın SHA-256 replay'i geçti; manifest SHA-256
`38490ec350a6b48dda34d42072e2bd262d44b175f8a436deaa50a808cfa0412c`.

ID invalid/incomplete ve kapalıdır. Sonuç Dataset v1, D-067 headroom, incident,
replacement normal veya fault yetkisi üretmez; D-067 15u `2/3`, 10u `1/3` kalır.

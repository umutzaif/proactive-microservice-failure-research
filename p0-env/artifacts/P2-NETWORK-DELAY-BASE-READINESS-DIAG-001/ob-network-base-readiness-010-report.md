# ob-network-base-readiness-010 invalid operational diagnostic report

## Status

`ob-network-base-readiness-010`, canonical revision
`8e15ef1a11034b62110d90822521c6f21263dcc5` üzerinde **invalid/incomplete** kapandı.
Kimlik yeniden kullanılamaz.

## Verified boundary

Runtime/source/SSH preflight ve source-bound deployment bundle geçti; Minikube ve base +
10u workload başladı. Toplam 74 örnek toplandı. Recommendationservice bir kez Ready olarak
180 saniyelik stability penceresini başlattı; 33 stability örneğinde tek UID korunurken
restart count `1..5` oldu, yalnız bir server örneği Ready idi ve 18 kötü container-state
örneği görüldü. `CrashLoopBackOff` ile server exit 137 gözlendi.

Evidence capture, boş current/previous log çıktısının PowerShell'de `$null`a çözülmesi ve
`WriteAllLines`ın null contents'i reddetmesiyle assessment/semantic-verifier öncesinde durdu.
Bu nedenle gözlemler olumsuz olsa da diagnostic geçerli assessment olarak yorumlanmaz.

Profile kapanışta stopped; container `exit 137`, `OOMKilled=false`; host
WHEA-17/Kernel-Power-41/BugCheck farkları `0/0/0` oldu. On üç içerik dosyasının SHA-256
mührü offline replay ile geçti. Fault/scientific window yoktur; Dataset v1 ve D-067
değişmez.


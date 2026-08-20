# ob-netdelay-15u-007 invalid/incomplete raporu

PR #78 sonrası Git ve yerel contract kapıları geçti; başlangıç RecordId `137584`,
Docker `29.6.1` ve Minikube `Stopped` olarak bağımsız doğrulandı. Runner'ın bilimsel
preflight'ı başlamadan PowerShell `ShouldProcess` çağrısı non-interactive bağlamda
null-reference üretti. Cluster/deployment, warmup, fault ve lifecycle başlamadı.

Altı runner çıktı kökü girişimden sonra yoktu; Minikube `Stopped` kaldı. Host RecordId
`137584 -> 137584`, yeni WHEA17/KP41/bugcheck `0/0/0`. Run invalid/incomplete olarak
korunur, ID yeniden kullanılamaz ve eşikler değişmez. Replacement, `-Confirm:$false`
entrypoint sözleşmesini önce fixture ile doğrulayan yeni benzersiz kimlik gerektirir.

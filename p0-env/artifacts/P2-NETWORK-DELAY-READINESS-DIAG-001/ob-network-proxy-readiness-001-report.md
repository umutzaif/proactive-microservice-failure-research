# ob-network-proxy-readiness-001 incomplete tanı raporu

Fault veya toxic uygulanmadı. Base deployment ve proxy rollout sonrasında ilk pod
condition snapshot'ı yazılırken opsiyonel `reason` alanı bulunmadığı için PowerShell
StrictMode fail-closed durdu. Readiness kök nedeni belirlenemedi.

Rollback doğrulandı; recommendationservice yalnız `server` container ve doğrudan
`productcatalogservice:3550` adresine döndü. Minikube durduruldu. Host başlangıç/bitiş
sayımı `881/5/1`, fark `0/0/0`dır. Diagnostic ID yeniden kullanılmaz. Düzeltme
opsiyonel Kubernetes alanlarını eksik olduğunda `null` kaydetmeli ve yeni benzersiz
diagnostic ID ile yürütülmelidir.

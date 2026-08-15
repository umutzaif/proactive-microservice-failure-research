# ob-network-server-termination-001 tamamlanmış tanı raporu

Scientific toxic/fault uygulanmadı. No-toxic overlay altında 180 saniyelik pencere
33 gözlem üretti. `network-delay-proxy` `33/33` Ready ve 0 restart kaldı;
recommendationservice `server` en çok 5 restart gördü ve final state
`CrashLoopBackOff`, son termination `Error/137` idi.

Kubernetes events doğrudan `Container server failed liveness probe, will be restarted`
mesajını 5 kez kaydetti. Deployment'ta server liveness/readiness sözleşmesi gRPC 8080,
`timeoutSeconds=1`, `periodSeconds=5`, `failureThreshold=3` idi. Previous server logu
container'ın initialization, profiler, proxy adresi ve `listening on port: 8080`
adımlarına ulaştığını; ardından probe connection timeout zincirinin oluştuğunu gösterdi.

Node hem önce hem sonra Ready, `MemoryPressure=False`, `DiskPressure=False` ve
`PIDPressure=False` idi. Container status `OOMKilled` değil `Error/137` kaydetti.
Bu kanıt doğrudan operasyonel nedeni kubelet'in tekrarlanan liveness timeout'ları
sonrası server'ı restart etmesi olarak sınıflandırır; OOM hipotezini desteklemez.

Metrics API cluster'da mevcut değildi. Bu yüzden probe timeout'unun altında CPU
starvation, kısa runtime stall veya başka bir responsiveness nedeni olup olmadığı
çözülemez. Exit 137 tek başına OOM kanıtı olarak kullanılmaz; probe veya resource
ayarları değiştirilmez ve replacement belirlenmez.

Rollback yalnız base `server` container'ı ve doğrudan `productcatalogservice:3550`
adresini doğruladı. Minikube durduruldu, host WHEA Event 17 / Kernel-Power 41 /
bugcheck farkı `0/0/0` geçti. Tanı geçerli ve tamamlanmıştır fakat Dataset v1/modeling
girdisi değildir; diagnostic ID tekrar kullanılmaz.

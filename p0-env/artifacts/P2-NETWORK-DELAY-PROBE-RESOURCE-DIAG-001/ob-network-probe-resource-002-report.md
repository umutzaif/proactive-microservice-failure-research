# ob-network-probe-resource-002 geçerli tamamlanmış tanı raporu

Scientific toxic/fault uygulanmadı. D-048 ile ön-kayıtlı no-toxic overlay 180 saniye
ve 5 saniyelik poll ile tamamlandı. Hedef pod UID
`f181078c-c05c-44fb-8d59-0d2a12892670` için proxy `33/33` Ready ve restart `0`;
server `1/33` Ready, restart maksimum `5` ve kapanış durumu `CrashLoopBackOff` idi.
Kubernetes aynı event nesnesinde beş liveness-probe `Killing` occurrence'ı kaydetti.
Son server termination `137/Error` idi; bu değer tek başına OOM kanıtı sayılmadı.

Prometheus arşivi aynı pod/server için 13 cAdvisor metric türünü 180 saniye boyunca
kapattı. Container restartları ayrı cgroup serileri ürettiği için counter artışları
seri içinde hesaplanıp toplandı. CPU toplamı `7,310895 sn`, 180 saniyelik pencere
ortalaması `40,616m`, maksimum ardışık-sample rate `499,307m`; throttled time
`28,907722 sn` ve ölçülen CFS throttled-period oranı `363/363 = %100` idi. CPU
pressure waiting artışı `21,270718 sn` oldu. Memory working-set maksimum
`26.697.728 byte` (`25,46 MiB / 450 MiB`); memory failcnt, OOM event ve memory
pressure waiting artışı `0` kaldı. Node Memory/Disk/PID pressure false ve Ready true
olarak değişmeden kaldı.

Bu eşzamanlı tekrar, server'ın 200m CPU kotasında yoğun CFS throttling ve CPU pressure
yaşamasının liveness timeout/restart zinciri için güçlü bir yakın-mekanizma açıklaması
olduğunu destekler; memory/OOM ve node-pressure hipotezlerini desteklemez. Gözlemsel
tanı, CPU throttling'in tek nihai kök neden olduğunu veya farklı probe/resource
ayarının bilimsel olarak üstün olduğunu kanıtlamaz.

Host System `RecordId` `136167 -> 136167` monoton kaldı; yeni WHEA 17,
Kernel-Power 41 ve bugcheck `0/0/0`. Rollback base tek `server` container ve doğrudan
`productcatalogservice:3550` adresini doğruladı; Minikube durduruldu. Bağımsız verifier
`completed_valid_diagnostic` döndürdü. İlk mühürlü schema-v1 özetindeki
`liveness_killing_count=1` event-nesnesi sayısıdır; ham event `count=5` occurrence
taşır. Bu semantik schema-v2 salt-okunur replay'de `event_objects=1` ve
`occurrences=5` olarak ayrıldı. 18 dosyalık SHA-256 manifesti offline replay'de
`18/18`, mismatch `0` geçti. Diagnostic Dataset v1/modeling dışıdır; replacement
resource/probe koşulu bu sonuç içinde belirlenmez.

# ob-network-resource-compat-005 valid raporu

D-054 no-toxic replacement run'ı fresh Git/ID/RecordId-host, base deployment,
collector/Prometheus `ob-netdelay-15u-005`, `ob-second-15u-1r-v1` (15 kullanıcı,
spawn rate 1, seed 1), 500m/100m canlı deployment ve proxy clean-state kapılarını
geçti. Toxic/fault uygulanmadı.

Aynı pod UID'siyle 23 stability ve 34 measurement örneğinde server/proxy `%100`
Ready ve restart `0` idi. On üç cAdvisor metric türü 180 saniyeyi kapsadı. CFS
throttled period `16/1154` (`0,0138648`), CPU pressure waiting artışı `0,498235 sn`,
maksimum working set `34.852.864 byte`; memory failcnt, OOM ve memory pressure artışı
`0` idi. Node pressure yoktu; proxy önce/sonra temiz ve rollback başarılıydı.

D-054 provenance kapısı expected run ID, artifact klasörü ve `run-manifest.json`
kimliğini `ob-network-resource-compat-005` olarak eşleştirdi; manifest telemetry ID,
workload, 500m/100m ve no-fault sözleşmesini doğruladı. RecordId `137554 -> 137564`
monoton ve yeni WHEA Event 17, Kernel-Power 41, bugcheck `0/0/0`; Minikube tamamen
Stopped idi.

On dokuz ham/enriched lifecycle, metric, log, host, rollback, manifest ve verifier
dosyası SHA-256 ile mühürlendi; resmi ve bağımsız replay `19/19` geçti. Run valid
no-toxic resource compatibility kanıtıdır, fakat Dataset v1 fault/modeling örneği
değildir. Sonuç D-050/O-020 compatibility kapısını kapatır; scientific fault veya
sonraki akademik aşamaya otomatik yetki vermez.

# ob-network-resource-compat-004 invalid provenance raporu

D-053 replacement run'ı fresh Git/ID/RecordId-host, base deployment, collector ve
Prometheus `ob-netdelay-15u-005` bağı, `ob-second-15u-1r-v1` workload'u ve proxy
clean-state kapılarını geçti. Toxic/fault uygulanmadı.

500m overlay altında aynı pod UID'siyle 23 stability ve 34 measurement örneği
toplandı; iki container tüm örneklerde Ready ve restart 0 idi. On üç cAdvisor metric
türü 180 saniyeyi kapsadı. CFS throttled period `18/1127` (`0,0159716`), CPU pressure
waiting artışı `0,534809 sn`, maksimum working set `34.742.272 byte`; failcnt, OOM ve
memory pressure artışı `0` idi. Node pressure yoktu, proxy önce/sonra temizdi,
rollback geçti. RecordId `137533 -> 137546` monoton ve yeni WHEA Event 17,
Kernel-Power 41, bugcheck `0/0/0`; Minikube tamamen Stopped idi.

Ancak canonical verifier artifact dizini `ob-network-resource-compat-004` olmasına
rağmen sonuçtaki `run_id` alanını hard-coded `ob-network-resource-compat-002` yazdı
ve expected/observed run-ID eşleşmesini gate olarak denetlemedi. Bu provenance
çelişkisi bağımsız `provenance-verification.json` içinde fail-closed kaydedildi.
Dolayısıyla fiziksel/lifecycle eşikleri geçmiş olsa da run bilimsel olarak invalid
sınıflandırılır ve Dataset v1'e alınmaz.

On dokuz ham/enriched lifecycle, metric, host, rollback, log ve verifier dosyası
SHA-256 manifestiyle mühürlendi; resmi ve bağımsız replay `19/19` geçti. ID yeniden
kullanılmaz, eşikler değiştirilmez. Verifier provenance düzeltmesi ve olası benzersiz
replacement ayrı kontrollü commit gerektirir.

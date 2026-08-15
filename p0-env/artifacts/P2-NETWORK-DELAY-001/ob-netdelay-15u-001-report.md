# ob-netdelay-15u-001 invalid run raporu

Durum: **invalid/incomplete; kanıt korundu; run ID tekrar kullanılamaz**.

Fresh Git/host/Docker/Minikube, 15 deployment, active run-ID, workload, canlı proxy,
`toxics=[]` ve target stability kapıları geçti. Warmup ve baseline tamamlandı; toxic
120,094 saniyede 12 adımla 750 ms'ye çıktı. PowerShell 7 `ConvertFrom-Json`, canonical
`ramp_end_utc` stringini `System.DateTime` nesnesine çevirdi; locale string dönüşümü
`Z` biçimini kaybetti ve steady deadline guard `phase_start_utc_must_be_canonical_z`
hatasıyla fail-closed durdu. Steady ve cooldown tamamlanmadığı için fiziksel etki ve
manifestation değerlendirilmedi.

Emergency cleanup `toxics=[]` durumunu doğruladı; base rollback geçti, proxy ConfigMap
silindi ve Minikube durduruldu. Host farkı WHEA 17 / Kernel-Power 41 / bugcheck için
`0/0/0`dır. Raw log, enriched log ve schema-v3 telemetry bağımsız verifier'ları geçti.
Invalid offline receipt bu arşivlerin ve lifecycle/host/cleanup/rollback kanıtlarının
SHA-256 hashlerini bağlar ve `valid_for_modeling=false` taşır.

Bu run dataset örneği değildir. Veri silinmez, üzerine yazılmaz, aynı ID ile
tekrarlanmaz ve eşikler sonuçtan sonra değiştirilmez. Replacement bu sonuç commitinde
belirlenmez.

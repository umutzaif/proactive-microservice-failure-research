# ob-network-proxy-readiness-003 replacement ön-kaydı

İlk iki diagnostic ID incomplete korunur ve kullanılmaz. Bu replacement current pod
seçimindeki eksik `deletionTimestamp` alanını null-safe resolver üzerinden okur.
Toxic/fault yoktur; 180/5 saniye gözlem, deployment/ReplicaSet/events, iki container
current/previous logları, rollback ve host sözleşmesi değişmez. Sonuç görülmeden
scientific timeout, readiness probe veya yeni network-delay run ID belirlenmez.

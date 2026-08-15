# ob-network-proxy-readiness-002 replacement ön-kaydı

İlk diagnostic ID incomplete korunur ve kullanılmaz. Bu replacement yalnız eksik
Kubernetes condition/container alanlarını `null` olarak kaydeden null-safe serializer
ekler. Toxic/fault yoktur; 180/5 saniye gözlem, events/log, rollback ve host sözleşmesi
değişmez. Sonuç görülmeden scientific timeout, readiness probe veya yeni network-delay
run ID belirlenmez.

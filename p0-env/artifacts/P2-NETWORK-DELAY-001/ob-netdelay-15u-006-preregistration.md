# P2-NETWORK-DELAY-001 / ob-netdelay-15u-006 ön-kaydı

Bu replacement, valid `ob-network-resource-compat-005` kanıtıyla 500m server CPU
limitini scientific lifecycle'a taşır. Workload `ob-second-15u-1r-v1` (15 kullanıcı,
spawn rate 1, seed 1), target edge, 12x10 saniyelik `0 -> 750 ms` ramp, jitter 0,
toxicity 1 ve `300/300/120/300/300` lifecycle değişmez.

Fiziksel etki, first-symptom, manifestation, schema-v3 boundary-crossing trace,
coverage, cleanup/rollback ve offline receipt eşikleri D-041/D-043 ile aynıdır.
Runner ayrıca RecordId host kapısı, native JSON stdout/stderr izolasyonu, immutable
run-manifest ve canlı server `500m/100m` sözleşmesini fault öncesinde zorunlu kılar.

Invalid kanıt silinmez; aynı ID tekrarlanmaz ve eşikler sonuçtan sonra değiştirilmez.
Bu commit fault yürütmez. Canonical merge ve ayrıca açık canlı yürütme onayı gerekir.
Model eğitimi, LLM doğrulaması ve graph/GAT çalıştırılmaz.

# P2-NETWORK-DELAY-001 / ob-netdelay-15u-003 replacement ön-kaydı

`ob-netdelay-15u-002` zorunlu normal final-receipt kapısında invalid olarak
korunmuş ve tekrar kullanımı yasaklanmıştır. Bu replacement yalnız fault-class-aware
metadata dispatch ve portable invalid-receipt v2 düzeltmelerini ekler; bilimsel
koşulları değiştirmez.

- workload: `ob-second-15u-1r-v1`; 15 kullanıcı, spawn rate 1, seed 1;
- target: `recommendationservice -> productcatalogservice`, downstream;
- ramp: jitter 0, toxicity 1, 12 adet 10 saniyelik adım,
  `63,125,188,250,313,375,438,500,563,625,688,750 ms`;
- lifecycle: `300 warmup / 300 baseline / 120 ramp / 300 steady / 300 cooldown`;
- fiziksel etki: baseline/steady ayrı ayrı en az 48 dolu 5 saniyelik pencere ve
  steady-baseline median fark `>=500 ms`;
- first symptom ve manifestation: D-041/D-043 eşikleri aynen korunur;
- bütün Git/host/Docker/Minikube/deployment/workload/run-ID/Prometheus/collector,
  proxy-clean ve 120 saniyelik target-stability kapıları fault öncesinde tekrar geçer;
- raw/enriched/schema-v3, boundary-crossing, cleanup/rollback, host ve offline receipt
  kapıları değişmez;
- başarısızlıkta Invalid kanıt silinmez, aynı ID tekrarlanmaz ve eşikler sonuçtan sonra değiştirilmez.

Bu ön-kayıt fault yürütmez. Canonical merge ve ayrıca açık kullanıcı yürütme onayı
gereklidir. model eğitimi, LLM doğrulaması ve graph/GAT çalıştırılmaz.

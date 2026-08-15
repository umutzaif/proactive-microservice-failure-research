# P2-NETWORK-DELAY-001 / ob-netdelay-15u-005 replacement ön-kaydı

`ob-netdelay-15u-004` warmup/fault öncesi bounded readiness kapısında invalid/
incomplete korunmuş ve tekrar kullanımı yasaklanmıştır. Fault'suz tamamlanmış tanı
proxy'nin 33/33 Ready ve 0 restart, server'ın 30/33 Ready ve 1 restart olduğunu;
tek all-Ready podun 16,616 saniyede oluştuğunu gösterdi. Kalıcı failure yeniden
üretilmedi; `004`ün kesin kök nedeni geriye dönük iddia edilmez.

Bu replacement 120/5 saniyelik kapıyı veya bilimsel eşikleri değiştirmez. Yalnız
convergence arşivine pod UID/deletion timestamp/phase/conditions ile container
ready/started/restart/state/last-state ayrıntısını ekler.

- workload: `ob-second-15u-1r-v1`; 15 kullanıcı, spawn rate 1, seed 1;
- target: `recommendationservice -> productcatalogservice`, downstream;
- ramp: jitter 0, toxicity 1, 12 adet 10 saniyelik adım,
  `63,125,188,250,313,375,438,500,563,625,688,750 ms`;
- lifecycle: `300 warmup / 300 baseline / 120 ramp / 300 steady / 300 cooldown`;
- fiziksel etki: baseline/steady ayrı ayrı en az 48 dolu 5 saniyelik pencere ve
  steady-baseline median fark `>=500 ms`;
- proxy rollout sonrası en çok 120 saniye, 5 saniye cadence ile tam bir pod; pod Ready,
  `server` ve `network-delay-proxy` container'ları Ready olmalıdır;
- first symptom ve manifestation: D-041/D-043 eşikleri aynen korunur;
- bütün Git/host/Docker/Minikube/deployment/workload/run-ID/Prometheus/collector,
  proxy-clean ve 120 saniyelik target-stability kapıları fault öncesinde tekrar geçer;
- raw/enriched/schema-v3, boundary-crossing, cleanup/rollback, host ve offline receipt
  kapıları değişmez;
- başarısızlıkta Invalid kanıt silinmez, aynı ID tekrarlanmaz ve eşikler sonuçtan sonra değiştirilmez.

Bu ön-kayıt fault yürütmez. Canonical merge ve ayrıca açık kullanıcı yürütme onayı
gereklidir. model eğitimi, LLM doğrulaması ve graph/GAT çalıştırılmaz.

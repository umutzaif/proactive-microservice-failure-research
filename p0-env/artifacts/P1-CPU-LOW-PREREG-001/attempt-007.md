# ob-cpu-low-007 Attempt Binding

`ob-cpu-low-007`, geçersiz `ob-cpu-low-006` yerine kullanılacak yeni ve benzersiz
düşük şiddetli CPU-stress tekrarıdır. Hedef, workload, seed, SLO, 120 saniye
ramp, 300 saniye steady, cooldown ve fiziksel-etki eşikleri değiştirilmemiştir.

Tek teknik değişiklik `cpu-recommendation-low-v3` profilidir: fault başlangıç ve
bitiş UTC değerleri worker'ın gerçek `started` ve `completed` olaylarından
üretilir. Dış `kubectl exec` taşıma başlangıç/bitiş UTC değerleri ayrıca korunur
ancak bilimsel fault fazının sınırları olarak kullanılmaz. Worker duvar saati ve
monotonic süresi ayrı ayrı 420 +/- 5 saniye kapısından geçmelidir.

Run 007; bu düzeltme canonical `main` revisionına merge edilmeden, temiz çalışma
ağacı ve bağımsız preflight kapıları doğrulanmadan başlatılamaz. Run 006 invalid
kalır; kanıtları değiştirilmez ve run ID yeniden kullanılmaz.

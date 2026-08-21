# ob-netdelay-15u-control-001 kontrol sözleşmesi

Bu belge D-058 birinci `fault-control` bloğunun ikinci slotunu, fault sonucu için yeni
eşik üretmeden tanımlar. Kontrol aynı proxy overlay, workload, kaynaklar ve toplam
`300/300/120/300/300` lifecycle'ı kullanır; hiçbir toxic oluşturulamaz.

120 saniyelik `matched_ramp_interval` ve 300 saniyelik `matched_steady_interval`, fault
run'ındaki zaman maruziyetine eşlenir fakat injection olarak etiketlenmez. Metadata bu
fazları kendi adlarıyla tutar; ortak SLO replay'i için ayrıca açık pencere eşlemesi
üretilir. Pre/mid/post/cleanup API snapshotlarının tamamında `toxics=[]` zorunludur.

Target-edge baseline ve matched-steady coverage ayrı ayrı en az 48 gerçek 5 saniyelik
pencere olmalıdır. Median latency farkı raporlanır fakat kontrol geçerliliği için
post-hoc üst/alt eşik kullanılmaz. Frozen SLO replay'inde `failure_manifestation=null`
zorunludur. Pod, host, raw/enriched/schema-v3, rollback ve final receipt kapıları fault
run ile aynıdır.

Bu sözleşme runner uygulaması veya canlı onay değildir. Runner ve kontrol-özel analyzer/
metadata verifier pozitif ve toxic/manifestation/coverage negatif fixture'larıyla ayrı
canonical committe uygulanacaktır. Invalid run korunur ve aynı ID kullanılmaz.

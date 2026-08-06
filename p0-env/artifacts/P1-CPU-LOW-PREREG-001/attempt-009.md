# ob-cpu-low-009 Attempt Binding

`ob-cpu-low-009`, lifecycle collection-binding kusuru nedeniyle invalid kapanan
`ob-cpu-low-008` yerine kullanılacak yeni ve benzersiz run'dır. Aynı
`cpu-recommendation-low-v4` profili, hedef, şiddet, workload, seed, SLO, faz
süreleri ve kabul kapıları korunur.

Tek teknik düzeltme injector'ın worker event `Generic.List[object]` koleksiyonunu
resolver'a vermeden önce açıkça `.ToArray()` ile `object[]` yapmasıdır. Test,
Windows PowerShell 5.1 canlı koleksiyon şeklini üretmeli; eski `@($list)` yolunun
reddedildiğini ve `.ToArray()` yolunun geçtiğini göstermelidir.

Run 008 invalid kalır; kanıtları değiştirilmez ve run ID yeniden kullanılmaz.
Run 009 ancak düzeltme canonical main'e merge edilip yeni deployment run ID ile
tüm preflight kapıları yeniden geçtikten sonra başlayabilir.

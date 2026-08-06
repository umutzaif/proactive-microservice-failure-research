# ob-cpu-low-008 Attempt Binding

`ob-cpu-low-008`, pre-execution worker hash kapısında invalid kapanan
`ob-cpu-low-007` yerine kullanılacak yeni ve benzersiz run'dır. Hedef, şiddet,
workload, seed, SLO, ramp, steady, cooldown, physical-effect ve lifecycle UTC
kapıları değişmemiştir.

Tek yeni teknik sözleşme `cpu-recommendation-low-v4` içindeki
`worker_hash_normalization=utf8-lf` alanıdır. Worker kaynak metni SHA-256 öncesi
UTF-8 BOM'suz ve LF satır sonlu canonical byte dizisine çevrilir. LF ve CRLF
checkout'larının aynı metin için eşit hash ürettiği, farklı kaynak içeriğinin ise
eşit kabul edilmediği bağımsız fixture ile doğrulanmalıdır.

Run 007 invalid kalır; v3 profili ve kanıtları değiştirilmez. Run 008 ancak v4
düzeltmesi canonical main'e merge edildikten ve yeni deployment run ID ile tüm
preflight kapıları geçtikten sonra başlayabilir.

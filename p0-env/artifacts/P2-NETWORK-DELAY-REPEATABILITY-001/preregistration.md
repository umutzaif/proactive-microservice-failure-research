# P2 network-delay tekrarlanabilirlik ve kontrol bloğu ön-kaydı

Bu ön-kayıt D-058'i uygular. `ob-netdelay-15u-008`, randomize edilmemiş ilk geçerli
fizibilite/pilot run'ı olarak korunur; dört yeni bloktaki denge veya doğrulayıcı örnek
büyüklüğü hesabına geriye dönük randomize edilmiş gibi katılmaz.

## Amaç

Birincil amaç, D-041/D-055 ile dondurulmuş 500 ms network-delay fiziksel etkisinin ve
latency manifestation zamanının bağımsız run'larda değişkenliğini ölçmek; eşlenmiş
no-toxic kontrollerle gün/host/sıra/cold-start karıştırıcılarını görünür kılmaktır.
Bu blok model, LLM, GAT veya Dataset v1 geçişini otomatik yetkilendirmez.

## Dondurulmuş sıra ve koşullar

Seed `20260821` ile dengeli iki `fault-control` ve iki `control-fault` etiketi
randomize edilmiştir. Canonical sıra `randomization-plan.json` içindedir:

1. `repeat-001` fault, ardından `control-001`;
2. `repeat-002` fault, ardından `control-002`;
3. `control-003`, ardından `repeat-003` fault;
4. `control-004`, ardından `repeat-004` fault.

Fault run'larında workload `15/1/seed 1`, hedef edge, 500m/100m kaynaklar,
`300/300/120/300/300`, `0->750 ms`, `>=500 ms` etki, frozen SLO, D-038,
schema-v3, cleanup, rollback, RecordId host ve receipt kapıları değişmez. Kontrol,
aynı overlay/workload/resources/lifecycle ile toxic oluşturmadan yürütülür.

## Portability ve yürütme kapıları

Canlı slot öncesinde raw verifier hem Windows PowerShell 5.1 hem pwsh 7 altında aynı
immutable arşivde aynı UTC sınır sonucunu vermelidir. UTC alanları ham JSON'dan tekil
canonical `Z` string olarak alınır ve invariant `DateTimeOffset` ile ayrıştırılır;
locale veya otomatik JSON `DateTime` cast'i bilimsel pencereyi belirleyemez.

Her slot canonical merge, ayrı açık runtime onayı, fresh Git/host/cluster/run-ID,
workload, proxy-clean ve pod kararlılığı kapılarına bağlıdır. Invalid girişim silinmez,
aynı ID kullanılmaz ve otomatik ikame edilmez.

## Kapanış ve raporlama

Dört eşlenmiş çiftin tamamı geçerli olmadan randomize pilot blok kapanmaz. Kapanışta
fault-control farkları, fiziksel etki, first-symptom/manifestation zamanı, yanlış
kontrol manifestation'ı, run-arası dağılım ve sıra etkisi raporlanır. Bundan sonra
güven aralığı/equivalence/power hedeflerinden hangisinin savunulacağı kullanıcı
tarafından ayrıca seçilir ve gerekiyorsa ek örnek büyüklüğü prospektif dondurulur.

İlk geçerli slot raporu ayrıca araştırmanın mevcut konumunu gösteren bir şema,
yapılan işlemler, ölçülen/test edilen değişkenler ve bunların temel savunma tezindeki
karşılığını içerecektir.

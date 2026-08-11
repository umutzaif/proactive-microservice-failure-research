# P1-WORKLOAD-RESOURCE-BUDGET-001 Report

## Amaç ve sınır

Bu fault içermeyen masa-başı analiz, D-030 sonrasında O-010 kararını destekler.
Yeni workload seçmez, eşik değiştirmez ve bilimsel dataset'e girmez. Girdileri
mühürlü 10/15/20-user kapasite özetleri, sürümlü `cpu-recommendation-high-v1`
profili ve üç geçerli high-run özetidir.

## Yeniden üretilebilir sonuç

- Servis CPU limiti: `200m`; high talebi: `150m`; D-030 rezervi: `25m`.
- High fiziksel artışları: `146.589m`, `143.819m`, `150.416m`; ortalama
  `146.941m`.
- 15-user normal ortalama CPU: `35.890m`.
  - 25m rezerv korunursa maksimum high talebi: `139.110m`.
  - 150m talep korunursa gereken minimum limit: `210.890m`.
  - Gözlenen high ortalama artışı toplamsal varsayılırsa tahmini steady:
    `182.831m`; 200m limite kalan: `17.169m`.
- 20-user normal ortalama CPU: `43.015m`.
  - 25m rezerv korunursa maksimum high talebi: `131.985m`.
  - 150m talep korunursa gereken minimum limit: `218.015m`.
  - Toplamsal tahmini steady: `189.956m`; limite kalan: `10.044m`.
- 10–15 user noktaları arasındaki doğrusal tarama, `1.30x` request yoğunluğunu
  yaklaşık `13.594` user ve `33.112m` normal mean CPU noktasına yerleştirir.
  Bu tarama, daha küçük user adayının eski `<=25m` kapısını aynı anda çözmesinin
  beklenmediğini gösterir.

## Alternatifler

1. `25m` rezervi ve 200m limiti koruyup high talebini azaltmak: kaynak güvenliğini
   korur fakat severity artık iki workload arasında aynı olmaz.
2. `25m` rezervi ve `+150m` high talebini koruyup limiti artırmak: nominal bütçeyi
   korur fakat deployment/fault fiziğini ve önceki run'larla karşılaştırılabilirliği
   değiştirir.
3. 15 user, 200m limit ve `+150m` high profilini koruyup yeni deneyler için
   teorik minimum rezervi limitin `%5`i (`10m`) olarak önceden kaydetmek:
   `normal mean <=40m`. Bu, tek-değişken workload karşılaştırmasını korur; fakat
   D-030 sonucundan sonra tasarlanmış yeni bir kuraldır ve açık akademik onay ister.
4. Daha küçük kullanıcı adayını denemek: eski iki kapının yapısal gerilimi nedeniyle
   ek maliyet yaratır; doğrusal tarama deneysel kanıt değildir ve gerçek run bunu
   yanlışlayabilir.

## Teknik öneri ve karar kapısı

Karşılaştırılabilirliği en iyi koruyan seçenek 3'tür: 15-user workload, değişmeyen
200m limit, low/medium/high profilleri, seed, SLO ve lifecycle; yalnız yeni ve
prospektif `%5` nominal rezerv gerekçesi. Bu rapor öneriyi kabul edilmiş karar
yapmaz. O-010 kullanıcı tarafından açıkça çözülmeden workload ön-kaydı, normal
baseline veya fault run başlatılamaz.

## Sınırlılıklar ve yanlışlama

Doğrusal enterpolasyon gözlenmiş bir 13–14 user run değildir. Normal CPU ile high
artışını toplamak etkileşimsizlik varsayımıdır; throttling ve scheduler davranışı
nedeniyle gerçek steady farklı olabilir. Analiz `analysis.json` ile yeniden
üretilebilir; yeni preregistered 15-user normal/fault run'ları bu tahminleri
yanlışlayabilir. Sonuçlar görülmeden geçerlilik kapıları dondurulmalıdır.

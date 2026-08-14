# P1-CPU-001 kanıt ve etiket fizibilitesi kapanış raporu

## Kapsam ve yöntem

Bu rapor yeni deney veya model üretmez. `results_registry.md`, mühürlü scientific
metadata/final receipt zincirleri ve üç 10-user severity özeti ile
`P1-SECOND-WORKLOAD-FAULT-BLOCK-001` kapanışını birlikte denetler. Invalid run'lar
sayımda korunur, fakat bilimsel sonuç hesaplarına katılmaz.

Bağımsız yeniden üretim için registry'deki `P1-CPU-001 / ob-cpu-*` satırları
status alanına göre sayılabilir; her geçerli run'ın final receipt'i
`verify-finalized-run.ps1` ile tekrar sınanabilir. Fiziksel-etki sayıları ilgili
severity kapanış raporlarından, manifestation sonucu ise hash ile mühürlü
`manifestation-evidence.json` ve scientific metadata'dan çapraz kontrol edilir.

## Run muhasebesi

| Grup | Geçerli | Invalid | Toplam |
|---|---:|---:|---:|
| P1-CPU-001 bilimsel run/attempt | 21 | 14 | 35 |
| Geçerli normal | 6 | - | 6 |
| Geçerli CPU fault | 15 | - | 15 |

Toplam geçerli-run oranı `21/35 = %60`'tır. Bu oran operasyonel zincirin
öğrenme sürecini de içerir; invalid kanıtlar silinmemiş ve benzersiz run ID'leri
yeniden kullanılmamıştır.

## Fiziksel etki ve olay etiketi

10-user low/medium/high üç-run özetlerinde CPU artışı ortalama
`50,349/99,649/146,941m`, CV `%3,576/%4,947/%2,254` olmuştur. 15-user
low/medium/high ikişer-run özetlerinde ortalama `51,098/93,987/140,435m`, CV
`%5,384/%0,704/%5,312` olmuştur. Bu, iki workload ve üç severity altında
ölçülmüş fiziksel actuation'ın betimsel olarak tekrarlandığını destekler.

Geçerli 15 fault run'ın tamamında frozen `p1-cpu-001-slo-v1` manifestation
sonucu `null`'dır. Bu nedenle:

- pozitif fault manifestation olayı: `0/15`;
- pozitif lead-time örneği: `0`;
- manifestation öncesi pozitif sınıf penceresi: `0`;
- event-level rule/logistic/XGBoost karşılaştırması: mevcut etiketlerle bilimsel
  olarak tanımlanamaz.

Invalid `ob-cpu-15u-normal-002` içindeki manifestation, fault sınıfı için pozitif
olay değildir ve invalid run olduğu için geçerli modele taşınamaz.

## Telemetri ve missingness sınırı

21 geçerli run'ın tamamı run-ID, raw/enriched log, schema-v3 metric/trace,
lifecycle, host-health, final receipt ve bağımsız offline replay kapılarını
geçmiştir. Bu, arşiv/provenance ve UTC kapsam hizalamasını destekler.

Ancak canonical 5 saniyelik feature-window tablosu henüz üretilmediği için
feature-level modalite missingness oranı ölçülmüş değildir. Bu rapor archive
coverage başarısını feature missingness sonucu gibi sunmaz.

## Pilot karar kapısı sonucu

1. Fiziksel fault etkisi tekrarlanabilir: **evet, betimsel olarak**.
2. Manifestation enjeksiyondan ayrılabilir: **değerlendirilemez; pozitif olay yok**.
3. Pre-failure sinyal: **değerlendirilemez; pozitif horizon etiketi yok**.
4. Modalite hizası: **archive/provenance katmanında geçti; feature missingness bekliyor**.
5. Dataset v1 geçişi: **hayır**. Manifestation, lead-time ve event-based baseline
   kapıları karşılanmadı.

## Durdurma sınırı

Bu kapanış CPU stress'i otomatik olarak RCA-only sınıfa dönüştürmez; yeni fault,
hedef servis, severity veya SLO seçmez. Aynı koşullarda daha fazla CPU run'ı
toplamak fiziksel varyansı daraltabilir, fakat gözlenen sıfır olay oranında pozitif
etiket sorununu çözme garantisi yoktur. Sonraki deney tasarımı açık akademik karar
ve ayrı ön-kayıt gerektirir. Model, LLM ve GAT çalıştırılmamıştır.

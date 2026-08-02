# P1-TARGET-SERVICE-SELECTION-001 raporu

- Tarih: 2026-08-02
- Durum: `completed`
- Kaynak bilimsel run: `ob-cpu-normal-002`
- Karar: İlk CPU-stress kalibrasyon hedefi `recommendationservice`.
- Fault injection: yapılmadı
- Dataset üretimi: yapılmadı; geçerli normal baseline yeniden analiz edildi.

## Yöntem

`analyze-target-service-candidates.py`, scientific metadata içindeki normal-baseline UTC sınırlarını kullandı ve warm-up verisini dışladı. Health-check ve OTLP exporter spanları kullanıcı-yolu sayımına alınmadı. Geçerli-run kontrolü zorunlu tutuldu; `ob-cpu-normal-001` invalid metadata negatif testi reddedildi.

## Karşılaştırma

| Ölçüt | checkoutservice | recommendationservice |
|---|---:|---:|
| CPU ortalama | 1,225 mCPU | 11,962 mCPU |
| CPU p95 | 7,074 mCPU | 41,982 mCPU |
| CPU maksimum | 7,703 mCPU | 53,982 mCPU |
| Memory ortalama | 7,845 MiB | 33,200 MiB |
| Kullanıcı-yolu spanı | 340 | 1.078 |
| Ana kullanıcı işlemi | 26 PlaceOrder | 539 ListRecommendations |
| Error span | 0 | 0 |
| Container başlangıç zamanı sayısı | 1 | 1 |
| CPU limiti | 200 mCPU | 200 mCPU |

## Gerekçe ve sınırlılıklar

Recommendationservice aynı workload altında daha sık çağrıldı, daha ölçülebilir normal CPU etkinliği gösterdi ve yalnız ProductCatalog çağrısı içeren daha basit bir downstream yapıya sahipti. Checkoutservice daha zengin downstream manifestation olanağı sunsa da `PlaceOrder` çağrısı seyrektir.

Karar tek geçerli normal baseline'a dayanır ve fault yanıtını kanıtlamaz. Recommendationservice içindeki seed edilmemiş `random.sample`, öneri içeriğine değişkenlik ekler; CPU fault kalibrasyonunda bu sınırlılık raporlanacaktır. Hedef, ilk kalibrasyon sonuçları semptom veya gecikmeli SLO etkisi üretmezse protokole göre yeniden değerlendirilebilir.

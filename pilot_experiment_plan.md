# Pilot Deney Planı: Online Boutique CPU Stress

## 1. Amaç

Bu pilotun amacı yüksek doğruluklu nihai model üretmek değil, proaktif hata tahmininin veri açısından mümkün olup olmadığını belirlemektir.

Ana soru:

> Kontrollü ve kademeli CPU stress altında, kullanıcıya yansıyan SLO ihlalinden önce tekrar edilebilir log, metric veya trace sinyalleri oluşuyor mu?

## 2. Hipotezler

- H1: CPU stress ramp başladıktan sonra `failure_manifestation` öncesinde latency, queue/retry, span duration veya error eğilimlerinden en az biri düzenli biçimde değişir.
- H2: Bu sinyaller sabit bir 30 saniyelik horizon içinde normal koşullardan olay-bazlı olarak ayrılabilir.
- H3: Enjeksiyon başlangıç zamanı ile manifestation zamanı arasında pozitif ve koşullar arasında değişken bir lead time vardır.

H1 reddedilirse hata profili, hedef servis veya SLO tanımı değiştirilmeden doğrudan ana dataset üretimine geçilmez.

## 2.1 Başlatma durumu - 28 Temmuz 2026

- Telemetri yazılım hattı: **Doğrulandı.** `P1-TELEMETRY-EXPORT-001` tamamlandı, kabul edildi ve PR #10 ile `main` dalına alındı.
- Host stability: **Geçti.** `P1-HOST-STABILITY-002` kapsamında temiz boot altında iki ayrı 30 dakikalık aktif yük gözlemi ve bir 10 dakikalık tam E2E kapanış tamamlandı. Yeni WHEA Event 17, bugcheck veya Kernel-Power Event 41 oluşmadı.
- Ham log, enriched log, metric, trace ve finalization hattı: **Kısa pencerede geçti.** `ob-host-stability-003` koşusunda `close_run=passed` sonucu alındı.
- Uzun pencere trace export: **Açık teknik kapı.** `ob-host-stability-002` koşusunda frontend için Jaeger 5.000 trace sınırına ulaşıldı ve exporter olası veri kırpılmasını kabul etmeyerek koşuyu geçersiz saydı.
- `P1-CPU-001`: **planned/blocklu.**

Telemetry merge ve host stability kapıları kapanmıştır. Bilimsel normal run, fault injection, SLO kalibrasyonu veya model verisi toplamadan önce trace sorguları zaman dilimlerine bölünmeli, trace ID üzerinden tekilleştirilmeli ve en az 30 dakikalık yük penceresinde kayıpsız dışa aktarım doğrulanmalıdır.
## 3. Pilot aşamaları

### P0 - Ortam ve gözlemlenebilirlik

- Online Boutique'in sabit bir sürümünü kur.
- Normal kullanıcı yolunu ve servis graph'ını çıkar.
- Log, Prometheus uyumlu metric ve OpenTelemetry trace toplandığını doğrula.
- Run ID'nin üç modalitede izlenebilir olduğunu doğrula.
- Normal yükte 30–60 dakikalık stabilite ölçümü yap.

Çıktı: ortam envanteri, topoloji, telemetri schema örnekleri, normal performans özeti.

### P1 - Hedef servis seçimi

En az iki aday servis için kısa yük testleri yap. Seçim ölçütleri:

- kullanıcı yolunda bulunması,
- CPU baskısının downstream semptom oluşturması,
- normal koşulda stabil olması,
- tek hata hedefinin açıkça etiketlenebilmesi,
- kod ve logların yorumlanabilir olması.

Seçim araştırma karar kaydına işlenir.

### P2 - Fault profile kalibrasyonu

Üç kademeli profil tasarla:

- düşük: semptom oluşturur, SLO ihlali oluşturmayabilir,
- orta: gecikmeli SLO ihlali üretir,
- yüksek: belirgin fakat anlık olmayan ihlal üretir.

Ramp süresi, sabit fault süresi ve kaldırma süresi versioned configuration olarak kaydedilir.

### P3 - Veri toplama

Geçici hedef:

- 3 şiddet x 2 yük seviyesi x en az 2 tekrar = en az 12 fault run,
- her yük seviyesi için en az 3 normal run = en az 6 normal run.

Run sırası randomize edilir. Aynı fault profilleri arka arkaya zorunlu olarak çalıştırılmaz. Başarısız run'lar tekrar edilse bile kayıttan çıkarılmaz.

## 4. Run zaman çizelgesi

Başlangıç önerisi:

| Evre | Süre | Kullanım |
|---|---:|---|
| Reset/health check | Duruma bağlı | Geçerlilik kontrolü |
| Warm-up | 5 dk | Dataset dışında |
| Normal baseline | 5 dk | Negatif/pre-fault veri |
| CPU ramp | 2–5 dk | Pre-failure gelişim |
| Sabit stress | 5 dk | Manifestation gözlemi |
| Fault removal | Anlık/kontrollü | Recovery başlangıcı |
| Cooldown | 5 dk | Recovery analizi |

Süreler P0 ve ilk iki kalibrasyon run'ından sonra güncellenebilir.

## 5. Pilot özellikleri

Karmaşık embedding yerine önce yorumlanabilir özellikler:

- servis CPU ortalama/maksimum/eğim,
- memory,
- request rate,
- error rate,
- latency mean/p95 ve eğim,
- span duration mean/p95,
- failed span oranı,
- retry/timeout sayısı,
- warning/error log sayısı,
- yeni log template sayısı,
- upstream/downstream servislerde aynı özellikler.

## 6. Pilot analizleri

1. Her run için injection, symptom ve manifestation işaretli zaman serisi grafikleri.
2. Normal ve pre-failure pencerelerin dağılım karşılaştırması.
3. Lead-time dağılımı.
4. Eksiklik ve timestamp-hizalama raporu.
5. Basit rule/logistic/XGBoost baseline ile grouped validation.
6. Hangi özelliklerin yalnızca enjeksiyon sonrasında değil, manifestation öncesinde değiştiğinin kontrolü.

Pilot sırasında LLM ve GAT eğitilmeyecek. Önce veri ve etiket fizibilitesi kanıtlanacak.

## 7. Başarı ve durdurma ölçütleri

### Dataset v1'e geçiş için

- Geçerli fault run oranı kabul edilebilir düzeyde olmalı.
- Manifestation zamanı kuralla ve tekrar edilebilir biçimde saptanabilmeli.
- Fault run'ların anlamlı bölümünde en az 15–30 saniyelik pozitif lead time bulunmalı.
- En az bir basit model olay-bazlı değerlendirmede chance/rule baseline'dan tutarlı biçimde iyi olmalı.
- Sonuç yalnızca tek bir yük veya şiddet profiline bağlı olmamalı.

### Revizyon gerektiren durumlar

- Stress doğrudan anlık çöküş oluşturuyorsa ramp yavaşlatılır.
- Hiç SLO ihlali oluşmuyorsa hedef servis/şiddet değiştirilir.
- Enjeksiyon başlangıcı model için kolay bir yapay işaret bırakıyorsa schedule ve fault aracı gözden geçirilir.
- Pre-failure sinyal yoksa CPU stress yalnızca RCA sınıfı yapılır ve farklı gelişen hata seçilir.

## 8. Pilot teslim paketi

- Ortam ve sürüm manifesti
- Servis topolojisi
- Fault/workload profilleri
- Run manifesti
- Veri kalite raporu
- Normal performans ve SLO önerisi
- Zaman serisi pilot grafikleri
- Basit baseline sonuçları
- Dataset v1'e geçiş kararı ve gerekçesi

# D148 Akademik Çıktı Hızlı Rehberi

## Bu klasörde ne var

- `d148-venue-neutral-academic-paper.docx`: Düzenlenebilir akademik makale.
- `d148-venue-neutral-academic-paper.pdf`: Sekiz sayfalık, görsel olarak denetlenmiş okuma ve sunum kopyası.
- `academic-readiness-matrix.md`: Çalışmanın hangi akademik ölçütleri geçtiğini ve hangi sınırlılıkların açık kaldığını gösteren denetim cetveli.

## Belgeyi nasıl okuyabilirsiniz

Önce PDF'teki Abstract, üç Research Question ve Conclusion bölümlerini okuyun. Ardından Method bölümündeki treatment, workload, physical-effect ve frozen-SLO sözleşmelerini inceleyin. Results bölümündeki tablo yalnızca kabul edilen run'ların betimsel CPU etkisini gösterir. Threats to Validity ve Data and Artifact Availability bölümleri, hangi sonuçların savunulamayacağını açıklar.

## Savunulabilir ana sonuç

Test edilen host ve profillerde CPU fault actuation ölçülebilir ve sıralıydı; buna karşın 15 geçerli fault run'ın hiçbirinde dondurulmuş SLO manifestation oluşmadı. Bu sonuç, CPU fault'larının hiçbir zaman servis bozulması üretmediğini kanıtlamaz. Çalışmanın akademik katkısı; fault isteği, fiziksel etki, servis manifestation, geçerlilik paydası ve yeniden üretilebilirlik katmanlarını birbirinden ayırmasıdır.

## Değişmeyen sınırlar

- Toplam 35 attempt: 21 valid, 14 invalid.
- Geçerli fault run: 15; frozen-SLO manifestation: 0/15.
- Bağımsız receipt replay: 0/21.
- D147 network-delay çalışması 3/6 düzeyinde durdurulmuştur ve bu makalenin sonucu değildir.
- Gelecekteki confirmatory hedef 60 bağımsız pozitif incident ve 60 normal control olarak korunur.

Belge akademik incelemeye hazırdır; dış konferans gönderimine hazır değildir. Yazar bilgisi, venue formatı, anonymity, receipt katmanı ve ayrı gönderim yetkisi daha sonra ele alınmalıdır.

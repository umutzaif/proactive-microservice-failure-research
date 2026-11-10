# D-148 Türkçe Araştırma Özeti

## Çalışmanın amacı

Bu çalışma, CPU fault enjeksiyonunun fiziksel olarak uygulanması ile kullanıcı
açısından ölçülebilir bir hizmet bozulmasının oluşmasını birbirinden ayırır.
Temel soru şudur: düşük, orta ve yüksek CPU stres profilleri hedef serviste
ölçülebilir CPU artışı üretirken, önceden dondurulmuş SLO kuralını da aşıyor mu?

Çalışma yerel Online Boutique dağıtımında `recommendationservice` üzerinde, aynı
hostta, 10 ve 15 sanal kullanıcı iş yükleriyle yürütülmüş kayıtları inceler.
Sonuçlar yalnızca bu host, servis, iş yükleri, fault profilleri ve SLO için
geçerlidir.

## Yöntem ve geçerlilik sınırı

Kayıtta 35 benzersiz girişim vardır. Bunların 21'i geçerlidir: altı normal
kontrol ve 15 fault koşusu. On dört girişim geçersizdir. Geçersiz girişimler
silinmemiş, yeniden etiketlenmemiş ve bilimsel sonuç paydasına alınmamıştır.
Bu fail-closed yaklaşım, operasyonel bir denemenin bağımsız ve geçerli bir
bilimsel gözlem gibi gösterilmesini önler.

Dondurulmuş manifestation kuralı beş saniyelik pencereler kullanır. Ürün servisi
p95 latency değerinin 345.992 ms üstünde veya global error rate değerinin
sıfırdan büyük olması üç ardışık dolu pencerede devam etmelidir. Boş pencere
seriyi sıfırlar. Eşikler fault sonuçları görüldükten sonra seçilmemiştir.

## Temel bulgular

Geçerli fault koşularında CPU actuation düzenli biçimde ölçülmüştür. Ortalama
CPU artışları 10 kullanıcı için düşük/orta/yüksek profillerde
`50.349/99.649/146.941 mCPU`, 15 kullanıcı için
`51.098/93.987/140.435 mCPU` olmuştur.

Buna rağmen 15 geçerli fault koşusunun hiçbiri dondurulmuş SLO manifestation
kuralını aşmamıştır: `0/15`. Dolayısıyla pozitif erken uyarı olayı ve pozitif
lead-time örneği yoktur. Bu sonuç bir erken uyarı modelinin başarılı veya
başarısız olduğunu göstermez; mevcut kanıt üzerinde böyle bir model performansı
bilimsel olarak tanımlı değildir.

## Çalışmanın katkısı

Çalışmanın üç sınırlı katkısı vardır:

1. Fiziksel fault actuation ile SLO manifestation kavramlarını ölçülebilir
   biçimde ayırır.
2. Otuz beş girişimin tamamını görünür tutarken bilimsel paydayı 21 geçerli
   koşuyla sınırlandıran fail-closed muhasebeyi gösterir.
3. Takip edilen kanıt ile receipt seviyesindeki yeniden oynatmayı ayrı
   reproducibility katmanları olarak raporlar.

Receipt replay için beklenen 21 çiftin hiçbiri mevcut değildir: `0/21`.
Repository içindeki takip edilen kanıt ve türetilmiş tablolar doğrulanabilir,
fakat eksik receipt dosyaları yeniden oluşturulmuş veya doğrulanmış gibi
gösterilemez.

## Ne iddia edilebilir, ne iddia edilemez?

İddia edilebilir: test edilen profiller ölçülebilir CPU artışı üretmiş, ancak 15
geçerli fault koşusunda dondurulmuş SLO manifestation oluşmamıştır. Geçersiz
girişimler görünür kalmış ve bilimsel paydadan çıkarılmıştır.

İddia edilemez: CPU fault hiçbir zaman hizmet bozulması üretmez; sonuç üretim
sistemlerine genellenebilir; bir tahmin modeli doğrulanmıştır; artifact tam
receipt seviyesinde yeniden üretilebilirdir.

Gelecekteki doğrulayıcı model karşılaştırması için hedef hâlâ 60 bağımsız
pozitif olay ve 60 normal kontrol koşusudur. Bir koşu içindeki pencereler bağımsız
olay gibi sayılarak bu hedef büyütülemez.

## Savunmada açıklanması gereken noktalar

- Başarılı injector komutu neden SLO ihlali kanıtı değildir?
- Geçersiz girişimler neden kayıtta tutulur fakat sonuç paydasına girmez?
- `0/15` sonucu neden evrensel bir CPU fault sonucu değildir?
- Receipt replay `0/21` iken hangi reproducibility iddiaları kurulabilir?
- Pozitif olay yokken neden model performansı raporlanamaz?

## What knowledge did I gain from this step?

Bir negatif sonucun bilimsel olarak değersiz olmadığını; değerinin iddia
sınırlarını, geçerlilik paydasını ve yeniden üretilebilirlik katmanlarını açıkça
göstermekten geldiğini öğrendim. Ayrıca görsel olarak tamamlanmış bir PDF veya
sunumun tek başına submission-ready kanıtı olmadığını, içerik ve provenance
kapılarının ayrı doğrulanması gerektiğini öğrendim.

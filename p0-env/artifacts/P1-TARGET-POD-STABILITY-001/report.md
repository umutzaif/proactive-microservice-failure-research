# P1-TARGET-POD-STABILITY-001 Raporu

## Amaç

D-038 kapsamında fault hedefinin yalnız Kubernetes `Available/Ready` durumuna değil,
120 saniye boyunca değişmeyen pod UID, container ID ve restart sayısına sahip olmasını
zorunlu kılmak. Bu tooling doğrulamasıdır; bilimsel run veya dataset örneği değildir.

## Akış

`verify-target-pod-stability.ps1`, warm-up öncesinde hedef podu 5 saniyede bir 120
saniye gözler ve read-only kanıt üretir. `invoke-cpu-stress.ps1`, worker exec'ten
hemen önce canlı pod/container kimliğini bu mühürlü final snapshot ile karşılaştırır.
Fark varsa retry yapmadan fault öncesi durur. Stabilite kanıtının SHA-256 değeri
injector execution evidence içine yazılır ve final receipt zinciriyle bağlanır.

## Bağımsız testler

- Kararlı pod UID/container ID/restart fixture'ı: geçti.
- Restart sayısı değişen fixture: fail-closed reddedildi.
- Hedef `server` container'ı eksik fixture: fail-closed reddedildi.
- 15-user low/medium/high profil sözleşmeleri: geçti.
- Değiştirilmiş medium fiziksel-etki sözleşmesi: negatif testte reddedildi.
- Runner, injector ve scientific metadata verifier uçtan uca D-038 wiring kontrolü:
  geçti. Stabilite kanıtının tamamı injector evidence içinde korunur.

## Sınırlılıklar

Kapı 120 saniyelik ek hazırlık süresi oluşturur ve geçici restartları daha fazla
invalid girişim olarak görünür kılabilir. Uygulama altyapı kararlılığını garanti
etmez; yalnız ön-kayıtlı gözlem penceresi ve worker öncesi kimlik bağını kanıtlar.
Fault fiziği, workload, seed, lifecycle, SLO ve coverage eşikleri değişmez.

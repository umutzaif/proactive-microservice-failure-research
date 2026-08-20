# P2-NETWORK-DELAY-RESOURCE-COMPAT-DESIGN-001

## Amaç ve problem

Geçerli `ob-network-probe-resource-002`, recommendationservice server'ın mevcut
`100m/200m` CPU request/limit sözleşmesinde beş liveness restart ile `363/363` CFS
throttled period ve `+21,270718 sn` CPU-pressure waiting ürettiğini gösterdi. Bu
tasarım, probe toleransını değiştirmeden yalnız CPU kota hipotezini sınar. Scientific
toxic/fault yürütmez ve Dataset v1/modeling örneği üretmez.

## Seçilen değişiklik

No-toxic network-delay overlay üzerinde yalnız server CPU limit `200m -> 500m`
değişir. CPU request `100m`, memory request/limit `220/450Mi`, image, env, workload,
proxy, security context ve gRPC readiness/liveness probe aynen kalır. `500m`, `002`de
ölçülen maksimum ardışık-sample CPU rate `499,307m`yi kapsayan en dar yuvarlak
adaydır. Request'in sabit kalması scheduler rezervasyonunu değiştirmez.

## Alternatifler ve trade-off

- Probe timeout/failure threshold değişikliği, responsiveness nedenini değil kubelet
  toleransını değiştirir; ilk tek-değişken testi olarak reddedildi.
- CPU request ve limiti birlikte artırmak scheduling ile quota etkisini karıştırır.
- `300m`, gözlenen yaklaşık `499m` burst'ü kapsamaz; `1000m` ilk aday için gereksiz
  host bütçesi ve daha geniş davranış değişikliği yaratır.
- `500m`, hostta daha yüksek burst'e izin verir ve throttling'i tamamen kaldırma
  garantisi vermez; bu nedenle scientific replacement öncesi no-fault gate gerekir.

## Prospektif compatibility sözleşmesi

İlk ve tek ön-kayıtlı aday `ob-network-resource-compat-001`dir. Canonical merge ve
ayrı açık runtime onayı olmadan çalıştırılmaz.

- workload: `ob-second-15u-1r-v1`, 15 user, spawn rate 1, seed 1
- toxic/fault: yasak; proxy API temiz olmalı
- target stability: `120 sn / 5 sn`, tek pod, iki container Ready, restart `0`
- ölçüm: `180 sn / 5 sn`; 13/13 cAdvisor türü ve en az `175 sn` metric coverage
- lifecycle: ölçüm boyunca server/proxy Ready `%100`, restart `0`
- resource effect: CFS throttled-period fraction `<0,50` ve CPU-pressure waiting
  delta `<10,635359 sn`; ikisi de `002` değerinden en az yarı azalma göstermelidir
- memory/node: failcnt/OOM/memory pressure `0`; node Memory/Disk/PID pressure false
- host: RecordId kapısıyla yeni WHEA 17, Kernel-Power 41, bugcheck `0/0/0`
- kapanış: base rollback, immutable evidence, SHA-256 manifest ve offline replay

Herhangi bir kapı başarısızsa benzersiz ID invalid olarak korunur; eşikler sonuçtan
sonra değiştirilmez. Başarı yalnız no-toxic resource compatibility'yi gösterir;
scientific network-delay replacement, fault yürütmesi, model/LLM/GAT veya probe
değişikliği yetkisi vermez.

## Bağımsız doğrulama ve yaygın hatalar

`verify-network-resource-compat-design.ps1`, patch'in tek operasyon olduğunu, yalnız
server CPU limit yolunu `500m` yaptığını, prereg ID/eşiklerini ve toxic yetkisizliğini
doğrular. Rendered manifestte server request/memory/probe değerleri ile proxy
security/resource sözleşmesi ayrıca karşılaştırılmalıdır. Container sırasına körü
körüne güvenmek, request'i de değiştirmek veya timeout'u sessizce artırmak bu tasarımın
en önemli yanlış uygulamalarıdır.

# P1-HOST-STABILITY-003 — Temiz Boot Sonrası Aktif Yük Tekrarı

- Tarih: 2026-07-29
- Durum: `invalid`
- Karar: `repeat`
- Fault injection: yok
- Bilimsel dataset kullanımı: hayır; host başlangıç kapısı doğrulaması

## Amaç

Temiz Windows başlangıcından sonra Docker, Minikube ve Online Boutique
loadgenerator yükü altında yeni WHEA-Logger Event 17, Kernel-Power Event 41
veya bugcheck oluşmadan 30 dakikalık aktif pencerenin tamamlanabildiğini
doğrulamak.

## Başlangıç koşulları

```text
code_revision=b604d390b61c2e85e880e8081dc9ddf1a52dcda2
boot_utc=2026-07-29T17:52:44.5000000Z
precheck_utc=2026-07-29T17:59:25.1132563Z
baseline_whea_event_17=0
baseline_kernel_power_event_41=0
baseline_bugcheck_event_1001=0
ethernet=Up, 1 Gbps
wifi=Not Present
docker_server=29.6.1
deployment_available=15/15
loadgenerator_available=true
```

Repo başlangıçta temizdi; yerel `main` ve `origin/main` aynı `b604d39`
revisionındaydı.

## Aktif yük penceresi

```text
window_start_utc=2026-07-29T18:02:43.1006252Z
first_whea_utc=2026-07-29T18:06:57.4575789Z
last_whea_utc=2026-07-29T18:06:57.5423638Z
whea_event_17_delta=8
kernel_power_event_41_delta=0
bugcheck_event_1001_delta=0
window_completed=false
```

İzleyici beşinci örnekte WHEA farkını saptadı ve 30 dakikalık pencereyi
erken durdurdu. Olaylar aşağıdaki aynı PCI Express Root Port üzerinde
oluştu:

```text
component=PCI Express Root Port
error_source=Advanced Error Reporting (PCI Express)
bus_device_function=0x0:0x1D:0x5
device=PCI\VEN_8086&DEV_06B5&SUBSYS_1E911043&REV_F0
```

Sonraki salt okunur PnP eşlemesi root portun tek bus relation/child aygıtını
doğruladı:

```text
root_port=Intel(R) PCI Express Root Port #14 - 06B5
root_location=PCIROOT(0)#PCI(1D05)
child=MediaTek Wi-Fi 6 MT7921 Wireless LAN Card
child_instance=PCI\VEN_14C3&DEV_7961&SUBSYS_46801A3B&REV_00\4&2E364405&0&00ED
child_location=PCIROOT(0)#PCI(1D05)#PCI(0000)
child_problem=CM_PROB_DISABLED / Code 22
wlan_driver=MediaTek 3.0.1.1314, oem26.inf
bluetooth_driver=MediaTek 1.3.17.159, oem93.inf
root_port_driver=Intel 10.1.31.2, oem53.inf
bios=FX506LHB.311
```

Son WHEA kaydının ham alanlarında `CorrectableErrorStatus=0x1`,
`UncorrectableErrorStatus=0x0` görüldü. Wi-Fi aygıtının Windows'ta devre dışı
olması PCIe linkini fiziksel olarak kapatmadığı için Code 22 durumu WHEA
tekrarını önlemedi.

CPU performance counter sorgusu yerel sayaç adı/API hatası verdi; bu hata
host kapısı kararını etkilemedi. Bellek örnekleri yaklaşık 2.165–2.310 MB
serbest fiziksel bellek gösterdi.

## Kapanış

Minikube ve Docker Desktop kontrollü kapatıldı. Kapanış sonrasında olay
farkları değişmedi:

```text
post_shutdown_utc=2026-07-29T18:09:25.8046539Z
whea_event_17_delta=8
kernel_power_event_41_delta=0
bugcheck_event_1001_delta=0
controlled_shutdown=passed
```

## Karar

Host stability kapısı bu tekrarda geçmedi. Bilimsel normal baseline run
başlatılmadı; benzersiz bilimsel run ID atanmadı, close-run artefact'ı veya
bilimsel dataset üretilmedi ve fault injection yapılmadı.

`P1-HOST-STABILITY-002` geçmiş kabul kanıtı olarak korunur; bu yeni sonuç
mevcut hostun bilimsel koşu öncesinde tekrar kararsızlık gösterdiğini
belgeler. PCIe `00:1D.5` sorunu giderilip yeni bir temiz-boot doğrulaması
geçmeden `P1-CPU-001` veri toplamasına başlanmamalıdır.

## 30 Temmuz tam güç/EC sıfırlaması takibi

Kullanıcı bilgisayarı kapattı, adaptör ve USB aygıtlarını çıkardı, güç
düğmesini yaklaşık 40 saniye basılı tuttu ve sistemi yeniden açtı. Takip
kontrolü aşağıdaki sonucu verdi:

```text
captured_utc=2026-07-30T12:16:27.5073247Z
reported_boot_utc=2026-07-29T17:52:44.5000000Z
total_whea_event_17_since_reported_boot=103
whea_event_17_on_2026-07-30=95
first_new_whea_utc=2026-07-30T12:16:18.5731721Z
last_new_whea_utc=2026-07-30T12:16:19.7957362Z
kernel_power_event_41=0
bugcheck_event_1001=0
wlan_pnp=CM_PROB_DISABLED / Code 22 / Not Present
bluetooth_pnp=CM_PROB_PHANTOM / Unknown
bluetooth_last_arrival_local=2026-07-30T14:15:52+03:00
bluetooth_last_removal_local=2026-07-30T14:15:55+03:00
```

Windows boot zamanı değişmedi; kapanış Fast Startup/hybrid kernel session
nedeniyle yeni bir boot oturumu oluşturmamış olabilir. Bununla birlikte güç
sıfırlaması sonrasında 95 yeni WHEA Event 17 oluşması ve kartın USB Bluetooth
işlevinin PnP'den üç saniye içinde ayrılması sorunun yalnız bilimsel yükten
kaynaklanmadığını gösterir. Aynı kartın PCIe WLAN ve USB Bluetooth
işlevlerinin birlikte kararsızlaşması fiziksel kart, M.2 yuva/temas veya kart
güç yolunun profesyonel olarak incelenmesini gerektirir.

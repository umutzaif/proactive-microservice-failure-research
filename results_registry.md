# Deney SonuÃ§larÄ± KaydÄ±

Bu belge bÃ¼tÃ¼n deneylerin, baÅŸarÄ±sÄ±z olanlar dahil, deÄŸiÅŸmez Ã¶zet kaydÄ±dÄ±r. Her satÄ±r bir Ã§alÄ±ÅŸtÄ±rma ailesini temsil eder; ayrÄ±ntÄ±lÄ± artefact yolu verilmelidir.

## Durumlar

- `planned`
- `running`
- `completed`
- `invalid`
- `superseded`

## Deney kayÄ±t tablosu

| Experiment ID | Tarih | Durum | AmaÃ§ | Dataset/split | Model/koÅŸul | Birincil sonuÃ§ | Artefact | Not |
|---|---|---|---|---|---|---|---|---|
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-10u-007 | 2026-09-10 | planned | D-114 manuel Ethernet replacement, Ã¶zgÃ¼n 10u-002 slotu | Veri Ã¼retilmedi | 10/1/1, no-toxic, 500m; tÃ¼m kapÄ±lar korunur | HenÃ¼z Ã§alÄ±ÅŸtÄ±rÄ±lmadÄ± | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-10u-007-preregistration.md` | 006 kapalÄ±; 003 final; no-retry; merge ve ayrÄ± runtime onayÄ± gerekli |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-10u-006 | 2026-09-09 | invalid/incomplete | D-113 Ethernet replacement | Dataset/D-067 dÄ±ÅŸÄ± | YakÄ±nsama, 25 stabilite gÃ¶zlemi ve baseline tamamlandÄ± | archive_telemetry failed; Engine kaybÄ±; rollback failed, stop 82; Ã¶zgÃ¼n host 0/0/0; 10 EylÃ¼l kontrolÃ¼nde stopped/137/OOM false | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-10u-006-report.md` | ID kapalÄ±; telemetry/metadata/receipt yok; D-067 10u 1/3, 15u 2/3; rollback doÄŸrulanmadÄ± |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-10u-005 | 2026-09-08 | invalid/incomplete | D-110 Ethernet replacement, Ã¶zgÃ¼n invalid 10u-002 yuvasÄ± | Dataset/D-067 dÄ±ÅŸÄ± | Preflight/base/run-ID/workload geÃ§ti; target stability 2 pod nedeniyle durdu | Warm-up/baseline baÅŸlamadÄ±; rollback ve stopped state doÄŸrulandÄ±; host 0/0/0, Ethernet sabit | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-10u-005-report.md` | ID kapalÄ±; D-067 10u 1/3, 15u 2/3; 003 final slot; replacement yetkisiz |
| P0-ENV-001 | 2026-07-15 | completed | Online Boutique ve observability smoke test | Pilot v0 | Online Boutique v0.10.6, normal sistem | 15/15 deployment hazÄ±r; kullanÄ±cÄ± akÄ±ÅŸÄ± 5/5 HTTP 200; log/metric/trace toplandÄ± | `p0-env/artifacts/P0-ENV-001/` | `run_id` propagation yok; P1 Ã¶ncesi giderilecek |
| P1-LOG-ARCHIVE-001 | 2026-07-21 | completed | Ham log arÅŸivleme ve bÃ¼tÃ¼nlÃ¼k doÄŸrulamasÄ± | Uygulanamaz; araÃ§ doÄŸrulamasÄ± | Normal sistem, fault injection yok | 16/16 manifest girdisi doÄŸrulandÄ±; 17/17 dosya salt okunur | `p0-env/artifacts/P1-LOG-ARCHIVE-001/` | Ä°lk bozuk manifest denemesi silinmeden invalid olarak korundu; yerel mÃ¼hÃ¼r WORM deÄŸildir |
| P1-ARCHIVE-UTC-001 | 2026-07-23 | completed | Ham log arÅŸivinin UTC baÅŸlangÄ±Ã§ sÄ±nÄ±rÄ±nÄ± dÃ¼zeltmek | Uygulanamaz; araÃ§ doÄŸrulamasÄ± | Normal sistem, fault injection yok | Alt sÃ¼reÃ§ UTC round-trip eÅŸit; belirsiz yerel tarih reddedildi | `p0-env/artifacts/P1-ARCHIVE-UTC-001/` | Ã–nceki araÃ§ arÅŸivinde pencere 182,16 dakika; bilimsel veri olarak kullanÄ±lamaz |
| P1-LOG-ENRICH-001 | 2026-07-23 | completed | Ham loglarÄ± deÄŸiÅŸtirmeden parsed kayÄ±tlara run ID eklemek | Uygulanamaz; araÃ§ doÄŸrulamasÄ± | `log-envelope-v1`, fault injection yok | 58.670 kayÄ±t; run ID uyuÅŸmazlÄ±ÄŸÄ± 0; JSON hatasÄ± 0 | `p0-env/artifacts/P1-LOG-ENRICH-001/` | Kaynak pencere bilimsel veri deÄŸildir; yeni benzersiz run ile E2E test gerekli |
| P1-NORMAL-E2E-001 | 2026-07-25 | invalid | Benzersiz run ID ile normal koÅŸul E2E telemetry doÄŸrulamasÄ± | Uygulanamaz; altyapÄ± E2E doÄŸrulamasÄ± | Normal sistem, fault injection yok; `ob-normal-e2e-001` ve `ob-normal-e2e-002` | E2E-002 ham ve enriched log doÄŸrulamasÄ± geÃ§ti; Ã§ok-modlu run host Ã§Ã¶kmesi nedeniyle geÃ§ersiz | `p0-env/artifacts/P1-NORMAL-E2E-001/` | DPC_WATCHDOG_VIOLATION 0x133; restart sonrasÄ± Jaeger/Prometheus verisi korunmadÄ± ve aynÄ± run ID ile yeni telemetry oluÅŸtu |
| P1-TELEMETRY-EXPORT-001 | 2026-07-25 | completed | Log, metric ve trace verisini aynÄ± run penceresinde immutable dÄ±ÅŸa aktarmak ve final receipt Ã¼retmek | Uygulanamaz; araÃ§ doÄŸrulamasÄ± | Normal tooling trafiÄŸi; fault injection yok; telemetry schema v2 | 47.546 metric sample, 1.109 enriched log, 152 tam trace ve 806 span doÄŸrulandÄ±; `close_run=passed` | `p0-env/artifacts/P1-TELEMETRY-EXPORT-001/` | 15 boundary-crossing trace ham katmanda korundu ve selected katmandan dÄ±ÅŸlandÄ±; PR #10 ile `main` revision `f650bdd` Ã¼zerine merge edildi |
| P1-HOST-STABILITY-001 | 2026-07-25 | invalid | Hostun telemetry yÃ¼kÃ¼ altÄ±nda deney Ã§alÄ±ÅŸtÄ±rmaya uygunluÄŸunu doÄŸrulamak | Uygulanamaz; host kapÄ±sÄ± | Docker/Minikube tooling yÃ¼kÃ¼; Wi-Fi disabled | AynÄ± PCIe Root Port 00:1D.5 Ã¼zerinde 2 yeni WHEA Event 17 | `p0-env/artifacts/P1-TELEMETRY-EXPORT-001/` | Host dÃ¼zeltilmeden P1-CPU-001 baÅŸlatÄ±lmamalÄ± |
| P1-HOST-STABILITY-002 | 2026-07-28 | completed | Temiz boot altÄ±nda host stabilite kapÄ±sÄ±nÄ± tekrar doÄŸrulamak | Uygulanamaz; altyapÄ± doÄŸrulamasÄ± | Ä°ki 30 dakikalÄ±k yÃ¼k gÃ¶zlemi ve bir 10 dakikalÄ±k tam E2E kapanÄ±ÅŸ | WHEA Event 17: 0; Kernel-Power 41: 0; tam close-run baÅŸarÄ±lÄ± | `p0-env/artifacts/P1-HOST-STABILITY-002/` | Host kapÄ±sÄ± kabul edildi; uzun koÅŸularda Jaeger trace limitine ulaÅŸÄ±lmasÄ± ayrÄ± teknik engel olarak kaldÄ± |
| P1-HOST-STABILITY-003 | 2026-07-29 | invalid | Temiz boot sonrasÄ±nda aktif yÃ¼k altÄ±nda host stabilitesini yeniden doÄŸrulamak | Uygulanamaz; host kapÄ±sÄ± | Online Boutique loadgenerator; fault injection yok | 5. dakikada PCIe 00:1D.5 Ã¼zerinde 8 yeni WHEA Event 17; Kernel-Power 41 ve bugcheck 0 | `p0-env/artifacts/P1-HOST-STABILITY-003/` | Bilimsel baseline baÅŸlatÄ±lmadÄ±; PCIe sorunu giderilip temiz-boot host doÄŸrulamasÄ± geÃ§meden P1-CPU-001 veri toplamasÄ±na geÃ§ilmemeli |
| P1-HOST-STABILITY-004 | 2026-08-02 | completed | BIOS iÅŸlemi sonrasÄ±nda host stabilite kapÄ±sÄ±nÄ± yeniden doÄŸrulamak | Uygulanamaz; host kapÄ±sÄ± | 30 dakika aktif yÃ¼k ve `ob-host-stability-004` ile 10 dakika tam E2E kapanÄ±ÅŸ; fault injection yok | WHEA Event 17, Kernel-Power 41 ve bugcheck 0; close-run ve offline receipt geÃ§ti | `p0-env/artifacts/P1-HOST-STABILITY-004/` | 530.862 metric sample, 3.087 selected trace ve 32.697 span; bilimsel dataset deÄŸildir; P1-CPU-001 baÅŸlamadan ana araÅŸtÄ±rma deÄŸerlendirmesi ve kullanÄ±cÄ± onayÄ± beklenmeli |
| P1-CPU-001 / ob-cpu-normal-001 | 2026-08-02 | invalid | Ä°lk normal baseline adayÄ±nÄ± fault injection olmadan toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | Host ve log kapÄ±larÄ± geÃ§ti; Prometheus run-scoped metric sample bulunmadÄ±ÄŸÄ± iÃ§in close-run reddedildi | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-001-report.md` | 20.136 enriched log korundu; partial telemetry ve Ã¼Ã§ close-run hata receipt'i `_invalid` altÄ±nda; dataset'e alÄ±nmaz, fault injection baÅŸlatÄ±lmaz |
| P1-CPU-001 / ob-cpu-normal-002 | 2026-08-02 | completed | Ä°kinci fault'suz normal baseline adayÄ±nÄ± tÃ¼m bilimsel kapÄ±larla toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 532.256 metric sample, 3.004 selected trace, 31.439 span; tÃ¼m verifier'lar ve post-shutdown host kapÄ±sÄ± geÃ§ti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-002-report.md` | Ä°lk geÃ§erli bilimsel normal baseline adayÄ±; finalization UTC hassasiyet hatasÄ± `_invalid` receipt olarak korundu; fault injection baÅŸlatÄ±lmadÄ± |
| P1-CPU-001 / ob-cpu-normal-003 | 2026-08-02 | completed | ÃœÃ§Ã¼ncÃ¼ fault'suz normal baseline adayÄ±nÄ± baÄŸÄ±msÄ±z tekrar olarak toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 538.304 metric sample, 3.338 selected trace, 35.109 span; 15 deployment lifecycle ve tÃ¼m verifier kapÄ±larÄ± geÃ§ti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-003-report.md` | GeÃ§erli bilimsel normal baseline adayÄ±; host olayÄ± 0; fault injection baÅŸlatÄ±lmadÄ± |
| P1-CPU-001 / ob-cpu-normal-004 | 2026-08-02 | completed | DÃ¶rdÃ¼ncÃ¼ fault'suz normal baseline adayÄ±nÄ± baÄŸÄ±msÄ±z tekrar olarak toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 513.784 metric sample, 3.257 selected trace, 33.970 span; 15 deployment lifecycle ve tÃ¼m verifier kapÄ±larÄ± geÃ§ti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-004-report.md` | GeÃ§erli bilimsel normal baseline adayÄ±; post-shutdown host olayÄ± 0; fault injection baÅŸlatÄ±lmadÄ± |
| P1-ACTIVE-RUN-ID-GATE-001 | 2026-08-02 | completed | Deployment sonrasÄ±nda collector ve Prometheus'un beklenen run ID'yi gerÃ§ekten etkinleÅŸtirdiÄŸini doÄŸrulamak | Uygulanamaz; tooling doÄŸrulamasÄ± | `ob-active-run-gate-tool-001`; fault injection yok | ConfigMap/pod/runtime kapÄ±larÄ± geÃ§ti; 4.112 run-scoped metric series; yanlÄ±ÅŸ ID negatif testi reddedildi | `p0-env/artifacts/P1-ACTIVE-RUN-ID-GATE-001/report.md` | Bilimsel dataset deÄŸildir; yeni baseline Ã¶ncesinde zorunlu pre-lifecycle kapÄ± olarak kullanÄ±lÄ±r |
| P1-TARGET-SERVICE-SELECTION-001 | 2026-08-02 | completed | Ä°lk CPU-stress kalibrasyon hedefini iki aday arasÄ±nda kanÄ±ta dayalÄ± seÃ§mek | Uygulanamaz; geÃ§erli normal baseline yeniden analizi | checkoutservice ve recommendationservice; fault injection yok | Recommendation: 11,962 mCPU ortalama ve 1.078 kullanÄ±cÄ±-yolu spanÄ±; checkout: 1,225 mCPU ve 340 span | `p0-env/artifacts/P1-TARGET-SERVICE-SELECTION-001/` | `recommendationservice` D-014 ile seÃ§ildi; sonuÃ§ fault yanÄ±tÄ± kanÄ±tÄ± veya bilimsel fault run deÄŸildir |
| P1-SLO-CANDIDATE-001 | 2026-08-03 | completed | ÃœÃ§ geÃ§erli normal run'dan latency/error SLI daÄŸÄ±lÄ±mÄ±nÄ± Ã§Ä±karmak | GeÃ§erli normal-baseline yeniden analizi | 180 tam 5 sn pencere; frontend server spanlarÄ±; fault injection yok | Pencere-p95 latency p99 4.279,712 ms; 2.219 istekte hata 0; tekrar analizi byte-identical | `p0-env/artifacts/P1-SLO-CANDIDATE-001/` | O-003 aÃ§Ä±k: `/` route normalde yaklaÅŸÄ±k 4 sn; neden aÃ§Ä±klanmadan SLO dondurulmadÄ± ve fault injection baÅŸlatÄ±lmadÄ± |
| P1-SLO-ROOT-DIAGNOSTIC-001 | 2026-08-03 | completed | `/` normal gecikmesinin trace kritik-yol adayÄ±nÄ± ve kaynak/log karÅŸÄ±lÄ±ÄŸÄ±nÄ± belirlemek | GeÃ§erli normal-baseline yeniden analizi | 236 HTTP 200 `/` trace'i; fault injection ve deployment deÄŸiÅŸikliÄŸi yok | Downstream spanlar ms dÃ¼zeyinde; frontend kaynak kodundaki spansÄ±z, koÅŸulsuz GCP metadata DNS lookup gÃ¼Ã§lÃ¼ neden hipotezi | `p0-env/artifacts/P1-SLO-CANDIDATE-001/frontend-root-diagnostic-report.md` | Nedensellik henÃ¼z kanÄ±tlanmadÄ±; benchmark patch/A-B smoke akademik karÅŸÄ±laÅŸtÄ±rÄ±labilirliÄŸi etkilediÄŸi iÃ§in karar bekleniyor |
| P1-FRONTEND-DNS-AB-001 | 2026-08-03 | invalid | GCP metadata DNS autodetection patch'inin `/` latency etkisini A/B/A ile sÄ±namak | Tooling smoke; bilimsel dataset deÄŸil | Upstream A â†’ patched B â†’ upstream A; 5 warm-up + 5 Ã¶lÃ§Ã¼m isteÄŸi; fault yok | Treatment warm p95 227,792 ms; A kontrolleri 101,283 ms median ile 4.030,807 ms median arasÄ±nda uyuÅŸmadÄ± | `p0-env/artifacts/P1-FRONTEND-DNS-AB-001/report.md` | Cold-start ve DNS-cache/sequence carry-over nedeniyle nedensellik kurulamadÄ±; iki attempt silinmeden korundu, patch reddedilmedi fakat kabul de edilmedi |
| P1-FRONTEND-DNS-AB-002 | 2026-08-03 | completed | DNS patch etkisini baÄŸÄ±msÄ±z eÅŸzamanlÄ± podlar ve randomize eÅŸlenmiÅŸ turlarla sÄ±namak | Preregistered tooling testi; bilimsel dataset deÄŸil | 6 tur Ã— 2 varyant Ã— 10 concurrent `/` isteÄŸi; seed 20260803; fault yok | 120/120 HTTP 200; treatment 6/6 hÄ±zlÄ±; maksimum median oranÄ± 0,722 ile preregistered â‰¤0,25 kapÄ±sÄ± baÅŸarÄ±sÄ±z | `p0-env/artifacts/P1-FRONTEND-DNS-AB-002/report.md` | GeÃ§erli negatif sonuÃ§; eÅŸik post hoc gevÅŸetilmedi, patch bilimsel deployment'a alÄ±nmadÄ±, SLO aÃ§Ä±k ve fault injection baÅŸlamadÄ± |
| P1-SLO-ROUTE-CANDIDATE-001 | 2026-08-03 | completed | Global, `/`-hariÃ§ ve `/product/{id}` normal SLI nÃ¼fuslarÄ±nÄ± karÅŸÄ±laÅŸtÄ±rmak | GeÃ§erli normal-baseline yeniden analizi | 3 run; 180 tam 5 sn pencere; frontend server spanlarÄ±; fault yok | ÃœrÃ¼n ailesi 1.066 istek, 179/180 dolu pencere; window-p95 p99 345,992 ms, maksimum 451,162 ms, hata 0; replay byte-identical | `p0-env/artifacts/P1-SLO-ROUTE-CANDIDATE-001/` | Karar desteÄŸi aÅŸamasÄ±nda O-003 aÃ§Ä±ktÄ±; daha sonra P1-SLO-FREEZE-001 ve D-015 ile Ã§Ã¶zÃ¼ldÃ¼. Fault injection bu analizde baÅŸlamadÄ± |
| P1-SLO-FREEZE-001 | 2026-08-03 | completed | P1-CPU-001 failure manifestation kuralÄ±nÄ± fault verisi Ã¶ncesi dondurmak ve normal veride falsifiye etmek | SÃ¼rÃ¼m `p1-cpu-001-slo-v1`; bilimsel dataset deÄŸil | Product window-p95 >345,992 ms veya global error rate >0; 3 ardÄ±ÅŸÄ±k dolu 5 sn pencere | ÃœÃ§ normal run'da latency aÅŸÄ±m sayÄ±sÄ± 0/0/1, maksimum streak 0/0/1; error streak 0; yanlÄ±ÅŸ manifestation 0 | `p0-env/artifacts/P1-SLO-FREEZE-001/` | D-015 ile O-003 Ã§Ã¶zÃ¼ldÃ¼; yalnÄ±z normal uyumluluÄŸu kanÄ±tlar, fault duyarlÄ±lÄ±ÄŸÄ± henÃ¼z bilinmez ve fault injection bu kayÄ±tla otomatik baÅŸlamaz |
| P1-CPU-LOW-PREREG-001 | 2026-08-04 | completed | Ä°lk dÃ¼ÅŸÃ¼k CPU kalibrasyonunu fault verisi Ã¶ncesi preregister etmek ve gÃ¼venlik araÃ§larÄ±nÄ± doÄŸrulamak | Tooling/preregistration; bilimsel dataset deÄŸil | recommendationservice; 50m; 120 sn ramp; 300 sn steady; sabit SLO grid; bounded worker; Prometheus etki kapÄ±sÄ± | Worker, CPU-effect pozitif/negatif, metadata pozitif/negatif, fixed-grid/empty-window/timestamp ve parser testleri geÃ§ti | `p0-env/artifacts/P1-CPU-LOW-PREREG-001/` | Fault uygulanmadÄ±; canlÄ± preflight ve temiz committed revision geÃ§meden `ob-cpu-low-001` baÅŸlayamaz |
| P1-CPU-001 / ob-cpu-low-001 | 2026-08-04 | invalid | Ä°lk dÃ¼ÅŸÃ¼k CPU-stress kalibrasyon attempt'i | `cpu-recommendation-low-v1`; workload/SLO deÄŸiÅŸmedi | 5 dk warm-up + 5 dk pre-fault baseline tamamlandÄ±; injector baÅŸlangÄ±cÄ±nda PowerShell Confirm binding hatasÄ± | Fault worker baÅŸlamadÄ±; fault_injected=false; Minikube durdu; post-cleanup WHEA/KP41/bugcheck toplamlarÄ± 881/5/1 | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-001-report.md` | Lifecycle eksik; dataset'e alÄ±nmaz, silinmez ve run ID yeniden kullanÄ±lmaz. AynÄ± donmuÅŸ koÅŸullarda yeni benzersiz run gerekir |
| P1-CPU-001 / ob-cpu-low-002 | 2026-08-04 | invalid | DÃ¼ÅŸÃ¼k CPU-stress kalibrasyonunu tam lifecycle ile sÄ±namak | `cpu-recommendation-low-v1`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | CPU +50,591m ve tÃ¼m telemetry/host/pod kapÄ±larÄ± geÃ§ti; interval 59/60 < preregistered 240 olduÄŸu iÃ§in effect gate baÅŸarÄ±sÄ±z; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-002-report.md` | Dataset'e alÄ±nmaz ve retroaktif geÃ§erli yapÄ±lmaz. D-018 dÃ¼zeltmesi yalnÄ±z `v2` ve yeni `ob-cpu-low-003` iÃ§in geÃ§erlidir |
| P1-CPU-001 / ob-cpu-low-003 | 2026-08-04 | invalid | DÃ¼zeltilmiÅŸ fiziksel-etki coverage kapÄ±sÄ±yla dÃ¼ÅŸÃ¼k CPU-stress kalibrasyonunu toplamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/60, CPU +48,890m, host/pod/telemetry kapÄ±larÄ± geÃ§ti; manifestation null; final receipt UTC verifier type hatasÄ±yla oluÅŸmadÄ± | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-003-report.md` | Dataset'e alÄ±nmaz ve retroaktif finalize edilmez. KanÄ±t korunur; canonical UTC Ã¼retici/verifier dÃ¼zeltmesi yeni run ID gerektirir |
| P1-CPU-001 / ob-cpu-low-004 | 2026-08-04 | completed | AynÄ± v2 koÅŸullarÄ±nÄ± canonical UTC finalization dÃ¼zeltmesiyle tekrarlamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/60; CPU +48,463m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-004-report.md` | Ä°lk geÃ§erli dÃ¼ÅŸÃ¼k CPU-stress kalibrasyon adayÄ±. DÃ¼ÅŸÃ¼k ÅŸiddette SLO manifestation oluÅŸmamasÄ± geÃ§erli negatif bulgudur; eÅŸik post hoc deÄŸiÅŸtirilmez |
| P1-CPU-001 / ob-cpu-low-005 | 2026-08-06 | completed | Ä°lk geÃ§erli dÃ¼ÅŸÃ¼k CPU sonucunun baÄŸÄ±msÄ±z tekrarÄ±nÄ± toplamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 004 ile koÅŸullar deÄŸiÅŸmeden ayrÄ± lifecycle ve artifact | Coverage 59/60; CPU +52,050m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-005-report.md` | Ä°kinci geÃ§erli dÃ¼ÅŸÃ¼k CPU adayÄ± ve ilk baÄŸÄ±msÄ±z tekrar; `006` tamamlanmadan Ã¼Ã§-run tekrarlanabilirlik Ã¶zeti yapÄ±lmaz |
| P1-CPU-001 / ob-cpu-low-006 | 2026-08-06 | invalid | Ä°lk geÃ§erli dÃ¼ÅŸÃ¼k CPU sonucunun ikinci baÄŸÄ±msÄ±z tekrarÄ±nÄ± toplamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 004/005 ile koÅŸullar deÄŸiÅŸmeden yeni canonical revision ve artifact | Coverage 60/60, CPU +48,899m, host/pod/telemetry geÃ§ti; worker 420,000 sn fakat outer exec steady 305,313 sn ve final receipt reddedildi | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-006-report.md` | Dataset'e alÄ±nmaz; tolerans post hoc gevÅŸetilmez. GerÃ§ek worker UTC kaynaÄŸÄ± iÃ§in aÃ§Ä±k karar ve yeni run ID gerekir |
| P1-CPU-001 / ob-cpu-low-007 | 2026-08-06 | invalid | GeÃ§ersiz 006 yerine worker-emitted UTC ile yeni dÃ¼ÅŸÃ¼k CPU tekrarÄ±nÄ± toplamak | `cpu-recommendation-low-v3`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline tamamlandÄ±; injector pre-execution hash kapÄ±sÄ±nda durdu | Active run-ID geÃ§ti; fault uygulanmadÄ±; LF profil hash'i ile Windows CRLF working-tree hash'i uyuÅŸmadÄ±; host delta 0/0/0 | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-007-report.md` | Dataset'e alÄ±nmaz, silinmez ve run ID yeniden kullanÄ±lmaz. v3 hash'i retroaktif deÄŸiÅŸtirilmez; platform-independent hash sÃ¶zleÅŸmesi yeni profil/run gerektirir |
| P1-CPU-001 / ob-cpu-low-008 | 2026-08-06 | invalid | Platform-independent worker hash sÃ¶zleÅŸmesiyle dÃ¼ÅŸÃ¼k CPU tekrarÄ±nÄ± toplamak | `cpu-recommendation-low-v4`; diÄŸer koÅŸullar deÄŸiÅŸmedi | Warm-up/baseline ve 420 sn worker tamamlandÄ±; lifecycle resolver Ã¶ncesi PowerShell collection binding hatasÄ± | Hash geÃ§ti; 84 heartbeat; worker monotonic 420,000 sn; pod/host stabil; cooldown/archive/receipt tamamlanmadÄ± | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-008-report.md` | Dataset'e alÄ±nmaz ve retroaktif finalize edilmez. Generic.List aÃ§Ä±kÃ§a object[] yapÄ±lmadan resolver'a verilemedi; yeni run ID gerekir |
| P1-CPU-001 / ob-cpu-low-009 | 2026-08-06 | completed | AynÄ± v4 koÅŸullarÄ±nÄ± aÃ§Ä±k event-array dÃ¶nÃ¼ÅŸÃ¼mÃ¼yle tekrarlamak | `cpu-recommendation-low-v4`; diÄŸer koÅŸullar deÄŸiÅŸmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +50,534m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-009-report.md` | ÃœÃ§Ã¼ncÃ¼ geÃ§erli dÃ¼ÅŸÃ¼k CPU adayÄ±; D-020 tekrarlanabilirlik setini tamamlar. Null manifestation SLO'yu post hoc deÄŸiÅŸtirmez |
| P1-CPU-LOW-REPEAT-001 | 2026-08-06 | completed | ÃœÃ§ geÃ§erli dÃ¼ÅŸÃ¼k-ÅŸiddet run'Ä±nda fiziksel etki ve manifestation tekrarlanabilirliÄŸini Ã¶zetlemek | 004, 005, 009; betimsel analiz | CPU artÄ±ÅŸÄ± ortalama 50,349m; sample SD 1,801m; CV %3,576; aralÄ±k 48,463â€“52,050m | ÃœÃ§Ã¼nde physical/telemetry/host/receipt geÃ§ti; Ã¼Ã§Ã¼nde manifestation null | `p0-env/artifacts/P1-CPU-LOW-REPEAT-001/report.md` | DÃ¼ÅŸÃ¼k profil fiziksel actuation tekrarlanabilir; pre-failure Ã¶ngÃ¶rÃ¼ veya yeni severity kararÄ± deÄŸildir |
| P1-CPU-001 / ob-cpu-medium-001 | 2026-08-06 | completed | Ä°lk orta ÅŸiddetli CPU kalibrasyonunu toplamak | `cpu-recommendation-medium-v1`; 100m; min +50m; aynÄ± workload/seed/SLO | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +101,910m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-001-report.md` | Ä°lk geÃ§erli medium CPU adayÄ±; tek run tekrarlanabilirlik veya high severity yetkisi oluÅŸturmaz; SLO post hoc deÄŸiÅŸtirilmez |
| P1-CPU-001 / ob-cpu-medium-002 | 2026-08-06 | invalid | Ä°lk geÃ§erli medium sonucunun baÄŸÄ±msÄ±z tekrarÄ±nÄ± toplamak | `cpu-recommendation-medium-v1`; koÅŸullar 001 ile deÄŸiÅŸmedi | Worker/host/pod/telemetry geÃ§ti; effect analyzer aynÄ± pod/container iÃ§in eski kÄ±sa seriyi seÃ§ti | Orijinal effect 0/0 interval ve final receipt yok; tanÄ±sal aktif-seri replay 59/59, +100,828m; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-002-report.md` | Dataset'e alÄ±nmaz ve retroaktif geÃ§erli yapÄ±lmaz; D-026 yalnÄ±z sonraki yeni run ID iÃ§in geÃ§erlidir |
| P1-CPU-001 / ob-cpu-medium-003 | 2026-08-06 | completed | D-026 fail-closed seri seÃ§imiyle ikinci medium tekrarÄ±nÄ± toplamak | `cpu-recommendation-medium-v1`; koÅŸullar 001/002 ile deÄŸiÅŸmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +103,042m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-003-report.md` | Ä°kinci geÃ§erli medium aday; invalid 002 sete katÄ±lmaz, D-025 Ã¼Ã§-valid-run Ã¶zeti tamamlanmadÄ± |
| P1-CPU-001 / ob-cpu-medium-004 | 2026-08-07 | completed | Invalid 002 yerine Ã¼Ã§Ã¼ncÃ¼ geÃ§erli medium adayÄ±nÄ± toplamak | `cpu-recommendation-medium-v1`; 001/003 koÅŸullarÄ± ve D-026 deÄŸiÅŸmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +93,994m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-004-report.md` | ÃœÃ§Ã¼ncÃ¼ geÃ§erli medium aday; D-025 betimsel setini tamamlar, high severity otomatik yetkili deÄŸildir |
| P1-CPU-MEDIUM-REPEAT-001 | 2026-08-07 | completed | ÃœÃ§ geÃ§erli medium run'da fiziksel etki ve manifestation tekrarlanabilirliÄŸini Ã¶zetlemek | 001, 003, 004; betimsel analiz | CPU artÄ±ÅŸÄ± ortalama 99,649m; sample SD 4,930m; CV %4,947; aralÄ±k 93,994â€“103,042m | ÃœÃ§Ã¼nde physical/telemetry/host/receipt geÃ§ti; Ã¼Ã§Ã¼nde manifestation null | `p0-env/artifacts/P1-CPU-MEDIUM-REPEAT-001/report.md` | Medium physical actuation dÃ¼ÅŸÃ¼k varyansla tekrarlandÄ±; pre-failure Ã¶ngÃ¶rÃ¼, high severity veya yeni workload yetkisi deÄŸildir |
| P1-CPU-001 / ob-cpu-high-001 | 2026-08-07 | completed | Ä°lk yÃ¼ksek ÅŸiddetli CPU kalibrasyonunu toplamak | `cpu-recommendation-high-v1`; 150m; min +75m; aynÄ± workload/seed/SLO | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +146,589m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-high-001-report.md` | Ä°lk geÃ§erli high aday; tek latency ihlali Ã¼Ã§lÃ¼ streak deÄŸildir; tek run tekrarlanabilirlik veya workload/service/SLO deÄŸiÅŸikliÄŸi yetkisi oluÅŸturmaz |
| P1-CPU-001 / ob-cpu-high-002 | 2026-08-07 | completed | Ä°lk geÃ§erli high sonucunun baÄŸÄ±msÄ±z tekrarÄ±nÄ± toplamak | `cpu-recommendation-high-v1`; koÅŸullar 001 ile deÄŸiÅŸmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +143,819m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-high-002-report.md` | Ä°kinci geÃ§erli high aday ve ilk baÄŸÄ±msÄ±z tekrar; 003 tamamlanmadan Ã¼Ã§-run Ã¶zeti yapÄ±lmaz |
| P1-CPU-001 / ob-cpu-high-003 | 2026-08-07 | completed | Ä°lk geÃ§erli high sonucunun ikinci baÄŸÄ±msÄ±z tekrarÄ±nÄ± toplamak | `cpu-recommendation-high-v1`; koÅŸullar 001/002 ile deÄŸiÅŸmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/58; CPU +150,416m; host/pod/telemetry/final receipt/offline verifier geÃ§ti; iki-pencere maksimum streak ve manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-high-003-report.md` | ÃœÃ§Ã¼ncÃ¼ geÃ§erli high aday; dÃ¶rt latency ihlali Ã¼Ã§lÃ¼ streak oluÅŸturmadÄ± |
| P1-CPU-HIGH-REPEAT-001 | 2026-08-07 | completed | ÃœÃ§ geÃ§erli high run'da fiziksel etki ve manifestation tekrarlanabilirliÄŸini Ã¶zetlemek | 001, 002, 003; betimsel analiz | CPU artÄ±ÅŸÄ± ortalama 146,941m; sample SD 3,313m; CV %2,254; aralÄ±k 143,819â€“150,416m | ÃœÃ§Ã¼nde physical/telemetry/host/receipt geÃ§ti; Ã¼Ã§Ã¼nde manifestation null | `p0-env/artifacts/P1-CPU-HIGH-REPEAT-001/report.md` | High physical actuation dÃ¼ÅŸÃ¼k varyansla tekrarlandÄ±; pre-failure Ã¶ngÃ¶rÃ¼, model veya yeni kapsam yetkisi deÄŸildir |
| P1-WORKLOAD-CAPACITY-001 | 2026-08-10 | completed | Ä°kinci workload seviyesini fault outcome'u kullanmadan seÃ§mek | Tooling/karar desteÄŸi; dataset deÄŸil | 20 -> 10 -> 15 users; replacement ID'ler D-031/032 ile; seed 20260810 | 15/20 request oranÄ± 1,417/1,908 geÃ§ti; mean CPU 35,890/43,015m ile <=25m kapÄ±sÄ± geÃ§medi; selected=null | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/report.md` | EÅŸikler deÄŸiÅŸtirilmedi; ikinci-workload normal/fault planÄ± aktive edilmedi; O-010 aÃ§Ä±ldÄ± |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-20u-001 | 2026-08-10 | invalid | Ä°lk 20-user kapasite adayÄ±nÄ± Ã¶lÃ§mek | Tooling; dataset deÄŸil; fault yok | Active ID/log/schema-v3 telemetry/host/SLO geÃ§ti | Pod stability false fakat bileÅŸen snapshot'larÄ± yazÄ±lmadÄ±; CPU analizi Ã§oklu cAdvisor serisiyle kontamine; seÃ§imde kullanÄ±lmaz | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-20u-001-report.md` | KanÄ±t korunur, ID yeniden kullanÄ±lmaz; D-031 yalnÄ±z yeni run'lara uygulanÄ±r |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-10u-001 | 2026-08-10 | invalid | AynÄ± gÃ¼n 10-user request-intensity kontrolÃ¼ toplamak | Tooling; dataset deÄŸil; fault yok | Active ID ve 300 sn warm-up geÃ§ti; measurement baÅŸlamadÄ± | Canonical profil `normal_baseline_seconds`, ilk runner yalnÄ±z `measurement_seconds` bekledi | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-10u-001-report.md` | KanÄ±t korunur, ID kullanÄ±lmaz; D-032 yeni run'da iki canonical alanÄ± fail-closed normalize eder |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-10u-002 | 2026-08-10 | completed | D-030 aynÄ±-gÃ¼n request-intensity kontrolÃ¼nÃ¼ toplamak | Tooling; dataset deÄŸil; fault yok | `ob-default-10u-1r-v1`; D-031/032 kapÄ±larÄ± | 2,492375 frontend span/s; recommendation mean CPU 26,011m; SLO null; pod/host/telemetry geÃ§ti | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-10u-002-report.md` | 15/20-user oranlarÄ±nÄ±n frozen paydasÄ±dÄ±r; bilimsel normal baseline deÄŸildir |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-15u-001 | 2026-08-10 | completed | 15-user ikinci-workload adayÄ±nÄ± deÄŸerlendirmek | Tooling; dataset deÄŸil; fault yok | Request ratio 1,417334x; mean CPU 35,890m | Request kapÄ±sÄ± geÃ§ti, <=25m CPU kapÄ±sÄ± geÃ§medi; SLO null, pod/host/telemetry geÃ§ti | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-15u-001-report.md` | GeÃ§erli negatif karar kanÄ±tÄ±; aday seÃ§ilmez, eÅŸik gevÅŸetilmez |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-20u-002 | 2026-08-10 | completed | D-031 uyumlu 20-user replacement adayÄ±nÄ± deÄŸerlendirmek | Tooling; dataset deÄŸil; fault yok | Request ratio 1,907908x; mean CPU 43,015m | Request kapÄ±sÄ± geÃ§ti, <=25m CPU kapÄ±sÄ± geÃ§medi; SLO null, pod/host/telemetry geÃ§ti | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-20u-002-report.md` | GeÃ§erli negatif karar kanÄ±tÄ±; selected_users=null sonucunu tamamlar |
| P1-WORKLOAD-RESOURCE-BUDGET-001 | 2026-08-11 | completed | O-010 iÃ§in workload/high/limit kaynak bÃ¼tÃ§esi seÃ§eneklerini hesaplamak | Tooling/karar desteÄŸi; dataset deÄŸil; yeni run/fault yok | MÃ¼hÃ¼rlÃ¼ 10/15/20 kapasite Ã¶zetleri, high-v1 profil ve Ã¼Ã§-run high Ã¶zeti | 15-user toplamsal tahmini kalan 17,169m; 20-user 10,044m; 1,30x enterpolasyon noktasÄ± 13,594 user/33,112m | `p0-env/artifacts/P1-WORKLOAD-RESOURCE-BUDGET-001/` | Teknik Ã¶neri 15 user + deÄŸiÅŸmeyen profil/limit + prospektif %5 nominal rezervdir; O-010 aÃ§Ä±k kullanÄ±cÄ± kararÄ± olmadan Ã§Ã¶zÃ¼lmez |
| P1-SECOND-WORKLOAD-PREREG-001 | 2026-08-11 | completed | Ä°kinci workload bilimsel bloÄŸunu sonuÃ§lardan Ã¶nce dondurmak | Preregistration/tooling; dataset deÄŸil | `ob-second-15u-1r-v1`; `<=40m`; 3 normal + 6 fault; seed 20260810 | D-033, workload ve eÅŸ-fizikli low/medium/high profilleri ile run kimlik/sÄ±rasÄ± Ã¶n-kaydedildi | `p0-env/artifacts/P1-SECOND-WORKLOAD-PREREG-001/preregistration.md` | Merge Ã¶ncesi run yok; Ã¼Ã§ normal tamamlanmadan fault yok; model/LLM/GAT yetkisi yok |
| P1-SECOND-WORKLOAD-RUNTIME-001 | 2026-08-11 | completed | 15-user workload runtime/metadata baÄŸÄ±nÄ± fail-closed hazÄ±rlamak | Tooling; dataset deÄŸil; run/fault yok | Parametreli orchestrator, active workload ve metadata verifier fixture'larÄ± | 15u pozitif; 15u fault + 10u metadata negatif; static doÄŸru/yanlÄ±ÅŸ profil testleri geÃ§ti | `p0-env/artifacts/P1-SECOND-WORKLOAD-RUNTIME-001/report.md` | CanlÄ± deployment ve normal-baseline orchestrator kapÄ±larÄ± henÃ¼z gereklidir |
| P1-SECOND-WORKLOAD-NORMAL-RUNNER-001 | 2026-08-11 | completed | 15-user scientific normal lifecycle'Ä±nÄ± fail-closed hazÄ±rlamak | Tooling; dataset deÄŸil; canlÄ± run/fault yok | 300 sn warm-up + 300 sn baseline; log/telemetry/host/receipt kapÄ±larÄ± | AST/no-fault, gerekli kapÄ±lar, 15u metadata pozitif, yanlÄ±ÅŸ-ID negatif ve gerÃ§ek parametreli WhatIf geÃ§ti | `p0-env/artifacts/P1-SECOND-WORKLOAD-NORMAL-RUNNER-001/report.md` | Merge ve ayrÄ± workload/run-ID binding sonrasÄ± normal-001 baÅŸlayabilir; Ã¼Ã§ normalden Ã¶nce fault yok |
| P1-CPU-001 / ob-cpu-15u-normal-001 | 2026-08-11 | completed | Ä°kinci workload seviyesinin ilk bilimsel normal kontrolÃ¼nÃ¼ toplamak | Pilot normal baseline; dataset adayÄ± | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod/log/schema-v3/metadata/receipt/replay geÃ§ti; 533.101 metric, 3.851 trace, 46.830 span; SLO null; mean CPU 39,807m | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-001-report.md` | Ä°lk geÃ§erli 15u normal; 002/003 tamamlanmadan fault yok ve tekrarlanabilirlik iddiasÄ± yok |
| P1-CPU-001 / ob-cpu-15u-normal-002 | 2026-08-11 | invalid | Ä°kinci 15-user normal tekrarÄ±nÄ± aynÄ± koÅŸullarda toplamak | Pilot normal baseline; dataset dÄ±ÅŸÄ± invalid | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod ve log/schema-v3 replay geÃ§ti; frozen latency SLO'su 3 ardÄ±ÅŸÄ±k pencerede aÅŸÄ±ldÄ±; manifestation `19:10:07.812Z` | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-002-report.md` | Mean CPU 43,612m dÄ±ÅŸlama nedeni deÄŸildir; kanÄ±t korunur, ID kullanÄ±lmaz, valid blok 1/3 kalÄ±r |
| P1-CPU-001 / ob-cpu-15u-normal-003 | 2026-08-11 | completed | Ä°kinci geÃ§erli 15-user normal kontrolÃ¼nÃ¼ toplamak | Pilot normal baseline; dataset adayÄ± | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod/log/schema-v3/metadata/receipt/replay geÃ§ti; 524.692 metric, 3.765 trace, 45.877 span; SLO null; mean CPU 41,816m | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-003-report.md` | Ä°kinci geÃ§erli 15u normal; blok 2/3, replacement tamamlanmadan fault yok |
| P1-CPU-001 / ob-cpu-15u-normal-004 | 2026-08-13 | completed | Invalid `002` yerine Ã¼Ã§Ã¼ncÃ¼ geÃ§erli 15-user normal kontrolÃ¼nÃ¼ toplamak | Pilot normal baseline; dataset adayÄ± | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod/log/schema-v3/metadata/receipt/replay geÃ§ti; 495.764 metric, 3.743 trace, 45.864 span; SLO null; mean CPU 22,585m | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-004-report.md` | GeÃ§erli set 001/003/004 ve blok 3/3; randomize fault sÄ±rasÄ±nÄ±n canonical baÄŸ kapÄ±sÄ± aÃ§Ä±ldÄ± |
| P1-CPU-001 / ob-cpu-15u-medium-002 | 2026-08-13 | invalid | Randomize sÄ±ranÄ±n ilk 15-user medium fault run'Ä±nÄ± toplamak | `cpu-recommendation-medium-15u-v1`; fault uygulanmadan invalid/incomplete | 300 sn warm-up + 300 sn baseline; injector contract preflight | Run-ID/workload geÃ§ti; injector 15u profil kimliÄŸini allowlist'te tanÄ±madÄ± ve worker baÅŸlamadan fail-closed durdu | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-002-report.md` | KanÄ±t korunur, ID kullanÄ±lmaz; D-036 dÃ¼zeltmesi merge edilince aynÄ± slot `medium-003` ile tekrarlanÄ±r |
| P1-CPU-001 / ob-cpu-15u-medium-003 | 2026-08-13 | invalid | D-036 sonrasÄ± ilk randomize medium slotunu tamamlamak | `cpu-recommendation-medium-15u-v1`; fault fiziksel olarak uygulandÄ±, kapanÄ±ÅŸ incomplete | Full lifecycle tamamlandÄ±; dÄ±ÅŸ runner timeout'u final metadata/receipt Ã¶ncesi | TanÄ±sal coverage 59/59 ve CPU +99,972m; SLO null, host 0/0/0, log/schema-v3 replay geÃ§ti; final receipt yok | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-003-report.md` | Dataset dÄ±ÅŸÄ±; retroaktif valid yapÄ±lmaz; D-037 ile >=60 dk timeout ve yeni `medium-004` gerekir |
| P1-CPU-001 / ob-cpu-15u-medium-004 | 2026-08-13 | completed | D-037 altÄ±nda ilk randomize 15-user medium slotunu geÃ§erli tamamlamak | `cpu-recommendation-medium-15u-v1`; dataset adayÄ± | 300/300/120/300/300 sn lifecycle; dÄ±ÅŸ timeout 65 dk | Coverage 59/59, CPU +94,454m; host 0/0/0, pod/log/schema-v3/metadata/receipt/replay geÃ§ti; 1.090.922 metric, 8.535 trace, 105.284 span; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-004-report.md` | Ä°lk randomize slot tamamlandÄ±; canonical merge sonrasÄ± sÄ±radaki dondurulmuÅŸ slot `low-002` |
| P1-CPU-001 / ob-cpu-15u-low-002 | 2026-08-13 | invalid | Ä°kinci randomize 15-user low slotunu toplamak | `cpu-recommendation-low-15u-v1`; fault uygulanmadan invalid/incomplete | Runner ilk active run-ID kapÄ±sÄ± | Minikube hazÄ±r deÄŸildi; warm-up/baseline/fault baÅŸlamadÄ±; `run-error.json` korundu | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-002-report.md` | Dataset dÄ±ÅŸÄ±; ID kullanÄ±lmaz; cluster readiness sonrasÄ± aynÄ± frozen koÅŸullarla `low-003` replacement gerekir |
| P1-CPU-001 / ob-cpu-15u-low-003 | 2026-08-13 | invalid | Cluster readiness sonrasÄ± ikinci randomize low slotunu tamamlamak | `cpu-recommendation-low-15u-v1`; fault uygulanmadan invalid/incomplete | Active run-ID/workload + 300 sn warm-up + 300 sn baseline | Worker exec anÄ±nda `server` container bulunamadÄ±; host 0/0/0; fiziksel-etki/receipt yok | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-003-report.md` | Dataset dÄ±ÅŸÄ±; ID kullanÄ±lmaz; replacement Ã¶ncesi pod restart-stability ve exec-yarÄ±ÅŸÄ± kapÄ±sÄ± kararÄ± gerekir |
| P1-TARGET-POD-STABILITY-001 | 2026-08-13 | completed | D-038 target pod/container stabilite kapÄ±sÄ±nÄ± baÄŸÄ±msÄ±z fixture'larla doÄŸrulamak | Tooling; dataset deÄŸil; fault yok | 120 sn/5 sn policy; stable/restart/missing-container fixture'larÄ± | Pozitif fixture geÃ§ti; restart ve eksik-container negatifleri reddedildi; 15u profil regresyonlarÄ± geÃ§ti | `p0-env/artifacts/P1-TARGET-POD-STABILITY-001/report.md` | D-038 canonical merge ve `low-004` binding sonrasÄ± canlÄ± run yapÄ±labilir |
| P1-CPU-001 / ob-cpu-15u-low-004 | 2026-08-13 | completed | D-038 altÄ±nda ikinci randomize low slotunu tamamlamak | `cpu-recommendation-low-15u-v1`; dataset adayÄ± | D-038 120 sn + deÄŸiÅŸmeyen 300/300/120/300/300 lifecycle | D-038 25 gÃ¶zlem/restart 0; coverage 59/59, CPU +49,153m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geÃ§ti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-004-report.md` | Ä°kinci randomize slot tamamlandÄ±; canonical merge sonrasÄ± Ã¼Ã§Ã¼ncÃ¼ slot `high-001` |
| P1-CPU-001 / ob-cpu-15u-high-001 | 2026-08-14 | completed | ÃœÃ§Ã¼ncÃ¼ randomize 15-user high slotunu toplamak | `cpu-recommendation-high-15u-v1`; dataset adayÄ± | D-038 120 sn + 300/300/120/300/300 lifecycle | D-038 25/restart 0; coverage 59/58, CPU +135,160m, throttling 99,790m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geÃ§ti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-high-001-report.md` | ÃœÃ§Ã¼ncÃ¼ slot tamamlandÄ±; canonical merge sonrasÄ± dÃ¶rdÃ¼ncÃ¼ slot `high-002` |
| P1-CPU-001 / ob-cpu-15u-high-002 | 2026-08-14 | completed | DÃ¶rdÃ¼ncÃ¼ randomize 15-user high slotunu toplamak | `cpu-recommendation-high-15u-v1`; dataset adayÄ± | D-038 120 sn + 300/300/120/300/300 lifecycle | D-038 25/restart 0; coverage 59/59, CPU +145,710m, throttling 137,848m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geÃ§ti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-high-002-report.md` | DÃ¶rdÃ¼ncÃ¼ slot tamamlandÄ±; canonical merge sonrasÄ± beÅŸinci slot `low-001` |
| P1-CPU-001 / ob-cpu-15u-low-001 | 2026-08-14 | completed | BeÅŸinci randomize 15-user low slotunu toplamak | `cpu-recommendation-low-15u-v1`; dataset adayÄ± | D-038 120 sn + 300/300/120/300/300 lifecycle | D-038 25/sabit restart 1; coverage 59/59, CPU +53,044m, throttling 77,737m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geÃ§ti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-001-report.md` | BeÅŸinci slot tamamlandÄ±; canonical merge sonrasÄ± son slot `medium-001` ayrÄ± sohbette yÃ¼rÃ¼tÃ¼lÃ¼r |
| P1-CPU-001 / ob-cpu-15u-medium-001 | 2026-08-14 | invalid | AltÄ±ncÄ± ve son randomize 15-user medium slotunu toplamak | `cpu-recommendation-medium-15u-v1`; dataset dÄ±ÅŸÄ± invalid/incomplete | D-038 120 sn + frozen 300/300/120/300/300 lifecycle | D-038 25/sabit restart 3; coverage 60/59, CPU +100,390m; host 0/0/0; pod/log/schema-v3 replay geÃ§ti ve SLO null; warm-up 299,9970699 sn olduÄŸu iÃ§in `warmup_too_short`, final receipt yok | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-001-report.md` | KanÄ±t korunur, ID kullanÄ±lmaz; valid fault bloÄŸu 5/6 kalÄ±r ve otomatik sonraki aÅŸama/replacement kararÄ± verilmez |
| P1-PHASE-DURATION-GUARD-001 | 2026-08-14 | completed | Frozen minimum faz sÃ¼relerini scheduler erken dÃ¶nÃ¼ÅŸÃ¼ne karÅŸÄ± uygulamak ve replacement'Ä± Ã¶n-kaydetmek | Tooling/preregistration; dataset deÄŸil; fault yok | BaÅŸlangÄ±Ã§ UTC deadline guard; Ã¼Ã§ 300 sn host-zamanlÄ± faz; koÅŸullar deÄŸiÅŸmedi | KÄ±sa fixture erken dÃ¶nmedi; runner Ã¼Ã§ guard kullanÄ±yor; korunmasÄ±z 300 sn sleep yok | `p0-env/artifacts/P1-PHASE-DURATION-GUARD-001/report.md` | `ob-cpu-15u-medium-005` yalnÄ±z canonical merge sonrasÄ± aynÄ± koÅŸullarla yÃ¼rÃ¼tÃ¼lebilir; blok 5/6 kalÄ±r |
| P1-CPU-001 / ob-cpu-15u-medium-005 | 2026-08-14 | completed | D-039 altÄ±nda son randomize 15-user medium slotunu geÃ§erli tamamlamak | `cpu-recommendation-medium-15u-v1`; dataset adayÄ± | D-038 120 sn + D-039 korumalÄ± 300/300/120/300/300 lifecycle | D-038 25/sabit restart 1; sÃ¼reler geÃ§ti; coverage 59/59, CPU +93,519m, throttling 69,644m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geÃ§ti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-005-report.md` | AltÄ±ncÄ± geÃ§erli fault slotu; blok 6/6, bilimsel run sayÄ±sÄ± 21 |
| P1-SECOND-WORKLOAD-FAULT-BLOCK-001 | 2026-08-14 | completed | Ä°kinci-workload fault bloÄŸunu kanÄ±ta dayalÄ± kapatmak | 2 low + 2 medium + 2 high geÃ§erli run; betimsel analiz | Mean CPU artÄ±ÅŸÄ± low/medium/high 51,098/93,987/140,435m; CV %5,384/%0,704/%5,312 | AltÄ± run fiziksel/host/pod/telemetry/receipt/replay geÃ§ti; manifestation 6/6 null | `p0-env/artifacts/P1-SECOND-WORKLOAD-FAULT-BLOCK-001/report.md` | Fault blok 6/6 kapanÄ±r; model/LLM/GAT veya sonraki metodoloji aÅŸamasÄ±na otomatik geÃ§iÅŸ yok |
| P1-TRACE-CHUNK-TOOL-001 | 2026-07-28 | completed | Uzun run pencerelerini kayÄ±psÄ±z trace sorgu parÃ§alarÄ±na bÃ¶lmek | Uygulanamaz; sentetik araÃ§ doÄŸrulamasÄ± | Schema v3; iki servis ve dÃ¶rt zaman parÃ§asÄ± | Pozitif fixture geÃ§ti; boÅŸluk ve limit negatif testleri reddedildi | `p0-env/artifacts/P1-TRACE-CHUNK-TOOL-001/` | Bilimsel veri deÄŸildir; canlÄ± doÄŸrulama daha sonra P1-TRACE-CHUNK-LIVE-001 ile geÃ§ti |
| P1-TRACE-CHUNK-LIVE-001 | 2026-07-28 | completed | Schema v3 trace export hattÄ±nÄ± 30 dakikalÄ±k gerÃ§ek yÃ¼kte doÄŸrulamak | Uygulanamaz; canlÄ± tooling doÄŸrulamasÄ± | `ob-trace-chunk-live-001`, fault injection yok | 49/49 parÃ§a doÄŸrulandÄ±; maksimum 924/5000; close-run geÃ§ti | `p0-env/artifacts/P1-TRACE-CHUNK-LIVE-001/` | 9.441 selected trace ve 100.056 span; PR #12 ile `main` revision `c29e2b2` Ã¼zerine merge edildi |
| P1-CPU-001 | 2026-08-14 | completed | CPU stress altÄ±nda pre-failure sinyal fizibilitesi | Pilot v0; 21 geÃ§erli, 14 invalid attempt | 6 normal + 15 fault geÃ§erli run; iki workload, Ã¼Ã§ severity | Fiziksel actuation tekrarlandÄ±; geÃ§erli fault manifestation `0/15`, pozitif lead-time `0`; feature missingness henÃ¼z hesaplanmadÄ± | `p0-env/artifacts/P1-CPU-001-CLOSURE-001/report.md` | Dataset v1'e geÃ§ilmez; yeni deney tasarÄ±mÄ± aÃ§Ä±k akademik karar ve ayrÄ± Ã¶n-kayÄ±t gerektirir |
| P2-NETWORK-DELAY-DESIGN-001 | 2026-08-15 | completed | Kademeli network delay iÃ§in hedef, izolasyon, fiziksel etki ve SLO karar desteÄŸi | Tooling/preregistration; dataset deÄŸil; scientific fault yok | AltÄ± geÃ§erli normal run, iki workload; 5 sn edge/route replay; privilege/cleanup/gerÃ§ek-imaj doÄŸrulamasÄ± | recommendationservice -> productcatalogservice 6/6 run, min coverage %98; 3.872 span; ilk-semptom normal false-positive 0/6; SLO false manifestation 0/6; birleÅŸik verifier 18/18 | `p0-env/artifacts/P2-NETWORK-DELAY-DESIGN-001/report.md` | D-041 donduruldu; run ID null ve fault yetkisiz. Canonical merge sonrasÄ± ayrÄ± canlÄ± no-toxic overlay/overhead kapÄ±sÄ± gerekir |
| P2-NETWORK-DELAY-PROXY-LIVE-001 / ob-network-proxy-live-001 | 2026-08-15 | completed | CanlÄ± no-toxic proxy overhead, pod continuity ve rollback compatibility kapÄ±sÄ± | Operasyonel tooling kanÄ±tÄ±; dataset deÄŸil; scientific fault yok | 15 user, rate 1, seed 1; 300 sn warmup, 300 sn base, 120 sn stabilizasyon, 300 sn proxy | Base/proxy 60/60 target-edge pencere; median 4,136/4,4775 ms, overhead +0,3415 ms <=5 ms; SLO null; host 0/0/0; temiz rollback; receipt 90/90 | `p0-env/artifacts/P2-NETWORK-DELAY-PROXY-LIVE-001/report.md` | D-042; scientific run ID/fault yetkisi yok. Canonical merge sonrasÄ± ayrÄ± Ã¶n-kayÄ±t ve kullanÄ±cÄ± onayÄ± gerekir |
| P2-NETWORK-DELAY-PREREG-001 / ob-netdelay-15u-001 | 2026-08-15 | completed | Ä°lk scientific network-delay run koÅŸullarÄ±nÄ± ve fail-closed lifecycle tooling'ini sonuÃ§tan Ã¶nce dondurmak | Tooling/preregistration; dataset deÄŸil; scientific fault yok | 15 user/rate 1/seed 1; 0-750 ms 12-adÄ±mlÄ± ramp; 300/300/120/300/300; etki >=500 ms ve coverage 48/48 | BirleÅŸik prereg verifier 13/13; mutation-negative ramp, effect/coverage/cleanup/metadata ve runner contract testleri geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-001/report.md` | D-043; merge fault yetkisi deÄŸildir. AyrÄ± kullanÄ±cÄ± onayÄ± ve fresh runtime kapÄ±larÄ± gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-001 | 2026-08-15 | invalid | Ä°lk kademeli network-delay bilimsel gÃ¶zlemini toplamak | Dataset dÄ±ÅŸÄ± invalid/incomplete | Fresh kapÄ±lar + 300/300/120/300/300 planÄ± | Preflight, warmup, baseline ve 120,094 sn ramp geÃ§ti; PowerShell 7 JSON DateTime dÃ¶nÃ¼ÅŸÃ¼mÃ¼ steady baÅŸlangÄ±Ã§ UTC guard'Ä±nÄ± reddetti; steady/cooldown ve effect/manifestation yok; emergency cleanup, rollback, host 0/0/0, raw/enriched/schema-v3 ve invalid receipt geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-001-report.md` | KanÄ±t korunur, ID kullanÄ±lmaz, eÅŸikler deÄŸiÅŸmez; replacement bu sonuÃ§ta belirlenmez |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-001 / ob-netdelay-15u-002 | 2026-08-15 | completed | UTC type-boundary kusurunu dÃ¼zeltmek ve deÄŸiÅŸmeyen replacement'Ä± Ã¶n-kaydetmek | Tooling/preregistration; dataset deÄŸil; fault yok | D-043 koÅŸullarÄ± aynen; typed JSON UTC invariant canonical Z | PowerShell 7 typed-DateTime pozitif ve locale-string negatif fixture; runner/prereg contract verifier'larÄ± | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-002-preregistration.md` | D-044; canonical merge + ayrÄ± kullanÄ±cÄ± onayÄ± + fresh kapÄ±lar gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-002 | 2026-08-15 | invalid | DeÄŸiÅŸmeyen koÅŸullarla ilk tam network-delay gÃ¶zlemi replacement'Ä± | Dataset dÄ±ÅŸÄ± invalid; scientific candidate evidence | D-043/D-044; tam lifecycle | Coverage 60/60, median 5,300/756,702 ms, etki +751,402 ms; first symptom 13:07:44.987Z, latency manifestation 13:08:39.987Z; lifecycle/pod/cleanup/rollback/host 0/0/0 ve schema-v3 geÃ§ti; generic final receipt CPU-specific `severity` varsayÄ±mÄ±yla baÅŸarÄ±sÄ±z | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-002-report.md` | Zorunlu receipt kapÄ±sÄ± nedeniyle invalid; ID kullanÄ±lmaz. Bulgular modeling Ã¶rneÄŸi deÄŸildir; replacement bu sonuÃ§ta belirlenmez |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-002 / ob-netdelay-15u-003 | 2026-08-15 | completed | Receipt dispatch kusurunu dÃ¼zeltmek ve deÄŸiÅŸmeyen replacement'Ä± Ã¶n-kaydetmek | Tooling/preregistration; dataset deÄŸil; fault yok | D-043 koÅŸullarÄ± aynen; fault-class-aware verifier ve canonical-JSON invalid receipt v2 | CPU/network dispatch contract, LF/CRLF canonical-hash fixture ve prereg verifier | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-003-preregistration.md` | D-045; canonical merge + ayrÄ± kullanÄ±cÄ± onayÄ± + fresh kapÄ±lar gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-003 | 2026-08-15 | invalid | D-045 sonrasÄ± deÄŸiÅŸmeyen network-delay replacement'Ä±nÄ± yÃ¼rÃ¼tmek | Dataset dÄ±ÅŸÄ± invalid/incomplete preflight; fault yok | Fresh host/cluster/run-ID/workload/proxy kapÄ±larÄ± | Base deployment, run-ID, workload ve statik overlay geÃ§ti; canlÄ± proxy sÃ¶zleÅŸmesi rollout sonrasÄ± pod sayÄ±sÄ±nÄ± tam 1 gÃ¶rmedi ve `live_proxy_pod_count_mismatch` ile durdu; warmup/fault baÅŸlamadÄ±, rollback ve host `0/0/0` geÃ§ti; invalid-preflight receipt 7/7 | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-003-report.md` | ID kullanÄ±lmaz; telemetry yokluÄŸu receipt'te baÄŸlÄ±dÄ±r. Bilimsel eÅŸikler deÄŸiÅŸmez; replacement bu sonuÃ§ commit'inde belirlenmez |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-003 / ob-netdelay-15u-004 | 2026-08-15 | completed | Proxy pod termination yarÄ±ÅŸÄ±nÄ± bounded convergence ile Ã§Ã¶zmek ve deÄŸiÅŸmeyen replacement'Ä± Ã¶n-kaydetmek | Tooling/preregistration; dataset deÄŸil; fault yok | D-043 koÅŸullarÄ± aynen; 120/5 sn tek Ready pod ve finally host-after | Pozitif tek-pod; zero/multiple/container/pod-not-ready negatif fixture'larÄ±; runner/prereg contract | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-004-preregistration.md` | D-046; canonical merge + ayrÄ± kullanÄ±cÄ± onayÄ± + fresh kapÄ±lar gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-004 | 2026-08-15 | invalid | D-046 sonrasÄ± deÄŸiÅŸmeyen replacement'Ä± yÃ¼rÃ¼tmek | Dataset dÄ±ÅŸÄ± invalid/incomplete preflight; fault yok | 120/5 sn bounded tek Ready proxy pod kapÄ±sÄ± | 22 gÃ¶zlem: pod count ilk 2 gÃ¶zlemde 2, sonraki 20 gÃ¶zlemde 1; Ready true 0/22; `live_proxy_single_ready_pod_timeout`; warmup/fault yok; rollback, host 0/0/0 ve invalid receipt 8/8 geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-004-report.md` | ID kullanÄ±lmaz; fiziksel etki/manifestation sonucu yok. Timeout deÄŸiÅŸtirilmez; replacement Ã¶ncesi ayrÄ± no-fault readiness tanÄ±sÄ± gerekir |
| P2-NETWORK-DELAY-READINESS-DIAG-001 / ob-network-proxy-readiness-001 | 2026-08-15 | invalid | O-018 readiness bileÅŸenini fault'suz ayrÄ±ÅŸtÄ±rmak | Invalid/incomplete diagnostic; dataset deÄŸil; fault yok | 180 sn / 5 sn ayrÄ±ntÄ±lÄ± pod/container/events/log planÄ± | Ä°lk condition snapshot'Ä±nda opsiyonel `reason` alanÄ± yoktu; StrictMode serialization'Ä± durdurdu; rollback ve host 0/0/0 geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-READINESS-DIAG-001/ob-network-proxy-readiness-001-report.md` | KÃ¶k neden belirlenmedi; ID kullanÄ±lmaz. Null-safe serializer ve yeni diagnostic ID ayrÄ± commit gerektirir |
| P2-NETWORK-DELAY-READINESS-DIAG-001 / ob-network-proxy-readiness-002 | 2026-08-15 | invalid | Null-safe serializer ile readiness sorununu yeniden Ã¼retmek | Invalid/incomplete diagnostic; dataset deÄŸil; fault yok | 180 sn / 5 sn; pod/container, deployment, ReplicaSet, events | 33 gÃ¶zlem; proxy Ready 33/33, server 31/33; kalÄ±cÄ± failure yeniden Ã¼retilmedi. Current pod log seÃ§iminde eksik `deletionTimestamp` StrictMode'u durdurdu; rollback/host 0/0/0 geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-READINESS-DIAG-001/ob-network-proxy-readiness-002-report.md` | GÃ¶zlem deÄŸerli fakat log kapanÄ±ÅŸÄ± eksik; ID kullanÄ±lmaz. Kalan null-safe eriÅŸim ve yeni diagnostic ID gerekir |
| P2-NETWORK-DELAY-READINESS-DIAG-001 / ob-network-proxy-readiness-003 | 2026-08-15 | completed | O-018'i ayrÄ±ntÄ±lÄ± pod/container/events/log kanÄ±tÄ±yla kapatmak | GeÃ§erli tamamlanmÄ±ÅŸ diagnostic; dataset/modeling dÄ±ÅŸÄ±; fault yok | 180 sn / 5 sn; pod/container, deployment, ReplicaSet, events, current/previous log, rollback ve host | 33 gÃ¶zlem; proxy Ready 33/33 ve 0 restart, server Ready 30/33 ve 1 restart; tek all-Ready pod 16,616 sn'de; 004'Ã¼n kalÄ±cÄ± failure'Ä± yeniden Ã¼retilmedi; rollback/host 0/0/0 geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-READINESS-DIAG-001/ob-network-proxy-readiness-003-report.md` | Proxy hatasÄ± gÃ¶zlenmedi; geÃ§ici server probe timeout/restart gÃ¶rÃ¼ldÃ¼. 004'Ã¼n kesin kÃ¶k nedeni per-container kanÄ±t yokluÄŸundan geriye dÃ¶nÃ¼k kanÄ±tlanamaz; ID kullanÄ±lmaz |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-004 / ob-netdelay-15u-005 | 2026-08-15 | completed | D-047 ile readiness evidence Ã§Ã¶zÃ¼nÃ¼rlÃ¼ÄŸÃ¼nÃ¼ artÄ±rmak ve deÄŸiÅŸmeyen replacement'Ä± Ã¶n-kaydetmek | Tooling/preregistration; dataset deÄŸil; fault yok | D-043 koÅŸullarÄ± ve 120/5 sn kapÄ± aynen; per-pod condition ve per-container readiness/restart/state | Runner contract, readiness fixtures, run-ID propagation ve prereg verifier | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-005-preregistration.md` | D-047; canonical merge + ayrÄ± kullanÄ±cÄ± onayÄ± + fresh kapÄ±lar gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-005 | 2026-08-15 | invalid | D-047 sonrasÄ± deÄŸiÅŸmeyen replacement'Ä± yÃ¼rÃ¼tmek | Dataset dÄ±ÅŸÄ± invalid/incomplete preflight; fault yok | 120/5 sn ayrÄ±ntÄ±lÄ± tek Ready proxy pod kapÄ±sÄ± | 22 gÃ¶zlem: pod count 2 sonra 21 kez 1; Ready 0/22; proxy 22/22 Ready/0 restart, yeni server 1/22 Ready ve restart 0->4, son durum CrashLoopBackOff, termination exit 137/Error; rollback, host 0/0/0 ve invalid receipt 9/9 geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-005-report.md` | ID kullanÄ±lmaz; warmup/fault/telemetry yok. Exit 137 kesin OOM/kÃ¶k neden kanÄ±tÄ± deÄŸildir; replacement bu sonuÃ§ commit'inde belirlenmez |
| P2-NETWORK-DELAY-SERVER-TERMINATION-DIAG-001 / ob-network-server-termination-001 | 2026-08-15 | completed | O-018 server exit 137/CrashLoopBackOff nedenini faultsuz ayrÄ±ÅŸtÄ±rmak | GeÃ§erli tamamlanmÄ±ÅŸ diagnostic; dataset/modeling dÄ±ÅŸÄ±; toxic/fault yok | 180 sn / 5 sn; pod/container, events/describe/log, node/resource/metrics/kubelet, rollback/host | 33 gÃ¶zlem; proxy 33/33 Ready/0 restart, server max 5 restart/CrashLoopBackOff; events 5 kez liveness-failed Killing; probe gRPC 8080 timeout 1 sn/period 5 sn/failure 3; node pressure false, OOMKilled yok, metrics API yok; rollback/host 0/0/0 | `p0-env/artifacts/P2-NETWORK-DELAY-SERVER-TERMINATION-DIAG-001/ob-network-server-termination-001-report.md` | DoÄŸrudan neden kubelet liveness restart zinciri; timeout'un altÄ±nda yatan responsiveness nedeni Ã§Ã¶zÃ¼lemedi. ID kullanÄ±lmaz; replacement ayrÄ± karar ister |
| P2-NETWORK-DELAY-PROBE-RESOURCE-DIAG-001 / ob-network-probe-resource-001 | 2026-08-15 | invalid | O-019 probe timeout ile CPU/throttling/memory/OOM/pressure zaman baÄŸÄ±nÄ± faultsuz Ã¶lÃ§mek | Invalid/incomplete diagnostic; dataset/modeling dÄ±ÅŸÄ±; toxic/fault yok | 180 sn / 5 sn; cAdvisor Prometheus serileri + pod/event/log/node/rollback/host | Yeni pod server/proxy 33/33 Ready/0 restart; 5 readiness + 1 liveness timeout, Killing yok. CPU mean/max 32,466/373,423m; throttled-period %11,84; CPU pressure ~7,55 sn; memory max 33,242/450 MiB, failcnt/OOM/memory-pressure 0. Host WHEA count 881->879 non-monotonic; rollback geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-PROBE-RESOURCE-DIAG-001/ob-network-probe-resource-001-report.md` | Host-health kanÄ±tÄ± geÃ§ersiz ve restart yeniden Ã¼retilmedi; nedensellik kurulamaz. ID kullanÄ±lmaz, O-019 aÃ§Ä±k, replacement ayrÄ± karar ister |
| P2-NETWORK-DELAY-PROBE-RESOURCE-DIAG-001 / ob-network-probe-resource-002 | 2026-08-15 | completed | D-048 RecordId host kapÄ±sÄ±yla O-019 eÅŸzamanlÄ± resource tanÄ±sÄ±nÄ± deÄŸiÅŸmeden tekrarlamak | GeÃ§erli tamamlanmÄ±ÅŸ no-fault diagnostic; dataset/modeling dÄ±ÅŸÄ± | AynÄ± no-toxic overlay, 180 sn / 5 sn, 13 cAdvisor seri; yeni WHEA 17/KP41/bugcheck 0; log reset fail-closed | Proxy 33/33 Ready/0 restart; server 1/33 Ready, max 5 restart, 5 liveness Killing. CPU mean/max 40,616/499,307m; throttled-period 363/363, CPU pressure +21,271 sn; memory max 25,46/450 MiB, failcnt/OOM/memory-pressure 0; node pressure yok; rollback/host/18-file offline replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-PROBE-RESOURCE-DIAG-001/ob-network-probe-resource-002-report.md` | CPU quota throttling/pressure yakÄ±n mekanizma olarak gÃ¼Ã§lÃ¼ desteklenir; tek nihai kÃ¶k neden veya replacement ayarÄ± kanÄ±tlanmaz |
| P2-NETWORK-DELAY-RESOURCE-COMPAT-DESIGN-001 / ob-network-resource-compat-001 | 2026-08-20 | planned | Probe/request/memory sabitken 500m server CPU limitinin no-toxic compatibility etkisini sÄ±namak | Tooling/preregistration; dataset/modeling dÄ±ÅŸÄ±; fault yok | 120/5 stability + 180/5 measurement; Ready %100/restart 0; 13 metric/175 sn; throttling <0,50; CPU pressure <10,635359 sn; host/node/rollback/seal | Tek-op patch, positive/2 negative fixture ve rendered server/proxy/probe sÃ¶zleÅŸmesi geÃ§ti; canlÄ± run henÃ¼z yÃ¼rÃ¼tÃ¼lmedi | `p0-env/artifacts/P2-NETWORK-DELAY-RESOURCE-COMPAT-DESIGN-001/report.md` | D-050; canonical merge + ayrÄ± runtime onayÄ± gerekir; geÃ§iÅŸ scientific fault yetkisi deÄŸildir |
| P2-NETWORK-DELAY-RESOURCE-COMPAT-001 / ob-network-resource-compat-001 | 2026-08-20 | invalid | D-050 500m no-toxic resource compatibility kapÄ±sÄ±nÄ± yÃ¼rÃ¼tmek | Invalid/incomplete preflight; dataset/modeling dÄ±ÅŸÄ±; fault yok | Fresh Git/ID/host/deploy/run-ID/workload; sonra 120/5 + 180/5 | Base kapÄ±lar geÃ§ti; overlay sonrasÄ± kubectl birleÅŸik Ã§Ä±ktÄ±sÄ±ndaki JSON dÄ±ÅŸÄ± satÄ±r ConvertFrom-Json'Ä± durdurdu. Stability/measurement baÅŸlamadÄ±; rollback doÄŸrulamasÄ± aynÄ± parser kusuruyla eksik; Minikube stopped, host 0/0/0, 4/4 offline seal geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-RESOURCE-COMPAT-001/ob-network-resource-compat-001-report.md` | ID kullanÄ±lmaz; koÅŸul/eÅŸik deÄŸiÅŸmez; parser fix ve replacement ayrÄ± commit gerekir |
| P2-NETWORK-DELAY-RESOURCE-COMPAT-REPLACEMENT-001 / ob-network-resource-compat-002 | 2026-08-20 | invalid | D-051 JSON kanal ayrÄ±mÄ±yla D-050 koÅŸullarÄ±nÄ± deÄŸiÅŸmeden yeniden yÃ¼rÃ¼tmek | Invalid/incomplete preflight; dataset/modeling dÄ±ÅŸÄ±; fault yok | Fresh Git/ID/RecordId-host/deploy/run-ID/workload; sonra deÄŸiÅŸmeyen D-050 kapÄ±larÄ± | Base, run-ID ve workload geÃ§ti; overlay rollout sonrasÄ± doÄŸrudan kubectl Ã§Ä±ktÄ±sÄ±ndaki JSON dÄ±ÅŸÄ± `k...` parser'Ä± durdurdu. Stability/measurement/fiziksel etki baÅŸlamadÄ±; rollback verifier eksik artifact ile fail. Minikube stopped, host 0/0/0, 4/4 offline seal geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-RESOURCE-COMPAT-001/ob-network-resource-compat-002-report.md` | ID kullanÄ±lmaz; koÅŸul/eÅŸik deÄŸiÅŸmez; kÃ¶k neden tanÄ±sÄ± ve replacement ayrÄ± kontrollÃ¼ commit ister |
| P2-NETWORK-DELAY-RESOURCE-COMPAT-REPLACEMENT-002 / ob-network-resource-compat-003 | 2026-08-20 | invalid | D-052 native JSON stdout/stderr fiziksel izolasyonuyla D-050'yi deÄŸiÅŸmeden yeniden yÃ¼rÃ¼tmek | Invalid/incomplete preflight; dataset/modeling dÄ±ÅŸÄ±; fault yok | Fresh Git/ID/RecordId-host/deploy/run-ID/workload; sonra deÄŸiÅŸmeyen D-050 kapÄ±larÄ± | Base, run-ID ve workload geÃ§ti; KJson `$Args` otomatik deÄŸiÅŸken Ã§akÄ±ÅŸmasÄ± helper'a boÅŸ argÃ¼man verdi. Stability/measurement/fiziksel etki baÅŸlamadÄ±; rollback verifier eksik artifact ile fail. Minikube stopped, host 0/0/0, 4/4 seal/replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-RESOURCE-COMPAT-001/ob-network-resource-compat-003-report.md` | ID kullanÄ±lmaz; koÅŸul/eÅŸik deÄŸiÅŸmez; binding fix ve replacement ayrÄ± kontrollÃ¼ commit ister |
| P2-NETWORK-DELAY-RESOURCE-COMPAT-REPLACEMENT-003 / ob-network-resource-compat-004 | 2026-08-20 | invalid | D-053 sonrasÄ± D-050'yi deÄŸiÅŸmeden yÃ¼rÃ¼tmek | Invalid provenance; dataset/modeling dÄ±ÅŸÄ±; fault yok | 120/5 + 180/5; 13 metric/175 sn; physical/lifecycle/host/rollback/seal ve verifier run-ID | 23+34 stabil Ã¶rnek, 13/13 ve 180 sn; throttling 18/1127=%1,597, CPU pressure +0,535 sn, memory/OOM/node/host temiz, rollback ve 19/19 seal geÃ§ti. Verifier hard-coded `002` run-ID yazdÄ± ve ID gate'i yoktu | `p0-env/artifacts/P2-NETWORK-DELAY-RESOURCE-COMPAT-001/ob-network-resource-compat-004-report.md` | Fiziksel kapÄ±lar geÃ§ti fakat provenance verifier Ã§eliÅŸkisi nedeniyle invalid; ID kullanÄ±lmaz, eÅŸikler deÄŸiÅŸmez |
| P2-NETWORK-DELAY-RESOURCE-COMPAT-REPLACEMENT-004 / ob-network-resource-compat-005 | 2026-08-20 | valid | D-054 provenance kapÄ±sÄ±yla D-050'yi deÄŸiÅŸmeden yÃ¼rÃ¼tmek | GeÃ§erli no-toxic compatibility; dataset/modeling dÄ±ÅŸÄ±; fault yok | 120/5 + 180/5; 13 metric/175 sn; physical/lifecycle/host/rollback/seal + expected/folder/manifest ID | 23+34 stabil Ã¶rnek, 13/13 ve 180 sn; throttling 16/1154=%1,386, CPU pressure +0,498 sn; memory/OOM/node/host temiz, rollback, provenance ve 19/19 seal/replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-RESOURCE-COMPAT-001/ob-network-resource-compat-005-report.md` | D-050/O-020 kapanÄ±r; scientific fault veya sonraki aÅŸama yetkisi deÄŸildir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-006 | 2026-08-20 | invalid | D-055 500m scientific replacement'Ä± yÃ¼rÃ¼tmek | Invalid/incomplete preflight; dataset deÄŸil; fault yok | Fresh gates + compositional overlay verifier | Deploy/run-ID/workload/convergence geÃ§ti; verifier base patch'i Ã¼st klasÃ¶rde arayÄ±p durdu. Warmup/fault yok; rollback, host 0/0/0 ve 6/6 seal geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-006-report.md` | ID kullanÄ±lmaz; eÅŸikler deÄŸiÅŸmez; verifier fix/replacement ayrÄ± commit ister |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-006 / ob-netdelay-15u-007 | 2026-08-20 | planned | Compositional overlay verifier kaynaÄŸÄ±nÄ± ayÄ±rarak D-055'i deÄŸiÅŸmeden yÃ¼rÃ¼tmek | Tooling/preregistration; fault yok | Deployed 500m overlay + source design verifier; diÄŸer tÃ¼m kapÄ±lar aynÄ± | Runner contract ve proxy fixture'larÄ±; canlÄ± run yok | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-007-preregistration.md` | Merge + ayrÄ± runtime onayÄ± gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-007 | 2026-08-20 | invalid | D-056 replacement'Ä±nÄ± yÃ¼rÃ¼tmek | Invalid/incomplete entrypoint; dataset deÄŸil; lifecycle/fault yok | Git/contract/RecordId-host/Docker/Minikube baÅŸlangÄ±Ã§ kapÄ±larÄ± | Runner `ShouldProcess` non-interactive Ã§aÄŸrÄ±da preflight Ã¶ncesi null-reference Ã¼retti; Minikube stopped kaldÄ±, host 0/0/0 ve 5/5 diagnostic seal/replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-007-report.md` | ID kullanÄ±lmaz; bilimsel eÅŸikler deÄŸerlendirilmedi/deÄŸiÅŸmez; replacement ayrÄ± commit ister |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-007 / ob-netdelay-15u-008 | 2026-08-20 | planned | D-057 ile non-interactive entrypoint'i dÃ¼zeltip D-055/D-056'yÄ± deÄŸiÅŸmeden yÃ¼rÃ¼tmek | Tooling/preregistration; fault yok | Mandatory ExecutionApproved + ConfirmImpact Low + WhatIf; diÄŸer tÃ¼m kapÄ±lar aynÄ± | Static runner contract ve subprocess WhatIf no-mutation fixture | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-008-preregistration.md` | Merge + ayrÄ± runtime onayÄ± gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-008 | 2026-08-20 | completed | D-055/D-056/D-057 altÄ±nda ilk geÃ§erli 500m network-delay bilimsel run'Ä±nÄ± toplamak | GeÃ§erli exploratory 750ms pilot; yeni ladder/confirmatory sayÄ±ya dahil deÄŸil | 15/1/1; D-038; 300/300/120/300/300; 0->750 ms; effect >=500 ms | D-038 25/restart 0; coverage 60/60; median 3,238->755,233 ms, effect +751,995 ms; latency manifestation 18:25:43.328Z; host 0/0/0; raw/enriched/schema-v3/final replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-008-report.md` | D-066 sonrasÄ± yalnÄ±z tarihsel exploratory kanÄ±t; 25/50/100/250/500ms ladder hÃ¼cresi veya 60-incident confirmatory Ã¶rneÄŸi deÄŸildir |
| P2-NETWORK-DELAY-REPEATABILITY-001 | 2026-08-21 | superseded | D-058 shell-portability kapÄ±sÄ±nÄ± kapatÄ±p dÃ¶rt randomize eÅŸlenmiÅŸ kontrol/fault blokta run-arasÄ± varyansÄ± Ã¶lÃ§mek | Ä°lk fault slotundan sonra D-061â€“D-066 ile ileriye dÃ¶nÃ¼k durduruldu | `008` set dÄ±ÅŸÄ± pilot; seed 20260821; F-C,F-C,C-F,C-F; aynÄ± overlay/workload/resource/lifecycle; fault >=500 ms | pwsh5.1/pwsh7 portability geÃ§ti ve ilk fault slotu valid tamamlandÄ±; kalan slotlar yÃ¼rÃ¼tÃ¼lmedi | `p0-env/artifacts/P2-NETWORK-DELAY-REPEATABILITY-001/preregistration.md` | Tarihsel plan korunur; kalan 750ms slotlar Ã§alÄ±ÅŸtÄ±rÄ±lmaz; yeni yol headroom, 500m baseline reset, probe ayrÄ±mÄ± ve ladder'dÄ±r |
| P2-NETWORK-DELAY-REPEATABILITY-001 / ob-netdelay-15u-repeat-001 | 2026-08-21 | completed | D-059 ile ilk randomize fault slotunu deÄŸiÅŸmeyen `008` koÅŸullarÄ±nda toplamak | GeÃ§erli exploratory 750ms pilot; yeni ladder/confirmatory sayÄ±ya dahil deÄŸil | 15/1/1; 500m/100m; D-038; 300/300/120/300/300; 0->750 ms; effect >=500 ms | D-038 25/restart 0; coverage 60/60; median 5,548->755,171 ms; effect +749,623 ms; first symptom 29,397 sn; latency manifestation 104,397 sn; host 0/0/0; raw/enriched/schema-v3/final replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-REPEATABILITY-001/ob-netdelay-15u-repeat-001-report.md` | D-066 sonrasÄ± tarihsel exploratory kanÄ±t; control-001 yÃ¼rÃ¼tÃ¼lmez ve blok confirmatory paired sonuÃ§ sayÄ±lmaz |
| P2-NETWORK-DELAY-CONTROL-CONTRACT-001 / ob-netdelay-15u-control-001 | 2026-08-21 | superseded | D-060 ile ilk paired no-toxic kontrolÃ¼n metadata ve geÃ§erlilik semantiÄŸini dondurmak | UygulanmamÄ±ÅŸ contract; runner/canlÄ± kontrol yok | AynÄ± overlay/15/1/1/500m/100m/300-300-120-300-300; toxic yok; matched intervals; coverage >=48/48; null manifestation | 11-check static contract verifier; canlÄ± kanÄ±t Ã¼retilmedi | `p0-env/artifacts/P2-NETWORK-DELAY-REPEATABILITY-001/ob-netdelay-15u-control-001-contract.md` | D-066 ile yÃ¼rÃ¼tÃ¼lemez; profil `superseded_not_executable`, run ID kullanÄ±lmaz |
| P2-NETWORK-DELAY-HEADROOM-001 | 2026-08-21 | planned | D-061â€“D-063 iÃ§in fault Ã¶ncesi yeniden Ã¼retilebilir headroom girdilerini ve mevcut kanÄ±t sÄ±nÄ±rÄ±nÄ± tanÄ±mlamak | D-067 decision-support + collection prereg; fault/severity seÃ§imi yok | 500m/100m; no-toxic proxy; 10u+15u; ladder 25/50/100/250/500ms; frozen 594,664ms SLO; workload baÅŸÄ±na >=3 baÄŸÄ±msÄ±z yeni normal | 12-check verifier; eligible 0/3+0/3; max + max(5ms, range); seed 20260821 sÄ±ra donduruldu; leakage/authorization/choice negatifleri | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/preregistration.md` | Tooling commitinden sonra bu aÅŸamaya Ã¶zgÃ¼ genel onayla altÄ± no-fault run; fault ve severity seÃ§imi yok |
| P2-NETWORK-DELAY-HEADROOM-TOOLING-001 | 2026-08-21 | completed | D-067 altÄ± yeni 500m no-toxic normalin P2-Ã¶zgÃ¼ runner/analyzer/metadata kapÄ±larÄ±nÄ± uygulamak | Tooling; canlÄ± run/fault yok | pre/post clean; 500m/100m/100m; 120s stability; 300/300; 60/48; null SLO; pod/host/schema-v3/rollback/receipt | Runner parse/no-fault/gates; analyzer coverage+manifestation negative; metadata toxic negative; generic dispatch geÃ§ti | `p0-env/scripts/run-network-delay-headroom-normal.ps1` | Merge beklemeden aynÄ± kullanÄ±cÄ±-onaylÄ± aÅŸama dalÄ±nda commit; ilk run baÄŸÄ± ve WhatIf sonraki immutable commit |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-15u-001 | 2026-08-21 | invalid | D-067 randomize sÄ±ranÄ±n ilk 15u no-toxic proxy normalini toplamak | Dataset/headroom dÄ±ÅŸÄ± invalid normal; fault yok | 15u/rate1/seed1; 500m/100m/100m; no-toxic; 120s stability; 300/300; 60/48; null SLO; pod/host/schema-v3/rollback/receipt | Bilimsel pencere, 60/60 coverage, null manifestation, pod/host/schema-v3 ve rollback geÃ§ti; tanÄ±sal Ã¼st-kuyruk 299,901 ms; PowerShell `$Host` Ã§akÄ±ÅŸmasÄ± metadata/final receipt Ã¶ncesi kapanÄ±ÅŸÄ± durdurdu | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-15u-001-report.md` | SonuÃ§ D-067 hesabÄ±na alÄ±nmaz; immutable invalid receipt ile korunur, ID tekrar kullanÄ±lmaz ve eÅŸikler deÄŸiÅŸmez |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-15u-004 | 2026-08-21 | invalid | D-068 ile invalid ilk 15u sÄ±ra slotunu aynÄ± koÅŸullarda telafi etmek | Dataset/headroom dÄ±ÅŸÄ± invalid normal; fault yok | 15u/rate1/seed1; 500m/100m/100m; no-toxic; 120s stability; 300/300; 60/48; null SLO; pod/host/schema-v3/rollback/receipt | Bilimsel pencere, raw/enriched/schema-v3, null manifestation, pod/host ve rollback geÃ§ti; tanÄ±sal Ã¼st-kuyruk 605,978 ms; metadata verifier eski allowlist nedeniyle kimliÄŸi reddetti ve final receipt oluÅŸmadÄ± | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-15u-004-report.md` | SonuÃ§ D-067 hesabÄ±na alÄ±nmaz; immutable invalid receipt ile korunur, ID tekrar kullanÄ±lmaz |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-15u-005 | 2026-08-21 | invalid | D-069 ile invalid ilk sÄ±ra slotunu aynÄ± dondurulmuÅŸ koÅŸullarda yeniden telafi etmek | Dataset/headroom dÄ±ÅŸÄ± invalid normal; fault yok | 15u/rate1/seed1; 500m/100m/100m; no-toxic; 120s stability; 300/300; 60/48; null SLO; pod/host/schema-v3/rollback/receipt | Metadata 15/15 dahil bilimsel/operasyonel kapÄ±lar geÃ§ti; tanÄ±sal Ã¼st-kuyruk 1082,282 ms; shared finalizer top-level `random_seed` yokluÄŸunu StrictMode altÄ±nda reddetti ve partial receipt `_invalid` altÄ±nda korundu | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-15u-005-report.md` | Valid final receipt yok; sonuÃ§ D-067 hesabÄ±na alÄ±nmaz, ID tekrar kullanÄ±lmaz |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-15u-006 | 2026-08-21 | completed | D-070 ile invalid ilk slotu aÃ§Ä±k seed provenance ile aynÄ± koÅŸullarda telafi etmek | GeÃ§erli D-067 normal headroom girdisi; fault yok | 15u/rate1/seed1; 500m/100m/100m; no-toxic; 120s stability; 300/300; 60/48; null SLO; pod/host/schema-v3/rollback/receipt | Ãœst-kuyruk 539,155 ms; 60/60 nonempty; null manifestation; raw 17/17; enriched 26.475; telemetry 25/25, 514.271 sample, 3.803 trace, 47.714 span; metadata 15/15; pod/host/rollback/final receipt replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-15u-006-report.md` | Ä°lk geÃ§erli 15u tekrar: 1/3; tek baÅŸÄ±na repeatability/headroom/severity kararÄ± Ã¼retmez |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-15u-002 | 2026-08-21 | completed | D-067 etkili sÄ±ranÄ±n ikinci 15u no-toxic normalini toplamak | GeÃ§erli D-067 normal headroom girdisi; fault yok | 15u/rate1/seed1; 500m/100m/100m; no-toxic; 120s stability; 300/300; 60/48; null SLO; pod/host/schema-v3/rollback/receipt | Ãœst-kuyruk 374,397 ms; 60/60 nonempty; null manifestation; raw 17/17; enriched 26.110; telemetry 25/25, 505.206 sample, 3.750 trace, 46.445 span; metadata 15/15; pod/host/rollback/final receipt replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-15u-002-report.md` | Ä°kinci geÃ§erli 15u tekrar: 2/3; iki-run spread 164,758 ms yalnÄ±z betimsel, headroom/severity kararÄ± yok |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-10u-001 | 2026-08-21 | completed | D-067 etkili sÄ±ranÄ±n ilk 10u no-toxic normalini toplamak | GeÃ§erli D-067 normal headroom girdisi; fault yok | 10u/rate1/seed1; 500m/100m/100m; no-toxic; 120s stability; 300/300; 60/48; null SLO; pod/host/schema-v3/rollback/receipt | Ãœst-kuyruk 612,248 ms; 60/60 nonempty; manifestation null; raw 17/17; enriched 20.340; telemetry 25/25, 508.877 sample, 3.112 trace, 33.165 span; metadata 15/15; pod/host/rollback/final receipt replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-10u-001-report.md` | Ä°lk geÃ§erli 10u tekrar: 1/3; tek maksimum SLO eÅŸiÄŸini aÅŸsa da Ã¼Ã§ ardÄ±ÅŸÄ±k ihlal yok, headroom/severity kararÄ± yok |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-10u-002 | 2026-08-22 | invalid | D-067 etkili sÄ±ranÄ±n ikinci 10u no-toxic normalini toplamak | Dataset/headroom dÄ±ÅŸÄ± invalid preflight; fault yok | 10u/rate1/seed1; 500m/100m/100m; no-toxic; deployment/stability/warmup/baseline/receipt kapÄ±larÄ± | Base deployment availability recommendationservice Ã¼zerinde timeout; warmup/baseline baÅŸlamadÄ±; rollback rollout da timeout, Minikube stopped; host 0/0/0; diagnostic seal/replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-10u-002-report.md` | 10u sayacÄ± 1/3 kalÄ±r; ID kullanÄ±lmaz, eÅŸikler deÄŸiÅŸmez; D-071 base readiness tanÄ±sÄ± onaylÄ±, replacement yetkisiz |
| P2-NETWORK-DELAY-HEADROOM-001 / ob-netdelay-500m-normal-10u-004 | 2026-09-01 | invalid | D-091 ile invalid `10u-002` yuvasÄ±nÄ± aynÄ± D-067 koÅŸullarÄ±nda telafi etmek | Invalid/incomplete preflight; Dataset/headroom dÄ±ÅŸÄ±; fault yok | Canonical `2c85414`; 10u/rate1/seed1; base deployment Ã¶ncesi/sonrasÄ± kapÄ±lar | Docker disk-full ile eÅŸzamanlÄ± API kaybÄ±; `step_failed:deploy_base`; warm-up/baseline yok; rollback apply ve profile stop baÅŸarÄ±sÄ±z; host-after yok; Ã¼Ã§ runner dosyasÄ± + assessment sealed | `p0-env/artifacts/P2-NETWORK-DELAY-HEADROOM-001/ob-netdelay-500m-normal-10u-004-report.md` | ID kapalÄ±; D-067 10u 1/3, 15u 2/3; disk cleanup/recovery/replacement ayrÄ± onaylÄ± |
| P2-KUBERNETES-BOOTSTRAP-DIAG-001 / ob-docker-disk-recovery-001 | 2026-09-02 | valid | D-093 ile disk-full sonrasÄ± clean reconstruction recoverability sÄ±namak | D-094 completed operational diagnostic; Dataset/headroom dÄ±ÅŸÄ± | Canonical `86cb3d9`; C: free >=15 GiB; exact delete/absence; v1.34.0/4 CPU/6144 MiB/32 GiB/containerd; 180/5 | ~23,98 GiB preflight; delete/yokluk; 31/31 healthy; 1 Ready node; 8/8 kube-system Running; host 0/0/0; stopped exit 130/OOM false; verifier ve 12-file replay geÃ§ti | `p0-env/artifacts/P2-KUBERNETES-BOOTSTRAP-DIAG-001/ob-docker-disk-recovery-001-report.md` | ID kapalÄ±; clean reconstruction desteklenir, unique cause/application/D-067/replacement/fault kanÄ±tÄ± deÄŸildir |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-001 | 2026-08-27 | invalid | D-071 altÄ±nda `10u-002` sonrasÄ± taze base recommendationservice readiness/stability kanÄ±tÄ± toplamak | Invalid/incomplete operasyonel preflight; dataset/headroom dÄ±ÅŸÄ±; fault yok | Mevcut base + 10u workload; overlay yok; 900/5 + 180/5 planÄ± | Docker Linux engine yoktu; Minikube/deployment/gÃ¶zlem baÅŸlamadÄ±. Erken hata yolunda bitiÅŸik `throw` tokenization kusuru gÃ¶rÃ¼ldÃ¼; host 0/0/0 ve 4-file seal/replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-001-report.md` | ID kullanÄ±lmaz; recommendationservice sonucu yok. D-072 aynÄ± koÅŸullu `002` replacement'Ä±nÄ± baÄŸlar |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-002 | 2026-08-28 | invalid | D-072 ile altyapÄ±-preflight invalid `001`i aynÄ± D-071 koÅŸullarÄ±nda telafi etmek | Invalid/incomplete operasyonel preflight; dataset/headroom dÄ±ÅŸÄ±; toxic/fault yok | Docker ready; mevcut base + 10u; overlay yok; 900/5 convergence + Available sonrasÄ± 180/5 stability; host/seal/replay | Docker Engine 29.7.2, contract ve WhatIf geÃ§ti; Minikube node oluÅŸtu fakat API server sÃ¼reci hiÃ§ gÃ¶rÃ¼nmedi ve `K8S_APISERVER_MISSING` verdi. Deployment/workload/gÃ¶zlem baÅŸlamadÄ±; cluster stopped, host 0/0/0 ve 4-file SHA replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-002-report.md` | ID kullanÄ±lmaz; recommendationservice sonucu ve D-067 sayÄ±m deÄŸiÅŸikliÄŸi yok. Sonraki tanÄ±/replacement ayrÄ± karar ve yeni ID ister |
| P2-KUBERNETES-BOOTSTRAP-DIAG-001 / ob-k8s-bootstrap-001 | 2026-08-28 | valid | `002` Ã¶ncesi stale Minikube persistent-state hipotezini temiz bootstrap ile sÄ±namak | GeÃ§erli operasyonel altyapÄ± tanÄ±sÄ±; dataset/headroom dÄ±ÅŸÄ±; application/workload/toxic/fault yok | Eski container/volume/log kanÄ±tÄ±; exact-profile delete ve yokluk doÄŸrulamasÄ±; deÄŸiÅŸmeyen v1.34.0/4 CPU/6144 MiB/32 GiB/containerd; 180/5 system stability; host/seal/replay | Delete yokluÄŸu geÃ§ti; clean start baÅŸarÄ±lÄ±; 30/30 host+kubelet+apiserver Running ve kubeconfig Configured; host 0/0/0, cluster stopped, semantic verifier ve 12/12 SHA replay geÃ§ti | `p0-env/artifacts/P2-KUBERNETES-BOOTSTRAP-DIAG-001/ob-k8s-bootstrap-001-report.md` | Stale karÄ±ÅŸÄ±k state hipotezi desteklenir, eski volume tek neden olarak kanÄ±tlanmaz; recommendationservice veya replacement normal yetkisi yoktur |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-003 | 2026-08-28 | invalid | D-073 clean bootstrap sonrasÄ± eksik recommendationservice base readiness/stability gÃ¶zlemini toplamak | Invalid/incomplete operasyonel preflight; dataset/headroom dÄ±ÅŸÄ±; toxic/fault yok | Canonical `bb98f28`; Docker 29.7.2; mevcut base + 10u; overlay yok; deÄŸiÅŸmeyen 900/5 + 180/5 planÄ± | Minikube API server sÃ¼reci altÄ± dakikada hiÃ§ oluÅŸmadÄ±; `K8S_APISERVER_MISSING/minikube_start_failed`. Deployment/workload/gÃ¶zlem baÅŸlamadÄ±; cluster stopped, host 0/0/0 ve 4-file SHA replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-003-report.md` | ID kullanÄ±lmaz; D-073 geriye dÃ¶nÃ¼k deÄŸiÅŸmez, recommendationservice sonucu yoktur; D-067 15u 2/3, 10u 1/3 kalÄ±r ve sonraki adÄ±m ayrÄ± karar ister |
| P2-MINIKUBE-STATE-POSTMORTEM-001 / ob-minikube-state-postmortem-001 | 2026-08-29 | valid | D-075 sonrasÄ± gerÃ§ek state-root provenance'Ä±nÄ± ve durmuÅŸ profile'Ä±n eriÅŸilebilir postmortem kanÄ±tÄ±nÄ± toplamak | GeÃ§erli D-076 read-only operasyonel kanÄ±t; dataset/headroom dÄ±ÅŸÄ±; application/workload/fault yok | Canonical `8f88f70`; external/resolved/expected MINIKUBE_HOME; exact profile/container/volume; config/lastStart/Docker/Minikube logs; no mutation; semantic verifier/seal | Repository-local root eÅŸleÅŸti; Docker 29.7.2; container exited/restart 0/OOM false/exit 130; volume ve Ã¼Ã§ source mevcut; `K8S_APISERVER_MISSING` korundu; semantic verifier ve 9/9 SHA replay geÃ§ti | `p0-env/artifacts/P2-MINIKUBE-STATE-POSTMORTEM-001/ob-minikube-state-postmortem-001/` | D-075 provenance'Ä± kapandÄ±; stopped state tek kÃ¶k neden saÄŸlamaz. Profile/bootstrap/application/replacement/fault yetkisi yok; D-067 deÄŸiÅŸmez |
| P2-MINIKUBE-STATE-POSTMORTEM-TOOLING-001 | 2026-08-29 | completed | Docker-off preflight'Ä±nda PowerShell 5.1 native stderr taksonomisini runtime-baÄŸÄ±msÄ±z yapmak | D-077 tooling; canlÄ± diagnostic/artifact yok | Native stdout/stderr/exit-code isolation; success-with-stderr ve nonzero-with-stderr fixtures; D-076 preflight/inspect/log capture binding | Ä°lk Ã§aÄŸrÄ± artifact-free `NativeCommandError` ile durdu; ID tÃ¼ketilmedi. Ortak capture helper ve iki-runtime contract testleri eklendi | `p0-env/scripts/native-command-capture.ps1` | D-076 kimliÄŸi/koÅŸullarÄ± deÄŸiÅŸmez; merge ve Docker readiness sonrasÄ± aynÄ± preregistered runtime ayrÄ±ca yÃ¼rÃ¼tÃ¼lÃ¼r |
| P2-KUBERNETES-BOOTSTRAP-OBS-DIAG-001 / ob-k8s-bootstrap-observe-001 | 2026-08-29 | valid | D-076'nÄ±n stopped-state sÄ±nÄ±rÄ± sonrasÄ±nda bootstrap sÄ±rasÄ±nda canlÄ± process/journal kanÄ±tÄ± toplamak | D-079 operational diagnostic; dataset/headroom dÄ±ÅŸÄ±; application/workload/fault yok | Preserved stopped profile; unchanged v1.34.0/4 CPU/6144 MiB/32 GiB/containerd; 58 samples; live kubelet/containerd; stop/host/verifier/seal | `K8S_APISERVER_MISSING`; kubelet missing `/etc/kubernetes/bootstrap-kubelet.conf` ile restart, control-plane container yok; host 0/0/0; semantic verifier ve 13/13 SHA replay geÃ§ti | `p0-env/artifacts/P2-KUBERNETES-BOOTSTRAP-OBS-DIAG-001/ob-k8s-bootstrap-observe-001/` | YakÄ±n mekanizma tek kÃ¶k neden deÄŸildir; `start_exit_code=null` ve CRI help output tooling sÄ±nÄ±rlamalarÄ±dÄ±r; D-067 15u 2/3, 10u 1/3 kalÄ±r; application/replacement/fault yetkisi yok |
| P2-KUBERNETES-BOOTSTRAP-OBS-TOOLING-001 | 2026-08-29 | completed | D-079 non-interactive entrypoint null-reference kusurunu dÃ¼zeltmek | D-080 tooling; runtime artifact/Minikube baÅŸlangÄ±cÄ± yok | Mandatory ExecutionApproved + ConfirmImpact Low + WhatIf; diÄŸer D-079 koÅŸullarÄ± aynÄ± | Ä°lk Ã§aÄŸrÄ± artifact Ã¶ncesi durdu; ID tÃ¼ketilmedi. Static ve subprocess dry-run regresyonu hazÄ±rlanÄ±r | `p0-env/scripts/run-kubernetes-bootstrap-observability-diagnostic.ps1` | Merge sonrasÄ± aynÄ± D-079 kimliÄŸi yÃ¼rÃ¼tÃ¼lebilir; bilimsel/runtime kapsamÄ± geniÅŸlemez |
| P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001 / ob-k8s-bootstrap-state-consistency-001 | 2026-08-29 | invalid | D-079 restart dalÄ±ndaki kÄ±smi existing-config state'ini ve iki tooling boÅŸluÄŸunu prospektif sÄ±namak | Invalid/incomplete D-081 operasyonel tanÄ±; dataset/headroom dÄ±ÅŸÄ±; application/workload/fault yok | Canonical `934ca07`; preserved stopped profile; unchanged v1.34.0/4 CPU/6144 MiB/32 GiB/containerd/420/5 | Ä°lk live inspect parse beklenen `State` alanÄ±nÄ± Ã¼retmedi; state snapshot/assessment oluÅŸmadÄ±. Ä°lk seal dosya kilidinde durdu; process kapanÄ±nca 7/7 replay geÃ§ti; profile stopped, host 0/0/0 | `p0-env/artifacts/P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001/ob-k8s-bootstrap-state-consistency-001-report.md` | ID yeniden kullanÄ±lamaz; state-consistency sorusu aÃ§Ä±k, D-067 15u 2/3 ve 10u 1/3; replacement ayrÄ± karar/onay ister |
| P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001 / ob-k8s-bootstrap-state-consistency-002 | 2026-08-29 | invalid | Invalid `001`in inspect-shape ve redirect kapanÄ±ÅŸ boÅŸluklarÄ±nÄ± aynÄ± koÅŸullarda kapatmak | D-082 invalid/incomplete operational replacement; dataset/headroom dÄ±ÅŸÄ± | Canonical `79e7914`; unchanged preserved profile/v1.34.0/4 CPU/6144 MiB/32 GiB/containerd/420/5; 77 observations; start exit 105; live container | CRI list capture geÃ§ti; K8S_APISERVER_MISSING ve missing bootstrap-kubelet.conf tekrarlandÄ±. Ä°ki state capture `exit_code=2`, empty stdout; verifier capture baÅŸarÄ±sÄ±nÄ± denetlemedi ve `R` alias Ã§akÄ±ÅŸmasÄ± runner Ã§Ä±ktÄ±sÄ±nda hata Ã¼retti | `p0-env/artifacts/P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001/ob-k8s-bootstrap-state-consistency-002-report.md` | ID kapalÄ±; profile/container stopped, OOMKilled=false, host 0/0/0, 17/17 replay; state-consistency sorusu ve kÃ¶k neden aÃ§Ä±k; D-067 deÄŸiÅŸmez |
| P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-TOOLING-002 | 2026-08-31 | completed | D-082 shell argument fragmentation ve false-positive verifier kusurlarÄ±nÄ± runtime olmadan kapatmak | D-083 offline tooling; dataset/headroom dÄ±ÅŸÄ± | Windows argument escaping; runner capture exit/stdout/path assertions; alias-safe verifier; sealed-invalid negative ve synthetic-valid positive fixture | PowerShell 5.1/7 native argument testleri ile runtime/verifier/contract regresyonlarÄ± geÃ§ti | `p0-env/scripts/test-bootstrap-state-consistency-verifier.ps1` | `001`/`002` deÄŸiÅŸmez; yeni diagnostic ID ve runtime ayrÄ± onay/karar gerektirir |
| P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001 / ob-k8s-bootstrap-state-consistency-003 | 2026-08-31 | valid | D-083 sonrasÄ± state-consistency sorusunu aynÄ± koÅŸullarda yeniden test etmek | D-084 completed operational diagnostic; dataset/headroom dÄ±ÅŸÄ± | Canonical `168bff3`; preserved profile; v1.34.0/4 CPU/6144 MiB/32 GiB/containerd/420/5; 79 samples; start exit 105 | Ä°ki boundary'de flags/config/etcd ve aynÄ± hashli kubeadm YAML'lar present; bootstrap/kubelet conf ile apiserver/etcd manifestleri missing. Existing-config restart + no reconfiguration; CRI empty; 470 kubelet missing-file kaydÄ±; K8S_APISERVER_MISSING | `p0-env/artifacts/P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001/ob-k8s-bootstrap-state-consistency-003-report.md` | ID kapalÄ±; profile/container stopped, OOMKilled=false, host 0/0/0, verifier ve 17/17 replay; partial-state kanÄ±tÄ± tek kÃ¶k neden deÄŸildir; D-067 deÄŸiÅŸmez |
| P2-KUBERNETES-BOOTSTRAP-DIAG-001 / ob-k8s-bootstrap-recovery-001 | 2026-08-31 | valid | D-084 partial existing-state sonrasÄ±nda clean reconstruction recoverability sÄ±namak | D-085 completed operational diagnostic; dataset/headroom dÄ±ÅŸÄ± | Canonical `82f7faf`; exact delete/yokluk; v1.34.0/4 CPU/6144 MiB/32 GiB/containerd; 180/5 | Clean bootstrap; 31/31 healthy; 1 Ready node; 8/8 kube-system Running | `p0-env/artifacts/P2-KUBERNETES-BOOTSTRAP-DIAG-001/ob-k8s-bootstrap-recovery-001-report.md` | ID kapalÄ±; stopped, exit 130, OOMKilled=false, host 0/0/0, verifier ve 12/12 replay; origin/unique cause kanÄ±tlanmaz; D-067 deÄŸiÅŸmez |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-004 | 2026-08-31 | invalid | D-085 sonrasÄ± eksik recommendationservice application readiness/stability gÃ¶zlemini toplamak | D-086 invalid/incomplete operational preflight; dataset/headroom dÄ±ÅŸÄ± | Canonical `64bfad6`; deÄŸiÅŸmeyen base + 10u; overlay/toxic/fault yok; 900/5 + 180/5 planÄ± | Kubernetes baÅŸladÄ±; ignored worktree-local upstream source eksikliÄŸiyle base apply baÅŸarÄ±sÄ±z. Application/workload/readiness baÅŸlamadÄ±; stopped, exit 130/OOM false, host 0/0/0, 4-file replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-004-report.md` | ID kapalÄ±; application sonucu yok; D-067 15u 2/3, 10u 1/3 kalÄ±r |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-005 | 2026-09-01 | invalid | `004` source-preflight invalidliÄŸini aynÄ± application sÃ¶zleÅŸmesiyle telafi etmek | D-087 invalid/incomplete operational preflight; dataset/headroom dÄ±ÅŸÄ± | Canonical `8c37880`; exact source `5b3a712...`; base + 10u; 900/5 + 180/5 planÄ± | Source, Kubernetes ve base apply geÃ§ti; ilk snapshot absent `containerID` direct StrictMode eriÅŸiminde durdu. Observation yok; stopped, exit 130/OOM false, host 0/0/0, 4-file replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-005-report.md` | ID kapalÄ±; application sonucu yok; D-067 deÄŸiÅŸmez |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-006 | 2026-09-01 | invalid | `005` optional early-pod field tooling invalidliÄŸini aynÄ± application sÃ¶zleÅŸmesiyle telafi etmek | D-088 invalid/incomplete verifier closure; dataset/headroom dÄ±ÅŸÄ± | Canonical `fc180c8`; exact source; base + 10u; 900/5 + 180/5 | Availability, 60 observation, 32 stability, tek UID/restart 0/all Ready/no bad state ve supported assessment; semantic verifier `$Host` Ã§akÄ±ÅŸmasÄ±nda durdu, child exit yutuldu; stop/host/13-file replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-006-report.md` | ID kapalÄ±; assessment tanÄ±sal, valid deÄŸil; D-067 deÄŸiÅŸmez |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-007 | 2026-09-01 | valid | `006` semantic-verifier closure invalidliÄŸini aynÄ± application sÃ¶zleÅŸmesiyle telafi etmek | D-089/D-090 completed operational diagnostic; dataset/headroom dÄ±ÅŸÄ± | Canonical `9c6feb9`; pinned source; base+10u; 900/5 + 180/5; alias-safe verifier/child exit gate | Availability; 40 observation; 33 stability; tek UID; restart count sabit 2; all Ready; no bad state; semantic verifier, host 0/0/0 ve 13-file replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-007-report.md` | Ä°ki restart convergence Ã¶ncesi/sÄ±rasÄ±nda; stability'de yenisi yok. ID kapalÄ±; D-067 deÄŸiÅŸmez; normal/fault yetkisi yok |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-008 | 2026-09-02 | invalid | D-094 clean reconstruction sonrasÄ± application readiness/stability durumunu yeniden doÄŸrulamak | D-095/D-097 invalid/incomplete operational preflight; dataset/headroom dÄ±ÅŸÄ± | Canonical `089b675`; D-096 roots/profile/source pass; unchanged base + 10u; 900/5 + 180/5 plan | Existing-profile start `IF_SSH_AUTH`; public-key authentication rejected; base/workload/observation yok; stopped exit 130/OOM false; host 0/0/0; initial 5-file + final 9-file replay | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-008-report.md` | ID kapalÄ±; SSH auth yakÄ±n mekanizma, unique cause deÄŸil; D-067 15u 2/3, 10u 1/3; delete/reset/replacement/fault ayrÄ± |
| P2-NETWORK-DELAY-BASE-READINESS-TOOLING-001 | 2026-09-02 | completed | D-095 clean-code ile D-094 checkout-local runtime state/source provenance Ã§atÄ±ÅŸmasÄ±nÄ± kapatmak | D-096 repository-only portability tooling; runtime/artifact yok | Explicit mandatory roots; absolute resolved paths; D-094 profile config + stopped exit 130/OOM false + volume + pinned source preflight; manifest/verifier binding | PS5.1/7 contract ve verifier fixture testleri | `p0-env/scripts/run-network-base-readiness-diagnostic.ps1` | `008` tÃ¼ketilmedi; D-095 koÅŸullarÄ± ve D-067 deÄŸiÅŸmez; merge/runtime ayrÄ± |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-009 | 2026-09-03 | invalid | D-097 SSH mismatch sonrasÄ± application readiness/stability doÄŸrulamasÄ± | D-098/D-099 invalid/incomplete operational diagnostic; dataset/headroom dÄ±ÅŸÄ± | Canonical `39f00a9`; matching 44eb runtime/source/key; base+10u planÄ± | Start geÃ§ti; overlay checkout-relative eksik source yolunda `base_apply_failed`. Workload/observation yok; stopped exit 130/OOM false; host 0/0/0; 6-file replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-009-report.md` | ID kapalÄ±; D-067 deÄŸiÅŸmez; retry/fault yetkisi yok |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-010 | 2026-09-03 | invalid | `009` source-binding invalidliÄŸini deÄŸiÅŸmeyen application sÃ¶zleÅŸmesiyle telafi etmek | D-099/D-100 invalid/incomplete operational diagnostic; dataset/headroom dÄ±ÅŸÄ± | Canonical `8e15ef1`; source-bound base+10u; 900/5+180/5; no fault | Source/apply geÃ§ti; availability true; 33 stability Ã¶rneÄŸinde restart 1..5, Ready 1, bad-state 18. Empty log capture null contents ile assessment Ã¶ncesi durdu; stopped exit 137/OOM false, host 0/0/0, 13-file replay | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-010-report.md` | ID kapalÄ±; observation olumsuz fakat valid assessment deÄŸil; D-067 deÄŸiÅŸmez |
| P2-NETWORK-DELAY-BASE-READINESS-DIAG-001 / ob-network-base-readiness-011 | 2026-09-03 | valid | `010` null evidence-capture invalidliÄŸini aynÄ± sÃ¶zleÅŸmeyle telafi etmek | D-100/D-101 completed operational diagnostic; dataset/headroom dÄ±ÅŸÄ± | Canonical `5bac21a`; null-safe capture; source-bound base+10u; 900/5+180/5; no fault | Availability true; 34 stability Ã¶rneÄŸi; tek UID; restart sabit 6; Ready 34/34; bad state yok; zero-byte previous log; semantic verifier, host 0/0/0, stopped exit 137/OOM false ve 16-file replay geÃ§ti | `p0-env/artifacts/P2-NETWORK-DELAY-BASE-READINESS-DIAG-001/ob-network-base-readiness-011-report.md` | ID kapalÄ±; D-067 deÄŸiÅŸmez; normal/fault yetkisi yok |
| P1-HOST-NETWORK-PORTABILITY-001 / ob-host-network-portability-wifi-001 | 2026-09-04 | invalid/incomplete | Exact Wi-Fi adaptÃ¶rÃ¼+sÃ¼rÃ¼cÃ¼sÃ¼nÃ¼n mevcut host-stability sÃ¶zleÅŸmesini destekleyip desteklemediÄŸini sÄ±namak | D-102â€“D-106 Dataset-dÄ±ÅŸÄ± no-fault qualification | Clean boot geÃ§ti; 2x1800 sn aktif yÃ¼k + 600 sn E2E; Ã¼Ã§ ayrÄ± UID; Wi-Fi baÄŸlamÄ± kararlÄ±; her pencerede RecordId host 0/0/0 | `archive_raw_logs`, PowerShell pipeline sonrasÄ± gÃ¼venilmez `$LASTEXITCODE` nedeniyle Ã§alÄ±ÅŸan profili stopped sÄ±nÄ±flandÄ±rdÄ±; application telemetry closure geÃ§medi. 8 dosyalÄ±k seal replay geÃ§ti; profile final durumda stopped | `p0-env/artifacts/P1-HOST-NETWORK-PORTABILITY-001/ob-host-network-portability-wifi-001/` | ID tÃ¼ketildi; baÅŸarÄ±/qualification iddiasÄ± yok; aynÄ± ID tekrar edilmez; Dataset/D-067 sayÄ±mÄ±na girmez |
| P1-HOST-NETWORK-PORTABILITY-001 / ob-host-network-portability-wifi-002 | 2026-09-05 | invalid/incomplete | D-106 teknik delta ile exact Wi-Fi adaptÃ¶rÃ¼+sÃ¼rÃ¼cÃ¼sÃ¼ portability qualification | D-107â€“D-108 Dataset-dÄ±ÅŸÄ± no-fault replacement | Clean boot geÃ§ti; 2x1800 sn + 600 sn; Ã¼Ã§ UID; Wi-Fi baÄŸlamÄ± kararlÄ±; her pencerede host 0/0/0 | Close alt sÃ¼reci explicit external `MINIKUBE_HOME` deÄŸerini repository-local varsayÄ±lanla ezdi; yanlÄ±ÅŸ profile store nedeniyle `archive_raw_logs` failed. 8-file seal replay geÃ§ti; final profile stopped. Stop sonrasÄ±nda aynÄ± Wi-Fi PCIe parent Ã¼zerinde 12 WHEA-17 oluÅŸtu | `p0-env/artifacts/P1-HOST-NETWORK-PORTABILITY-001/ob-host-network-portability-wifi-002/` | ID tÃ¼ketildi; qualification iddiasÄ± yok; aynÄ± ID tekrar edilmez; Dataset/D-067 sayÄ±mÄ±na girmez |
| D-109 / Wi-Fi host-remediation inventory | 2026-09-06 | complete / runtime-blocking | Tekrarlanan Wi-Fi PCIe WHEA-17 sinyalinde resmÃ® remediation adayÄ± var mÄ±? | Salt-okunur model/BIOS/driver/power inventory + resmÃ® ASUS karÅŸÄ±laÅŸtÄ±rmasÄ± | WLAN 3.0.1.1314 ve chipset 10.1.31.2 resmÃ® paketlerle eÅŸleÅŸiyor; BIOS 311, gÃ¶rÃ¼nen destek BIOS 310; AC ASPM off | GÃ¼venli resmÃ® update adayÄ± doÄŸrulanmadÄ±; ASUS/yetkili servis remediasyonuna kadar uzun Wi-Fi runtime bloke | `p0-env/artifacts/P1-HOST-NETWORK-PORTABILITY-001/d109-host-remediation-inventory.md` | Ayar deÄŸiÅŸmedi; seri/aÄŸ kimliÄŸi yok; Dataset/D-067 deÄŸiÅŸmedi |
| M0-RULE-001 | - | planned | Kural tabanlÄ± alarm baseline | Pilot sonrasÄ± | Threshold baseline | Bekleniyor | - | Validation ile eÅŸik seÃ§ilecek |
| M1-XGB-001 | - | planned | Tabular temporal baseline | Dataset v1 | XGBoost | Bekleniyor | - | Kalibrasyon dahil |
| M2-GRU-001 | - | planned | Sequence temporal model | Dataset v1 | GRU | Bekleniyor | - | 15/30/60 s horizon |
| L1-VERIFY-001 | - | planned | LLM false-positive azaltÄ±mÄ± | Dataset v1 test | Evidence-grounded verifier | Bekleniyor | - | Kodlu/kodsuz kontroller |
| R1-GRAPH-001 | - | planned | Root-cause ranking | Dataset v1 test | Graph baselines -> GCN/GAT | Bekleniyor | - | Top-1/Top-3/MRR |

## P0-ENV-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P0-ENV-001"
research_question: "Online Boutique yerel ortamda sÃ¼rdÃ¼rÃ¼lebilir biÃ§imde Ã§alÄ±ÅŸÄ±yor ve log/metric/trace toplanabiliyor mu?"
status: completed
code_revision: "online-boutique v0.10.6 / 5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb"
config_revision: "kustomization sha256:DD7A94CC04FECA210AC30A2A53DFB31FF047BE961F010A1EFF57F693F557C914; observability sha256:E7F4BBE531AB4645D536969DA2DCDE20FF7120521C5DEB22455279626526489B"
dataset_version: "Pilot v0 (veri Ã¼retilmedi)"
split_manifest: null
feature_version: null
model: "Normal sistem; model yok"
seeds: []
primary_metric: "deployment readiness + normal-flow smoke + telemetry availability"
primary_result: "15/15 deployment Available; 5/5 smoke adÄ±mÄ± HTTP 200; log/metric/trace toplandÄ±"
confidence_interval: null
secondary_results:
  prometheus_cadvisor_target: "up"
  namespace_cpu_rate_example: 0.1194279549487128
  jaeger_paymentservice_trace_count: 5
  run_id_present_in_three_modalities: false
runtime: "Kurulum ve doÄŸrulama oturumu, 2026-07-15"
hardware: "8 logical CPU host; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P0-ENV-001/"
known_issues:
  - "run_id logs/metrics/traces iÃ§inde yok; P1 Ã¶ncesi propagation gerekli"
  - "bazÄ± trace service adlarÄ± unknown_service; OTEL_SERVICE_NAME sabitlenmeli"
  - "immutable ham log arÅŸivi P1 run pipeline'Ä±nda kurulmalÄ±"
  - "trace sampling oranÄ± P1 Ã¶ncesi aÃ§Ä±kÃ§a sabitlenmeli"
decision: "repeat"
```

## P1-LOG-ARCHIVE-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-LOG-ARCHIVE-001"
research_question: "Ham Kubernetes loglarÄ± run bazÄ±nda, Ã¼zerine yazÄ±lmadan ve SHA-256 ile doÄŸrulanabilir biÃ§imde arÅŸivlenebiliyor mu?"
status: completed
code_revision: "82ed754 environment baseline; implementation revision is the Git commit containing this record"
config_revision: "deployment_revision is recorded in the local run metadata"
dataset_version: null
split_manifest: null
feature_version: null
model: null
seeds: []
primary_metric: "verified manifest entries / total manifest entries"
primary_result: "16/16 manifest entry verified; failure_count=0"
confidence_interval: null
secondary_results:
  raw_log_file_count: 15
  raw_log_files_containing_run_id: 0
  readonly_file_count: 17
  wrong_run_id_rejected: true
  invalid_manifest_rejected: true
  unmanifested_file_rejected: true
  invalid_archive_preserved: true
runtime: "P1 readiness tooling validation, 2026-07-21"
hardware: "Local Windows 11 host; existing p0-online-boutique Minikube profile"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-LOG-ARCHIVE-001/"
known_issues:
  - "Run ID is linked at archive metadata level but is absent from 15/15 raw log files; parsed log enrichment is required before experimental collection"
  - "Windows read-only attribute and SHA-256 manifest provide project-level sealing, not hardware/cloud WORM object lock"
  - "Local raw run archives are excluded from Git and require separate backed-up storage before scientific runs"
  - "The first manifest-path implementation failed verification and remains preserved under the local _invalid archive path"
decision: "accept"
```

## P1-ARCHIVE-UTC-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-ARCHIVE-UTC-001"
research_question: "Ham log arÅŸivinin baÅŸlangÄ±Ã§ UTC sÄ±nÄ±rÄ± alt PowerShell sÃ¼recinde saat kaymasÄ± olmadan korunabiliyor mu?"
status: completed
code_revision: "f41a15c environment baseline; implementation revision is the Git commit containing this record"
config_revision: null
dataset_version: null
split_manifest: null
feature_version: null
model: null
seeds: []
primary_metric: "parent/child PowerShell UTC round-trip equality"
primary_result: "roundtrip_equal=True"
confidence_interval: null
secondary_results:
  ambiguous_local_datetime_rejected: true
  syntax_errors: 0
  previous_capture_window_minutes: 182.16
runtime: "P1 readiness UTC tooling validation, 2026-07-23"
hardware: "Local Windows 11 host"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-ARCHIVE-UTC-001/"
known_issues:
  - "A new unique run ID still requires an end-to-end archive window validation"
  - "The prior 182.16-minute tooling archive is not eligible as scientific data and remains preserved"
  - "Parsed log run ID enrichment remains required before experimental collection"
decision: "accept"
```

## P1-LOG-ENRICH-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-LOG-ENRICH-001"
research_question: "MÃ¼hÃ¼rlenmiÅŸ ham loglar deÄŸiÅŸtirilmeden her parsed kayda run ID ve kaynak provenance bilgisi eklenebiliyor mu?"
status: completed
code_revision: "9823020 environment baseline; implementation revision is the Git commit containing this record"
config_revision: "source deployment revision 55585918b90772dc5d33ca6107eace832885741f8064974f0e2fb1ad6d80a544"
dataset_version: null
split_manifest: null
feature_version: "log-envelope-v1"
model: null
seeds: []
primary_metric: "run ID mismatch count across enriched records"
primary_result: "0 mismatch across 58670 records"
confidence_interval: null
secondary_results:
  source_log_file_count: 15
  output_ndjson_file_count: 15
  verified_record_count: 58670
  timestamp_missing_count: 0
  json_failure_count: 0
  sequence_failure_count: 0
  verified_manifest_file_count: 16
  readonly_file_count: 17
  invalid_outputs_preserved: 2
  unmanifested_file_rejected: true
runtime: "P1 readiness log enrichment validation, 2026-07-23"
hardware: "Local Windows 11 host"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-LOG-ENRICH-001/"
known_issues:
  - "Source raw archive spans 182.16 minutes and is tooling-only, not scientific data"
  - "A new unique run ID with corrected UTC boundary requires end-to-end normal-run validation"
  - "Embedded severity, trace ID and message-template parsing remains versioned future work"
decision: "accept"
```

## P1-NORMAL-E2E-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-NORMAL-E2E-001"
research_question: "Benzersiz run ID ile normal koÅŸul log, metric ve trace hattÄ± uÃ§tan uca doÄŸrulanabiliyor mu?"
status: invalid
code_revision: "da5c88b21a9fe557bcf563be9b4271c912bbd54e"
config_revision: "kustomization sha256:2C29B96EFB19D64CFEE7C2515209FE2CA3EFA47743F97A73D0F215A303D50B70; observability sha256:5922741E09B3BF11AC5773AB5F0F710CA9899F3A3F868838B4BBFA72EAE6BAB3"
dataset_version: null
split_manifest: null
feature_version: "log-envelope-v1"
model: "Normal sistem; model yok; fault injection yok"
seeds: []
primary_metric: "AynÄ± run penceresinde doÄŸrulanmÄ±ÅŸ telemetry modality sayÄ±sÄ± / 3"
primary_result: "Log hattÄ± doÄŸrulandÄ±; metric ve trace host restartÄ± nedeniyle doÄŸrulanamadÄ±; tam run invalid"
confidence_interval: null
secondary_results:
  smoke_http_200: "5/5"
  raw_manifest_verified: "16/16"
  raw_readonly_files: "17/17"
  enriched_records_verified: 4586
  missing_timestamp_count: 0
  json_failure_count: 0
  run_id_mismatch_count: 0
  host_bugcheck: "DPC_WATCHDOG_VIOLATION 0x133"
  whea_count_after_power_cycle_and_cluster_restart: 0
runtime: "E2E-002 valid log window 2026-07-25T12:26:52.664Z sonrasÄ± 2,38 dakika; host crash ve restart sonrasÄ± telemetry kapsam dÄ±ÅŸÄ±"
hardware: "ASUS TUF Gaming F15 FX506LHB; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-NORMAL-E2E-001/"
known_issues:
  - "E2E-001 yapay newline nedeniyle 3 eksik timestamp Ã¼retti ve invalid olarak korundu"
  - "E2E-002 doÄŸrulamasÄ± sÄ±rasÄ±nda host DPC_WATCHDOG_VIOLATION 0x133 ile yeniden baÅŸladÄ±"
  - "Jaeger ve Prometheus kalÄ±cÄ± telemetry volume kullanmÄ±yor"
  - "Restart sonrasÄ± loadgenerator aynÄ± run ID ile yeni telemetry Ã¼retti"
  - "BSOD iÃ§in minidump stack analizi henÃ¼z yapÄ±lmadÄ±"
decision: "repeat"
```

## P1-TELEMETRY-EXPORT-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-TELEMETRY-EXPORT-001"
research_question: "Log, metric ve trace artefact'larÄ± aynÄ± run ID ve UTC penceresiyle cluster dÄ±ÅŸÄ±nda mÃ¼hÃ¼rlenip baÄŸÄ±msÄ±z doÄŸrulanabiliyor mu?"
status: completed
code_revision: "8e39ac9 environment baseline; implementation revision is the Git commit containing this record"
config_revision: "kustomization sha256:E87C27F5A083504D023FE2FD933AC95F911F5BB643224DA50B295D41A02774A8; observability sha256:F4D5C2AE2F86DA3EB14673F2FBB76D085F178A93DCC2821EB520EFB2B3FBD5F7"
dataset_version: null
split_manifest: null
feature_version: "log-envelope-v1; telemetry-schema-v2"
model: null
seeds: []
primary_metric: "verified finalization gates / total finalization gates"
primary_result: "8/8 close-run gates passed; offline final receipt verification passed"
confidence_interval: null
secondary_results:
  raw_log_file_count: 15
  enriched_record_count: 1109
  metric_series_count: 4883
  metric_sample_count: 47546
  raw_unique_trace_count: 167
  boundary_excluded_trace_count: 15
  selected_complete_trace_count: 152
  selected_span_count: 806
  run_id_mismatch_count: 0
  timestamp_failure_count: 0
  manifest_tamper_rejected: true
  overwrite_rejected: true
  wrong_deployed_run_id_rejected: true
  failed_close_receipt_preserved: true
runtime: "Tooling-only validation, 2026-07-25"
hardware: "ASUS TUF Gaming F15 FX506LHB; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TELEMETRY-EXPORT-001/"
known_issues:
  - "Local read-only plus SHA-256 sealing is project-level immutability, not hardware/cloud WORM"
  - "Boundary-crossing traces are preserved raw but excluded from the complete in-window selected trace layer"
  - "Scientific runs remain blocked by the separate host stability gate"
decision: "accept"
```

## P1-HOST-STABILITY-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-HOST-STABILITY-001"
research_question: "Yerel host telemetry tooling yÃ¼kÃ¼ altÄ±nda WHEA hatasÄ± Ã¼retmeden kararlÄ± kalÄ±yor mu?"
status: invalid
code_revision: "8e39ac9 environment baseline"
config_revision: null
dataset_version: null
split_manifest: null
feature_version: null
model: null
seeds: []
primary_metric: "WHEA-Logger Event 17 count during tooling load"
primary_result: "2 corrected PCIe AER errors on root port 00:1D.5; host gate failed"
confidence_interval: null
secondary_results:
  whea_event_id: 17
  whea_count: 2
  pci_root_port: "PCI\\VEN_8086&DEV_06B5&SUBSYS_1E911043&REV_F0"
  wifi_adapter_disabled_during_load: true
  minikube_stopped_cleanly: true
  docker_stopped_cleanly: true
runtime: "2026-07-25 tooling load; WHEA events at 21:10:01 Europe/Istanbul"
hardware: "ASUS TUF Gaming F15 FX506LHB; BIOS FX506LHB.311"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TELEMETRY-EXPORT-001/"
known_issues:
  - "Same PCIe root port was implicated around the prior DPC_WATCHDOG_VIOLATION 0x133"
  - "Disabling the MediaTek MT7921 adapter in Windows did not prevent corrected PCIe errors"
  - "Minidump stack analysis and firmware/driver remediation remain required"
decision: "repeat"
```

## P1-HOST-STABILITY-002 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-HOST-STABILITY-002"
research_question: "Temiz boot altÄ±nda Docker, Minikube, Online Boutique yÃ¼kÃ¼ ve artefact kapatma iÅŸlemleri sÄ±rasÄ±nda host kararlÄ± kalÄ±yor mu?"
status: completed
code_revision: "f650bdd"
config_revision: "kustomization sha256:7bd29d2fde51fe35cdf36d4b31f0f2310ecab67bfdb266791ef4c3a052ad2bc4; observability sha256:9b8f72cb8435e30e7d70ed09050ecb2b053902905d5525de8251cad1c9f26262"
dataset_version: "Uygulanamaz; bilimsel dataset Ã¼retilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "Temiz boot sonrasÄ±nda gÃ¶zlenen WHEA Event 17 sayÄ±sÄ±"
primary_result: "0"
confidence_interval: null
secondary_results:
  kernel_power_41_count: 0
  completed_30_minute_load_windows: 2
  completed_10_minute_e2e_windows: 1
  final_run_id: "ob-host-stability-003"
  final_run_duration_seconds: 616.342
  raw_log_file_count: 15
  enriched_record_count: 14881
  metric_series_count: 4013
  metric_sample_count: 497612
  raw_unique_trace_count: 3187
  verified_unique_trace_count: 3185
  verified_span_count: 33417
  boundary_excluded_trace_count: 2
  close_run_passed: true
runtime: "Temiz boot altÄ±nda iki 30 dakikalÄ±k aktif yÃ¼k gÃ¶zlemi ve bir 10 dakikalÄ±k tam E2E doÄŸrulama"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet baÄŸlÄ±, Wi-Fi devre dÄ±ÅŸÄ±"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-002/"
known_issues:
  - "P1-HOST-STABILITY-001 Ã¶nceki boot dÃ¶nemindeki WHEA ve bugcheck kanÄ±tÄ±yla invalid olarak korunmaktadÄ±r"
  - "ob-host-stability-001 Prometheus run etiketi yenilenmediÄŸi iÃ§in geÃ§ersizdir"
  - "ob-host-stability-002 Jaeger servis baÅŸÄ±na 5000 trace sÄ±nÄ±rÄ±na ulaÅŸtÄ±ÄŸÄ± iÃ§in geÃ§ersizdir"
  - "Uzun sÃ¼reli deneylerden Ã¶nce trace export zaman dilimlerine bÃ¶lÃ¼nmeli ve trace ID ile tekilleÅŸtirilmelidir"
decision: "accept"
```

## P1-CPU-001 / ob-cpu-normal-003 ve ob-cpu-normal-004 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-CPU-001"
run_kind: "normal_baseline"
status: completed
scientific_candidates: true
run_ids: ["ob-cpu-normal-003", "ob-cpu-normal-004"]
workload_profile: "ob-default-10u-1r-v1"
random_seed: 1
fault_injection: false
tracked_deployment_count: 15
deployment_uid_or_restart_changes: 0
host_health_failures: 0
post_shutdown_host_health: passed
metric_sample_counts: [538304, 513784]
enriched_record_counts: [21798, 21150]
unique_trace_counts: [3338, 3257]
selected_span_counts: [35109, 33970]
telemetry_schema_version: 3
trace_chunk_counts: [21, 21]
run_id_time_chunk_failure_count: 0
final_receipts: passed
offline_finalized_run_verification: passed
dataset_inclusion: true
fault_injection_started: false
decision: "accept-two-additional-normal-baseline-candidates-and-stop"
```

## P1-CPU-001 / ob-cpu-normal-002 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-CPU-001"
run_id: "ob-cpu-normal-002"
run_kind: "normal_baseline"
status: completed
scientific_candidate: true
code_revision: "7872498366444c927e3eb8ff377b74e42e50d5e3"
workload_profile: "ob-default-10u-1r-v1"
random_seed: 1
warmup_seconds: 300.2446798
normal_baseline_seconds: 300.811541
fault_injection: false
host_health:
  whea_event_17_delta: 0
  kernel_power_41_delta: 0
  bugcheck_delta: 0
post_shutdown_host_health: passed
raw_log_file_count: 15
enriched_record_count: 19599
metric_series_count: 4975
metric_sample_count: 532256
telemetry_schema_version: 3
trace_chunk_count: 21
unique_trace_count: 3004
selected_span_count: 31439
boundary_excluded_trace_count: 4
run_id_time_chunk_failure_count: 0
final_receipt: passed
offline_finalized_run_verification: passed
dataset_inclusion: true
fault_injection_authorized: false
artifact_path: "p0-env/artifacts/P1-CPU-001/ob-cpu-normal-002-report.md"
decision: "accept-normal-baseline-candidate-and-stop"
```

## P1-CPU-001 / ob-cpu-normal-001 invalid run Ã¶zeti

```yaml
experiment_id: "P1-CPU-001"
run_id: "ob-cpu-normal-001"
run_kind: "normal_baseline"
status: invalid
code_revision: "9ecb59fcba6019223599c1b80eb5334331baeb5b"
workload_profile: "ob-default-10u-1r-v1"
random_seed: 1
warmup_seconds: 300.2343755
normal_baseline_seconds: 300.7827668
fault_injection: false
host_health:
  whea_event_17_delta: 0
  kernel_power_41_delta: 0
  bugcheck_delta: 0
raw_log_file_count: 15
enriched_record_count: 20136
log_verification: passed
metric_trace_archive: failed
invalid_reason: "Prometheus response does not contain run-scoped metric samples"
dataset_inclusion: false
fault_injection_authorized: false
artifact_path: "p0-env/artifacts/P1-CPU-001/ob-cpu-normal-001-report.md"
decision: "invalid-preserve-and-diagnose-before-repeat"
```

## P1-HOST-STABILITY-003 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-HOST-STABILITY-003"
research_question: "Temiz boot sonrasÄ±nda Online Boutique aktif yÃ¼kÃ¼ altÄ±nda host yeni WHEA, Kernel-Power 41 veya bugcheck Ã¼retmeden kararlÄ± kalÄ±yor mu?"
status: invalid
code_revision: "b604d390b61c2e85e880e8081dc9ddf1a52dcda2"
config_revision: "deÄŸiÅŸmedi"
dataset_version: "Uygulanamaz; bilimsel dataset Ã¼retilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "30 dakikalÄ±k aktif yÃ¼k penceresinde yeni WHEA-Logger Event 17 sayÄ±sÄ±"
primary_result: "8; pencere 5. dakikada erken durduruldu"
confidence_interval: null
secondary_results:
  boot_utc: "2026-07-29T17:52:44.5000000Z"
  window_start_utc: "2026-07-29T18:02:43.1006252Z"
  first_whea_utc: "2026-07-29T18:06:57.4575789Z"
  last_whea_utc: "2026-07-29T18:06:57.5423638Z"
  whea_event_id: 17
  whea_count: 8
  pci_root_port: "00:1D.5"
  pci_device: "PCI\\VEN_8086&DEV_06B5&SUBSYS_1E911043&REV_F0"
  kernel_power_41_count: 0
  bugcheck_count: 0
  controlled_shutdown: true
  scientific_run_started: false
runtime: "2026-07-29; aktif pencere yaklaÅŸÄ±k 5 dakika"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet baÄŸlÄ±, Wi-Fi PnP Ã¼zerinde yok"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-003/"
known_issues:
  - "PCIe Root Port 00:1D.5 Ã¼zerinde temiz boot sonrasÄ±nda aktif yÃ¼k altÄ±nda WHEA Event 17 tekrarlandÄ±"
  - "Yerel CPU performance counter sorgusu baÅŸarÄ±sÄ±z oldu; host kapÄ±sÄ± kararÄ± olay gÃ¼nlÃ¼ÄŸÃ¼ farkÄ±na dayanÄ±r"
decision: "repeat"
```

## P1-HOST-STABILITY-004 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-HOST-STABILITY-004"
research_question: "BIOS iÅŸlemi sonrasÄ±nda host Online Boutique aktif yÃ¼kÃ¼ ve tam telemetry kapanÄ±ÅŸÄ± altÄ±nda kararlÄ± kalÄ±yor mu?"
status: completed
code_revision: "b604d390b61c2e85e880e8081dc9ddf1a52dcda2"
config_revision: "kustomization sha256:9fb58c8af5abbcc72555e09561da30bc2aab93579278090b90871a37505ac16b; observability sha256:778cce588b05c65c923657e55418da421355a7610eaf3569b6b085bbd9045307"
dataset_version: "Uygulanamaz; bilimsel dataset Ã¼retilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "30 dakikalÄ±k aktif yÃ¼k ve 10 dakikalÄ±k E2E kapanÄ±ÅŸta yeni host olayÄ± sayÄ±sÄ±"
primary_result: "WHEA Event 17: 0; Kernel-Power 41: 0; bugcheck: 0; close_run=passed"
confidence_interval: null
secondary_results:
  bios: "FX506LHB.311"
  active_load_duration_seconds: 1824.808
  active_load_sample_count: 31
  maximum_cpu_percent: 73
  minimum_free_memory_mb: 568.86
  run_id: "ob-host-stability-004"
  e2e_duration_seconds: 609.522
  raw_log_file_count: 15
  enriched_record_count: 20153
  metric_series_count: 4771
  metric_sample_count: 530862
  telemetry_schema_version: 3
  trace_query_chunk_seconds: 300
  trace_chunk_count: 21
  raw_unique_trace_count: 3097
  unique_trace_count: 3087
  selected_span_count: 32697
  boundary_excluded_trace_count: 10
  trace_chunk_coverage_failure_count: 0
  close_run_passed: true
  offline_finalized_run_verification: true
  whea_count: 0
  kernel_power_41_count: 0
  bugcheck_count: 0
runtime: "2026-08-02T09:03:04.968Z/2026-08-02T09:55:06.571Z; aktif yÃ¼k, E2E ve kontrollÃ¼ kapanÄ±ÅŸ dahil"
hardware: "ASUS TUF Gaming F15 FX506LHB; BIOS 311; Ethernet baÄŸlÄ±; MT7921 WLAN ve Bluetooth PnP OK"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-004/"
known_issues:
  - "P1-HOST-STABILITY-003 Ã¶nceki WHEA baÅŸarÄ±sÄ±zlÄ±ÄŸÄ±yla invalid olarak korunmaktadÄ±r"
  - "Bu doÄŸrulama bilimsel dataset deÄŸildir"
decision: "accept"
```

## P1-TRACE-CHUNK-TOOL-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-TRACE-CHUNK-TOOL-001"
research_question: "Jaeger trace sorgularÄ± zaman parÃ§alarÄ±na bÃ¶lÃ¼nerek sessiz kÄ±rpma olmadan doÄŸrulanabilir mi?"
status: completed
code_revision: "68d8106 + trace chunking work package"
config_revision: "deÄŸiÅŸmedi"
dataset_version: "Uygulanamaz; sentetik fixture"
split_manifest: null
feature_version: null
model: "AraÃ§ doÄŸrulamasÄ±; model yok"
seeds: []
primary_metric: "geÃ§en sentetik trace chunking doÄŸrulama kapÄ±sÄ±"
primary_result: "5/5 passed"
confidence_interval: null
secondary_results:
  telemetry_schema_version: 3
  synthetic_service_count: 2
  synthetic_trace_chunk_count: 4
  synthetic_unique_trace_count: 3
  schema_v3_fixture_verification: true
  cross_chunk_trace_id_deduplication: true
  chunk_gap_negative_test: true
  chunk_limit_negative_test: true
  invalid_limit_archive_preservation: true
  schema_v2_backward_compatibility_archives: 2
runtime: "Yerel sentetik araÃ§ testi; canlÄ± cluster deneyi yok"
hardware: "Uygulanamaz"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TRACE-CHUNK-TOOL-001/"
known_issues:
  - "En az 30 dakikalÄ±k gerÃ§ek yÃ¼k altÄ±nda schema v3 close-run doÄŸrulamasÄ± bekleniyor"
  - "VarsayÄ±lan 300 saniyelik parÃ§a yoÄŸun yÃ¼kte yine Jaeger limitine ulaÅŸabilir"
decision: "accept"
```

## P1-TRACE-CHUNK-LIVE-001 tamamlanma Ã¶zeti

```yaml
experiment_id: "P1-TRACE-CHUNK-LIVE-001"
research_question: "Schema v3 zaman parÃ§alÄ± Jaeger export hattÄ± 30 dakikalÄ±k gerÃ§ek yÃ¼kte kÄ±rpÄ±lmadan doÄŸrulanabiliyor mu?"
status: completed
code_revision: "31d0373"
config_revision: "kustomization sha256:807d94bf496c75d53351940fe3297a9e023eddb6204bbb6b96fa16fa148e6514; observability sha256:566737186884dcc0ab51a0a820b60bd2931ec9c24f0ec5eb0d27b5ee04a80a48"
dataset_version: "Uygulanamaz; canlÄ± tooling doÄŸrulamasÄ±"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "doÄŸrulanan trace parÃ§alarÄ± / toplam trace parÃ§alarÄ±"
primary_result: "49/49; close_run=passed"
confidence_interval: null
secondary_results:
  run_id: "ob-trace-chunk-live-001"
  duration_seconds: 1826.833
  host_sample_count: 31
  maximum_cpu_percent: 69
  minimum_free_memory_mb: 497.02
  raw_log_file_count: 15
  enriched_record_count: 61812
  metric_series_count: 4124
  metric_sample_count: 1492623
  jaeger_service_count: 7
  trace_query_chunk_seconds: 300
  trace_chunk_count: 49
  maximum_chunk_trace_count: 924
  trace_limit_per_service: 5000
  trace_response_count: 21647
  raw_unique_trace_count: 9443
  unique_trace_count: 9441
  selected_span_count: 100056
  boundary_excluded_trace_count: 2
  trace_chunk_coverage_failure_count: 0
  whea_count: 0
  kernel_power_41_count: 0
  bugcheck_count: 0
  merged_pull_request: 12
  merged_main_revision: "c29e2b2"
runtime: "2026-07-28T17:53:29.122Z/2026-07-28T18:23:55.955Z"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet baÄŸlÄ±, Wi-Fi devre dÄ±ÅŸÄ±"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TRACE-CHUNK-LIVE-001/"
known_issues:
  - "Minimum free memory 497.02 MB dÃ¼zeyine indi; fault run sÄ±rasÄ±nda izlenmelidir"
decision: "accept"
```

## Her tamamlanan deney iÃ§in zorunlu Ã¶zet

```yaml
experiment_id: ""
research_question: ""
status: completed
code_revision: ""
config_revision: ""
dataset_version: ""
split_manifest: ""
feature_version: ""
model: ""
seeds: []
primary_metric: ""
primary_result: ""
confidence_interval: ""
secondary_results: {}
runtime: ""
hardware: ""
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: ""
known_issues: []
decision: "accept | repeat | reject | supersede"
```

## Pilot karar kapÄ±sÄ±

P1-CPU-001 sonrasÄ±nda aÅŸaÄŸÄ±dakiler doldurulur:

| Soru | Ã–lÃ§Ã¼t | SonuÃ§ | Karar |
|---|---|---|---|
| Fault etkisi tekrarlanabilir mi? | AynÄ± profilde benzer metric/SLO davranÄ±ÅŸÄ± | Ä°ki workload ve Ã¼Ã§ severity altÄ±nda dÃ¼ÅŸÃ¼k CV'li fiziksel artÄ±ÅŸ; fault manifestation `0/15` | Evet, yalnÄ±z fiziksel actuation iÃ§in betimsel olarak |
| Manifestation enjeksiyondan ayrÄ±labiliyor mu? | Pozitif ve deÄŸiÅŸken lead time | GeÃ§erli fault manifestation `0/15`; pozitif lead-time Ã¶rneÄŸi `0` | DeÄŸerlendirilemez; kapÄ± geÃ§medi |
| Pre-failure sinyal var mÄ±? | Basit baseline chance Ã¼stÃ¼nde ve olay-bazlÄ± tutarlÄ± | Pozitif horizon etiketi yok; event-based model karÅŸÄ±laÅŸtÄ±rmasÄ± tanÄ±mlanamaz | DeÄŸerlendirilemez; model Ã§alÄ±ÅŸtÄ±rÄ±lmadÄ± |
| Modaliteler hizalÄ± mÄ±? | Kabul edilebilir missingness ve timestamp uyumu | 22/22 geÃ§erli run (21 P1 CPU + 1 P2 network-delay) archive/run-ID/UTC/schema-v3/receipt replay geÃ§ti; feature-window missingness raporu yok | Archive katmanÄ± geÃ§ti; feature katmanÄ± aÃ§Ä±k |
| Dataset v1'e geÃ§ilmeli mi? | YukarÄ±daki kanÄ±tlarÄ±n bÃ¼tÃ¼nÃ¼ | Manifestation, lead-time ve event-based baseline kapÄ±larÄ± karÅŸÄ±lanmadÄ± | HayÄ±r; akademik revizyon kararÄ± gerekir |

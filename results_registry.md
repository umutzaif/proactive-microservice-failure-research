# Deney Sonuçları Kaydı

Bu belge bütün deneylerin, başarısız olanlar dahil, değişmez özet kaydıdır. Her satır bir çalıştırma ailesini temsil eder; ayrıntılı artefact yolu verilmelidir.

## Durumlar

- `planned`
- `running`
- `completed`
- `invalid`
- `superseded`

## Deney kayıt tablosu

| Experiment ID | Tarih | Durum | Amaç | Dataset/split | Model/koşul | Birincil sonuç | Artefact | Not |
|---|---|---|---|---|---|---|---|---|
| P0-ENV-001 | 2026-07-15 | completed | Online Boutique ve observability smoke test | Pilot v0 | Online Boutique v0.10.6, normal sistem | 15/15 deployment hazır; kullanıcı akışı 5/5 HTTP 200; log/metric/trace toplandı | `p0-env/artifacts/P0-ENV-001/` | `run_id` propagation yok; P1 öncesi giderilecek |
| P1-LOG-ARCHIVE-001 | 2026-07-21 | completed | Ham log arşivleme ve bütünlük doğrulaması | Uygulanamaz; araç doğrulaması | Normal sistem, fault injection yok | 16/16 manifest girdisi doğrulandı; 17/17 dosya salt okunur | `p0-env/artifacts/P1-LOG-ARCHIVE-001/` | İlk bozuk manifest denemesi silinmeden invalid olarak korundu; yerel mühür WORM değildir |
| P1-ARCHIVE-UTC-001 | 2026-07-23 | completed | Ham log arşivinin UTC başlangıç sınırını düzeltmek | Uygulanamaz; araç doğrulaması | Normal sistem, fault injection yok | Alt süreç UTC round-trip eşit; belirsiz yerel tarih reddedildi | `p0-env/artifacts/P1-ARCHIVE-UTC-001/` | Önceki araç arşivinde pencere 182,16 dakika; bilimsel veri olarak kullanılamaz |
| P1-LOG-ENRICH-001 | 2026-07-23 | completed | Ham logları değiştirmeden parsed kayıtlara run ID eklemek | Uygulanamaz; araç doğrulaması | `log-envelope-v1`, fault injection yok | 58.670 kayıt; run ID uyuşmazlığı 0; JSON hatası 0 | `p0-env/artifacts/P1-LOG-ENRICH-001/` | Kaynak pencere bilimsel veri değildir; yeni benzersiz run ile E2E test gerekli |
| P1-NORMAL-E2E-001 | 2026-07-25 | invalid | Benzersiz run ID ile normal koşul E2E telemetry doğrulaması | Uygulanamaz; altyapı E2E doğrulaması | Normal sistem, fault injection yok; `ob-normal-e2e-001` ve `ob-normal-e2e-002` | E2E-002 ham ve enriched log doğrulaması geçti; çok-modlu run host çökmesi nedeniyle geçersiz | `p0-env/artifacts/P1-NORMAL-E2E-001/` | DPC_WATCHDOG_VIOLATION 0x133; restart sonrası Jaeger/Prometheus verisi korunmadı ve aynı run ID ile yeni telemetry oluştu |
| P1-TELEMETRY-EXPORT-001 | 2026-07-25 | completed | Log, metric ve trace verisini aynı run penceresinde immutable dışa aktarmak ve final receipt üretmek | Uygulanamaz; araç doğrulaması | Normal tooling trafiği; fault injection yok; telemetry schema v2 | 47.546 metric sample, 1.109 enriched log, 152 tam trace ve 806 span doğrulandı; `close_run=passed` | `p0-env/artifacts/P1-TELEMETRY-EXPORT-001/` | 15 boundary-crossing trace ham katmanda korundu ve selected katmandan dışlandı; PR #10 ile `main` revision `f650bdd` üzerine merge edildi |
| P1-HOST-STABILITY-001 | 2026-07-25 | invalid | Hostun telemetry yükü altında deney çalıştırmaya uygunluğunu doğrulamak | Uygulanamaz; host kapısı | Docker/Minikube tooling yükü; Wi-Fi disabled | Aynı PCIe Root Port 00:1D.5 üzerinde 2 yeni WHEA Event 17 | `p0-env/artifacts/P1-TELEMETRY-EXPORT-001/` | Host düzeltilmeden P1-CPU-001 başlatılmamalı |
| P1-HOST-STABILITY-002 | 2026-07-28 | completed | Temiz boot altında host stabilite kapısını tekrar doğrulamak | Uygulanamaz; altyapı doğrulaması | İki 30 dakikalık yük gözlemi ve bir 10 dakikalık tam E2E kapanış | WHEA Event 17: 0; Kernel-Power 41: 0; tam close-run başarılı | `p0-env/artifacts/P1-HOST-STABILITY-002/` | Host kapısı kabul edildi; uzun koşularda Jaeger trace limitine ulaşılması ayrı teknik engel olarak kaldı |
| P1-HOST-STABILITY-003 | 2026-07-29 | invalid | Temiz boot sonrasında aktif yük altında host stabilitesini yeniden doğrulamak | Uygulanamaz; host kapısı | Online Boutique loadgenerator; fault injection yok | 5. dakikada PCIe 00:1D.5 üzerinde 8 yeni WHEA Event 17; Kernel-Power 41 ve bugcheck 0 | `p0-env/artifacts/P1-HOST-STABILITY-003/` | Bilimsel baseline başlatılmadı; PCIe sorunu giderilip temiz-boot host doğrulaması geçmeden P1-CPU-001 veri toplamasına geçilmemeli |
| P1-HOST-STABILITY-004 | 2026-08-02 | completed | BIOS işlemi sonrasında host stabilite kapısını yeniden doğrulamak | Uygulanamaz; host kapısı | 30 dakika aktif yük ve `ob-host-stability-004` ile 10 dakika tam E2E kapanış; fault injection yok | WHEA Event 17, Kernel-Power 41 ve bugcheck 0; close-run ve offline receipt geçti | `p0-env/artifacts/P1-HOST-STABILITY-004/` | 530.862 metric sample, 3.087 selected trace ve 32.697 span; bilimsel dataset değildir; P1-CPU-001 başlamadan ana araştırma değerlendirmesi ve kullanıcı onayı beklenmeli |
| P1-CPU-001 / ob-cpu-normal-001 | 2026-08-02 | invalid | İlk normal baseline adayını fault injection olmadan toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | Host ve log kapıları geçti; Prometheus run-scoped metric sample bulunmadığı için close-run reddedildi | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-001-report.md` | 20.136 enriched log korundu; partial telemetry ve üç close-run hata receipt'i `_invalid` altında; dataset'e alınmaz, fault injection başlatılmaz |
| P1-CPU-001 / ob-cpu-normal-002 | 2026-08-02 | completed | İkinci fault'suz normal baseline adayını tüm bilimsel kapılarla toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 532.256 metric sample, 3.004 selected trace, 31.439 span; tüm verifier'lar ve post-shutdown host kapısı geçti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-002-report.md` | İlk geçerli bilimsel normal baseline adayı; finalization UTC hassasiyet hatası `_invalid` receipt olarak korundu; fault injection başlatılmadı |
| P1-CPU-001 / ob-cpu-normal-003 | 2026-08-02 | completed | Üçüncü fault'suz normal baseline adayını bağımsız tekrar olarak toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 538.304 metric sample, 3.338 selected trace, 35.109 span; 15 deployment lifecycle ve tüm verifier kapıları geçti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-003-report.md` | Geçerli bilimsel normal baseline adayı; host olayı 0; fault injection başlatılmadı |
| P1-CPU-001 / ob-cpu-normal-004 | 2026-08-02 | completed | Dördüncü fault'suz normal baseline adayını bağımsız tekrar olarak toplamak | Pilot normal baseline | 5 dk warm-up + 5 dk normal baseline; `ob-default-10u-1r-v1`; seed 1 | 513.784 metric sample, 3.257 selected trace, 33.970 span; 15 deployment lifecycle ve tüm verifier kapıları geçti | `p0-env/artifacts/P1-CPU-001/ob-cpu-normal-004-report.md` | Geçerli bilimsel normal baseline adayı; post-shutdown host olayı 0; fault injection başlatılmadı |
| P1-ACTIVE-RUN-ID-GATE-001 | 2026-08-02 | completed | Deployment sonrasında collector ve Prometheus'un beklenen run ID'yi gerçekten etkinleştirdiğini doğrulamak | Uygulanamaz; tooling doğrulaması | `ob-active-run-gate-tool-001`; fault injection yok | ConfigMap/pod/runtime kapıları geçti; 4.112 run-scoped metric series; yanlış ID negatif testi reddedildi | `p0-env/artifacts/P1-ACTIVE-RUN-ID-GATE-001/report.md` | Bilimsel dataset değildir; yeni baseline öncesinde zorunlu pre-lifecycle kapı olarak kullanılır |
| P1-TARGET-SERVICE-SELECTION-001 | 2026-08-02 | completed | İlk CPU-stress kalibrasyon hedefini iki aday arasında kanıta dayalı seçmek | Uygulanamaz; geçerli normal baseline yeniden analizi | checkoutservice ve recommendationservice; fault injection yok | Recommendation: 11,962 mCPU ortalama ve 1.078 kullanıcı-yolu spanı; checkout: 1,225 mCPU ve 340 span | `p0-env/artifacts/P1-TARGET-SERVICE-SELECTION-001/` | `recommendationservice` D-014 ile seçildi; sonuç fault yanıtı kanıtı veya bilimsel fault run değildir |
| P1-SLO-CANDIDATE-001 | 2026-08-03 | completed | Üç geçerli normal run'dan latency/error SLI dağılımını çıkarmak | Geçerli normal-baseline yeniden analizi | 180 tam 5 sn pencere; frontend server spanları; fault injection yok | Pencere-p95 latency p99 4.279,712 ms; 2.219 istekte hata 0; tekrar analizi byte-identical | `p0-env/artifacts/P1-SLO-CANDIDATE-001/` | O-003 açık: `/` route normalde yaklaşık 4 sn; neden açıklanmadan SLO dondurulmadı ve fault injection başlatılmadı |
| P1-SLO-ROOT-DIAGNOSTIC-001 | 2026-08-03 | completed | `/` normal gecikmesinin trace kritik-yol adayını ve kaynak/log karşılığını belirlemek | Geçerli normal-baseline yeniden analizi | 236 HTTP 200 `/` trace'i; fault injection ve deployment değişikliği yok | Downstream spanlar ms düzeyinde; frontend kaynak kodundaki spansız, koşulsuz GCP metadata DNS lookup güçlü neden hipotezi | `p0-env/artifacts/P1-SLO-CANDIDATE-001/frontend-root-diagnostic-report.md` | Nedensellik henüz kanıtlanmadı; benchmark patch/A-B smoke akademik karşılaştırılabilirliği etkilediği için karar bekleniyor |
| P1-FRONTEND-DNS-AB-001 | 2026-08-03 | invalid | GCP metadata DNS autodetection patch'inin `/` latency etkisini A/B/A ile sınamak | Tooling smoke; bilimsel dataset değil | Upstream A → patched B → upstream A; 5 warm-up + 5 ölçüm isteği; fault yok | Treatment warm p95 227,792 ms; A kontrolleri 101,283 ms median ile 4.030,807 ms median arasında uyuşmadı | `p0-env/artifacts/P1-FRONTEND-DNS-AB-001/report.md` | Cold-start ve DNS-cache/sequence carry-over nedeniyle nedensellik kurulamadı; iki attempt silinmeden korundu, patch reddedilmedi fakat kabul de edilmedi |
| P1-FRONTEND-DNS-AB-002 | 2026-08-03 | completed | DNS patch etkisini bağımsız eşzamanlı podlar ve randomize eşlenmiş turlarla sınamak | Preregistered tooling testi; bilimsel dataset değil | 6 tur × 2 varyant × 10 concurrent `/` isteği; seed 20260803; fault yok | 120/120 HTTP 200; treatment 6/6 hızlı; maksimum median oranı 0,722 ile preregistered ≤0,25 kapısı başarısız | `p0-env/artifacts/P1-FRONTEND-DNS-AB-002/report.md` | Geçerli negatif sonuç; eşik post hoc gevşetilmedi, patch bilimsel deployment'a alınmadı, SLO açık ve fault injection başlamadı |
| P1-SLO-ROUTE-CANDIDATE-001 | 2026-08-03 | completed | Global, `/`-hariç ve `/product/{id}` normal SLI nüfuslarını karşılaştırmak | Geçerli normal-baseline yeniden analizi | 3 run; 180 tam 5 sn pencere; frontend server spanları; fault yok | Ürün ailesi 1.066 istek, 179/180 dolu pencere; window-p95 p99 345,992 ms, maksimum 451,162 ms, hata 0; replay byte-identical | `p0-env/artifacts/P1-SLO-ROUTE-CANDIDATE-001/` | Karar desteği aşamasında O-003 açıktı; daha sonra P1-SLO-FREEZE-001 ve D-015 ile çözüldü. Fault injection bu analizde başlamadı |
| P1-SLO-FREEZE-001 | 2026-08-03 | completed | P1-CPU-001 failure manifestation kuralını fault verisi öncesi dondurmak ve normal veride falsifiye etmek | Sürüm `p1-cpu-001-slo-v1`; bilimsel dataset değil | Product window-p95 >345,992 ms veya global error rate >0; 3 ardışık dolu 5 sn pencere | Üç normal run'da latency aşım sayısı 0/0/1, maksimum streak 0/0/1; error streak 0; yanlış manifestation 0 | `p0-env/artifacts/P1-SLO-FREEZE-001/` | D-015 ile O-003 çözüldü; yalnız normal uyumluluğu kanıtlar, fault duyarlılığı henüz bilinmez ve fault injection bu kayıtla otomatik başlamaz |
| P1-CPU-LOW-PREREG-001 | 2026-08-04 | completed | İlk düşük CPU kalibrasyonunu fault verisi öncesi preregister etmek ve güvenlik araçlarını doğrulamak | Tooling/preregistration; bilimsel dataset değil | recommendationservice; 50m; 120 sn ramp; 300 sn steady; sabit SLO grid; bounded worker; Prometheus etki kapısı | Worker, CPU-effect pozitif/negatif, metadata pozitif/negatif, fixed-grid/empty-window/timestamp ve parser testleri geçti | `p0-env/artifacts/P1-CPU-LOW-PREREG-001/` | Fault uygulanmadı; canlı preflight ve temiz committed revision geçmeden `ob-cpu-low-001` başlayamaz |
| P1-CPU-001 / ob-cpu-low-001 | 2026-08-04 | invalid | İlk düşük CPU-stress kalibrasyon attempt'i | `cpu-recommendation-low-v1`; workload/SLO değişmedi | 5 dk warm-up + 5 dk pre-fault baseline tamamlandı; injector başlangıcında PowerShell Confirm binding hatası | Fault worker başlamadı; fault_injected=false; Minikube durdu; post-cleanup WHEA/KP41/bugcheck toplamları 881/5/1 | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-001-report.md` | Lifecycle eksik; dataset'e alınmaz, silinmez ve run ID yeniden kullanılmaz. Aynı donmuş koşullarda yeni benzersiz run gerekir |
| P1-CPU-001 / ob-cpu-low-002 | 2026-08-04 | invalid | Düşük CPU-stress kalibrasyonunu tam lifecycle ile sınamak | `cpu-recommendation-low-v1`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | CPU +50,591m ve tüm telemetry/host/pod kapıları geçti; interval 59/60 < preregistered 240 olduğu için effect gate başarısız; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-002-report.md` | Dataset'e alınmaz ve retroaktif geçerli yapılmaz. D-018 düzeltmesi yalnız `v2` ve yeni `ob-cpu-low-003` için geçerlidir |
| P1-CPU-001 / ob-cpu-low-003 | 2026-08-04 | invalid | Düzeltilmiş fiziksel-etki coverage kapısıyla düşük CPU-stress kalibrasyonunu toplamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/60, CPU +48,890m, host/pod/telemetry kapıları geçti; manifestation null; final receipt UTC verifier type hatasıyla oluşmadı | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-003-report.md` | Dataset'e alınmaz ve retroaktif finalize edilmez. Kanıt korunur; canonical UTC üretici/verifier düzeltmesi yeni run ID gerektirir |
| P1-CPU-001 / ob-cpu-low-004 | 2026-08-04 | completed | Aynı v2 koşullarını canonical UTC finalization düzeltmesiyle tekrarlamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/60; CPU +48,463m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-004-report.md` | İlk geçerli düşük CPU-stress kalibrasyon adayı. Düşük şiddette SLO manifestation oluşmaması geçerli negatif bulgudur; eşik post hoc değiştirilmez |
| P1-CPU-001 / ob-cpu-low-005 | 2026-08-06 | completed | İlk geçerli düşük CPU sonucunun bağımsız tekrarını toplamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 004 ile koşullar değişmeden ayrı lifecycle ve artifact | Coverage 59/60; CPU +52,050m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-005-report.md` | İkinci geçerli düşük CPU adayı ve ilk bağımsız tekrar; `006` tamamlanmadan üç-run tekrarlanabilirlik özeti yapılmaz |
| P1-CPU-001 / ob-cpu-low-006 | 2026-08-06 | invalid | İlk geçerli düşük CPU sonucunun ikinci bağımsız tekrarını toplamak | `cpu-recommendation-low-v2`; `p1-cpu-001-slo-v1`; seed 1 | 004/005 ile koşullar değişmeden yeni canonical revision ve artifact | Coverage 60/60, CPU +48,899m, host/pod/telemetry geçti; worker 420,000 sn fakat outer exec steady 305,313 sn ve final receipt reddedildi | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-006-report.md` | Dataset'e alınmaz; tolerans post hoc gevşetilmez. Gerçek worker UTC kaynağı için açık karar ve yeni run ID gerekir |
| P1-CPU-001 / ob-cpu-low-007 | 2026-08-06 | invalid | Geçersiz 006 yerine worker-emitted UTC ile yeni düşük CPU tekrarını toplamak | `cpu-recommendation-low-v3`; `p1-cpu-001-slo-v1`; seed 1 | 5 dk warm-up + 5 dk baseline tamamlandı; injector pre-execution hash kapısında durdu | Active run-ID geçti; fault uygulanmadı; LF profil hash'i ile Windows CRLF working-tree hash'i uyuşmadı; host delta 0/0/0 | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-007-report.md` | Dataset'e alınmaz, silinmez ve run ID yeniden kullanılmaz. v3 hash'i retroaktif değiştirilmez; platform-independent hash sözleşmesi yeni profil/run gerektirir |
| P1-CPU-001 / ob-cpu-low-008 | 2026-08-06 | invalid | Platform-independent worker hash sözleşmesiyle düşük CPU tekrarını toplamak | `cpu-recommendation-low-v4`; diğer koşullar değişmedi | Warm-up/baseline ve 420 sn worker tamamlandı; lifecycle resolver öncesi PowerShell collection binding hatası | Hash geçti; 84 heartbeat; worker monotonic 420,000 sn; pod/host stabil; cooldown/archive/receipt tamamlanmadı | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-008-report.md` | Dataset'e alınmaz ve retroaktif finalize edilmez. Generic.List açıkça object[] yapılmadan resolver'a verilemedi; yeni run ID gerekir |
| P1-CPU-001 / ob-cpu-low-009 | 2026-08-06 | completed | Aynı v4 koşullarını açık event-array dönüşümüyle tekrarlamak | `cpu-recommendation-low-v4`; diğer koşullar değişmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +50,534m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-low-009-report.md` | Üçüncü geçerli düşük CPU adayı; D-020 tekrarlanabilirlik setini tamamlar. Null manifestation SLO'yu post hoc değiştirmez |
| P1-CPU-LOW-REPEAT-001 | 2026-08-06 | completed | Üç geçerli düşük-şiddet run'ında fiziksel etki ve manifestation tekrarlanabilirliğini özetlemek | 004, 005, 009; betimsel analiz | CPU artışı ortalama 50,349m; sample SD 1,801m; CV %3,576; aralık 48,463–52,050m | Üçünde physical/telemetry/host/receipt geçti; üçünde manifestation null | `p0-env/artifacts/P1-CPU-LOW-REPEAT-001/report.md` | Düşük profil fiziksel actuation tekrarlanabilir; pre-failure öngörü veya yeni severity kararı değildir |
| P1-CPU-001 / ob-cpu-medium-001 | 2026-08-06 | completed | İlk orta şiddetli CPU kalibrasyonunu toplamak | `cpu-recommendation-medium-v1`; 100m; min +50m; aynı workload/seed/SLO | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +101,910m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-001-report.md` | İlk geçerli medium CPU adayı; tek run tekrarlanabilirlik veya high severity yetkisi oluşturmaz; SLO post hoc değiştirilmez |
| P1-CPU-001 / ob-cpu-medium-002 | 2026-08-06 | invalid | İlk geçerli medium sonucunun bağımsız tekrarını toplamak | `cpu-recommendation-medium-v1`; koşullar 001 ile değişmedi | Worker/host/pod/telemetry geçti; effect analyzer aynı pod/container için eski kısa seriyi seçti | Orijinal effect 0/0 interval ve final receipt yok; tanısal aktif-seri replay 59/59, +100,828m; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-002-report.md` | Dataset'e alınmaz ve retroaktif geçerli yapılmaz; D-026 yalnız sonraki yeni run ID için geçerlidir |
| P1-CPU-001 / ob-cpu-medium-003 | 2026-08-06 | completed | D-026 fail-closed seri seçimiyle ikinci medium tekrarını toplamak | `cpu-recommendation-medium-v1`; koşullar 001/002 ile değişmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +103,042m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-003-report.md` | İkinci geçerli medium aday; invalid 002 sete katılmaz, D-025 üç-valid-run özeti tamamlanmadı |
| P1-CPU-001 / ob-cpu-medium-004 | 2026-08-07 | completed | Invalid 002 yerine üçüncü geçerli medium adayını toplamak | `cpu-recommendation-medium-v1`; 001/003 koşulları ve D-026 değişmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +93,994m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-medium-004-report.md` | Üçüncü geçerli medium aday; D-025 betimsel setini tamamlar, high severity otomatik yetkili değildir |
| P1-CPU-MEDIUM-REPEAT-001 | 2026-08-07 | completed | Üç geçerli medium run'da fiziksel etki ve manifestation tekrarlanabilirliğini özetlemek | 001, 003, 004; betimsel analiz | CPU artışı ortalama 99,649m; sample SD 4,930m; CV %4,947; aralık 93,994–103,042m | Üçünde physical/telemetry/host/receipt geçti; üçünde manifestation null | `p0-env/artifacts/P1-CPU-MEDIUM-REPEAT-001/report.md` | Medium physical actuation düşük varyansla tekrarlandı; pre-failure öngörü, high severity veya yeni workload yetkisi değildir |
| P1-CPU-001 / ob-cpu-high-001 | 2026-08-07 | completed | İlk yüksek şiddetli CPU kalibrasyonunu toplamak | `cpu-recommendation-high-v1`; 150m; min +75m; aynı workload/seed/SLO | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +146,589m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-high-001-report.md` | İlk geçerli high aday; tek latency ihlali üçlü streak değildir; tek run tekrarlanabilirlik veya workload/service/SLO değişikliği yetkisi oluşturmaz |
| P1-CPU-001 / ob-cpu-high-002 | 2026-08-07 | completed | İlk geçerli high sonucunun bağımsız tekrarını toplamak | `cpu-recommendation-high-v1`; koşullar 001 ile değişmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/59; CPU +143,819m; host/pod/telemetry/final receipt/offline verifier geçti; manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-high-002-report.md` | İkinci geçerli high aday ve ilk bağımsız tekrar; 003 tamamlanmadan üç-run özeti yapılmaz |
| P1-CPU-001 / ob-cpu-high-003 | 2026-08-07 | completed | İlk geçerli high sonucunun ikinci bağımsız tekrarını toplamak | `cpu-recommendation-high-v1`; koşullar 001/002 ile değişmedi | 5 dk warm-up + 5 dk baseline + 120 sn ramp + 300 sn steady + 5 dk cooldown | Coverage 59/58; CPU +150,416m; host/pod/telemetry/final receipt/offline verifier geçti; iki-pencere maksimum streak ve manifestation null | `p0-env/artifacts/P1-CPU-001/ob-cpu-high-003-report.md` | Üçüncü geçerli high aday; dört latency ihlali üçlü streak oluşturmadı |
| P1-CPU-HIGH-REPEAT-001 | 2026-08-07 | completed | Üç geçerli high run'da fiziksel etki ve manifestation tekrarlanabilirliğini özetlemek | 001, 002, 003; betimsel analiz | CPU artışı ortalama 146,941m; sample SD 3,313m; CV %2,254; aralık 143,819–150,416m | Üçünde physical/telemetry/host/receipt geçti; üçünde manifestation null | `p0-env/artifacts/P1-CPU-HIGH-REPEAT-001/report.md` | High physical actuation düşük varyansla tekrarlandı; pre-failure öngörü, model veya yeni kapsam yetkisi değildir |
| P1-WORKLOAD-CAPACITY-001 | 2026-08-10 | completed | İkinci workload seviyesini fault outcome'u kullanmadan seçmek | Tooling/karar desteği; dataset değil | 20 -> 10 -> 15 users; replacement ID'ler D-031/032 ile; seed 20260810 | 15/20 request oranı 1,417/1,908 geçti; mean CPU 35,890/43,015m ile <=25m kapısı geçmedi; selected=null | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/report.md` | Eşikler değiştirilmedi; ikinci-workload normal/fault planı aktive edilmedi; O-010 açıldı |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-20u-001 | 2026-08-10 | invalid | İlk 20-user kapasite adayını ölçmek | Tooling; dataset değil; fault yok | Active ID/log/schema-v3 telemetry/host/SLO geçti | Pod stability false fakat bileşen snapshot'ları yazılmadı; CPU analizi çoklu cAdvisor serisiyle kontamine; seçimde kullanılmaz | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-20u-001-report.md` | Kanıt korunur, ID yeniden kullanılmaz; D-031 yalnız yeni run'lara uygulanır |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-10u-001 | 2026-08-10 | invalid | Aynı gün 10-user request-intensity kontrolü toplamak | Tooling; dataset değil; fault yok | Active ID ve 300 sn warm-up geçti; measurement başlamadı | Canonical profil `normal_baseline_seconds`, ilk runner yalnız `measurement_seconds` bekledi | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-10u-001-report.md` | Kanıt korunur, ID kullanılmaz; D-032 yeni run'da iki canonical alanı fail-closed normalize eder |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-10u-002 | 2026-08-10 | completed | D-030 aynı-gün request-intensity kontrolünü toplamak | Tooling; dataset değil; fault yok | `ob-default-10u-1r-v1`; D-031/032 kapıları | 2,492375 frontend span/s; recommendation mean CPU 26,011m; SLO null; pod/host/telemetry geçti | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-10u-002-report.md` | 15/20-user oranlarının frozen paydasıdır; bilimsel normal baseline değildir |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-15u-001 | 2026-08-10 | completed | 15-user ikinci-workload adayını değerlendirmek | Tooling; dataset değil; fault yok | Request ratio 1,417334x; mean CPU 35,890m | Request kapısı geçti, <=25m CPU kapısı geçmedi; SLO null, pod/host/telemetry geçti | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-15u-001-report.md` | Geçerli negatif karar kanıtı; aday seçilmez, eşik gevşetilmez |
| P1-WORKLOAD-CAPACITY-001 / ob-capacity-20u-002 | 2026-08-10 | completed | D-031 uyumlu 20-user replacement adayını değerlendirmek | Tooling; dataset değil; fault yok | Request ratio 1,907908x; mean CPU 43,015m | Request kapısı geçti, <=25m CPU kapısı geçmedi; SLO null, pod/host/telemetry geçti | `p0-env/artifacts/P1-WORKLOAD-CAPACITY-001/ob-capacity-20u-002-report.md` | Geçerli negatif karar kanıtı; selected_users=null sonucunu tamamlar |
| P1-WORKLOAD-RESOURCE-BUDGET-001 | 2026-08-11 | completed | O-010 için workload/high/limit kaynak bütçesi seçeneklerini hesaplamak | Tooling/karar desteği; dataset değil; yeni run/fault yok | Mühürlü 10/15/20 kapasite özetleri, high-v1 profil ve üç-run high özeti | 15-user toplamsal tahmini kalan 17,169m; 20-user 10,044m; 1,30x enterpolasyon noktası 13,594 user/33,112m | `p0-env/artifacts/P1-WORKLOAD-RESOURCE-BUDGET-001/` | Teknik öneri 15 user + değişmeyen profil/limit + prospektif %5 nominal rezervdir; O-010 açık kullanıcı kararı olmadan çözülmez |
| P1-SECOND-WORKLOAD-PREREG-001 | 2026-08-11 | completed | İkinci workload bilimsel bloğunu sonuçlardan önce dondurmak | Preregistration/tooling; dataset değil | `ob-second-15u-1r-v1`; `<=40m`; 3 normal + 6 fault; seed 20260810 | D-033, workload ve eş-fizikli low/medium/high profilleri ile run kimlik/sırası ön-kaydedildi | `p0-env/artifacts/P1-SECOND-WORKLOAD-PREREG-001/preregistration.md` | Merge öncesi run yok; üç normal tamamlanmadan fault yok; model/LLM/GAT yetkisi yok |
| P1-SECOND-WORKLOAD-RUNTIME-001 | 2026-08-11 | completed | 15-user workload runtime/metadata bağını fail-closed hazırlamak | Tooling; dataset değil; run/fault yok | Parametreli orchestrator, active workload ve metadata verifier fixture'ları | 15u pozitif; 15u fault + 10u metadata negatif; static doğru/yanlış profil testleri geçti | `p0-env/artifacts/P1-SECOND-WORKLOAD-RUNTIME-001/report.md` | Canlı deployment ve normal-baseline orchestrator kapıları henüz gereklidir |
| P1-SECOND-WORKLOAD-NORMAL-RUNNER-001 | 2026-08-11 | completed | 15-user scientific normal lifecycle'ını fail-closed hazırlamak | Tooling; dataset değil; canlı run/fault yok | 300 sn warm-up + 300 sn baseline; log/telemetry/host/receipt kapıları | AST/no-fault, gerekli kapılar, 15u metadata pozitif, yanlış-ID negatif ve gerçek parametreli WhatIf geçti | `p0-env/artifacts/P1-SECOND-WORKLOAD-NORMAL-RUNNER-001/report.md` | Merge ve ayrı workload/run-ID binding sonrası normal-001 başlayabilir; üç normalden önce fault yok |
| P1-CPU-001 / ob-cpu-15u-normal-001 | 2026-08-11 | completed | İkinci workload seviyesinin ilk bilimsel normal kontrolünü toplamak | Pilot normal baseline; dataset adayı | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod/log/schema-v3/metadata/receipt/replay geçti; 533.101 metric, 3.851 trace, 46.830 span; SLO null; mean CPU 39,807m | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-001-report.md` | İlk geçerli 15u normal; 002/003 tamamlanmadan fault yok ve tekrarlanabilirlik iddiası yok |
| P1-CPU-001 / ob-cpu-15u-normal-002 | 2026-08-11 | invalid | İkinci 15-user normal tekrarını aynı koşullarda toplamak | Pilot normal baseline; dataset dışı invalid | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod ve log/schema-v3 replay geçti; frozen latency SLO'su 3 ardışık pencerede aşıldı; manifestation `19:10:07.812Z` | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-002-report.md` | Mean CPU 43,612m dışlama nedeni değildir; kanıt korunur, ID kullanılmaz, valid blok 1/3 kalır |
| P1-CPU-001 / ob-cpu-15u-normal-003 | 2026-08-11 | completed | İkinci geçerli 15-user normal kontrolünü toplamak | Pilot normal baseline; dataset adayı | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod/log/schema-v3/metadata/receipt/replay geçti; 524.692 metric, 3.765 trace, 45.877 span; SLO null; mean CPU 41,816m | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-003-report.md` | İkinci geçerli 15u normal; blok 2/3, replacement tamamlanmadan fault yok |
| P1-CPU-001 / ob-cpu-15u-normal-004 | 2026-08-13 | completed | Invalid `002` yerine üçüncü geçerli 15-user normal kontrolünü toplamak | Pilot normal baseline; dataset adayı | `ob-second-15u-1r-v1`; seed 1; 300 sn warm-up + 300 sn baseline; fault yok | Host `0/0/0`, pod/log/schema-v3/metadata/receipt/replay geçti; 495.764 metric, 3.743 trace, 45.864 span; SLO null; mean CPU 22,585m | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-normal-004-report.md` | Geçerli set 001/003/004 ve blok 3/3; randomize fault sırasının canonical bağ kapısı açıldı |
| P1-CPU-001 / ob-cpu-15u-medium-002 | 2026-08-13 | invalid | Randomize sıranın ilk 15-user medium fault run'ını toplamak | `cpu-recommendation-medium-15u-v1`; fault uygulanmadan invalid/incomplete | 300 sn warm-up + 300 sn baseline; injector contract preflight | Run-ID/workload geçti; injector 15u profil kimliğini allowlist'te tanımadı ve worker başlamadan fail-closed durdu | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-002-report.md` | Kanıt korunur, ID kullanılmaz; D-036 düzeltmesi merge edilince aynı slot `medium-003` ile tekrarlanır |
| P1-CPU-001 / ob-cpu-15u-medium-003 | 2026-08-13 | invalid | D-036 sonrası ilk randomize medium slotunu tamamlamak | `cpu-recommendation-medium-15u-v1`; fault fiziksel olarak uygulandı, kapanış incomplete | Full lifecycle tamamlandı; dış runner timeout'u final metadata/receipt öncesi | Tanısal coverage 59/59 ve CPU +99,972m; SLO null, host 0/0/0, log/schema-v3 replay geçti; final receipt yok | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-003-report.md` | Dataset dışı; retroaktif valid yapılmaz; D-037 ile >=60 dk timeout ve yeni `medium-004` gerekir |
| P1-CPU-001 / ob-cpu-15u-medium-004 | 2026-08-13 | completed | D-037 altında ilk randomize 15-user medium slotunu geçerli tamamlamak | `cpu-recommendation-medium-15u-v1`; dataset adayı | 300/300/120/300/300 sn lifecycle; dış timeout 65 dk | Coverage 59/59, CPU +94,454m; host 0/0/0, pod/log/schema-v3/metadata/receipt/replay geçti; 1.090.922 metric, 8.535 trace, 105.284 span; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-004-report.md` | İlk randomize slot tamamlandı; canonical merge sonrası sıradaki dondurulmuş slot `low-002` |
| P1-CPU-001 / ob-cpu-15u-low-002 | 2026-08-13 | invalid | İkinci randomize 15-user low slotunu toplamak | `cpu-recommendation-low-15u-v1`; fault uygulanmadan invalid/incomplete | Runner ilk active run-ID kapısı | Minikube hazır değildi; warm-up/baseline/fault başlamadı; `run-error.json` korundu | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-002-report.md` | Dataset dışı; ID kullanılmaz; cluster readiness sonrası aynı frozen koşullarla `low-003` replacement gerekir |
| P1-CPU-001 / ob-cpu-15u-low-003 | 2026-08-13 | invalid | Cluster readiness sonrası ikinci randomize low slotunu tamamlamak | `cpu-recommendation-low-15u-v1`; fault uygulanmadan invalid/incomplete | Active run-ID/workload + 300 sn warm-up + 300 sn baseline | Worker exec anında `server` container bulunamadı; host 0/0/0; fiziksel-etki/receipt yok | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-003-report.md` | Dataset dışı; ID kullanılmaz; replacement öncesi pod restart-stability ve exec-yarışı kapısı kararı gerekir |
| P1-TARGET-POD-STABILITY-001 | 2026-08-13 | completed | D-038 target pod/container stabilite kapısını bağımsız fixture'larla doğrulamak | Tooling; dataset değil; fault yok | 120 sn/5 sn policy; stable/restart/missing-container fixture'ları | Pozitif fixture geçti; restart ve eksik-container negatifleri reddedildi; 15u profil regresyonları geçti | `p0-env/artifacts/P1-TARGET-POD-STABILITY-001/report.md` | D-038 canonical merge ve `low-004` binding sonrası canlı run yapılabilir |
| P1-CPU-001 / ob-cpu-15u-low-004 | 2026-08-13 | completed | D-038 altında ikinci randomize low slotunu tamamlamak | `cpu-recommendation-low-15u-v1`; dataset adayı | D-038 120 sn + değişmeyen 300/300/120/300/300 lifecycle | D-038 25 gözlem/restart 0; coverage 59/59, CPU +49,153m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geçti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-004-report.md` | İkinci randomize slot tamamlandı; canonical merge sonrası üçüncü slot `high-001` |
| P1-CPU-001 / ob-cpu-15u-high-001 | 2026-08-14 | completed | Üçüncü randomize 15-user high slotunu toplamak | `cpu-recommendation-high-15u-v1`; dataset adayı | D-038 120 sn + 300/300/120/300/300 lifecycle | D-038 25/restart 0; coverage 59/58, CPU +135,160m, throttling 99,790m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geçti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-high-001-report.md` | Üçüncü slot tamamlandı; canonical merge sonrası dördüncü slot `high-002` |
| P1-CPU-001 / ob-cpu-15u-high-002 | 2026-08-14 | completed | Dördüncü randomize 15-user high slotunu toplamak | `cpu-recommendation-high-15u-v1`; dataset adayı | D-038 120 sn + 300/300/120/300/300 lifecycle | D-038 25/restart 0; coverage 59/59, CPU +145,710m, throttling 137,848m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geçti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-high-002-report.md` | Dördüncü slot tamamlandı; canonical merge sonrası beşinci slot `low-001` |
| P1-CPU-001 / ob-cpu-15u-low-001 | 2026-08-14 | completed | Beşinci randomize 15-user low slotunu toplamak | `cpu-recommendation-low-15u-v1`; dataset adayı | D-038 120 sn + 300/300/120/300/300 lifecycle | D-038 25/sabit restart 1; coverage 59/59, CPU +53,044m, throttling 77,737m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geçti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-low-001-report.md` | Beşinci slot tamamlandı; canonical merge sonrası son slot `medium-001` ayrı sohbette yürütülür |
| P1-CPU-001 / ob-cpu-15u-medium-001 | 2026-08-14 | invalid | Altıncı ve son randomize 15-user medium slotunu toplamak | `cpu-recommendation-medium-15u-v1`; dataset dışı invalid/incomplete | D-038 120 sn + frozen 300/300/120/300/300 lifecycle | D-038 25/sabit restart 3; coverage 60/59, CPU +100,390m; host 0/0/0; pod/log/schema-v3 replay geçti ve SLO null; warm-up 299,9970699 sn olduğu için `warmup_too_short`, final receipt yok | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-001-report.md` | Kanıt korunur, ID kullanılmaz; valid fault bloğu 5/6 kalır ve otomatik sonraki aşama/replacement kararı verilmez |
| P1-PHASE-DURATION-GUARD-001 | 2026-08-14 | completed | Frozen minimum faz sürelerini scheduler erken dönüşüne karşı uygulamak ve replacement'ı ön-kaydetmek | Tooling/preregistration; dataset değil; fault yok | Başlangıç UTC deadline guard; üç 300 sn host-zamanlı faz; koşullar değişmedi | Kısa fixture erken dönmedi; runner üç guard kullanıyor; korunmasız 300 sn sleep yok | `p0-env/artifacts/P1-PHASE-DURATION-GUARD-001/report.md` | `ob-cpu-15u-medium-005` yalnız canonical merge sonrası aynı koşullarla yürütülebilir; blok 5/6 kalır |
| P1-CPU-001 / ob-cpu-15u-medium-005 | 2026-08-14 | completed | D-039 altında son randomize 15-user medium slotunu geçerli tamamlamak | `cpu-recommendation-medium-15u-v1`; dataset adayı | D-038 120 sn + D-039 korumalı 300/300/120/300/300 lifecycle | D-038 25/sabit restart 1; süreler geçti; coverage 59/59, CPU +93,519m, throttling 69,644m; host 0/0/0; pod/log/schema-v3/metadata/receipt/replay geçti; SLO null | `p0-env/artifacts/P1-CPU-001/ob-cpu-15u-medium-005-report.md` | Altıncı geçerli fault slotu; blok 6/6, bilimsel run sayısı 21 |
| P1-SECOND-WORKLOAD-FAULT-BLOCK-001 | 2026-08-14 | completed | İkinci-workload fault bloğunu kanıta dayalı kapatmak | 2 low + 2 medium + 2 high geçerli run; betimsel analiz | Mean CPU artışı low/medium/high 51,098/93,987/140,435m; CV %5,384/%0,704/%5,312 | Altı run fiziksel/host/pod/telemetry/receipt/replay geçti; manifestation 6/6 null | `p0-env/artifacts/P1-SECOND-WORKLOAD-FAULT-BLOCK-001/report.md` | Fault blok 6/6 kapanır; model/LLM/GAT veya sonraki metodoloji aşamasına otomatik geçiş yok |
| P1-TRACE-CHUNK-TOOL-001 | 2026-07-28 | completed | Uzun run pencerelerini kayıpsız trace sorgu parçalarına bölmek | Uygulanamaz; sentetik araç doğrulaması | Schema v3; iki servis ve dört zaman parçası | Pozitif fixture geçti; boşluk ve limit negatif testleri reddedildi | `p0-env/artifacts/P1-TRACE-CHUNK-TOOL-001/` | Bilimsel veri değildir; canlı doğrulama daha sonra P1-TRACE-CHUNK-LIVE-001 ile geçti |
| P1-TRACE-CHUNK-LIVE-001 | 2026-07-28 | completed | Schema v3 trace export hattını 30 dakikalık gerçek yükte doğrulamak | Uygulanamaz; canlı tooling doğrulaması | `ob-trace-chunk-live-001`, fault injection yok | 49/49 parça doğrulandı; maksimum 924/5000; close-run geçti | `p0-env/artifacts/P1-TRACE-CHUNK-LIVE-001/` | 9.441 selected trace ve 100.056 span; PR #12 ile `main` revision `c29e2b2` üzerine merge edildi |
| P1-CPU-001 | 2026-08-14 | completed | CPU stress altında pre-failure sinyal fizibilitesi | Pilot v0; 21 geçerli, 14 invalid attempt | 6 normal + 15 fault geçerli run; iki workload, üç severity | Fiziksel actuation tekrarlandı; geçerli fault manifestation `0/15`, pozitif lead-time `0`; feature missingness henüz hesaplanmadı | `p0-env/artifacts/P1-CPU-001-CLOSURE-001/report.md` | Dataset v1'e geçilmez; yeni deney tasarımı açık akademik karar ve ayrı ön-kayıt gerektirir |
| P2-NETWORK-DELAY-DESIGN-001 | 2026-08-15 | completed | Kademeli network delay için hedef, izolasyon, fiziksel etki ve SLO karar desteği | Tooling/preregistration; dataset değil; scientific fault yok | Altı geçerli normal run, iki workload; 5 sn edge/route replay; privilege/cleanup/gerçek-imaj doğrulaması | recommendationservice -> productcatalogservice 6/6 run, min coverage %98; 3.872 span; ilk-semptom normal false-positive 0/6; SLO false manifestation 0/6; birleşik verifier 18/18 | `p0-env/artifacts/P2-NETWORK-DELAY-DESIGN-001/report.md` | D-041 donduruldu; run ID null ve fault yetkisiz. Canonical merge sonrası ayrı canlı no-toxic overlay/overhead kapısı gerekir |
| P2-NETWORK-DELAY-PROXY-LIVE-001 / ob-network-proxy-live-001 | 2026-08-15 | completed | Canlı no-toxic proxy overhead, pod continuity ve rollback compatibility kapısı | Operasyonel tooling kanıtı; dataset değil; scientific fault yok | 15 user, rate 1, seed 1; 300 sn warmup, 300 sn base, 120 sn stabilizasyon, 300 sn proxy | Base/proxy 60/60 target-edge pencere; median 4,136/4,4775 ms, overhead +0,3415 ms <=5 ms; SLO null; host 0/0/0; temiz rollback; receipt 90/90 | `p0-env/artifacts/P2-NETWORK-DELAY-PROXY-LIVE-001/report.md` | D-042; scientific run ID/fault yetkisi yok. Canonical merge sonrası ayrı ön-kayıt ve kullanıcı onayı gerekir |
| P2-NETWORK-DELAY-PREREG-001 / ob-netdelay-15u-001 | 2026-08-15 | completed | İlk scientific network-delay run koşullarını ve fail-closed lifecycle tooling'ini sonuçtan önce dondurmak | Tooling/preregistration; dataset değil; scientific fault yok | 15 user/rate 1/seed 1; 0-750 ms 12-adımlı ramp; 300/300/120/300/300; etki >=500 ms ve coverage 48/48 | Birleşik prereg verifier 13/13; mutation-negative ramp, effect/coverage/cleanup/metadata ve runner contract testleri geçti | `p0-env/artifacts/P2-NETWORK-DELAY-001/report.md` | D-043; merge fault yetkisi değildir. Ayrı kullanıcı onayı ve fresh runtime kapıları gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-001 | 2026-08-15 | invalid | İlk kademeli network-delay bilimsel gözlemini toplamak | Dataset dışı invalid/incomplete | Fresh kapılar + 300/300/120/300/300 planı | Preflight, warmup, baseline ve 120,094 sn ramp geçti; PowerShell 7 JSON DateTime dönüşümü steady başlangıç UTC guard'ını reddetti; steady/cooldown ve effect/manifestation yok; emergency cleanup, rollback, host 0/0/0, raw/enriched/schema-v3 ve invalid receipt geçti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-001-report.md` | Kanıt korunur, ID kullanılmaz, eşikler değişmez; replacement bu sonuçta belirlenmez |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-001 / ob-netdelay-15u-002 | 2026-08-15 | completed | UTC type-boundary kusurunu düzeltmek ve değişmeyen replacement'ı ön-kaydetmek | Tooling/preregistration; dataset değil; fault yok | D-043 koşulları aynen; typed JSON UTC invariant canonical Z | PowerShell 7 typed-DateTime pozitif ve locale-string negatif fixture; runner/prereg contract verifier'ları | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-002-preregistration.md` | D-044; canonical merge + ayrı kullanıcı onayı + fresh kapılar gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-002 | 2026-08-15 | invalid | Değişmeyen koşullarla ilk tam network-delay gözlemi replacement'ı | Dataset dışı invalid; scientific candidate evidence | D-043/D-044; tam lifecycle | Coverage 60/60, median 5,300/756,702 ms, etki +751,402 ms; first symptom 13:07:44.987Z, latency manifestation 13:08:39.987Z; lifecycle/pod/cleanup/rollback/host 0/0/0 ve schema-v3 geçti; generic final receipt CPU-specific `severity` varsayımıyla başarısız | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-002-report.md` | Zorunlu receipt kapısı nedeniyle invalid; ID kullanılmaz. Bulgular modeling örneği değildir; replacement bu sonuçta belirlenmez |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-002 / ob-netdelay-15u-003 | 2026-08-15 | completed | Receipt dispatch kusurunu düzeltmek ve değişmeyen replacement'ı ön-kaydetmek | Tooling/preregistration; dataset değil; fault yok | D-043 koşulları aynen; fault-class-aware verifier ve canonical-JSON invalid receipt v2 | CPU/network dispatch contract, LF/CRLF canonical-hash fixture ve prereg verifier | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-003-preregistration.md` | D-045; canonical merge + ayrı kullanıcı onayı + fresh kapılar gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-003 | 2026-08-15 | invalid | D-045 sonrası değişmeyen network-delay replacement'ını yürütmek | Dataset dışı invalid/incomplete preflight; fault yok | Fresh host/cluster/run-ID/workload/proxy kapıları | Base deployment, run-ID, workload ve statik overlay geçti; canlı proxy sözleşmesi rollout sonrası pod sayısını tam 1 görmedi ve `live_proxy_pod_count_mismatch` ile durdu; warmup/fault başlamadı, rollback ve host `0/0/0` geçti; invalid-preflight receipt 7/7 | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-003-report.md` | ID kullanılmaz; telemetry yokluğu receipt'te bağlıdır. Bilimsel eşikler değişmez; replacement bu sonuç commit'inde belirlenmez |
| P2-NETWORK-DELAY-REPLACEMENT-PREREG-003 / ob-netdelay-15u-004 | 2026-08-15 | completed | Proxy pod termination yarışını bounded convergence ile çözmek ve değişmeyen replacement'ı ön-kaydetmek | Tooling/preregistration; dataset değil; fault yok | D-043 koşulları aynen; 120/5 sn tek Ready pod ve finally host-after | Pozitif tek-pod; zero/multiple/container/pod-not-ready negatif fixture'ları; runner/prereg contract | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-004-preregistration.md` | D-046; canonical merge + ayrı kullanıcı onayı + fresh kapılar gerekir |
| P2-NETWORK-DELAY-001 / ob-netdelay-15u-004 | 2026-08-15 | invalid | D-046 sonrası değişmeyen replacement'ı yürütmek | Dataset dışı invalid/incomplete preflight; fault yok | 120/5 sn bounded tek Ready proxy pod kapısı | 22 gözlem: pod count ilk 2 gözlemde 2, sonraki 20 gözlemde 1; Ready true 0/22; `live_proxy_single_ready_pod_timeout`; warmup/fault yok; rollback, host 0/0/0 ve invalid receipt 8/8 geçti | `p0-env/artifacts/P2-NETWORK-DELAY-001/ob-netdelay-15u-004-report.md` | ID kullanılmaz; fiziksel etki/manifestation sonucu yok. Timeout değiştirilmez; replacement öncesi ayrı no-fault readiness tanısı gerekir |
| P2-NETWORK-DELAY-READINESS-DIAG-001 / ob-network-proxy-readiness-001 | 2026-08-15 | invalid | O-018 readiness bileşenini fault'suz ayrıştırmak | Invalid/incomplete diagnostic; dataset değil; fault yok | 180 sn / 5 sn ayrıntılı pod/container/events/log planı | İlk condition snapshot'ında opsiyonel `reason` alanı yoktu; StrictMode serialization'ı durdurdu; rollback ve host 0/0/0 geçti | `p0-env/artifacts/P2-NETWORK-DELAY-READINESS-DIAG-001/ob-network-proxy-readiness-001-report.md` | Kök neden belirlenmedi; ID kullanılmaz. Null-safe serializer ve yeni diagnostic ID ayrı commit gerektirir |
| P2-NETWORK-DELAY-READINESS-DIAG-001 / ob-network-proxy-readiness-002 | 2026-08-15 | invalid | Null-safe serializer ile readiness sorununu yeniden üretmek | Invalid/incomplete diagnostic; dataset değil; fault yok | 180 sn / 5 sn; pod/container, deployment, ReplicaSet, events | 33 gözlem; proxy Ready 33/33, server 31/33; kalıcı failure yeniden üretilmedi. Current pod log seçiminde eksik `deletionTimestamp` StrictMode'u durdurdu; rollback/host 0/0/0 geçti | `p0-env/artifacts/P2-NETWORK-DELAY-READINESS-DIAG-001/ob-network-proxy-readiness-002-report.md` | Gözlem değerli fakat log kapanışı eksik; ID kullanılmaz. Kalan null-safe erişim ve yeni diagnostic ID gerekir |
| M0-RULE-001 | - | planned | Kural tabanlı alarm baseline | Pilot sonrası | Threshold baseline | Bekleniyor | - | Validation ile eşik seçilecek |
| M1-XGB-001 | - | planned | Tabular temporal baseline | Dataset v1 | XGBoost | Bekleniyor | - | Kalibrasyon dahil |
| M2-GRU-001 | - | planned | Sequence temporal model | Dataset v1 | GRU | Bekleniyor | - | 15/30/60 s horizon |
| L1-VERIFY-001 | - | planned | LLM false-positive azaltımı | Dataset v1 test | Evidence-grounded verifier | Bekleniyor | - | Kodlu/kodsuz kontroller |
| R1-GRAPH-001 | - | planned | Root-cause ranking | Dataset v1 test | Graph baselines -> GCN/GAT | Bekleniyor | - | Top-1/Top-3/MRR |

## P0-ENV-001 tamamlanma özeti

```yaml
experiment_id: "P0-ENV-001"
research_question: "Online Boutique yerel ortamda sürdürülebilir biçimde çalışıyor ve log/metric/trace toplanabiliyor mu?"
status: completed
code_revision: "online-boutique v0.10.6 / 5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb"
config_revision: "kustomization sha256:DD7A94CC04FECA210AC30A2A53DFB31FF047BE961F010A1EFF57F693F557C914; observability sha256:E7F4BBE531AB4645D536969DA2DCDE20FF7120521C5DEB22455279626526489B"
dataset_version: "Pilot v0 (veri üretilmedi)"
split_manifest: null
feature_version: null
model: "Normal sistem; model yok"
seeds: []
primary_metric: "deployment readiness + normal-flow smoke + telemetry availability"
primary_result: "15/15 deployment Available; 5/5 smoke adımı HTTP 200; log/metric/trace toplandı"
confidence_interval: null
secondary_results:
  prometheus_cadvisor_target: "up"
  namespace_cpu_rate_example: 0.1194279549487128
  jaeger_paymentservice_trace_count: 5
  run_id_present_in_three_modalities: false
runtime: "Kurulum ve doğrulama oturumu, 2026-07-15"
hardware: "8 logical CPU host; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P0-ENV-001/"
known_issues:
  - "run_id logs/metrics/traces içinde yok; P1 öncesi propagation gerekli"
  - "bazı trace service adları unknown_service; OTEL_SERVICE_NAME sabitlenmeli"
  - "immutable ham log arşivi P1 run pipeline'ında kurulmalı"
  - "trace sampling oranı P1 öncesi açıkça sabitlenmeli"
decision: "repeat"
```

## P1-LOG-ARCHIVE-001 tamamlanma özeti

```yaml
experiment_id: "P1-LOG-ARCHIVE-001"
research_question: "Ham Kubernetes logları run bazında, üzerine yazılmadan ve SHA-256 ile doğrulanabilir biçimde arşivlenebiliyor mu?"
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

## P1-ARCHIVE-UTC-001 tamamlanma özeti

```yaml
experiment_id: "P1-ARCHIVE-UTC-001"
research_question: "Ham log arşivinin başlangıç UTC sınırı alt PowerShell sürecinde saat kayması olmadan korunabiliyor mu?"
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

## P1-LOG-ENRICH-001 tamamlanma özeti

```yaml
experiment_id: "P1-LOG-ENRICH-001"
research_question: "Mühürlenmiş ham loglar değiştirilmeden her parsed kayda run ID ve kaynak provenance bilgisi eklenebiliyor mu?"
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

## P1-NORMAL-E2E-001 tamamlanma özeti

```yaml
experiment_id: "P1-NORMAL-E2E-001"
research_question: "Benzersiz run ID ile normal koşul log, metric ve trace hattı uçtan uca doğrulanabiliyor mu?"
status: invalid
code_revision: "da5c88b21a9fe557bcf563be9b4271c912bbd54e"
config_revision: "kustomization sha256:2C29B96EFB19D64CFEE7C2515209FE2CA3EFA47743F97A73D0F215A303D50B70; observability sha256:5922741E09B3BF11AC5773AB5F0F710CA9899F3A3F868838B4BBFA72EAE6BAB3"
dataset_version: null
split_manifest: null
feature_version: "log-envelope-v1"
model: "Normal sistem; model yok; fault injection yok"
seeds: []
primary_metric: "Aynı run penceresinde doğrulanmış telemetry modality sayısı / 3"
primary_result: "Log hattı doğrulandı; metric ve trace host restartı nedeniyle doğrulanamadı; tam run invalid"
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
runtime: "E2E-002 valid log window 2026-07-25T12:26:52.664Z sonrası 2,38 dakika; host crash ve restart sonrası telemetry kapsam dışı"
hardware: "ASUS TUF Gaming F15 FX506LHB; minikube 4 CPU / 6144 MiB / 32 GiB"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-NORMAL-E2E-001/"
known_issues:
  - "E2E-001 yapay newline nedeniyle 3 eksik timestamp üretti ve invalid olarak korundu"
  - "E2E-002 doğrulaması sırasında host DPC_WATCHDOG_VIOLATION 0x133 ile yeniden başladı"
  - "Jaeger ve Prometheus kalıcı telemetry volume kullanmıyor"
  - "Restart sonrası loadgenerator aynı run ID ile yeni telemetry üretti"
  - "BSOD için minidump stack analizi henüz yapılmadı"
decision: "repeat"
```

## P1-TELEMETRY-EXPORT-001 tamamlanma özeti

```yaml
experiment_id: "P1-TELEMETRY-EXPORT-001"
research_question: "Log, metric ve trace artefact'ları aynı run ID ve UTC penceresiyle cluster dışında mühürlenip bağımsız doğrulanabiliyor mu?"
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

## P1-HOST-STABILITY-001 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-001"
research_question: "Yerel host telemetry tooling yükü altında WHEA hatası üretmeden kararlı kalıyor mu?"
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

## P1-HOST-STABILITY-002 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-002"
research_question: "Temiz boot altında Docker, Minikube, Online Boutique yükü ve artefact kapatma işlemleri sırasında host kararlı kalıyor mu?"
status: completed
code_revision: "f650bdd"
config_revision: "kustomization sha256:7bd29d2fde51fe35cdf36d4b31f0f2310ecab67bfdb266791ef4c3a052ad2bc4; observability sha256:9b8f72cb8435e30e7d70ed09050ecb2b053902905d5525de8251cad1c9f26262"
dataset_version: "Uygulanamaz; bilimsel dataset üretilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "Temiz boot sonrasında gözlenen WHEA Event 17 sayısı"
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
runtime: "Temiz boot altında iki 30 dakikalık aktif yük gözlemi ve bir 10 dakikalık tam E2E doğrulama"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet bağlı, Wi-Fi devre dışı"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-002/"
known_issues:
  - "P1-HOST-STABILITY-001 önceki boot dönemindeki WHEA ve bugcheck kanıtıyla invalid olarak korunmaktadır"
  - "ob-host-stability-001 Prometheus run etiketi yenilenmediği için geçersizdir"
  - "ob-host-stability-002 Jaeger servis başına 5000 trace sınırına ulaştığı için geçersizdir"
  - "Uzun süreli deneylerden önce trace export zaman dilimlerine bölünmeli ve trace ID ile tekilleştirilmelidir"
decision: "accept"
```

## P1-CPU-001 / ob-cpu-normal-003 ve ob-cpu-normal-004 tamamlanma özeti

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

## P1-CPU-001 / ob-cpu-normal-002 tamamlanma özeti

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

## P1-CPU-001 / ob-cpu-normal-001 invalid run özeti

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

## P1-HOST-STABILITY-003 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-003"
research_question: "Temiz boot sonrasında Online Boutique aktif yükü altında host yeni WHEA, Kernel-Power 41 veya bugcheck üretmeden kararlı kalıyor mu?"
status: invalid
code_revision: "b604d390b61c2e85e880e8081dc9ddf1a52dcda2"
config_revision: "değişmedi"
dataset_version: "Uygulanamaz; bilimsel dataset üretilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "30 dakikalık aktif yük penceresinde yeni WHEA-Logger Event 17 sayısı"
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
runtime: "2026-07-29; aktif pencere yaklaşık 5 dakika"
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet bağlı, Wi-Fi PnP üzerinde yok"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-003/"
known_issues:
  - "PCIe Root Port 00:1D.5 üzerinde temiz boot sonrasında aktif yük altında WHEA Event 17 tekrarlandı"
  - "Yerel CPU performance counter sorgusu başarısız oldu; host kapısı kararı olay günlüğü farkına dayanır"
decision: "repeat"
```

## P1-HOST-STABILITY-004 tamamlanma özeti

```yaml
experiment_id: "P1-HOST-STABILITY-004"
research_question: "BIOS işlemi sonrasında host Online Boutique aktif yükü ve tam telemetry kapanışı altında kararlı kalıyor mu?"
status: completed
code_revision: "b604d390b61c2e85e880e8081dc9ddf1a52dcda2"
config_revision: "kustomization sha256:9fb58c8af5abbcc72555e09561da30bc2aab93579278090b90871a37505ac16b; observability sha256:778cce588b05c65c923657e55418da421355a7610eaf3569b6b085bbd9045307"
dataset_version: "Uygulanamaz; bilimsel dataset üretilmedi"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "30 dakikalık aktif yük ve 10 dakikalık E2E kapanışta yeni host olayı sayısı"
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
runtime: "2026-08-02T09:03:04.968Z/2026-08-02T09:55:06.571Z; aktif yük, E2E ve kontrollü kapanış dahil"
hardware: "ASUS TUF Gaming F15 FX506LHB; BIOS 311; Ethernet bağlı; MT7921 WLAN ve Bluetooth PnP OK"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-HOST-STABILITY-004/"
known_issues:
  - "P1-HOST-STABILITY-003 önceki WHEA başarısızlığıyla invalid olarak korunmaktadır"
  - "Bu doğrulama bilimsel dataset değildir"
decision: "accept"
```

## P1-TRACE-CHUNK-TOOL-001 tamamlanma özeti

```yaml
experiment_id: "P1-TRACE-CHUNK-TOOL-001"
research_question: "Jaeger trace sorguları zaman parçalarına bölünerek sessiz kırpma olmadan doğrulanabilir mi?"
status: completed
code_revision: "68d8106 + trace chunking work package"
config_revision: "değişmedi"
dataset_version: "Uygulanamaz; sentetik fixture"
split_manifest: null
feature_version: null
model: "Araç doğrulaması; model yok"
seeds: []
primary_metric: "geçen sentetik trace chunking doğrulama kapısı"
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
runtime: "Yerel sentetik araç testi; canlı cluster deneyi yok"
hardware: "Uygulanamaz"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TRACE-CHUNK-TOOL-001/"
known_issues:
  - "En az 30 dakikalık gerçek yük altında schema v3 close-run doğrulaması bekleniyor"
  - "Varsayılan 300 saniyelik parça yoğun yükte yine Jaeger limitine ulaşabilir"
decision: "accept"
```

## P1-TRACE-CHUNK-LIVE-001 tamamlanma özeti

```yaml
experiment_id: "P1-TRACE-CHUNK-LIVE-001"
research_question: "Schema v3 zaman parçalı Jaeger export hattı 30 dakikalık gerçek yükte kırpılmadan doğrulanabiliyor mu?"
status: completed
code_revision: "31d0373"
config_revision: "kustomization sha256:807d94bf496c75d53351940fe3297a9e023eddb6204bbb6b96fa16fa148e6514; observability sha256:566737186884dcc0ab51a0a820b60bd2931ec9c24f0ec5eb0d27b5ee04a80a48"
dataset_version: "Uygulanamaz; canlı tooling doğrulaması"
split_manifest: null
feature_version: null
model: "Normal sistem; fault injection ve model yok"
seeds: []
primary_metric: "doğrulanan trace parçaları / toplam trace parçaları"
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
hardware: "ASUS TUF Gaming F15 FX506LHB; Ethernet bağlı, Wi-Fi devre dışı"
llm_model_version: null
prompt_hash: null
token_usage: null
artifact_path: "p0-env/artifacts/P1-TRACE-CHUNK-LIVE-001/"
known_issues:
  - "Minimum free memory 497.02 MB düzeyine indi; fault run sırasında izlenmelidir"
decision: "accept"
```

## Her tamamlanan deney için zorunlu özet

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

## Pilot karar kapısı

P1-CPU-001 sonrasında aşağıdakiler doldurulur:

| Soru | Ölçüt | Sonuç | Karar |
|---|---|---|---|
| Fault etkisi tekrarlanabilir mi? | Aynı profilde benzer metric/SLO davranışı | İki workload ve üç severity altında düşük CV'li fiziksel artış; fault manifestation `0/15` | Evet, yalnız fiziksel actuation için betimsel olarak |
| Manifestation enjeksiyondan ayrılabiliyor mu? | Pozitif ve değişken lead time | Geçerli fault manifestation `0/15`; pozitif lead-time örneği `0` | Değerlendirilemez; kapı geçmedi |
| Pre-failure sinyal var mı? | Basit baseline chance üstünde ve olay-bazlı tutarlı | Pozitif horizon etiketi yok; event-based model karşılaştırması tanımlanamaz | Değerlendirilemez; model çalıştırılmadı |
| Modaliteler hizalı mı? | Kabul edilebilir missingness ve timestamp uyumu | 21/21 geçerli run archive/run-ID/UTC/schema-v3/receipt replay geçti; feature-window missingness raporu yok | Archive katmanı geçti; feature katmanı açık |
| Dataset v1'e geçilmeli mi? | Yukarıdaki kanıtların bütünü | Manifestation, lead-time ve event-based baseline kapıları karşılanmadı | Hayır; akademik revizyon kararı gerekir |

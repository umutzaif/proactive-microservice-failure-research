# ob-cpu-15u-low-003 Raporu

## Sonuç

`ob-cpu-15u-low-003` `invalid/incomplete` kapandı ve dataset'e alınmaz. Active
run-ID/workload, 300 saniyelik warm-up ve 300 saniyelik normal baseline geçti.
Bounded fault worker başlatılırken Kubernetes hedef podda `server` container'ını
bulamadı; fiziksel fault uygulanmış kabul edilmez.

## Korunan kanıt

- Canonical revision: `e5f96c46f2929fba47442950d9de9f6ae6fc5904`.
- Active run-ID: collector ConfigMap/pod ve Prometheus ConfigMap/runtime geçti;
  4.183 run-scoped seri bulundu.
- Workload: `ob-second-15u-1r-v1`; 15 user, spawn rate 1, seed 1.
- Warm-up başlangıcı: `2026-08-13T16:29:39.5334809Z`.
- Normal baseline başlangıcı: `2026-08-13T16:34:39.5360664Z`.
- Başarısız adım: `bounded_cpu_injection`; hata zamanı
  `2026-08-13T16:39:42.6613118Z`.
- Hata: `container not found ("server")`.
- Fault öncesi readiness gözleminde recommendationservice `1/1` idi fakat yaklaşık
  20 saniye önce dördüncü restart'ını yapmıştı.
- Run öncesi/sonrası host sayaçları WHEA Event 17 / Kernel-Power 41 / bugcheck
  `881/5/1 -> 881/5/1`; fark `0/0/0`.
- `run-error.json` korunur ve run ID yeniden kullanılmaz.

## Bilimsel yorum sınırı

Worker başlamadığı ve fiziksel-etki kanıtı oluşmadığı için bu girişim low CPU etkisi
veya SLO yanıtı hakkında kanıt değildir. Kubernetes `Available` durumu tek başına
yeni restart etmiş hedef container'ın injection anında kararlı olduğunu kanıtlamaz.

## Açık operasyonel karar

Aynı frozen koşullarla yeni benzersiz replacement gerekir. Ancak yeni fault run
öncesinde hedef pod/container için restart-stability süresi ve exec-yarışı politikası
ön-kaydedilmelidir. Bu kapı kararlaştırılıp canonical merge edilmeden replacement
başlatılmaz ve randomize sıradaki sonraki slota geçilmez.

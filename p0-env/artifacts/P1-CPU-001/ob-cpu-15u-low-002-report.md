# ob-cpu-15u-low-002 Raporu

## Sonuç

`ob-cpu-15u-low-002` `invalid/incomplete` kapandı ve dataset'e alınmaz. Runner,
ilk `active_run_id` kapısında Minikube profilinin hazır olmadığını belirledi. Warm-up,
baseline veya fault lifecycle başlamadı; CPU fault uygulanmadı.

## Korunan kanıt

- Başarısız adım: `active_run_id`.
- Hata zamanı: `2026-08-13T15:43:42.2780470Z`.
- Preflight host sayaçları: WHEA Event 17 / Kernel-Power 41 / bugcheck `881/5/1`;
  önceki geçerli run sonrasından fark `0/0/0`.
- `run-error.json` korunur ve run ID yeniden kullanılmaz.

## Bilimsel yorum sınırı

Fault ve ölçüm evreleri başlamadığı için bu girişim low CPU etkisi veya SLO yanıtı
hakkında kanıt değildir. Hatanın korunması, başarısız girişimlerin görünmez biçimde
elenmesini önler; fakat bilimsel dataset'e dahil edilmesini sağlamaz.

## Sonraki kapı

Minikube ayrı olarak başlatılıp node, deployment ve active run-ID readiness kapıları
geçirilir. Aynı workload, seed, fault profili, lifecycle, SLO ve eşiklerle yeni
benzersiz `ob-cpu-15u-low-003` replacement kullanılır. Canonical merge öncesi yeni
fault run başlatılmaz.

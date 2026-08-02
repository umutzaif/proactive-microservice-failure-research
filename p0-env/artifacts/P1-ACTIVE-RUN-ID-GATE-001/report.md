# P1-ACTIVE-RUN-ID-GATE-001 raporu

- Tarih: 2026-08-02
- Durum: `completed`
- Amaç: deployment sonrasında collector ve Prometheus'un beklenen run ID'yi gerçekten etkinleştirdiğini bağımsız doğrulamak.
- Tooling run ID: `ob-active-run-gate-tool-001`
- Bilimsel dataset kullanımı: hayır
- Fault injection: yapılmadı

## Pozitif test

- Collector ConfigMap beklenen run ID: geçti.
- Collector canlı pod rollout annotation: geçti.
- Prometheus ConfigMap beklenen run ID: geçti.
- Prometheus canlı pod rollout annotation: geçti.
- Prometheus runtime API etkin config: geçti.
- Beklenen run ID ile gerçek metric series: `4.112`.
- `active_run_id_verification=passed`.

## Negatif test

Verifier `ob-wrong-run-id` beklentisini `Collector ConfigMap does not contain the expected run ID` gerekçesiyle reddetti; exit code `1`.

## Host ve kapsam

- WHEA Event 17: 0
- Kernel-Power 41: 0
- Bugcheck: 0
- Minikube kontrollü kapatıldı.
- Bu sonuç yalnız tooling kapısı kanıtıdır; önceki `ob-cpu-normal-001` run'ını geçerli yapmaz ve yeni bilimsel baseline değildir.

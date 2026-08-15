# ob-netdelay-15u-003 invalid/incomplete preflight raporu

## Sonuç

Run `invalid/incomplete` sınıflandırılmıştır. Fault ve warmup başlamamıştır; veri
Dataset v1 veya modelleme kapsamına alınamaz. Aynı run ID yeniden kullanılamaz.

## Kanıt

- PR #62 sonrası canonical revision: `8e67fb314e6593561b2ff0b9d63401cb2ba06f90`.
- Host başlangıç sayımları: WHEA17 `881`, Kernel-Power41 `5`, bugcheck `1`.
- Docker `29.6.1`; Minikube temiz stopped durumundan başlatıldı.
- Base deployment, active run-ID `ob-netdelay-15u-003`, collector/Prometheus ve
  `ob-second-15u-1r-v1` (`15/1/seed1`) kapıları geçti.
- Static network-delay proxy overlay doğrulaması geçti.
- Canlı sözleşme, recommendationservice rollout tamamlandıktan hemen sonra pod
  sayısını tam `1` görmedi ve `live_proxy_pod_count_mismatch` ile fail-closed durdu.
- `fault_started=false`; proxy-clean, D-038 target-stability ve lifecycle evrelerine
  ulaşılmadı. Bu nedenle raw/enriched log, metric ve trace arşivleri oluşmadı.
- Rollback doğrulandı: yalnız `server` container, doğrudan
  `productcatalogservice:3550`, proxy ConfigMap yok.
- Cluster durdurulduktan sonra bağımsız host-after sayımları `881/5/1`; fark `0/0/0`.

## Yorum sınırı

Bu attempt ağ gecikmesinin fiziksel etkisi veya manifestation hakkında bilgi vermez.
Başarısızlık fault öncesi canlı pod-set kararlılığı yarışıdır. Bilimsel eşikler
değiştirilmemiştir; replacement ancak ayrı tooling kararı, benzersiz ID, merge ve
yeni açık yürütme onayı sonrasında hazırlanabilir.

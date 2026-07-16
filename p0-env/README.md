# P0-ENV-001 tekrar üretim rehberi

Bu dizin yalnızca ortam kurulumu, normal trafik ve gözlemlenebilirlik smoke testini kapsar. Fault injection, model eğitimi, LLM doğrulaması ve GAT içermez.

## Sabit sürümler

Sürümlerin tek kaynağı `config/versions.yaml` dosyasıdır. Online Boutique kaynak ağacı `source/microservices-demo` altında `v0.10.6` / `5b3a712ab85ccb8f6f7cd5b720d36ba9a8d041eb` revizyonundadır.

## Kurulum

Yönetici PowerShell'de bir kez:

```powershell
choco install docker-desktop kubernetes-cli minikube -y --no-progress
```

Docker Desktop başladıktan sonra proje kökünde:

```powershell
powershell -ExecutionPolicy Bypass -File .\p0-env\scripts\deploy.ps1
```

Normal kullanıcı arayüzünü yerel porta almak için:

```powershell
. .\p0-env\scripts\env.ps1
minikube kubectl --profile p0-online-boutique -- -n online-boutique port-forward service/frontend 8080:80
```

Prometheus ve Jaeger için aynı yöntemle sırasıyla `service/prometheus 9090:9090` ve `service/jaeger 16686:16686` port-forward edilir.

## Geri alma

```powershell
powershell -ExecutionPolicy Bypass -File .\p0-env\scripts\cleanup.ps1
```

Bu komut yalnızca `p0-online-boutique` minikube profilini siler; kaynak, rapor ve sürüm manifestlerini korur.

## Bilinen sınır

Online Boutique `v0.10.6` normal telemetry kayıtlarında deney `run_id` alanı yoktur. P1 veri toplamadan önce logs, metrics ve traces için aynı `run_id` propagation tasarlanmalı ve ayrıca doğrulanmalıdır. Bu P0 kurulumu söz konusu akademik kuralı değiştirmez.


# Araştırmacı Operasyon Runbook'u

## Mevcut kapı

Yazılım veri hattı uçtan uca doğrulandı. Fakat hostta WHEA PCIe uyarıları ve
önceden `DPC_WATCHDOG_VIOLATION (0x133)` görüldü. Host kararlılığı çözülmeden
P1 fault run başlatılmamalıdır.

## Oturum başlangıcı

```powershell
Set-Location C:\Users\Asus-PC\Documents\Makale
git status --short --branch
```

Boot sonrası WHEA kontrolü:

```powershell
Get-WinEvent -FilterHashtable @{
  LogName = 'System'
  ProviderName = 'Microsoft-Windows-WHEA-Logger'
  StartTime = (Get-CimInstance Win32_OperatingSystem).LastBootUpTime
} -ErrorAction SilentlyContinue |
  Select-Object TimeCreated, Id, LevelDisplayName, Message
```

Olay varsa bilimsel run başlatmayın.

## Ortam

Docker Desktop hazır olduktan sonra:

```powershell
powershell -ExecutionPolicy Bypass -File .\p0-env\scripts\deploy.ps1
minikube status --profile p0-online-boutique
```

## Yeni run ID

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\p0-env\scripts\set-experiment-run-id.ps1 `
  -CurrentRunId '<mevcut-id>' `
  -NewRunId '<benzersiz-yeni-id>'
```

Config'i uygulayın, collector ve Prometheus'u restart edin, tüm deployment'ları
bekleyin. Aynı run ID'yi tekrar kullanmayın.

## Zamanlar

```powershell
$runId = '<benzersiz-yeni-id>'
$runStartUtc = [datetimeoffset]::UtcNow.ToString(
  'yyyy-MM-ddTHH:mm:ss.fffZ',
  [System.Globalization.CultureInfo]::InvariantCulture
)
```

Zorunlu protokol metadata'sını doldurun. Warm-up, workload ve fault profile
kimlikleri ayrıca versioned olmalıdır.

## Kullanıcı akışı

Ayrı terminal:

```powershell
minikube kubectl --profile p0-online-boutique -- `
  -n online-boutique port-forward service/frontend-external 8080:80
```

Port-forward terminali kapanırsa `Invoke-WebRequest` bağlantı hatası uygulama
arızası anlamına gelmeyebilir.

## Run kapanışı

Cluster'ı kapatmadan:

```powershell
$runEndUtc = [datetimeoffset]::UtcNow.ToString(
  'yyyy-MM-ddTHH:mm:ss.fffZ',
  [System.Globalization.CultureInfo]::InvariantCulture
)

powershell -ExecutionPolicy Bypass `
  -File .\p0-env\scripts\close-run.ps1 `
  -RunId $runId `
  -StartUtc $runStartUtc `
  -EndUtc $runEndUtc `
  -TraceQueryChunkSeconds 300
```

İlk gerçek run öncesinde sentetik şema v3 testi cluster gerektirmeden
çalıştırılmalıdır:

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\p0-env\scripts\test-trace-export-chunking.ps1
```

Yalnızca `close_run=passed` tam operasyonel başarıdır. Hata halinde run'ı
başarılı işaretlemeyin ve `_invalid` çıktıları silmeyin.

Offline kontrol:

```powershell
powershell -ExecutionPolicy Bypass `
  -File .\p0-env\scripts\verify-finalized-run.ps1 `
  -ReceiptPath ".\p0-env\artifacts\finalized\$runId"
```

Başarılı export/finalization sonrasında:

```powershell
minikube stop --profile p0-online-boutique
```

## Deney öncesi checklist

- [ ] Boot sonrası WHEA yok
- [ ] Git ve config revision kaydedildi
- [ ] Benzersiz run ID
- [ ] Tüm deployment'lar hazır
- [ ] Collector/Prometheus yeni config ile çalışıyor
- [ ] UTC saat ve metadata hazır
- [ ] Workload/fault profile versioned
- [ ] Warm-up sınırı kayıtlı
- [ ] Run bitmeden `close-run.ps1` çalışacak
- [ ] Trace chunking sentetik testi geçecek
- [ ] Hiçbir trace parçası Jaeger limitine ulaşmayacak
- [ ] Receipt offline doğrulanacak

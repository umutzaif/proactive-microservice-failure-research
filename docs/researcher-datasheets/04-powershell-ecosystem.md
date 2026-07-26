# Datasheet 04 — PowerShell Ekosistemi

## 1. PowerShell'i hangi zihinsel modelle okumalı?

PowerShell hem shell hem .NET programlama dilidir. Bu projede:

- shell tarafı: `git`, `minikube`, `kubectl`, `docker` process'lerini çağırır,
- .NET tarafı: dosya, JSON, tarih, regex, SHA-256 ve stream işlemlerini yapar.

Python karşılığı kabaca `subprocess + pathlib + json + hashlib`; C# karşılığı
`Process + System.IO + System.Text.Json + SHA256` birleşimidir.

## 2. Sözdizimi eşleştirme tablosu

| PowerShell | Python/C#/Java zihinsel karşılığı |
|---|---|
| `$value` | local variable |
| `@(...)` | materialized array/list |
| `[ordered]@{}` | insertion-ordered dictionary |
| `$_` | lambda'daki current item |
| `\| Where-Object` | `filter(...)` / LINQ `Where` |
| `\| ForEach-Object` | `map(...)` / LINQ `Select` |
| `\| Sort-Object` | `sorted(...)` / `OrderBy` |
| `ConvertFrom-Json` | JSON deserialize |
| `ConvertTo-Json` | JSON serialize |
| `Get-ChildItem` | directory enumeration |
| `Test-Path` | `Path.exists()` / `File.Exists` |
| `Resolve-Path` | canonical existing path |
| `[IO.Path]::GetFullPath` | absolute normalized path |
| `& executable @args` | `subprocess.run(args)` |
| `$LASTEXITCODE` | child process exit code |
| `throw` | exception |
| `try/catch/finally` | aynı kavram |
| backtick `` ` `` | satır devamı |

## 3. Pipeline nesne taşır

Bash çoğunlukla text taşır. PowerShell pipeline'ı .NET object taşır:

```powershell
Get-ChildItem |
    Where-Object { $_.Length -gt 0 } |
    Select-Object Name, Length
```

Python karşılığı:

```python
[
    {"Name": p.name, "Length": p.stat().st_size}
    for p in paths
    if p.stat().st_size > 0
]
```

Harici process çıktısı ise text'tir. Bu nedenle:

```powershell
$json = minikube kubectl ... -o json | ConvertFrom-Json
```

önce text alır, sonra object graph'a deserialize eder.

## 4. StrictMode ve ErrorActionPreference

Her kritik script:

```powershell
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
```

kullanır.

- `StrictMode`: tanımsız variable veya olmayan property kullanımını hata yapar.
- `ErrorActionPreference=Stop`: non-terminating PowerShell hatalarını exception
  gibi ele alır.

Bu, araştırma pipeline'ında “hata oldu ama script devam etti” riskini azaltır.

Harici executable hatası için ayrıca `$LASTEXITCODE` kontrol edilir.

## 5. Neden `@(...)` önemli?

PowerShell pipeline çıktısında:

- sıfır eleman → `$null`,
- bir eleman → scalar,
- çok eleman → array

olabilir. Bu nedenle `.Count` kullanılacaksa:

```powershell
$items = @($pipelineOutput)
```

ile diziye zorlanır. Finalizer geliştirmesinde yakalanan tek-string `.Count`
hatasının nedeni buydu.

## 6. Process çağrısı ve argument splatting

```powershell
$arguments = @('-NoProfile', '-File', $script, '-RunId', $runId)
$output = & powershell @arguments 2>&1
```

- `&`: command invocation operator.
- `@arguments`: array'i process argümanlarına açar.
- `2>&1`: stderr'i stdout akışına birleştirir.
- `$LASTEXITCODE`: child process'in gerçek exit code'u.

Bu yapı `close-run.ps1` içinde her verifier'ı ayrı process'te çalıştırır.
Dolayısıyla child script'in StrictMode/global state'i parent'ı kirletmez.

## 7. Tarih ve hassasiyet

UTC değerleri `[datetimeoffset]` ile parse edilir. `datetimeoffset`, timezone
offset bilgisini koruduğu için `[datetime]` türünden daha güvenlidir.

Format:

```text
yyyy-MM-ddTHH:mm:ss.fffZ
```

Trace timestamp'leri mikrosaniye, metric timestamp'leri Unix saniyesi,
Kubernetes logları nanosaniyeye kadar hassasiyet taşıyabilir. Kod bu formatları
karşılaştırma için ortak UTC eksenine dönüştürür.

## 8. Dosya yazma ve encoding

Markdown/JSON dosyaları:

```powershell
New-Object System.Text.UTF8Encoding($false)
```

ile UTF-8 BOM olmadan yazılır. Bu:

- Git diff tutarlılığı,
- Türkçe karakterlerin doğru saklanması,
- farklı parser'larla uyumluluk

için tercih edilir.

Windows PowerShell `Get-Content` bazen UTF-8 dosyayı yanlış gösterebilir;
gerekirse `[IO.File]::ReadAllText(path, [Text.Encoding]::UTF8)` kullanılmalıdır.

## 9. SHA-256

Dosya hash'i:

```powershell
Get-FileHash -Algorithm SHA256
```

Deployment revision gibi metin birleşimlerinin hash'i ise
`System.Security.Cryptography.SHA256` ile byte dizisi üzerinden hesaplanır.

Hash bütünlüğü kanıtlar; dosyanın kim tarafından üretildiğini veya güvenli bir
WORM ortamında tutulduğunu tek başına kanıtlamaz.

## 10. Read-only mühür

```powershell
$file.IsReadOnly = $true
```

kazara yazmayı önleyen yerel bir korumadır. Yetkili kullanıcı bunu kaldırabilir.
Bu nedenle verifier hem read-only attribute'u hem SHA-256 manifestini kontrol
eder.

## 11. PowerShell'e özgü dikkat noktaları

- Backtick satır sonunda görünmeyen whitespace varsa continuation bozulabilir.
- Tek tırnak interpolation yapmaz; çift tırnak `$variable` genişletir.
- JSONPath içindeki tırnaklar shell/minikube katmanlarında düşebilir; JSON
  deserialize edip object property seçmek daha güvenlidir.
- `$ErrorActionPreference=Stop`, native stderr redirect edilirken
  `NativeCommandError` oluşturabilir; child output toplarken geçici
  `Continue` kullanılıp exit code ayrıca kontrol edilir.
- Relative path, scriptin çağrıldığı klasöre bağlıdır; script içi kaynaklar
  `$PSScriptRoot` üzerinden çözülür.

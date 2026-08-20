# ob-network-resource-compat-005 ön-kaydı

Bu benzersiz replacement yalnız D-054 provenance kapısını ekler. Runner başlangıçta
`run-manifest.json` üretir; verifier expected run ID, artifact klasör adı ve manifest
run ID'sini eşleştirir. Telemetry run ID, workload, 500m/100m resource sözleşmesi ve
no-fault durumu da manifestten doğrulanır.

D-050'nin memory, probe, proxy, image, `ob-second-15u-1r-v1` workload'u ve bütün
prospektif lifecycle/resource/host/rollback/seal eşikleri değişmez. Run ancak bu
commit canonical merge edildikten ve kullanıcı ayrı canlı onay verdikten sonra
başlatılabilir. `001`-`004` invalid kalır; hiçbir ID yeniden kullanılmaz. Toxic/fault,
model, LLM ve GAT yasaktır.

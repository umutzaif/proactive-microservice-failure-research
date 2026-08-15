# ob-netdelay-15u-002 invalid run raporu

Durum: **invalid; zorunlu final receipt kapısı başarısız; kanıt korundu**.

Fresh preflight ve target stability geçti. `300/300/120/300/300` lifecycle tam
uygulandı; ramp 750 ms'ye ulaştı, normal cleanup `toxics=[]`, bütün pod fazları,
rollback ve host `0/0/0` geçti. Schema-v3 telemetry 4.309 seri, 1.097.817 sample,
35/35 trace chunk, 8.416 seçili trace ve 103.366 span ile doğrulandı.

Hedef-edge baseline/steady coverage `60/60`, median `5,300/756,702 ms` ve fark
`+751,402 ms`dir. First symptom `13:07:44.987Z`; dondurulmuş latency SLO
manifestation `13:08:39.987Z`dir. Bunlar scientific candidate kanıtıdır.

Ancak zorunlu close-run finalizer, CPU faultlarına özgü `severity` alanını generic
metadata verifier üzerinden istediği için network-delay metadata verification
aşamasında durdu. Normal final receipt oluşmadığından operasyonel kapı başarısızdır
ve run geçerli/modeling örneği sayılamaz. Ayrı invalid receipt raw/enriched/telemetry,
scientific metadata, effect/manifestation, lifecycle, host, cleanup ve rollback
kanıtlarını SHA-256 ile bağlar ve `valid_for_modeling=false` taşır.

Veri silinmez veya üzerine yazılmaz; `ob-netdelay-15u-002` tekrar kullanılmaz;
eşikler sonuçtan sonra değiştirilmez. Replacement bu sonuç commitinde belirlenmez.

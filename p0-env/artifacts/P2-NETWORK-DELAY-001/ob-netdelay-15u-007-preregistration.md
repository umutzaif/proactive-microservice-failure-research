# ob-netdelay-15u-007 ön-kaydı

`006` fault öncesi statik verifier'ın compositional overlay base dosyasını çözememesiyle
invalid kaldı. `007` yalnız verifier'a kaynak `network-delay-design` kökünü verir;
deployed overlay yine 500m/100m `network-delay-resource-compatibility` ve canlı resource
kapısıdır. Workload, ramp, lifecycle, effect/SLO, schema-v3 ve receipt eşikleri değişmez.

Invalid kanıt silinmez, ID tekrarlanmaz, eşikler sonuçtan sonra değiştirilmez. Bu commit
fault yürütmez; canonical merge ve ayrı canlı onay gerekir. Model/LLM/GAT kapsam dışıdır.

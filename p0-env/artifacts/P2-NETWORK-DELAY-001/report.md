# P2 network-delay ilk run ön-kayıt kapısı

Durum: completed tooling/preregistration; scientific fault başlatılmadı.

`ob-netdelay-15u-001`, D-043 altında 15 user, spawn rate 1, seed 1; yalnız
`recommendationservice -> productcatalogservice`; 12 adımlı `0 -> 750 ms` ramp ve
`300/300/120/300/300` lifecycle'a bağlandı. D-041 fiziksel etki, first-symptom ve
manifestation eşikleri değiştirilmedi. Invalid veri koruma ve run-ID tekrar etmeme
sözleşmeleri ön-kayıtta yer alır.

Bağımsız birleşik verifier 13/13 kontrolü geçti. Mutation-negative test değiştirilmiş
son ramp adımını; diğer negatif fixture'lar residual toxic, seyrek coverage ve
yetersiz ölçülmüş etkiyi reddetti. PowerShell runner contract testi ve parser geçti.

Bu rapor scientific sonuç veya dataset örneği değildir. Canonical merge ayrı fault
yetkisi vermez; kullanıcı açıkça onaylamalı ve run anındaki bütün fresh kapılar toxic
oluşturulmadan önce geçmelidir. Model, LLM ve GAT çalıştırılmadı.

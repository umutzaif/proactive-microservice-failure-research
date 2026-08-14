# P1-SECOND-WORKLOAD-FAULT-BLOCK-001 kapanış değerlendirmesi

## Kapsam

`ob-second-15u-1r-v1` altında D-033 ile randomize edilmiş altı geçerli CPU-stress
slotu: medium-004, low-004, high-001, high-002, low-001 ve medium-005. Invalid
attempt'ler korunur fakat bu betimsel özete dahil edilmez.

## Fiziksel etki tekrarlanabilirliği

| Severity | Geçerli run | Ortalama artış | Sample SD | CV | Aralık |
|---|---:|---:|---:|---:|---:|
| low | 2 | 51,098m | 2,751m | %5,384 | 49,153–53,044m |
| medium | 2 | 93,987m | 0,661m | %0,704 | 93,519–94,454m |
| high | 2 | 140,435m | 7,460m | %5,312 | 135,160–145,710m |

Altı run'ın tamamı fiziksel-etki, host, pod, telemetry, metadata, final receipt ve
offline replay kapılarını geçti. Altısında da frozen SLO manifestation `null` kaldı.

## Kapanış kararı

İkinci-workload normal blok `3/3`, fault blok `6/6` geçerli tamamlandı. Bu sonuç
fiziksel CPU actuation'ın severity ile arttığını ve her severity içinde iki run'da
betimsel olarak tekrarlandığını gösterir. Pozitif manifestation veya pre-failure
olay kanıtı yoktur. Bu nedenle blok kapanışı model eğitimi, LLM doğrulaması, GAT,
dataset v1 dondurma ya da metodoloji değişikliğine otomatik geçiş yetkisi vermez.

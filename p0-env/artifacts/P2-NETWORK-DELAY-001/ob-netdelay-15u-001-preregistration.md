# P2-NETWORK-DELAY-001 / ob-netdelay-15u-001 ön-kaydı

## Araştırma sorusu

`recommendationservice -> productcatalogservice` yönüne kademeli ve ölçülmüş ağ
gecikmesi uygulandığında, dondurulmuş failure-manifestation eşiğinden önce
hedef-edge trace latency semptomu oluşuyor mu?

Bu belge ilk scientific network-delay run'ını tanımlar; sonucu veya geçerliliği
garanti etmez. PR merge'i yalnız kontratı canonical yapar. Fault yürütmesi ayrıca
kullanıcı onayı ve run anındaki bütün host/cluster kapılarının geçmesini gerektirir.

## Değişmez bağlar

- run ID: `ob-netdelay-15u-001`; başarısız olursa tekrar kullanılmaz;
- experiment: `P2-NETWORK-DELAY-001`; fault class `network_delay`;
- workload: `ob-second-15u-1r-v1`; 15 kullanıcı, spawn rate 1, seed 1;
- target: yalnız `recommendationservice -> productcatalogservice`, downstream;
- injector: digest-pinned Toxiproxy 2.12.0 sidecar, privilege/`NET_ADMIN` yok;
- latency toxic: jitter `0`, toxicity `1`, steady `750 ms`;
- ramp: toxic `0 ms` ile oluşturulur; ramp başlangıcına bağlı deadline'larda her
  10 saniyede `63,125,188,250,313,375,438,500,563,625,688,750 ms` uygulanır;
- lifecycle: `300 warmup / 300 baseline / 120 ramp / 300 steady / 300 cooldown`;
- cleanup: steady sonunda `/reset`, ardından doğru proxy state ve `toxics=[]` geri
  okuması; cooldown temiz proxy üzerinden sürer;
- trace: schema-v3, 300 saniyelik chunk, boundary-crossing trace ayrı korunur.

## Run öncesi fail-closed kapılar

Fault yalnız aşağıdakilerin tamamı bağımsız geçtiğinde başlayabilir:

1. temiz Git, canonical profile/revision ve benzersiz boş artifact yolları;
2. host WHEA Event 17, Kernel-Power 41 ve bugcheck başlangıç snapshot'ı;
3. Docker/Minikube, 15 deployment availability ve tam pod snapshot;
4. active run ID'nin deployment/pod, collector ConfigMap/pod ve Prometheus runtime
   katmanlarında `ob-netdelay-15u-001` olması;
5. workload deployment/pod değerlerinin `15/1/seed1` olması;
6. recommendationservice podunda yalnız `server + network-delay-proxy`, doğru
   digest/upstream/listen, capability drop ve `privileged=false` olması;
7. proxy API'nin fault öncesi `enabled=true`, `toxics=[]` döndürmesi;
8. target-stability gözlemi boyunca recommendationservice UID ve restart sayılarının
   sabit kalması; gözlem süresi `120 saniye`, en az `25` snapshot;
9. Prometheus ve collector'ın active run-ID ile veri ürettiğinin yeniden okunması.

Herhangi biri başarısızsa toxic oluşturulmaz. Başlamış lifecycle'ta bir kapı
bozulursa cleanup/rollback ve kanıt kapanışı denenir; veri invalid olarak korunur.

## Sonuçtan önce dondurulmuş bilimsel kapılar

- fiziksel etki: baseline ve steady için ayrı ayrı en az 48 dolu 5 saniyelik
  hedef-edge penceresi ve `steady median - baseline median >=500 ms`;
- first symptom: hedef-edge window-p95 `>116,942 ms`, iki ardışık dolu pencere;
- manifestation: ürün-detail window-p95 `>594,664 ms` veya global user-route error
  rate `>0`, üç ardışık dolu pencere;
- lifecycle: bütün minimum süreler başlangıç UTC deadline'ına göre sağlanır;
- pod: her ölçüm fazı içinde bütün pod UID/restart değerleri sabit kalır;
- host: kapanış farkı WHEA 17 / Kernel-Power 41 / bugcheck için `0/0/0`;
- telemetry: raw/enriched log, metric ve schema-v3 trace verifier'ları ile final
  offline receipt geçer;
- cleanup: residual toxic, sidecar veya proxy ConfigMap kalmaz.

Manifestation oluşmaması, diğer kapılar geçerse geçerli negatif scientific sonuçtur.
Fiziksel etki, coverage, lifecycle, host, pod, telemetry veya cleanup kapısının
başarısızlığı run'ı invalid yapar. Invalid kanıt silinmez; aynı ID tekrarlanmaz ve
eşikler sonuçtan sonra değiştirilmez.

## Kapsam dışı

Bu ön-kayıt model eğitimi, feature dataset üretimi, LLM doğrulaması, graph/GAT,
tekrar sayısı kararı veya sonraki metodoloji aşamasını yetkilendirmez.

# ob-minikube-state-postmortem-001 ön-kaydı

D-075 sonrasında iki farklı host-side Minikube state-root bulundu. D-073 ve D-075
runner'ları repository-local `p0-env/state/minikube` kökünü `env.ps1` üzerinden seçti;
ancak D-075 öncesindeki manuel durum kontrolü farklı `Documents/Makale` kökünü sorguladı.
Bu diagnostic aynı profile adını state-root provenance kanıtı saymaz; `env.ps1` öncesi
dış değer ile sonrası resolved MINIKUBE_HOME absolute path'ini ayrı kaydeder.

Tanı kimliği `ob-minikube-state-postmortem-001`dir. Kapsam yalnız read-only stopped-state
postmortem'dir: exact repository-local profile path, Docker container/volume inspect,
host-side profile config ve lastStart, Docker logları ve Minikube last-start logları.
Docker engine hazır değilse, resolved root beklenen canonical path ile eşleşmezse, exact
profile/container yoksa veya container running ise artifact oluşturmadan fail-closed durur.

Profile delete, container/cluster start, Kubernetes sürüm/kaynak/addon değişikliği,
application manifest, workload, proxy/toxic ve scientific fault yasaktır. Stopped
container başlatılmadan live kubelet/containerd journal toplanamayacağı açık sınırlılıktır.
Çıktı tek kök neden, Dataset v1, D-067 headroom veya incident girdisi değildir.

Canlı postmortem yalnız canonical merge ve ayrı runtime approval sonrasında çalıştırılır.
Başarı bile profile silme, bootstrap retry, application readiness, replacement normal run
veya fault injection yetkisi vermez.

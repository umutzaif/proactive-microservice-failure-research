# P1-SECOND-WORKLOAD-RUNTIME-001 Report

## Amaç

D-033 ile ön-kaydedilen 15-user workload'un fault runtime ve metadata zincirinde
10-user bağlamıyla karışmasını fail-closed önlemek. Bu tooling doğrulamasıdır;
bilimsel run, fault injection veya dataset girdisi üretmez.

## Uygulama

- Fault orchestrator workload profil yolunu parametre olarak alır; profil kimliği
  ve seed'i dosyadan türetir ve fault profilinin workload bağıyla eşleştirir.
- Metadata verifier 10-user ve 15-user fault profil sözleşmelerini ayrı kabul
  listesinde tutar; fault profile ile scientific metadata workload kimliği eşit
  değilse reddeder.
- Active-workload verifier sürümlü profili static kustomization, canlı
  loadgenerator deployment ve canlı Ready pod ortam değişkenleriyle karşılaştırır.
  `USERS`, `RATE`, `WORKLOAD_PROFILE_ID` ve `WORKLOAD_RANDOM_SEED` birlikte geçmelidir.

## Bağımsız doğrulama

- 15-user high metadata pozitif fixture: geçti.
- 15-user fault profile + 10-user metadata negatif fixture: reddedildi.
- Active workload static mevcut-20u pozitif fixture: geçti.
- Active workload static yanlış-15u negatif fixture: reddedildi.
- Low/medium/high 15-user fault-fiziği eşitlik testleri: geçti.
- Workload bağlayıcı 15-user geçişi ve 20-user geri dönüşü: geçti; çalışma ağacı
  kustomization farkı olmadan geri yüklendi.

## Sınır ve sonraki kapı

Bu sonuç çalışan 15-user deployment'ı henüz kanıtlamaz; canlı verifier yalnız yeni
profil merge edilip deployment uygulandıktan sonra çalıştırılabilir. Ayrıca bilimsel
normal-baseline orchestrator'ı 15-user metadata/final receipt akışıyla hazırlanıp
test edilmeden `ob-cpu-15u-normal-001` başlatılamaz. Üç normal tamamlanmadan fault
run başlamaz.

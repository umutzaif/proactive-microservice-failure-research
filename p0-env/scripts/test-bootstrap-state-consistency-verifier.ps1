$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$source=Join-Path $PSScriptRoot '..\artifacts\P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001\ob-k8s-bootstrap-state-consistency-002'
$verifier=Join-Path $PSScriptRoot 'verify-kubernetes-bootstrap-state-consistency-diagnostic.ps1'
$failed=$false;try{& $verifier -ArtifactRoot $source -ExpectedDiagnosticId 'ob-k8s-bootstrap-state-consistency-002'|Out-Null}catch{$failed=$_.Exception.Message-eq'state_capture_failed:state-first-live.json'}
if(-not$failed){throw 'sealed_invalid_state_capture_not_rejected'}
$tmpRoot=Join-Path([IO.Path]::GetTempPath())("state-verifier-"+[guid]::NewGuid().ToString('N'));$tmp=Join-Path $tmpRoot 'ob-k8s-bootstrap-state-consistency-002'
try{
 New-Item -ItemType Directory -Path $tmpRoot|Out-Null;Copy-Item -LiteralPath $source -Destination $tmp -Recurse
 $paths=@('/var/lib/kubelet/kubeadm-flags.env','/var/lib/kubelet/config.yaml','/var/lib/minikube/etcd','/etc/kubernetes/bootstrap-kubelet.conf','/etc/kubernetes/kubelet.conf','/etc/kubernetes/manifests/kube-apiserver.yaml','/etc/kubernetes/manifests/etcd.yaml','/var/tmp/minikube/kubeadm.yaml','/var/tmp/minikube/kubeadm.yaml.new')
 $stdout=($paths|ForEach-Object{"MISSING|$_"})-join"`n";$capture=[ordered]@{exit_code=0;stdout=$stdout+"`n";stderr=''}|ConvertTo-Json
 foreach($n in @('state-first-live.json','state-final-live.json')){[IO.File]::WriteAllText((Join-Path $tmp $n),$capture,[Text.UTF8Encoding]::new($false))}
 $out=& $verifier -ArtifactRoot $tmp -ExpectedDiagnosticId 'ob-k8s-bootstrap-state-consistency-002';if($out-notmatch'kubernetes_bootstrap_state_consistency_verification=passed'){throw 'valid_state_fixture_not_accepted'}
}finally{Remove-Item -LiteralPath $tmpRoot -Recurse -Force -ErrorAction SilentlyContinue}

$source004=Join-Path $PSScriptRoot '..\artifacts\P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001\ob-k8s-bootstrap-state-consistency-003'
$tmpRoot004=Join-Path([IO.Path]::GetTempPath())("state-verifier-004-"+[guid]::NewGuid().ToString('N'));$tmp004=Join-Path $tmpRoot004 'ob-k8s-bootstrap-state-consistency-004'
try{
 New-Item -ItemType Directory -Path $tmpRoot004|Out-Null;Copy-Item -LiteralPath $source004 -Destination $tmp004 -Recurse
 $manifestPath=Join-Path $tmp004 'diagnostic-manifest.json';$manifest=Get-Content -LiteralPath $manifestPath -Raw|ConvertFrom-Json
 $manifestFields=[ordered]@{diagnostic_id='ob-k8s-bootstrap-state-consistency-004';preregistration_decision='D-123';runtime_state_root='C:\fixture\state';repair_backup_root='C:\fixture\state\.minikube\machines\p0-online-boutique\codex-key-backup-fixture';ssh_installed_public_sha256_expected='86bf057eb0bf9488079879a62c297157bd9e0b2a835b9097dc9d61b79d7e02b1';ssh_installed_public_fingerprint_expected='SHA256:E8X6DYnpxGPJpp3lUOnbtLCow0oNNLC9HomdrrWBEOs';ssh_backup_public_sha256_expected='b894781bbd918c99bb6c0232d79bc2ff3a42c2b2c8d4afb92f411fa38125ea30';ssh_backup_public_fingerprint_expected='SHA256:XncUCIjw5vHqQfhCy9PM5nFy+4p6lwqRkZcgMxas5LQ'}
 foreach($entry in $manifestFields.GetEnumerator()){$manifest|Add-Member -NotePropertyName $entry.Key -NotePropertyValue $entry.Value -Force}
 [IO.File]::WriteAllText($manifestPath,($manifest|ConvertTo-Json -Depth 20),[Text.UTF8Encoding]::new($false))
 $preflight=[ordered]@{passed=$true;installed_private_public_match=$true;backup_private_public_match=$true;container_contains_installed_public=$true;container_contains_backup_public=$false;authorized_key_count=1;container_state='exited';key_material_disclosed=$false;installed_public_sha256=$manifest.ssh_installed_public_sha256_expected;installed_public_fingerprint=$manifest.ssh_installed_public_fingerprint_expected;backup_public_sha256=$manifest.ssh_backup_public_sha256_expected;backup_public_fingerprint=$manifest.ssh_backup_public_fingerprint_expected}
 $preflightPath=Join-Path $tmp004 'ssh-key-repair-preflight.json';[IO.File]::WriteAllText($preflightPath,($preflight|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 $out004=& $verifier -ArtifactRoot $tmp004 -ExpectedDiagnosticId 'ob-k8s-bootstrap-state-consistency-004';if($out004-notmatch'kubernetes_bootstrap_state_consistency_verification=passed'){throw 'valid_d123_fixture_not_accepted'}
 $preflight.key_material_disclosed=$true;[IO.File]::WriteAllText($preflightPath,($preflight|ConvertTo-Json),[Text.UTF8Encoding]::new($false))
 $disclosureRejected=$false;try{& $verifier -ArtifactRoot $tmp004 -ExpectedDiagnosticId 'ob-k8s-bootstrap-state-consistency-004'|Out-Null}catch{$disclosureRejected=$_.Exception.Message-eq'ssh_key_repair_preflight_mismatch'}
 if(-not$disclosureRejected){throw 'd123_key_material_disclosure_not_rejected'}
}finally{Remove-Item -LiteralPath $tmpRoot004 -Recurse -Force -ErrorAction SilentlyContinue}
Write-Output 'bootstrap_state_consistency_verifier_tests=passed'

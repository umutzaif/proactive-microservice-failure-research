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
Write-Output 'bootstrap_state_consistency_verifier_tests=passed'

$ErrorActionPreference='Stop';Set-StrictMode -Version Latest
$runner=Join-Path $PSScriptRoot 'run-kubernetes-bootstrap-state-consistency-diagnostic.ps1'
$r=Get-Content -LiteralPath $runner -Raw
foreach($x in @("ConfirmImpact='Low'","DiagnosticId='ob-k8s-bootstrap-state-consistency-004'",'[Parameter(Mandatory)][string]$RuntimeStateRoot','[Parameter(Mandatory)][string]$RepairBackupRoot','explicit_bootstrap_state_consistency_approval_required','closed_diagnostic_id','get-minikube-ssh-key-provenance.ps1','ssh-key-repair-preflight.json','preregistration_decision=''D-123''','Resolve-DockerInspectState','Complete-RedirectedProcess','Assert-BootstrapStateCapture','first-inspect-candidate-capture.json','inspect-shape-error.json',"State `$docker 'first-live'","State `$docker 'final-live'",'bootstrap-kubelet.conf','kubelet.conf','kube-apiserver.yaml','kubeadm.yaml.new','cri-version-capture.json','cri-containers-capture.json','profile_deleted=$false','application_manifest_applied=$false','workload_started=$false','toxic_created=$false','scientific_fault_started=$false','minikube stop')){if(-not$r.Contains($x)){throw "state_consistency_runner_contract_missing:$x"}}
foreach($x in @('minikube delete','apply -k','config\online-boutique','manage-network-delay-proxy','toxic add')){if($r.Contains($x)){throw "state_consistency_forbidden_scope:$x"}}

$h=Get-Content -LiteralPath(Join-Path $PSScriptRoot 'get-minikube-ssh-key-provenance.ps1')-Raw
foreach($x in @('[Parameter(Mandatory)][string]$RuntimeStateRoot','[Parameter(Mandatory)][string]$RepairBackupRoot','repair_backup_outside_machine_root','codex-key-backup-*','FileSystemAccessRule','installed_private_public_match','backup_private_public_match','container_contains_installed_public','container_contains_backup_public','key_material_disclosed = $false','Remove-Item -LiteralPath $temporaryRoot')){if(-not$h.Contains($x)){throw "ssh_key_provenance_contract_missing:$x"}}
foreach($x in @('private_key_material','installed_private_key','backup_private_key')){if($h.Contains($x)){throw "ssh_key_provenance_disclosure_contract_failed:$x"}}

$v=Get-Content -LiteralPath(Join-Path $PSScriptRoot 'verify-kubernetes-bootstrap-state-consistency-diagnostic.ps1')-Raw
foreach($x in @('P2-KUBERNETES-BOOTSTRAP-STATE-CONSISTENCY-DIAG-001','Read-EvidenceJson','ssh-key-repair-preflight.json','ssh_key_repair_preflight_mismatch','start_exit_code_or_observations_missing','state_capture_failed','state_path_missing','cri_container_list_invalid','host_health_gate_failed')){if(-not$v.Contains($x)){throw "state_consistency_verifier_contract_missing:$x"}}

$closedOutput=& pwsh -NoProfile -File $runner -DiagnosticId 'ob-k8s-bootstrap-state-consistency-003' -RuntimeStateRoot 'Z:\must-not-be-resolved' -RepairBackupRoot 'Z:\must-not-be-resolved' -ExecutionApproved 2>&1
if($LASTEXITCODE-eq0-or($closedOutput-join"`n")-notmatch'closed_diagnostic_id'){throw 'closed_diagnostic_id_not_fail_closed_before_path_access'}
Write-Output 'kubernetes_bootstrap_state_consistency_contract_tests=passed'

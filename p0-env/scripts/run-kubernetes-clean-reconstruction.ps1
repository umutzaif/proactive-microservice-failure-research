[CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
param(
    [string]$ReconstructionId = 'ob-k8s-clean-reconstruction-001',
    [string]$Profile = 'p0-online-boutique',
    [Parameter(Mandatory)][string]$RuntimeStateRoot,
    [Parameter(Mandatory)][string]$BackupRoot,
    [Parameter(Mandatory)][string]$ExpectedCodeRevision,
    [switch]$ExecutionApproved,
    [switch]$DestructiveResetApproved
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
. (Join-Path $PSScriptRoot 'env.ps1')
. (Join-Path $PSScriptRoot 'host-event-recordid.ps1')
. (Join-Path $PSScriptRoot 'native-command-capture.ps1')

$repo = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$gate = 'P2-KUBERNETES-CLEAN-RECONSTRUCTION-001'
$artifactRoot = Join-Path $repo "p0-env\artifacts\$gate\$ReconstructionId"
function Utc { [datetimeoffset]::UtcNow.ToString('yyyy-MM-ddTHH:mm:ss.fffffffZ') }
function Write-Json([string]$Path, [object]$Value) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $Path) -Force | Out-Null
    [IO.File]::WriteAllText($Path, ($Value | ConvertTo-Json -Depth 100), [Text.UTF8Encoding]::new($false))
}
function Capture([string]$FilePath, [string[]]$ArgumentList) {
    $saved = $WhatIfPreference; $WhatIfPreference = $false
    try { Invoke-NativeCommandCapture -FilePath $FilePath -ArgumentList $ArgumentList }
    finally { $WhatIfPreference = $saved }
}
function Require-Capture([object]$Value, [string]$Name) {
    if ([int]$Value.exit_code -ne 0 -or [string]::IsNullOrWhiteSpace([string]$Value.stdout)) {
        throw "reconstruction_capture_failed:$Name"
    }
}
function Parse-SizeBytes([string]$Value) {
    if ($Value -notmatch '^([0-9]+(?:\.[0-9]+)?)(B|kB|MB|GB|TB)$') { throw "unsupported_size:$Value" }
    $factor = switch ($Matches[2]) { 'B' { 1 }; 'kB' { 1KB }; 'MB' { 1MB }; 'GB' { 1GB }; 'TB' { 1TB } }
    return [long]([double]$Matches[1] * [long]$factor)
}

if (-not $ExecutionApproved) { throw 'explicit_clean_reconstruction_execution_approval_required' }
if (-not $DestructiveResetApproved) { throw 'explicit_profile_delete_approval_required' }
if ($ReconstructionId -ne 'ob-k8s-clean-reconstruction-001') { throw 'unexpected_reconstruction_id' }
$revision = (& git -C $repo rev-parse HEAD).Trim()
if ($revision -ne $ExpectedCodeRevision) { throw 'expected_code_revision_mismatch' }
if (@(& git -C $repo status --porcelain).Count) { throw 'working_tree_not_clean' }
if (Test-Path -LiteralPath $artifactRoot) { throw 'immutable_reconstruction_output_exists' }

$runtimeState = (Resolve-Path -LiteralPath $RuntimeStateRoot -ErrorAction Stop).Path
if (-not [IO.Path]::IsPathRooted($BackupRoot)) { throw 'backup_root_must_be_absolute' }
$backupFull = [IO.Path]::GetFullPath($BackupRoot).TrimEnd('\')
if (Test-Path -LiteralPath $backupFull) { throw 'immutable_backup_root_exists' }
$backupParent = (Resolve-Path -LiteralPath (Split-Path -Parent $backupFull) -ErrorAction Stop).Path
if ($backupFull -eq $runtimeState.TrimEnd('\') -or $backupFull -eq $repo.TrimEnd('\') -or
    $backupFull.StartsWith($runtimeState.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase) -or
    $backupFull.StartsWith($repo.TrimEnd('\') + '\', [StringComparison]::OrdinalIgnoreCase)) {
    throw 'backup_root_must_be_external'
}
$env:MINIKUBE_HOME = $runtimeState
$docker = (Get-Command docker -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
$minikube = (Get-Command minikube -CommandType Application -ErrorAction Stop | Select-Object -First 1).Source
Require-Capture (Capture $docker @('info','--format','{{.ServerVersion}}')) 'docker_info'
$preInspect = Capture $docker @('inspect', $Profile); Require-Capture $preInspect 'profile_container'
$container = @($preInspect.stdout | ConvertFrom-Json)[0]
if ([bool]$container.State.Running) { throw 'profile_container_not_stopped' }
if ([string]$container.Name -ne "/$Profile" -or
    [string]$container.Config.Labels.'name.minikube.sigs.k8s.io' -ne $Profile) {
    throw 'profile_container_identity_mismatch'
}
$profileMount = @($container.Mounts | Where-Object { $_.Destination -eq '/var' -and $_.Name -eq $Profile })
if ($profileMount.Count -ne 1) { throw 'profile_volume_mount_mismatch' }
$volumeInspect = Capture $docker @('volume','inspect',$Profile); Require-Capture $volumeInspect 'profile_volume'
$volumeItems = @($volumeInspect.stdout | ConvertFrom-Json)
if ($volumeItems.Count -ne 1 -or [string]$volumeItems[0].Name -ne $Profile) {
    throw 'profile_volume_identity_mismatch'
}
$status = Capture $minikube @('status','--profile',$Profile,'--output=json')
if ([string]::IsNullOrWhiteSpace([string]$status.stdout)) { throw 'profile_status_missing' }
$statusObject = $status.stdout | ConvertFrom-Json
foreach ($property in @('Host','Kubelet','APIServer','Kubeconfig')) {
    if ([string]$statusObject.$property -ne 'Stopped') { throw "profile_component_not_stopped:$property" }
}
$profileConfigPath = Join-Path $runtimeState ".minikube\profiles\$Profile\config.json"
if (-not (Test-Path -LiteralPath $profileConfigPath -PathType Leaf)) { throw 'profile_config_missing' }
$profileConfig = Get-Content -LiteralPath $profileConfigPath -Raw | ConvertFrom-Json
if ($profileConfig.Name -ne $Profile -or $profileConfig.Driver -ne 'docker' -or
    [int]$profileConfig.CPUs -ne 4 -or [int]$profileConfig.Memory -ne 6144 -or
    [int]$profileConfig.DiskSize -ne 32768 -or
    $profileConfig.KubernetesConfig.KubernetesVersion -ne 'v1.34.0' -or
    $profileConfig.KubernetesConfig.ContainerRuntime -ne 'containerd') { throw 'profile_contract_mismatch' }
$predecessorManifest = Join-Path $repo 'p0-env\artifacts\P2-KUBERNETES-LIFECYCLE-STATE-DIAG-001\ob-k8s-lifecycle-state-diagnostic-001\sha256-manifest.json'
if (-not (Test-Path -LiteralPath $predecessorManifest -PathType Leaf)) { throw 'd130_predecessor_manifest_missing' }
$predecessorHash = (Get-FileHash -LiteralPath $predecessorManifest -Algorithm SHA256).Hash.ToLowerInvariant()
if ($predecessorHash -ne '85118c5235cfb3f14d4b52fa90bc17f068c3e258be259ff496e286fa911b0db7') {
    throw 'd130_predecessor_manifest_hash_mismatch'
}

$stateFiles = @(Get-ChildItem -LiteralPath $runtimeState -Recurse -Force -File)
$stateBytes = [long](($stateFiles | Measure-Object Length -Sum).Sum)
$df = Capture $docker @('system','df','-v','--format','json'); Require-Capture $df 'docker_system_df'
$dfObject = $df.stdout | ConvertFrom-Json
$volumeRow = @($dfObject.Volumes | Where-Object { $_.Name -eq $Profile })
if ($volumeRow.Count -ne 1) { throw 'profile_volume_usage_missing' }
$volumeBytes = Parse-SizeBytes ([string]$volumeRow[0].Size)
$freeBytes = [IO.DriveInfo]::new([IO.Path]::GetPathRoot($backupParent)).AvailableFreeSpace
$minimumPostBackupFreeBytes = [long](15GB)
$requiredFreeBytes = $stateBytes + $volumeBytes + $minimumPostBackupFreeBytes
if ($freeBytes -lt $requiredFreeBytes) { throw 'insufficient_backup_free_space' }
$boundary = New-HostEventRecordIdBoundary

if (-not $PSCmdlet.ShouldProcess(
    $Profile,
    'create and verify external state/volume backup, delete exact profile, then test clean system-only bootstrap'
)) { return }

New-Item -ItemType Directory -Path $artifactRoot | Out-Null
New-Item -ItemType Directory -Path $backupFull | Out-Null
$failure = $null; $deleteStarted = $false; $cleanStartAttempted = $false; $observations = @()
Write-Json (Join-Path $artifactRoot 'host-before.json') $boundary
Write-Json (Join-Path $artifactRoot 'predelete-container-inspect.json') $container
Write-Json (Join-Path $artifactRoot 'predelete-volume-inspect.json') ($volumeInspect.stdout | ConvertFrom-Json)
Write-Json (Join-Path $artifactRoot 'predelete-profile-status-capture.json') $status
Write-Json (Join-Path $artifactRoot 'reconstruction-manifest.json') ([ordered]@{
    schema_version=1; gate_id=$gate; reconstruction_id=$ReconstructionId
    preregistration_decision='D-131'; code_revision=$revision; profile=$Profile
    predecessor_decision='D-130'; predecessor_manifest_sha256=$predecessorHash
    runtime_state_root=$runtimeState; backup_root=$backupFull
    source_state_bytes=$stateBytes; source_volume_bytes=$volumeBytes
    backup_drive_free_bytes=$freeBytes; minimum_post_backup_free_bytes=$minimumPostBackupFreeBytes
    required_free_bytes=$requiredFreeBytes; application_manifest_applied=$false
    backup_contains_sensitive_runtime_credentials=$true
    backup_must_remain_outside_repository=$true
    workload_started=$false; toxic_created=$false; scientific_fault_started=$false
    scientific_window_started=$false; dataset_inclusion=$false
    headroom_decision_inclusion=$false; successor_authorized=$false
})

try {
    $stateBackup = Join-Path $backupFull 'runtime-state'
    New-Item -ItemType Directory -Path $stateBackup | Out-Null
    Get-ChildItem -LiteralPath $runtimeState -Force | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $stateBackup -Recurse -Force
    }
    $image = [string]$container.Config.Image
    $archiveCapture = Capture $docker @(
        'run','--rm',
        '--mount',"type=volume,src=$Profile,dst=/source,readonly",
        '--mount',"type=bind,src=$backupFull,dst=/backup",
        '--entrypoint','/bin/tar',$image,'-C','/source','-czf','/backup/profile-volume.tgz','.'
    )
    Write-Json (Join-Path $artifactRoot 'volume-backup-capture.json') $archiveCapture
    if ([int]$archiveCapture.exit_code -ne 0) { throw 'profile_volume_backup_failed' }
    $archive = Join-Path $backupFull 'profile-volume.tgz'
    if (-not (Test-Path -LiteralPath $archive -PathType Leaf) -or (Get-Item $archive).Length -le 0) {
        throw 'profile_volume_archive_missing'
    }
    $backupStateFiles = @(Get-ChildItem -LiteralPath $stateBackup -Recurse -Force -File)
    $backupStateBytes = [long](($backupStateFiles | Measure-Object Length -Sum).Sum)
    $stateEntries = @($backupStateFiles | Sort-Object FullName | ForEach-Object {
        [ordered]@{
            path=$_.FullName.Substring($stateBackup.Length + 1).Replace('\','/')
            bytes=$_.Length
            sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        }
    })
    $archiveListCapture = Capture $docker @(
        'run','--rm','--mount',"type=bind,src=$backupFull,dst=/backup,readonly",
        '--entrypoint','/bin/tar',$image,'-tzf','/backup/profile-volume.tgz'
    )
    Write-Json (Join-Path $artifactRoot 'volume-backup-list-capture.json') $archiveListCapture
    if ([int]$archiveListCapture.exit_code -ne 0 -or
        [string]::IsNullOrWhiteSpace([string]$archiveListCapture.stdout)) {
        throw 'profile_volume_archive_unreadable'
    }
    Write-Json (Join-Path $artifactRoot 'backup-manifest.json') ([ordered]@{
        schema_version=1; reconstruction_id=$ReconstructionId; backup_root=$backupFull
        runtime_state_source=$runtimeState; state_snapshot_file_count=$backupStateFiles.Count
        state_snapshot_bytes=$backupStateBytes; state_snapshot_files=$stateEntries
        volume_archive_bytes=(Get-Item $archive).Length
        volume_archive_sha256=(Get-FileHash $archive -Algorithm SHA256).Hash.ToLowerInvariant()
        source_container_id=[string]$container.Id; source_volume_name=$Profile; helper_image=$image
    })
    & pwsh -NoProfile -File (Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction-backup.ps1') `
        -ArtifactRoot $artifactRoot -BackupRoot $backupFull -ExpectedReconstructionId $ReconstructionId
    if ($LASTEXITCODE -ne 0) { throw 'backup_semantic_verification_failed' }
    Write-Json (Join-Path $artifactRoot 'backup-verification.json') ([ordered]@{passed=$true;verified_utc=Utc})

    $deleteStarted = $true
    $deleteCapture = Capture $minikube @('delete','--profile',$Profile)
    Write-Json (Join-Path $artifactRoot 'delete-capture.json') $deleteCapture
    if ([int]$deleteCapture.exit_code -ne 0) { throw 'minikube_delete_failed' }
    $containerAfterDelete = Capture $docker @('inspect',$Profile)
    $volumeAfterDelete = Capture $docker @('volume','inspect',$Profile)
    $containerExists = [int]$containerAfterDelete.exit_code -eq 0
    $volumeExists = [int]$volumeAfterDelete.exit_code -eq 0
    Write-Json (Join-Path $artifactRoot 'delete-verification.json') ([ordered]@{
        passed=(-not $containerExists -and -not $volumeExists)
        container_exists=$containerExists; volume_exists=$volumeExists; verified_utc=Utc
    })
    if ($containerExists -or $volumeExists) { throw 'profile_delete_verification_failed' }

    $cleanStartAttempted = $true
    $stdout = Join-Path $artifactRoot 'minikube-start.stdout.txt'
    $stderr = Join-Path $artifactRoot 'minikube-start.stderr.txt'
    $process = Start-Process -FilePath $minikube -ArgumentList @(
        'start','--profile',$Profile,'--driver=docker','--kubernetes-version=v1.34.0',
        '--cpus=4','--memory=6144mb','--disk-size=32g','--container-runtime=containerd'
    ) -RedirectStandardOutput $stdout -RedirectStandardError $stderr -PassThru -WindowStyle Hidden
    $completed = $process.WaitForExit(420000)
    if (-not $completed) { Stop-Process -Id $process.Id -Force; $process.WaitForExit() }
    $process.Refresh(); $startExit = [int]$process.ExitCode; $process.Dispose()
    Write-Json (Join-Path $artifactRoot 'start-process.json') ([ordered]@{
        completed_within_timeout=$completed; timeout_seconds=420; exit_code=$startExit
    })
    if (-not $completed -or $startExit -ne 0) { throw 'clean_minikube_start_failed' }

    $deadline = [datetimeoffset]::UtcNow.AddSeconds(180)
    do {
        $sample = Capture $minikube @('status','--profile',$Profile,'--output=json')
        $parsed = $null
        if ([int]$sample.exit_code -eq 0 -and -not [string]::IsNullOrWhiteSpace([string]$sample.stdout)) {
            $parsed = $sample.stdout | ConvertFrom-Json
        }
        $observations += ,[ordered]@{
            observed_utc=Utc; exit_code=[int]$sample.exit_code
            host=$(if($parsed){[string]$parsed.Host}else{$null})
            kubelet=$(if($parsed){[string]$parsed.Kubelet}else{$null})
            apiserver=$(if($parsed){[string]$parsed.APIServer}else{$null})
            kubeconfig=$(if($parsed){[string]$parsed.Kubeconfig}else{$null})
        }
        Start-Sleep -Seconds 5
    } while ([datetimeoffset]::UtcNow -lt $deadline)
    Write-Json (Join-Path $artifactRoot 'bootstrap-observations.json') ([ordered]@{
        duration_seconds=180; poll_seconds=5; observations=$observations
    })
    Write-Json (Join-Path $artifactRoot 'nodes-capture.json') (
        Capture $minikube @('kubectl','--profile',$Profile,'--','get','nodes','-o','json')
    )
    Write-Json (Join-Path $artifactRoot 'kube-system-pods-capture.json') (
        Capture $minikube @('kubectl','--profile',$Profile,'--','-n','kube-system','get','pods','-o','json')
    )
    $stable = @($observations | Where-Object {
        $_.exit_code -eq 0 -and $_.host -eq 'Running' -and $_.kubelet -eq 'Running' -and
        $_.apiserver -eq 'Running' -and $_.kubeconfig -eq 'Configured'
    })
    if ($observations.Count -lt 30 -or $stable.Count -ne $observations.Count) {
        throw 'clean_reconstruction_stability_not_supported'
    }
    Write-Json (Join-Path $artifactRoot 'assessment.json') ([ordered]@{
        schema_version=1; reconstruction_id=$ReconstructionId
        classification='fresh_kubernetes_reconstruction_supported'
        sample_count=$observations.Count; stable_sample_count=$stable.Count
        backup_verified=$true; exact_profile_deleted=$true
        causal_conclusion=$false; repair_cause_proven=$false; successor_authorized=$false
        dataset_inclusion=$false; headroom_decision_inclusion=$false
    })
}
catch {
    $failure = $_.Exception.Message
    Write-Json (Join-Path $artifactRoot 'run-error.json') ([ordered]@{
        failed_utc=Utc; error=$failure; delete_started=$deleteStarted
        clean_start_attempted=$cleanStartAttempted; scientific_fault_started=$false
    })
    Write-Json (Join-Path $artifactRoot 'assessment.json') ([ordered]@{
        schema_version=1; reconstruction_id=$ReconstructionId; classification='reconstruction_incomplete'
        failure=$failure; causal_conclusion=$false; repair_cause_proven=$false
        successor_authorized=$false; dataset_inclusion=$false; headroom_decision_inclusion=$false
    })
}
finally {
    if ($cleanStartAttempted) {
        Write-Json (Join-Path $artifactRoot 'stop-capture.json') (
            Capture $minikube @('stop','--profile',$Profile)
        )
    }
    Write-Json (Join-Path $artifactRoot 'final-profile-status-capture.json') (
        Capture $minikube @('status','--profile',$Profile,'--output=json')
    )
    Write-Json (Join-Path $artifactRoot 'final-container-inspect-capture.json') (
        Capture $docker @('inspect',$Profile)
    )
    try {
        Write-Json (Join-Path $artifactRoot 'host-after.json') (
            Measure-HostEventsAfterRecordIdBoundary -Boundary $boundary
        )
    }
    catch {
        Write-Json (Join-Path $artifactRoot 'host-after.json') ([ordered]@{
            passed=$false; error=$_.Exception.Message
            counts=[ordered]@{whea_event_17=-1;kernel_power_41=-1;bugcheck=-1}
        })
        if ($null -eq $failure) { $failure = 'host_after_capture_failed' }
    }
}

& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'verify-kubernetes-clean-reconstruction.ps1') `
    -ArtifactRoot $artifactRoot -ExpectedReconstructionId $ReconstructionId
if ($LASTEXITCODE -ne 0 -and $null -eq $failure) { $failure = 'semantic_verification_failed' }
& pwsh -NoProfile -File (Join-Path $PSScriptRoot 'seal-diagnostic-artifacts.ps1') `
    -ArtifactRoot $artifactRoot -Mode Create
if ($LASTEXITCODE -ne 0 -and $null -eq $failure) { $failure = 'reconstruction_seal_failed' }
if ($null -ne $failure) { throw "clean_reconstruction_failed:$failure" }
Write-Output "kubernetes_clean_reconstruction=completed id=$ReconstructionId"

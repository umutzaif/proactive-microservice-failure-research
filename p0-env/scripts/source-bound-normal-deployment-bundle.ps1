$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Get-SourceBoundBundleContentHash {
    param([Parameter(Mandatory)][string]$Root)

    $resolvedRoot = (Resolve-Path -LiteralPath $Root -ErrorAction Stop).Path
    $entries = @(Get-ChildItem -LiteralPath $resolvedRoot -File -Recurse | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($resolvedRoot.Length + 1).Replace('\','/')
        $hash = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
        "$relative|$($_.Length)|$hash"
    })
    $payload = ($entries -join "`n")
    $bytes = [Text.Encoding]::UTF8.GetBytes($payload)
    $digest = [Security.Cryptography.SHA256]::Create()
    try { ([BitConverter]::ToString($digest.ComputeHash($bytes))).Replace('-','').ToLowerInvariant() }
    finally { $digest.Dispose() }
}

function Invoke-SourceBoundKustomizeRender {
    param(
        [Parameter(Mandatory)][string]$KubectlPath,
        [Parameter(Mandatory)][string]$ConfigRoot,
        [Parameter(Mandatory)][string]$FailureName
    )

    [string[]]$output = @(& $KubectlPath kustomize $ConfigRoot 2>&1 | ForEach-Object { [string]$_ })
    if ($LASTEXITCODE -ne 0) { throw "$FailureName`:$(($output -join ' | '))" }
    $bytes = [Text.Encoding]::UTF8.GetBytes(($output -join "`n"))
    $digest = [Security.Cryptography.SHA256]::Create()
    try {
        [ordered]@{
            line_count = $output.Count
            sha256 = ([BitConverter]::ToString($digest.ComputeHash($bytes))).Replace('-','').ToLowerInvariant()
        }
    }
    finally { $digest.Dispose() }
}

function Assert-PhysicalPinnedOnlineBoutiqueSource {
    param(
        [Parameter(Mandatory)][string]$OnlineBoutiqueSourceRoot,
        [Parameter(Mandatory)][string]$ExpectedSourceRevision
    )

    if (-not [IO.Path]::IsPathRooted($OnlineBoutiqueSourceRoot)) { throw 'absolute_online_boutique_source_root_required' }
    $sourceItem = Get-Item -LiteralPath $OnlineBoutiqueSourceRoot -Force -ErrorAction Stop
    if (-not $sourceItem.PSIsContainer) { throw 'online_boutique_source_missing' }
    $pathItem = $sourceItem
    while ($null -ne $pathItem) {
        if (($pathItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0) { throw 'online_boutique_source_reparse_point_forbidden' }
        $pathItem = $pathItem.Parent
    }
    $source = $sourceItem.FullName
    if (-not (Test-Path -LiteralPath (Join-Path $source 'kustomize\base\kustomization.yaml') -PathType Leaf)) { throw 'source_base_missing' }
    [string[]]$revisionOutput = @(& git -C $source rev-parse HEAD 2>&1 | ForEach-Object { [string]$_ })
    if ($LASTEXITCODE -ne 0) { throw 'online_boutique_source_revision_unreadable' }
    $revision = ($revisionOutput -join '').Trim()
    if ($revision -ne $ExpectedSourceRevision) { throw "online_boutique_source_revision_mismatch:$revision" }
    [string[]]$dirty = @(& git -C $source status --porcelain 2>&1 | ForEach-Object { [string]$_ })
    if ($LASTEXITCODE -ne 0 -or $dirty.Count -ne 0) { throw 'online_boutique_source_not_clean' }
    [ordered]@{root=$source;revision=$revision;clean=$true;reparse_point=$false}
}

function Assert-NetworkDelayNormalDeploymentBundle {
    param(
        [Parameter(Mandatory)][object]$Bundle,
        [Parameter(Mandatory)][string]$KubectlPath
    )

    if (-not (Test-Path -LiteralPath $Bundle.root -PathType Container)) { throw 'deployment_bundle_missing' }
    $actualContentHash = Get-SourceBoundBundleContentHash -Root $Bundle.root
    if ($actualContentHash -ne $Bundle.content_sha256) { throw 'deployment_bundle_content_mismatch' }
    $baseRender = Invoke-SourceBoundKustomizeRender -KubectlPath $KubectlPath -ConfigRoot $Bundle.base_config -FailureName 'deployment_bundle_base_render_failed'
    $overlayRender = Invoke-SourceBoundKustomizeRender -KubectlPath $KubectlPath -ConfigRoot $Bundle.overlay_config -FailureName 'deployment_bundle_overlay_render_failed'
    if ($baseRender.sha256 -ne $Bundle.base_render_sha256 -or $overlayRender.sha256 -ne $Bundle.overlay_render_sha256) { throw 'deployment_bundle_render_mismatch' }
    $true
}

function Remove-NetworkDelayNormalDeploymentBundle {
    param([Parameter(Mandatory)][object]$Bundle)

    if ($null -eq $Bundle -or [string]::IsNullOrWhiteSpace([string]$Bundle.root)) { return }
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
    $bundleRoot = [IO.Path]::GetFullPath([string]$Bundle.root).TrimEnd('\')
    if (-not $bundleRoot.StartsWith($tempRoot + '\network-delay-normal-deploy-', [StringComparison]::OrdinalIgnoreCase)) { throw 'deployment_bundle_cleanup_path_escape' }
    if (Test-Path -LiteralPath $bundleRoot) { Remove-Item -LiteralPath $bundleRoot -Recurse -Force -WhatIf:$false -Confirm:$false }
}

function New-NetworkDelayNormalDeploymentBundle {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [Parameter(Mandatory)][string]$OnlineBoutiqueSourceRoot,
        [Parameter(Mandatory)][string]$ExpectedSourceRevision,
        [Parameter(Mandatory)][string]$KubectlPath
    )

    $repo = (Resolve-Path -LiteralPath $RepoRoot -ErrorAction Stop).Path
    $source = Assert-PhysicalPinnedOnlineBoutiqueSource -OnlineBoutiqueSourceRoot $OnlineBoutiqueSourceRoot -ExpectedSourceRevision $ExpectedSourceRevision
    $configRoot = Join-Path $repo 'p0-env\config'
    $requiredConfigs = @('online-boutique','network-delay-design','network-delay-resource-compatibility')
    foreach ($name in $requiredConfigs) {
        if (-not (Test-Path -LiteralPath (Join-Path $configRoot "$name\kustomization.yaml") -PathType Leaf)) { throw "deployment_bundle_config_missing:$name" }
    }

    $bundleRoot = Join-Path ([IO.Path]::GetTempPath()) ('network-delay-normal-deploy-'+[guid]::NewGuid().ToString('N'))
    try {
        New-Item -ItemType Directory -Path $bundleRoot -WhatIf:$false -Confirm:$false | Out-Null
        Copy-Item -LiteralPath (Join-Path $source.root 'kustomize\base') -Destination (Join-Path $bundleRoot 'upstream-base') -Recurse -WhatIf:$false -Confirm:$false
        foreach ($name in $requiredConfigs) {
            Copy-Item -LiteralPath (Join-Path $configRoot $name) -Destination (Join-Path $bundleRoot $name) -Recurse -WhatIf:$false -Confirm:$false
        }

        $baseConfig = Join-Path $bundleRoot 'online-boutique'
        $overlayConfig = Join-Path $bundleRoot 'network-delay-resource-compatibility'
        $kustomizationPath = Join-Path $baseConfig 'kustomization.yaml'
        $relativeSource = '../../source/microservices-demo/kustomize/base'
        $kustomization = Get-Content -LiteralPath $kustomizationPath -Raw
        if (([regex]::Matches($kustomization,[regex]::Escape($relativeSource))).Count -ne 1) { throw 'base_overlay_source_reference_contract_mismatch' }
        $kustomization = $kustomization.Replace($relativeSource,'../upstream-base')
        [IO.File]::WriteAllText($kustomizationPath,$kustomization,[Text.UTF8Encoding]::new($false))

        [string[]]$versionOutput = @(& $KubectlPath version --client -o json 2>&1 | ForEach-Object { [string]$_ })
        if ($LASTEXITCODE -ne 0) { throw "kubectl_client_version_failed:$(($versionOutput -join ' | '))" }
        $version = ($versionOutput -join "`n") | ConvertFrom-Json
        $baseRender = Invoke-SourceBoundKustomizeRender -KubectlPath $KubectlPath -ConfigRoot $baseConfig -FailureName 'deployment_bundle_base_render_failed'
        $overlayRender = Invoke-SourceBoundKustomizeRender -KubectlPath $KubectlPath -ConfigRoot $overlayConfig -FailureName 'deployment_bundle_overlay_render_failed'
        $contentHash = Get-SourceBoundBundleContentHash -Root $bundleRoot
        [ordered]@{
            schema_version = 1
            root = $bundleRoot
            base_config = $baseConfig
            overlay_config = $overlayConfig
            source_root = $source.root
            source_revision = $source.revision
            source_clean = $source.clean
            source_root_reparse_point = $source.reparse_point
            relative_checkout_source_reference_used = $false
            kubectl_client_version = [string]$version.clientVersion.gitVersion
            kustomize_version = [string]$version.kustomizeVersion
            upstream_file_count = @(Get-ChildItem -LiteralPath (Join-Path $bundleRoot 'upstream-base') -File -Recurse).Count
            content_sha256 = $contentHash
            base_render_line_count = $baseRender.line_count
            base_render_sha256 = $baseRender.sha256
            overlay_render_line_count = $overlayRender.line_count
            overlay_render_sha256 = $overlayRender.sha256
            passed = $true
        }
    }
    catch {
        if (Test-Path -LiteralPath $bundleRoot) { Remove-Item -LiteralPath $bundleRoot -Recurse -Force -WhatIf:$false -Confirm:$false }
        throw
    }
}

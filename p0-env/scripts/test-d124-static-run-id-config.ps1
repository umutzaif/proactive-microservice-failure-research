$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$verifier = Join-Path $PSScriptRoot 'verify-static-run-id-config.ps1'
$expected = 'ob-netdelay-500m-normal-10u-011'

$root = Join-Path ([IO.Path]::GetTempPath()) ('d124-run-id-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $root -Force | Out-Null
try {
    Copy-Item (Join-Path $PSScriptRoot '..\config\online-boutique\kustomization.yaml') $root
    Copy-Item (Join-Path $PSScriptRoot '..\config\online-boutique\observability.yaml') $root
    foreach ($name in @('kustomization.yaml','observability.yaml')) {
        $path = Join-Path $root $name
        $content = [IO.File]::ReadAllText($path).Replace(
            'ob-netdelay-500m-normal-10u-012',
            $expected
        )
        [IO.File]::WriteAllText($path,$content,[Text.UTF8Encoding]::new($false))
    }
    & $verifier -ExpectedRunId $expected -ConfigRoot $root | Out-Null
    foreach ($case in @(
        @{name='wrong_expected';expected='ob-netdelay-500m-normal-10u-010';mutate=$false;error='static_run_id_count_mismatch'},
        @{name='mixed_identity';expected=$expected;mutate=$true;error='static_run_id_count_mismatch'}
    )) {
        if ($case.mutate) {
            $path = Join-Path $root 'observability.yaml'
            $content = [IO.File]::ReadAllText($path)
            [IO.File]::WriteAllText(
                $path,
                ([regex]::new([regex]::Escape($expected))).Replace(
                    $content,
                    'ob-netdelay-500m-normal-10u-010',
                    1
                ),
                [Text.UTF8Encoding]::new($false)
            )
        }
        $failed = $false
        try { & $verifier -ExpectedRunId $case.expected -ConfigRoot $root | Out-Null }
        catch { $failed = $_.Exception.Message -match $case.error }
        if (-not $failed) { throw "d124_static_gate_negative_failed:$($case.name)" }
        if ($case.mutate) {
            $content = [IO.File]::ReadAllText((Join-Path $PSScriptRoot '..\config\online-boutique\observability.yaml')).Replace(
                'ob-netdelay-500m-normal-10u-012',
                $expected
            )
            [IO.File]::WriteAllText((Join-Path $root 'observability.yaml'),$content,[Text.UTF8Encoding]::new($false))
        }
    }
}
finally {
    Remove-Item -LiteralPath $root -Recurse -Force
}

Write-Output 'd124_static_run_id_config=passed positive=1 negative=2 runtime=none'

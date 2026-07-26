[CmdletBinding()]
param(
    [string]$Root = $PSScriptRoot
)

$ErrorActionPreference = 'Stop'
$rootPath = [IO.Path]::GetFullPath($Root).TrimEnd([char[]]@('\', '/'))
$rootPrefix = $rootPath + [IO.Path]::DirectorySeparatorChar
$manifestPath = Join-Path $rootPath 'SHA256MANIFEST.txt'
if (-not (Test-Path -LiteralPath $manifestPath -PathType Leaf)) {
    throw "Missing manifest: $manifestPath"
}

$expected = @{}
foreach ($line in Get-Content -LiteralPath $manifestPath -Encoding UTF8) {
    if ($line -notmatch '^([0-9a-f]{64})  (.+)$') {
        throw "Invalid manifest line: $line"
    }
    if ($expected.ContainsKey($Matches[2])) {
        throw "Duplicate manifest path: $($Matches[2])"
    }
    $expected[$Matches[2]] = $Matches[1]
}

$actual = @{}
foreach ($file in Get-ChildItem -LiteralPath $Root -File -Recurse -Force) {
    if ($file.FullName -eq $manifestPath) {
        continue
    }
    $fullPath = [IO.Path]::GetFullPath($file.FullName)
    if (-not $fullPath.StartsWith($rootPrefix, [StringComparison]::OrdinalIgnoreCase)) {
        throw "File escaped transfer root: $fullPath"
    }
    $relative = $fullPath.Substring($rootPrefix.Length).Replace('\', '/')
    if ($actual.ContainsKey($relative)) {
        throw "Duplicate file path: $relative"
    }
    $actual[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
}

$missing = @($expected.Keys | Where-Object { -not $actual.ContainsKey($_) })
$extra = @($actual.Keys | Where-Object { -not $expected.ContainsKey($_) })
if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
    throw "Manifest file-set mismatch. Missing=$($missing -join ', ') Extra=$($extra -join ', ')"
}

foreach ($relative in $expected.Keys) {
    if ($actual[$relative] -ne $expected[$relative]) {
        throw "SHA-256 mismatch: $relative"
    }
}

Write-Host "Transfer verification passed: $($expected.Count) files" -ForegroundColor Green

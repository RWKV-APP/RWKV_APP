[CmdletBinding()]
param(
    [string]$Destination = (Join-Path $HOME 'rwkv-kirin-workspace'),
    [switch]$AttachGitHistory
)

$ErrorActionPreference = 'Stop'
$packageRoot = $PSScriptRoot
$sourceRoot = Join-Path $packageRoot 'sources'
$stateRoot = Join-Path $packageRoot 'state'
$gitRepositories = @('rwkv_app', 'rwkv_mobile', 'rwkv_mobile_flutter', 'app_website')

function Get-NormalizedRoot {
    param([Parameter(Mandatory = $true)][string]$Path)
    return [IO.Path]::GetFullPath($Path).TrimEnd([char[]]@('\', '/'))
}

function Copy-Tree {
    param(
        [Parameter(Mandatory = $true)][string]$Source,
        [Parameter(Mandatory = $true)][string]$Target
    )
    New-Item -ItemType Directory -Path $Target -Force | Out-Null
    foreach ($item in Get-ChildItem -LiteralPath $Source -Force) {
        Copy-Item -LiteralPath $item.FullName -Destination $Target -Recurse -Force
    }
}

function Compare-CopiedTree {
    param(
        [Parameter(Mandatory = $true)][string]$Expected,
        [Parameter(Mandatory = $true)][string]$Actual,
        [string[]]$IgnoredRelativePaths = @()
    )

    $expectedRoot = Get-NormalizedRoot -Path $Expected
    $actualRoot = Get-NormalizedRoot -Path $Actual
    $expectedPrefix = $expectedRoot + [IO.Path]::DirectorySeparatorChar
    $actualPrefix = $actualRoot + [IO.Path]::DirectorySeparatorChar
    $expectedHashes = @{}
    $actualHashes = @{}

    foreach ($file in Get-ChildItem -LiteralPath $expectedRoot -File -Recurse -Force) {
        $relative = $file.FullName.Substring($expectedPrefix.Length).Replace('\', '/')
        if ($IgnoredRelativePaths -contains $relative) {
            continue
        }
        $expectedHashes[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }
    foreach ($file in Get-ChildItem -LiteralPath $actualRoot -File -Recurse -Force) {
        $relative = $file.FullName.Substring($actualPrefix.Length).Replace('\', '/')
        if ($IgnoredRelativePaths -contains $relative) {
            continue
        }
        $actualHashes[$relative] = (Get-FileHash -LiteralPath $file.FullName -Algorithm SHA256).Hash
    }

    $missing = @($expectedHashes.Keys | Where-Object { -not $actualHashes.ContainsKey($_) })
    $extra = @($actualHashes.Keys | Where-Object { -not $expectedHashes.ContainsKey($_) })
    if ($missing.Count -gt 0 -or $extra.Count -gt 0) {
        throw "Restored tree file-set mismatch. Missing=$($missing -join ', ') Extra=$($extra -join ', ')"
    }
    foreach ($relative in $expectedHashes.Keys) {
        if ($expectedHashes[$relative] -ne $actualHashes[$relative]) {
            throw "Restored tree hash mismatch: $relative"
        }
    }
}

function Initialize-RwkvAppEnvironment {
    param([Parameter(Mandatory = $true)][string]$Repository)
    $template = Join-Path $Repository '.env.example'
    $environment = Join-Path $Repository '.env'
    if (-not (Test-Path -LiteralPath $template -PathType Leaf)) {
        throw "Missing secret-free environment template: $template"
    }
    if (-not (Test-Path -LiteralPath $environment)) {
        Copy-Item -LiteralPath $template -Destination $environment
    }
}

function Apply-PatchIfPresent {
    param(
        [Parameter(Mandatory = $true)][string]$Repository,
        [Parameter(Mandatory = $true)][string]$Patch,
        [switch]$Index
    )
    if ((Get-Item -LiteralPath $Patch).Length -eq 0) {
        return
    }
    $arguments = @('-C', $Repository, 'apply', '--binary', '--whitespace=nowarn')
    if ($Index) {
        $arguments += '--index'
    }
    $arguments += $Patch
    & git @arguments
    if ($LASTEXITCODE -ne 0) {
        throw "git apply failed: $Patch"
    }
}

New-Item -ItemType Directory -Path $Destination -Force | Out-Null

foreach ($name in $gitRepositories) {
    $source = Join-Path $sourceRoot $name
    $state = Join-Path $stateRoot $name
    $target = Join-Path $Destination $name
    if (Test-Path -LiteralPath $target) {
        throw "Target already exists: $target"
    }

    if (-not $AttachGitHistory) {
        Copy-Tree -Source $source -Target $target
        if ($name -eq 'rwkv_app') {
            Initialize-RwkvAppEnvironment -Repository $target
            Compare-CopiedTree -Expected $source -Actual $target -IgnoredRelativePaths @('.env')
        } else {
            Compare-CopiedTree -Expected $source -Actual $target
        }
        continue
    }

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        throw 'Git is required with -AttachGitHistory'
    }
    $origin = (Get-Content -LiteralPath (Join-Path $state 'origin-url.txt') -Raw).Trim()
    $baseHead = (Get-Content -LiteralPath (Join-Path $state 'base-head.txt') -Raw).Trim()
    $branch = (Get-Content -LiteralPath (Join-Path $state 'branch.txt') -Raw).Trim()
    if ($origin -eq '[REDACTED]' -or [string]::IsNullOrWhiteSpace($origin)) {
        throw "A safe origin URL was not recorded for $name"
    }

    & git -c core.autocrlf=false clone --no-checkout $origin $target
    if ($LASTEXITCODE -ne 0) {
        throw "git clone failed for $name"
    }
    & git -C $target config core.autocrlf false
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to configure core.autocrlf for $name"
    }
    & git -C $target fetch origin $baseHead
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to fetch $baseHead for $name"
    }
    if ([string]::IsNullOrWhiteSpace($branch)) {
        & git -C $target checkout --detach $baseHead
    } else {
        & git -C $target checkout -B $branch $baseHead
    }
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to check out $baseHead for $name"
    }

    Apply-PatchIfPresent -Repository $target -Patch (Join-Path $state 'staged.patch') -Index
    Apply-PatchIfPresent -Repository $target -Patch (Join-Path $state 'unstaged.patch')

    $untracked = Join-Path $state 'untracked'
    if (Test-Path -LiteralPath $untracked -PathType Container) {
        Copy-Tree -Source $untracked -Target $target
    }

    $expectedStatus = @(
        Get-Content -LiteralPath (Join-Path $state 'status.files.txt') -Encoding UTF8
    )
    $actualStatus = @(& git -C $target status --porcelain=v1)
    if ($LASTEXITCODE -ne 0) {
        throw "Unable to inspect restored Git status for $name"
    }
    if (($expectedStatus -join "`n") -ne ($actualStatus -join "`n")) {
        throw "Restored Git status differs for $name"
    }
    if ($name -eq 'rwkv_app') {
        Initialize-RwkvAppEnvironment -Repository $target
    }
}

$harmonySource = Join-Path $sourceRoot 'rwkv_harmony'
$harmonyTarget = Join-Path $Destination 'rwkv_harmony'
if (Test-Path -LiteralPath $harmonyTarget) {
    throw "Target already exists: $harmonyTarget"
}
Copy-Tree -Source $harmonySource -Target $harmonyTarget
Compare-CopiedTree -Expected $harmonySource -Actual $harmonyTarget

Write-Host "Workspace restored to $Destination" -ForegroundColor Green
Write-Host 'Keep rwkv_harmony and rwkv_mobile as sibling directories'

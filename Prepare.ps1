<#
.SYNOPSIS
准备阶段：从官方 GitHub 克隆 7-Zip 源码，不再下载外部包
#>
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$repoDir = "$tempDir\7zip-official"
$buildDir = "$workDir\$BuildVersion"

# 确保临时目录存在
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# ==============================================
# 核心修复：从官方 GitHub 克隆（不下载外部包）
# ==============================================
if (-not (Test-Path $repoDir)) {
    Write-Host "🔧 克隆官方 7-Zip 仓库..."
    git clone https://github.com/ip7z/7zip.git "$repoDir" --depth 1
}

# 自动提取版本号（无论输入是 7z2600 还是 26.00 都能转成 26.00）
$verTag = $BuildVersion -replace '^7z',''  # 去掉开头的 7z
$verTag = $verTag -replace '(\d{2})(\d{2})','$1.$2' # 补回小数点

Write-Host "🔧 切换到版本: $verTag"

Set-Location $repoDir
git fetch --tags
git checkout "tags/$verTag" -f
Set-Location $workDir

# 复制源码到构建目录
if (Test-Path $buildDir) { Remove-Item $buildDir -Recurse -Force }
Copy-Item -Path "$repoDir\*" -Destination $buildDir -Recurse -Force

Write-Host "✅ Prepare 完成，源码已准备就绪！"

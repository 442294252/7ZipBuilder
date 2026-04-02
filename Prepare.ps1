<#
.SYNOPSIS
准备阶段：从官方 GitHub 克隆 7-Zip 源码，彻底解决复制冲突
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

# 🔧 核心修复：先彻底删除旧目录，再创建新目录，避免冲突
if (Test-Path $buildDir) {
    Write-Host "🧹 清理旧构建目录: $buildDir"
    Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# 确保临时目录存在
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# ==============================================
# 从官方 GitHub 克隆（带 --depth 1 加速，只拉最新）
# ==============================================
if (-not (Test-Path $repoDir)) {
    Write-Host "🔧 克隆官方 7-Zip 仓库..."
    git clone https://github.com/ip7z/7zip.git "$repoDir" --depth 1
}

# 自动提取版本号（兼容 7z2600 / 26.00 格式）
$verTag = $BuildVersion -replace '^7z',''
$verTag = $verTag -replace '(\d{2})(\d{2})','$1.$2'

Write-Host "🔧 切换到版本: $verTag"

Set-Location $repoDir
git fetch --tags --depth 1
git checkout "tags/$verTag" -f
Set-Location $workDir

# 🔧 核心修复：用 robocopy 替代 Copy-Item，彻底解决目录复制冲突
# robocopy 是 Windows 原生工具，完美处理目录复制，不会报容器冲突
Write-Host "🔧 复制源码到构建目录..."
robocopy "$repoDir" "$buildDir" /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) {
    throw "❌ robocopy 复制失败，退出码: $LASTEXITCODE"
}

Write-Host "✅ Prepare 完成，源码已准备就绪！"

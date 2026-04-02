<#
.SYNOPSIS
准备阶段：从官方 GitHub 克隆 7-Zip 源码，解决 robocopy 退出码冲突
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

# 1. 彻底清理旧目录，确保干净
if (Test-Path $buildDir) {
    Write-Host "🧹 清理旧构建目录: $buildDir"
    Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# 2. 确保临时目录存在
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# 3. 克隆官方仓库（如果不存在）
if (-not (Test-Path $repoDir)) {
    Write-Host "🔧 克隆官方 7-Zip 仓库..."
    git clone https://github.com/ip7z/7zip.git "$repoDir" --depth 1
}

# 4. 自动提取并切换到正确的版本号
$verTag = $BuildVersion -replace '^7z','' # 去掉 7z 前缀
$verTag = $verTag -replace '(\d{2})(\d{2})','$1.$2' # 补回小数点（2600 -> 26.00）

Write-Host "🔧 切换到版本: $verTag"

Set-Location $repoDir
git fetch --tags --depth 1
git checkout "tags/$verTag" -f
Set-Location $workDir

# 5. 🔧 核心修复：用 robocopy 复制，并重载判断逻辑
# robocopy 规则：Exit Code 0-8 都是正常成功，只有 >=8 才是错误
Write-Host "🔧 复制源码到构建目录..."
robocopy "$repoDir" "$buildDir" /E /NFL /NDL /NJH /NJS

# 检查退出码，0-8 均视为成功
if ($LASTEXITCODE -ge 8) {
    throw "❌ robocopy 复制严重失败，退出码: $LASTEXITCODE"
} else {
    Write-Host "✅ Prepare 完成，源码已准备就绪！(robocopy 退出码: $LASTEXITCODE)"
}

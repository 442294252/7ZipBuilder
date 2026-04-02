<#
.SYNOPSIS
7-Zip 构建准备脚本 - 终版（解决所有历史错误）
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

# ==============================================
# 1. 彻底清理旧目录，从根源避免复制冲突
# ==============================================
if (Test-Path $buildDir) {
    Write-Host "🧹 清理旧构建目录: $buildDir"
    Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# 2. 确保临时目录存在
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# ==============================================
# 3. 克隆官方GitHub仓库（零外网下载，彻底解决网络问题）
# ==============================================
if (-not (Test-Path $repoDir)) {
    Write-Host "🔧 克隆官方 7-Zip 仓库（ip7z/7zip）..."
    git clone https://github.com/ip7z/7zip.git "$repoDir" --depth 1
}

# ==============================================
# 4. 版本号自动转换（兼容7z2600/26.00所有格式，解决空值问题）
# ==============================================
if ($BuildVersion -match '7z(\d+)') {
    $verTag = $matches[1] -replace '(\d{2})(\d{2})','$1.$2' # 2600 -> 26.00
} elseif ($BuildVersion -match '(\d+)\.(\d+)') {
    $verTag = "$($matches[1]).$($matches[2])" # 直接用26.00
} else {
    throw "❌ 版本号格式错误: $BuildVersion，仅支持7z2600/26.00格式"
}

Write-Host "🔧 切换到官方版本标签: $verTag"

# 切换到对应版本tag
Set-Location $repoDir
git fetch --tags --depth 1
git checkout "tags/$verTag" -f
Set-Location $workDir

# ==============================================
# 5. robocopy复制源码（解决目录复制冲突+退出码问题）
# robocopy官方规则：0-8为成功，>=8为错误
# ==============================================
Write-Host "🔧 复制源码到构建目录..."
robocopy "$repoDir" "$buildDir" /E /NFL /NDL /NJH /NJS

# 严格按robocopy规则判断退出码
if ($LASTEXITCODE -ge 8) {
    throw "❌ robocopy复制失败，严重错误，退出码: $LASTEXITCODE"
} else {
    Write-Host "✅ Prepare步骤执行完成！源码已就绪（robocopy退出码: $LASTEXITCODE）"
    exit 0 # 强制返回0，确保GitHub Actions判定成功
}

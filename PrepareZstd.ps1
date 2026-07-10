param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $RawTag
)

$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$repoDir = "$tempDir\7zip-zstd"

# 从tag提取基础版本号 v26.02-v1.5.7 → 2602
$verBase = $RawTag -split "-v" | Select-Object -First 1
$verNum = $verBase.TrimStart('v') -replace '\.', ''
$BuildPrefix = "7z$verNum"
$buildDir = "$workDir\$BuildPrefix"

# 清理旧目录避免复制冲突
if (Test-Path $buildDir) {
    Remove-Item $buildDir -Recurse -Force -ErrorAction SilentlyContinue
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# 克隆 zstd 仓库
if (-not (Test-Path $repoDir)) {
    Write-Host "🔽 克隆 mcmilk/7-Zip-zstd"
    git clone https://github.com/mcmilk/7-Zip-zstd.git "$repoDir" --depth 1
}

# 切换完整tag（v26.02-v1.5.7）
Set-Location $repoDir
git fetch --tags --depth 1
git checkout "tags/$RawTag" -f
Set-Location $workDir

# robocopy 复制源码，规避 Copy-Item 目录报错
robocopy "$repoDir" "$buildDir" /E /NFL /NDL /NJH /NJS
if ($LASTEXITCODE -ge 8) {
    throw "❌ robocopy 源码复制失败"
}

# 执行共用自定义前置脚本
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    & $subPrepareScript $buildDir $BuildPrefix
}

# 输出构建前缀给后续脚本读取
Write-Output $BuildPrefix > "$workDir\7zVer.txt"
Write-Host "✅ PrepareZstd 完成，构建标识：$BuildPrefix"
exit 0

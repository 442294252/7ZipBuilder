param(
    [Parameter(Mandatory = $true)]
    [string] $BuildVersion,
    [Parameter(Mandatory = $true)]
    [string] $SourceDownloadUrl
)

$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$buildDir = "$workDir\$BuildVersion"

# 1. 创建目录
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# 2. 用提前获取好的链接下载源码，不再重复调用GitHub API，彻底避免匹配失败
$sourceZipPath = "$tempDir\$BuildVersion-src.7z"
if (-not (Test-Path $sourceZipPath)) {
    Write-Host "🔽 下载源码包: $BuildVersion" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $SourceDownloadUrl -OutFile $sourceZipPath -UseBasicParsing
}

# 3. 用系统自带7z解压源码，无需下载7zr.exe
if (-not (Test-Path $buildDir)) {
    Write-Host "📦 解压源码包" -ForegroundColor Gray
    7z x $sourceZipPath -o"$buildDir" -y | Out-Null
}

# 4. 调用子流程替换图标（完全兼容你现有的图标替换逻辑）
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    Write-Host "🎨 执行自定义图标替换" -ForegroundColor Cyan
    & $subPrepareScript $buildDir $BuildVersion
}

Write-Host "✅ Prepare步骤完成" -ForegroundColor Green

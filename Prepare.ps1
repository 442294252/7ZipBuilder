param(
    [Parameter(Mandatory = $true)]
    [string] $OfficialTag,
    [Parameter(Mandatory = $true)]
    [string] $SourceDownloadUrl
)

$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$buildDir = "$workDir\$OfficialTag"

# 创建目录
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# 下载源码包（用提前匹配好的官方链接，零匹配错误）
$sourceZipPath = "$tempDir\$OfficialTag-src.7z"
if (-not (Test-Path $sourceZipPath)) {
    Write-Host "🔽 下载官方源码包: $OfficialTag-src.7z" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $SourceDownloadUrl -OutFile $sourceZipPath -UseBasicParsing
}

# 解压源码（用系统自带7z，无需额外下载7zr.exe）
if (-not (Test-Path $buildDir)) {
    Write-Host "📦 解压源码包到: $buildDir" -ForegroundColor Gray
    7z x $sourceZipPath -o"$buildDir" -y | Out-Null
}

# 调用你的图标替换脚本，完全兼容原有逻辑
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    Write-Host "🎨 执行自定义图标替换" -ForegroundColor Cyan
    & $subPrepareScript $buildDir $OfficialTag
}

Write-Host "✅ Prepare步骤全部完成" -ForegroundColor Green

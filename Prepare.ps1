param(
    [Parameter(Mandatory = $true)]
    [string] $FilePrefix,
    [Parameter(Mandatory = $true)]
    [string] $SourceDownloadUrl
)

$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$buildDir = "$workDir\$FilePrefix"

# 创建目录
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# 下载源码包（文件名和官方完全一致：7z2600-src.7z）
$sourceZipPath = "$tempDir\$FilePrefix-src.7z"
if (-not (Test-Path $sourceZipPath)) {
    Write-Host "🔽 下载官方源码包: $FilePrefix-src.7z" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $SourceDownloadUrl -OutFile $sourceZipPath -UseBasicParsing
}

# 解压源码到对应目录（目录名和文件名前缀一致：7z2600）
if (-not (Test-Path $buildDir)) {
    Write-Host "📦 解压源码包到: $buildDir" -ForegroundColor Gray
    7z x $sourceZipPath -o"$buildDir" -y | Out-Null
}

# 调用你的图标替换脚本，完全兼容原有逻辑
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    Write-Host "🎨 执行自定义图标替换" -ForegroundColor Cyan
    & $subPrepareScript $buildDir $FilePrefix
}

Write-Host "✅ Prepare步骤完成" -ForegroundColor Green

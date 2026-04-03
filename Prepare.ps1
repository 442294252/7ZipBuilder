param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$buildDir = "$workDir\$BuildVersion"

# 1. 创建目录
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# ======================================================================
# 🔥 彻底删除访问 7-zip.org 的代码，改用 GitHub 官方源（绝对稳定）
# ======================================================================

# 2. 从 GitHub 下载源码（内网稳定，完全不碰 7-zip.org）
$sourceZipPath = "$tempDir\$BuildVersion-src.7z"
if (-not (Test-Path $sourceZipPath)) {
    Write-Host "🔽 Downloading source code from GitHub..." -ForegroundColor Cyan
    $api = "https://api.github.com/repos/ip7z/7zip/releases/latest"
    $response = Invoke-RestMethod -Uri $api -UseBasicParsing
    $sourceAsset = $response.assets | Where-Object { $_.name -eq "$BuildVersion-src.7z" }
    Invoke-WebRequest -Uri $sourceAsset.browser_download_url -OutFile $sourceZipPath -UseBasicParsing
}

# 3. 用系统自带 7z 解压源码（GitHub Runner 自带，无需下载 7zr.exe）
if (-not (Test-Path $buildDir)) {
    Write-Host "📦 Extracting source code..." -ForegroundColor Gray
    7z x $sourceZipPath -o"$buildDir" -y | Out-Null
}

# 4. 调用子流程替换图标（完全不受影响）
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    Write-Host "🎨 Applying custom icon..." -ForegroundColor Cyan
    & $subPrepareScript $buildDir $BuildVersion
}

Write-Host "✅ Prepare completed successfully" -ForegroundColor Green

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
if (-not (Test-Path $buildDir)) {
    New-Item -ItemType Directory -Path $buildDir -Force | Out-Null
}

# 2. 从 GitHub API 下载源码（不走7-zip.org，内网稳定）
$sourceZipPath = "$tempDir\$BuildVersion-src.7z"
if (-not (Test-Path $sourceZipPath)) {
    Write-Host "🔽 从GitHub下载源码: $BuildVersion" -ForegroundColor Cyan
    $api = "https://api.github.com/repos/ip7z/7zip/releases/latest"
    $response = Invoke-RestMethod -Uri $api -UseBasicParsing
    # 匹配源码包资产
    $sourceAsset = $response.assets | Where-Object { $_.name -eq "$BuildVersion-src.7z" }
    if (-not $sourceAsset) {
        Write-Error "❌ 未找到源码包: $BuildVersion-src.7z"
        exit 1
    }
    # 下载源码（GitHub内网，永不超时）
    Invoke-WebRequest -Uri $sourceAsset.browser_download_url -OutFile $sourceZipPath -UseBasicParsing
}

# 3. 用系统自带7z解压源码（稳定可靠）
Write-Host "📦 解压源码包: $sourceZipPath" -ForegroundColor Gray
7z x $sourceZipPath -o"$buildDir" -y | Out-Null

# 4. 调用子流程替换图标
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    Write-Host "🎨 执行图标替换..." -ForegroundColor Cyan
    & $subPrepareScript $buildDir $BuildVersion
}

Write-Host "✅ Prepare 步骤完成" -ForegroundColor Green

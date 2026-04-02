param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

# 版本号清洗：移除小数点，匹配官方命名（7z26.00 → 7z2600）
$verClean = $BuildVersion -replace '\.', ''
$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$buildDir = "$workDir\$BuildVersion"

# 确保目录存在
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir -Force | Out-Null }

# 下载7zr（解压工具）
if (-not (Test-Path "$tempDir\7zr.exe")) {
    Write-Host "下载7zr.exe..."
    Invoke-WebRequest -Uri "https://www.7-zip.org/a/7zr.exe" -OutFile "$tempDir\7zr.exe" -ErrorAction Stop
}

# 下载源码（修复文件名+双地址兜底，解决网络问题）
$srcFile = "$tempDir\${verClean}-src.7z"
if (-not (Test-Path $srcFile)) {
    Write-Host "从GitHub下载源码: $BuildVersion"
    $githubUrl = "https://github.com/ip7z/7zip/releases/download/$($BuildVersion.Replace('7z',''))/7z$verClean-src.7z"
    $officialUrl = "https://www.7-zip.org/a/7z$verClean-src.7z"
    
    try {
        Invoke-WebRequest -Uri $githubUrl -OutFile $srcFile -ErrorAction Stop
    }
    catch {
        Write-Warning "GitHub下载失败，尝试官方源..."
        Invoke-WebRequest -Uri $officialUrl -OutFile $srcFile -ErrorAction Stop
    }
}

# 解压源码
Write-Host "解压源码到 $buildDir"
& "$tempDir\7zr.exe" x "$srcFile" -o"$buildDir" -y | Out-Null
if ($LASTEXITCODE -ne 0) { throw "源码解压失败" }

# 执行子流程
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    & $subPrepareScript $buildDir $BuildVersion
    if ($LASTEXITCODE -ne 0) { throw "SubPrepare.ps1 执行失败" }
}

Write-Host "Prepare步骤执行完成 ✅"

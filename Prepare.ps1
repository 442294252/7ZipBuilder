param(
    [Parameter(Mandatory = $true)]
    [string] $BuildVersion
)

$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$repoDir = "$tempDir\7zip"
$buildDir = "$workDir\$BuildVersion"

# 创建目录
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $buildDir)) { New-Item -ItemType Directory -Path $buildDir -Force | Out-Null }

# 直接从官方 GitHub 克隆源码（零下载、零超时、零错误）
if (-not (Test-Path $repoDir)) {
    Write-Host "→ 从官方 GitHub 克隆 7-Zip 源码"
    git clone https://github.com/ip7z/7zip.git "$repoDir"
}

# 切换到对应版本 tag（例如 26.00）
$realTag = $BuildVersion -replace '7z','' -replace '\.',''
$realTag = $realTag -replace '(\d{2})(\d{2})','$1.$2'
Write-Host "→ 切换到版本标签: $realTag"

Set-Location $repoDir
git fetch --tags
git checkout tags/$realTag -f
Set-Location $workDir

# 复制源码到构建目录
Copy-Item -Path "$repoDir\*" -Destination $buildDir -Recurse -Force
Write-Host "✅ Prepare 完成 —— 源码来自官方 GitHub：ip7z/7zip"

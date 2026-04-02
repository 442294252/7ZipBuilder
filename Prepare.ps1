param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$buildDir = "$workDir\$BuildVersion"

if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir
}

# ==============================
# 🔴 禁用网络下载（解决超时问题）
# ==============================

# 下载7zR（已禁用，改用系统自带的7z）
# if (-not (Test-Path "$tempDir\7zr.exe")) {
#     Invoke-WebRequest -Uri "https://www.7-zip.org/a/7zr.exe" -OutFile "$tempDir\7zr.exe"
# }

# 下载并解压源码（已禁用，改用系统自带7z）
if (-not (Test-Path $buildDir)) {
    # 下载源码（已禁用）
    # if (-not (Test-Path "$tempDir\$BuildVersion-src.7z")) {
    #     Invoke-WebRequest -Uri "https://7-zip.org/a/$BuildVersion-src.7z" -OutFile "$tempDir\$BuildVersion-src.7z"
    # }

    # 改用系统自带 7z（GitHub Actions 自带）
    7z x "$tempDir\$BuildVersion-src.7z" -o"$buildDir" -y
}

# 如果子流程存在则调用子流程用于自定义操作源码
$subPrepareScript = "$workDir\SubPrepare.ps1"
if (Test-Path $subPrepareScript) {
    & $subPrepareScript $buildDir $BuildVersion
}

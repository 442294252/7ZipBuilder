<#
  最终版：完全复用成品作者ReplaceResources.ps1的核心逻辑
  适配7ZipBuilder原生脚本的调用规则，路径100%对齐作者实测结果
#>
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildDirectory,  # 对应作者的$BuildDirectory（7-Zip源码目录）
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion     # 对应作者的$BuildVersion（版本号，暂未用到）
)

# ==================== 第一步：定义路径（完全对齐作者） ====================
$workDir = $PSScriptRoot  # 仓库根目录
$resDir = "$workDir\Resources"  # 你上传的Resources文件夹路径

# 调试日志（Actions中可查）
Write-Host "`n===== [作者同款资源替换] 开始执行 =====`n" -ForegroundColor Cyan
Write-Host "✅ 源码目录：$BuildDirectory"
Write-Host "✅ 资源目录：$resDir"
Write-Host "✅ 资源目录是否存在：$(Test-Path $resDir)" -ForegroundColor Green

# ==================== 第二步：替换格式图标（作者实测路径） ====================
$iconTarget = "$BuildDirectory\CPP\7zip\Archive\Icons"
if (Test-Path "$resDir\FileIcons\*.ico" -and Test-Path $iconTarget) {
    Copy-Item -Force -Recurse -Path "$resDir\FileIcons\*.ico" -Destination $iconTarget
    Write-Host "✅ 替换格式图标完成：$iconTarget" -ForegroundColor Green
} else {
    Write-Host "❌ 格式图标缺失（本地/源码路径不存在）" -ForegroundColor Red
}

# ==================== 第三步：替换RC资源文件（作者实测路径，关键！） ====================
# 替换Format7zF.rc → resource.rc
$format7zFTarget = "$BuildDirectory\CPP\7zip\Bundles\Format7zF\resource.rc"
if (Test-Path "$resDir\Format7zF.rc" -and Test-Path (Split-Path $format7zFTarget)) {
    Copy-Item -Force -Path "$resDir\Format7zF.rc" -Destination $format7zFTarget
    Write-Host "✅ 替换Format7zF.rc完成：$format7zFTarget" -ForegroundColor Green
} else {
    Write-Host "❌ Format7zF.rc替换失败（文件/路径缺失）" -ForegroundColor Red
}

# 替换Fm.rc → resource.rc
$fmTarget = "$BuildDirectory\CPP\7zip\Bundles\Fm\resource.rc"
if (Test-Path "$resDir\Fm.rc" -and Test-Path (Split-Path $fmTarget)) {
    Copy-Item -Force -Path "$resDir\Fm.rc" -Destination $fmTarget
    Write-Host "✅ 替换Fm.rc完成：$fmTarget" -ForegroundColor Green
} else {
    Write-Host "❌ Fm.rc替换失败（文件/路径缺失）" -ForegroundColor Red
}

# ==================== 第四步：替换工具栏图标（作者实测路径） ====================
$toolBarTarget = "$BuildDirectory\CPP\7zip\UI\FileManager"
if (Test-Path "$resDir\ToolBarIcons\*.bmp" -and Test-Path $toolBarTarget) {
    Copy-Item -Force -Path "$resDir\ToolBarIcons\*.bmp" -Destination $toolBarTarget
    Write-Host "✅ 替换工具栏图标完成：$toolBarTarget" -ForegroundColor Green
} else {
    Write-Host "❌ 工具栏图标替换失败（文件/路径缺失）" -ForegroundColor Red
}

Write-Host "`n===== [作者同款资源替换] 执行完成 =====`n" -ForegroundColor Cyan

<#
  完全独立版：不依赖任何外部参数，自己读取版本号并执行替换
  适配原生脚本，不修改Prepare.ps1/Build.ps1/Package.ps1
#>

# ==================== 自给自足模式：自己获取所有信息 ====================
$workDir = $PSScriptRoot
$resDir = "$workDir\Resources"

# 自动读取版本号（从7zVer.txt）
try {
    $BuildVersion = Get-Content -Path "$workDir\7zVer.txt" -Raw -ErrorAction Stop
    $BuildVersion = $BuildVersion.Trim()
    $BuildDirectory = "$workDir\$BuildVersion" # 源码目录，与原生脚本一致
    Write-Host "`n===== [完全独立资源替换] 开始执行 =====`n" -ForegroundColor Cyan
    Write-Host "✅ 自动获取版本号：$BuildVersion"
    Write-Host "✅ 自动计算源码目录：$BuildDirectory"
    Write-Host "✅ 资源目录：$resDir"
    Write-Host "✅ 资源目录是否存在：$(Test-Path $resDir)" -ForegroundColor Green
}
catch {
    Write-Host "❌ 读取7zVer.txt失败，资源替换终止：$($_.Exception.Message)" -ForegroundColor Red
    exit 0 # 仅终止自身，不影响整体构建
}

# ==================== 替换格式图标（FileIcons/*.ico） ====================
$iconTarget = "$BuildDirectory\CPP\7zip\Archive\Icons"
Write-Host "`n--- 替换格式图标 ---" -ForegroundColor Cyan
Write-Host "目标路径：$iconTarget"
if (Test-Path "$resDir\FileIcons\*.ico" -and Test-Path $iconTarget) {
    try {
        Copy-Item -Force -Recurse -Path "$resDir\FileIcons\*.ico" -Destination $iconTarget -ErrorAction Stop
        Write-Host "✅ 格式图标替换成功" -ForegroundColor Green
    } catch {
        Write-Host "❌ 格式图标替换失败：$($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ 格式图标路径缺失（本地/源码）" -ForegroundColor Red
}

# ==================== 替换Format7zF.rc ====================
$format7zFTarget = "$BuildDirectory\CPP\7zip\Bundles\Format7zF\resource.rc"
Write-Host "`n--- 替换Format7zF.rc ---" -ForegroundColor Cyan
Write-Host "目标路径：$format7zFTarget"
if (Test-Path "$resDir\Format7zF.rc" -and Test-Path (Split-Path $format7zFTarget)) {
    try {
        Copy-Item -Force -Path "$resDir\Format7zF.rc" -Destination $format7zFTarget -ErrorAction Stop
        Write-Host "✅ Format7zF.rc替换成功" -ForegroundColor Green
    } catch {
        Write-Host "❌ Format7zF.rc替换失败：$($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Format7zF.rc路径缺失（本地/源码）" -ForegroundColor Red
}

# ==================== 替换Fm.rc ====================
$fmTarget = "$BuildDirectory\CPP\7zip\Bundles\Fm\resource.rc"
Write-Host "`n--- 替换Fm.rc ---" -ForegroundColor Cyan
Write-Host "目标路径：$fmTarget"
if (Test-Path "$resDir\Fm.rc" -and Test-Path (Split-Path $fmTarget)) {
    try {
        Copy-Item -Force -Path "$resDir\Fm.rc" -Destination $fmTarget -ErrorAction Stop
        Write-Host "✅ Fm.rc替换成功" -ForegroundColor Green
    } catch {
        Write-Host "❌ Fm.rc替换失败：$($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ Fm.rc路径缺失（本地/源码）" -ForegroundColor Red
}

# ==================== 替换工具栏图标（ToolBarIcons/*.bmp） ====================
$toolBarTarget = "$BuildDirectory\CPP\7zip\UI\FileManager"
Write-Host "`n--- 替换工具栏图标 ---" -ForegroundColor Cyan
Write-Host "目标路径：$toolBarTarget"
if (Test-Path "$resDir\ToolBarIcons\*.bmp" -and Test-Path $toolBarTarget) {
    try {
        Copy-Item -Force -Path "$resDir\ToolBarIcons\*.bmp" -Destination $toolBarTarget -ErrorAction Stop
        Write-Host "✅ 工具栏图标替换成功" -ForegroundColor Green
    } catch {
        Write-Host "❌ 工具栏图标替换失败：$($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ 工具栏图标路径缺失（本地/源码）" -ForegroundColor Red
}

Write-Host "`n===== [完全独立资源替换] 执行完成 =====`n" -ForegroundColor Cyan

<#
  终极无参数版：彻底规避参数解析问题，直接硬编码所有路径
#>

# ==================== 固定路径定义（与仓库结构100%对应） ====================
# 仓库根目录（脚本所在目录）
$workDir = $PSScriptRoot
# 资源目录（你上传的Resources文件夹）
$resDir = "$workDir\Resources"
# 从7zVer.txt读取版本号，拼接源码目录
$buildVersion = Get-Content -Path "$workDir\7zVer.txt" -Raw -ErrorAction SilentlyContinue
$BuildDirectory = "$workDir\$buildVersion"

# ==================== 调试日志 ====================
Write-Host "`n===== [终极无参数资源替换] 开始执行 =====`n" -ForegroundColor Cyan
Write-Host "✅ 7-Zip版本：$buildVersion"
Write-Host "✅ 源码目录：$BuildDirectory"
Write-Host "✅ 资源目录：$resDir"
Write-Host "✅ 资源目录是否存在：$(Test-Path $resDir)" -ForegroundColor Green

# ==================== 替换格式图标（FileIcons/*.ico） ====================
$iconTarget = "$BuildDirectory\CPP\7zip\Archive\Icons"
Write-Host "`n--- 替换格式图标 ---" -ForegroundColor Cyan
Write-Host "目标路径：$iconTarget"
if (Test-Path "$resDir\FileIcons\*.ico" -and Test-Path $iconTarget) {
    try {
        # 用数组方式传递参数，彻底避免解析问题
        $source = "$resDir\FileIcons\*.ico"
        $dest = $iconTarget
        Write-Host "执行：Copy-Item -Force -Recurse -Path $source -Destination $dest"
        Copy-Item -Force -Recurse -Path $source -Destination $dest -ErrorAction Stop
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
        $source = "$resDir\Format7zF.rc"
        $dest = $format7zFTarget
        Write-Host "执行：Copy-Item -Force -Path $source -Destination $dest"
        Copy-Item -Force -Path $source -Destination $dest -ErrorAction Stop
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
        $source = "$resDir\Fm.rc"
        $dest = $fmTarget
        Write-Host "执行：Copy-Item -Force -Path $source -Destination $dest"
        Copy-Item -Force -Path $source -Destination $dest -ErrorAction Stop
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
        $source = "$resDir\ToolBarIcons\*.bmp"
        $dest = $toolBarTarget
        Write-Host "执行：Copy-Item -Force -Path $source -Destination $dest"
        Copy-Item -Force -Path $source -Destination $dest -ErrorAction Stop
        Write-Host "✅ 工具栏图标替换成功" -ForegroundColor Green
    } catch {
        Write-Host "❌ 工具栏图标替换失败：$($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "❌ 工具栏图标路径缺失（本地/源码）" -ForegroundColor Red
}

Write-Host "`n===== [终极无参数资源替换] 执行完成 =====`n" -ForegroundColor Cyan

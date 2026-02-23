<#
  兼容版：无参数也能执行，完全复刻“无脚本时构建成功”的逻辑，同时替换图标
  核心：优先从7zVer.txt读版本号，参数仅作为兜底，避免参数错误中断构建
#>
# ==================== 第一步：参数容错（核心！避免构建中断） ====================
param(
    # 定义参数，但允许为空（容错）
    [string] $BuildDirectory = "",
    [string] $BuildVersion = ""
)

# 仓库根目录（固定，在线编译时脚本所在目录就是仓库根）
$workDir = $PSScriptRoot
# 资源目录（你上传的Resources文件夹）
$resDir = "$workDir\Resources"

# 优先从7zVer.txt读取版本号（原生脚本生成，100%准确），参数仅兜底
if (-not $BuildVersion -or $BuildVersion -eq "") {
    $BuildVersion = Get-Content -Path "$workDir\7zVer.txt" -Raw -ErrorAction SilentlyContinue
}
# 优先拼接源码目录，参数仅兜底
if (-not $BuildDirectory -or $BuildDirectory -eq "") {
    $BuildDirectory = "$workDir\$BuildVersion"
}

# ==================== 第二步：调试日志（仅输出，不中断） ====================
Write-Host "`n===== [兼容版资源替换] 开始执行 =====`n" -ForegroundColor Cyan
Write-Host "✅ 7-Zip版本：$BuildVersion"
Write-Host "✅ 源码目录：$BuildDirectory"
Write-Host "✅ 资源目录：$resDir"

# ==================== 第三步：资源替换（所有操作加ErrorAction SilentlyContinue，不中断构建） ====================
# 1. 替换格式图标
$iconTarget = "$BuildDirectory\CPP\7zip\Archive\Icons"
try {
    if (Test-Path "$resDir\FileIcons\*.ico" -and Test-Path $iconTarget) {
        Copy-Item -Force -Recurse -Path "$resDir\FileIcons\*.ico" -Destination $iconTarget -ErrorAction Stop
        Write-Host "✅ 替换格式图标完成" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 格式图标路径缺失（不影响构建）" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ 格式图标替换失败（不影响构建）：$($_.Exception.Message)" -ForegroundColor Yellow
}

# 2. 替换Format7zF.rc
$format7zFTarget = "$BuildDirectory\CPP\7zip\Bundles\Format7zF\resource.rc"
try {
    if (Test-Path "$resDir\Format7zF.rc" -and Test-Path (Split-Path $format7zFTarget)) {
        Copy-Item -Force -Path "$resDir\Format7zF.rc" -Destination $format7zFTarget -ErrorAction Stop
        Write-Host "✅ 替换Format7zF.rc完成" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Format7zF.rc路径缺失（不影响构建）" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Format7zF.rc替换失败（不影响构建）：$($_.Exception.Message)" -ForegroundColor Yellow
}

# 3. 替换Fm.rc
$fmTarget = "$BuildDirectory\CPP\7zip\Bundles\Fm\resource.rc"
try {
    if (Test-Path "$resDir\Fm.rc" -and Test-Path (Split-Path $fmTarget)) {
        Copy-Item -Force -Path "$resDir\Fm.rc" -Destination $fmTarget -ErrorAction Stop
        Write-Host "✅ 替换Fm.rc完成" -ForegroundColor Green
    } else {
        Write-Host "⚠️ Fm.rc路径缺失（不影响构建）" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ Fm.rc替换失败（不影响构建）：$($_.Exception.Message)" -ForegroundColor Yellow
}

# 4. 替换工具栏图标
$toolBarTarget = "$BuildDirectory\CPP\7zip\UI\FileManager"
try {
    if (Test-Path "$resDir\ToolBarIcons\*.bmp" -and Test-Path $toolBarTarget) {
        Copy-Item -Force -Path "$resDir\ToolBarIcons\*.bmp" -Destination $toolBarTarget -ErrorAction Stop
        Write-Host "✅ 替换工具栏图标完成" -ForegroundColor Green
    } else {
        Write-Host "⚠️ 工具栏图标路径缺失（不影响构建）" -ForegroundColor Yellow
    }
} catch {
    Write-Host "⚠️ 工具栏图标替换失败（不影响构建）：$($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host "`n===== [兼容版资源替换] 执行完成（即使有警告，构建仍会继续） =====`n" -ForegroundColor Cyan

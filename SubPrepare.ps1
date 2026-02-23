<#
  适配仓库原生脚本的图标替换脚本
  放置位置：仓库根目录（和Prepare.ps1/AutoBuild.ps1同目录）
  依赖：根目录必须有FileIcons文件夹，内含7z.ico/zip.ico等自定义图标
#>
param(
    # 严格匹配Prepare.ps1的调用参数：第一个是源码目录，第二个是版本号
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildDirectory,  # 对应原生脚本的$buildDir（源码根目录）
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion     # 对应原生脚本的$BuildVersion（如7z2409）
)

# ==================== 第一步：调试日志（Actions中可查） ====================
Write-Host "`n===== [自定义图标替换] 开始执行 =====`n" -ForegroundColor Cyan
Write-Host "✅ 7-Zip源码目录：$BuildDirectory"
Write-Host "✅ 7-Zip版本号：$BuildVersion"
Write-Host "✅ 当前脚本目录：$PSScriptRoot"
Write-Host "✅ FileIcons文件夹是否存在：$(Test-Path "$PSScriptRoot\FileIcons")"

# 检查自定义图标
$iconSourcePath = "$PSScriptRoot\FileIcons"
$iconFiles = Get-ChildItem -Path $iconSourcePath -Filter *.ico -ErrorAction SilentlyContinue
if (-not $iconFiles -or $iconFiles.Count -eq 0) {
    Write-Host "❌ 错误：FileIcons文件夹中无.ico文件！" -ForegroundColor Red
    exit 1
}
Write-Host "✅ 自定义图标列表：" -ForegroundColor Green
$iconFiles | ForEach-Object { Write-Host "   - $($_.Name) ($($_.Length)字节)" }

# ==================== 第二步：替换源码中的.ico文件（基础替换） ====================
# 定义7-Zip源码中所有可能的图标路径（适配原生脚本的目录结构）
$iconTargetPaths = @(
    "$BuildDirectory\CPP\7zip\Archive\Icons",          # 旧版本路径
    "$BuildDirectory\CPP\7zip\UI\FileManager\Icons",   # 新版本路径
    "$BuildDirectory\CPP\7zip\UI\Explorer\Icons",      # 右键菜单图标路径
    "$BuildDirectory\CPP\7zip\Archive\Zip\Icons"       # 格式专属图标路径
)

# 遍历路径，替换所有找到的图标
$replacedCount = 0
foreach ($targetPath in $iconTargetPaths) {
    if (Test-Path $targetPath) {
        # 强制覆盖原始图标
        Copy-Item -Force -Path "$iconSourcePath\*.ico" -Destination $targetPath
        $currentReplaced = (Get-ChildItem -Path $targetPath -Filter *.ico).Count
        $replacedCount += $currentReplaced
        Write-Host "✅ 已替换 $targetPath 下的 $currentReplaced 个图标" -ForegroundColor Green
    }
}

if ($replacedCount -eq 0) {
    Write-Host "⚠️ 警告：未找到可替换的图标路径！以下是源码中所有.ico文件路径：" -ForegroundColor Yellow
    Get-ChildItem -Path "$BuildDirectory\CPP\7zip" -Recurse -Filter *.ico -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "   - $($_.FullName)"
    }
} else {
    Write-Host "✅ 总计替换 $replacedCount 个图标文件" -ForegroundColor Green
}

# ==================== 第三步：替换编译后EXE的内嵌资源（关键！解决图标未生效） ====================
# 1. 下载ResourceHacker（在线编译环境无此工具，需自动下载）
$rhDir = "$BuildDirectory\Tools"
$rhExePath = "$rhDir\ResourceHacker.exe"
if (-not (Test-Path $rhExePath)) {
    Write-Host "✅ 正在下载ResourceHacker工具..." -ForegroundColor Green
    # 创建Tools目录
    New-Item -ItemType Directory -Path $rhDir -Force | Out-Null
    # 下载并解压
    $rhZipUrl = "https://www.angusj.com/resourcehacker/resource_hacker.zip"
    $rhZipPath = "$rhDir\rh.zip"
    Invoke-WebRequest -Uri $rhZipUrl -OutFile $rhZipPath -TimeoutSec 30
    Expand-Archive -Path $rhZipPath -DestinationPath $rhDir -Force
    Remove-Item -Path $rhZipPath -Force
    Write-Host "✅ ResourceHacker下载完成：$rhExePath" -ForegroundColor Green
}

# 2. 定义需要替换内嵌图标的EXE文件（编译后产物路径，适配原生Build.ps1）
$exePaths = @(
    "$BuildDirectory\CPP\7zip\Bundles\Format7zF\7zFM.exe",  # 7-Zip管理器主程序
    "$BuildDirectory\CPP\7zip\Bundles\Format7z\7zG.exe",     # 7-Zip图形化程序
    "$BuildDirectory\CPP\7zip\UI\Console\7z.exe"             # 7-Zip命令行程序
)

# 3. 替换EXE内嵌图标（MAINICON/IDR_MAINFRAME是7-Zip的图标资源名）
$mainIconPath = "$iconSourcePath\7z.ico"  # 主图标文件（需确保存在）
if (Test-Path $mainIconPath) {
    foreach ($exePath in $exePaths) {
        if (Test-Path $exePath) {
            Write-Host "✅ 替换 $exePath 的内嵌图标..." -ForegroundColor Green
            # ResourceHacker命令行替换图标（覆盖原有资源）
            & $rhExePath -open $exePath -save $exePath -action addoverwrite `
              -res $mainIconPath -mask ICONGROUP,MAINICON,0
            & $rhExePath -open $exePath -save $exePath -action addoverwrite `
              -res $mainIconPath -mask ICONGROUP,IDR_MAINFRAME,0
            Write-Host "✅ $exePath 内嵌图标替换完成" -ForegroundColor Green
        } else {
            Write-Host "⚠️ 未找到EXE文件：$exePath" -ForegroundColor Yellow
        }
    }
} else {
    Write-Host "❌ 主图标文件 $mainIconPath 不存在，跳过内嵌图标替换" -ForegroundColor Red
}

Write-Host "`n===== [自定义图标替换] 执行完成 =====`n" -ForegroundColor Cyan

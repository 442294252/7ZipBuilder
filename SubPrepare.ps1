<#
  核心作用：在线编译时替换7-Zip源码中的图标
  放置位置：仓库根目录（和AutoBuild.ps1同目录）
  依赖：根目录必须有FileIcons文件夹，且内含要替换的.ico文件
#>
param(
    # 必须严格匹配官方脚本的参数（一字不能改，否则不会被调用）
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildDirectory,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

# ==================== 第一步：调试日志（关键！用于Actions中查问题） ====================
Write-Host "`n===== [自定义图标替换] 开始执行 =====`n" -ForegroundColor Cyan
Write-Host "✅ 编译目录（BuildDirectory）：$BuildDirectory"
Write-Host "✅ 7-Zip版本（BuildVersion）：$BuildVersion"
Write-Host "✅ 当前脚本路径：$PSScriptRoot"
Write-Host "✅ 检查FileIcons文件夹是否存在：$(Test-Path "$PSScriptRoot\FileIcons")"

# 列出FileIcons中的图标文件（确认文件已上传）
$iconFiles = Get-ChildItem -Path "$PSScriptRoot\FileIcons" -Filter *.ico -ErrorAction SilentlyContinue
if ($iconFiles) {
    Write-Host "✅ FileIcons中的图标文件：" -ForegroundColor Green
    $iconFiles | ForEach-Object { Write-Host "   - $($_.Name)" }
} else {
    Write-Host "❌ 警告：FileIcons文件夹中未找到.ico文件！" -ForegroundColor Red
    exit 1 # 终止脚本，避免继续编译
}

# ==================== 第二步：定位7-Zip源码的图标路径（适配多版本） ====================
# 定义7-Zip不同版本可能的图标路径（按需调整，优先搜索）
$iconTargetPaths = @(
    "$BuildDirectory\CPP\7zip\Archive\Icons",          # 旧版本默认路径
    "$BuildDirectory\CPP\7zip\UI\FileManager\Icons",   # 新版本（如24.09+）路径
    "$BuildDirectory\CPP\7zip\Archive\Zip\Icons",      # 部分版本细分路径
    "$BuildDirectory\CPP\7zip\Icons"                   # 兜底路径
)

# 自动搜索存在的图标路径
$validTargetPath = $null
foreach ($path in $iconTargetPaths) {
    if (Test-Path $path) {
        $validTargetPath = $path
        Write-Host "✅ 找到7-Zip源码图标路径：$validTargetPath" -ForegroundColor Green
        break
    }
}

if (-not $validTargetPath) {
    Write-Host "❌ 错误：未找到7-Zip源码中的图标目录！" -ForegroundColor Red
    # 列出源码中所有.ico文件，方便排查（Actions日志中可看）
    Write-Host "🔍 搜索源码中所有.ico文件："
    Get-ChildItem -Path "$BuildDirectory\CPP\7zip" -Recurse -Filter *.ico -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Host "   - $($_.FullName)"
    }
    exit 1
}

# ==================== 第三步：替换图标（覆盖原始文件） ====================
try {
    # 复制自定义图标到源码路径（-Force强制覆盖）
    Copy-Item -Force -Path "$PSScriptRoot\FileIcons\*.ico" -Destination $validTargetPath
    Write-Host "✅ 图标替换完成！" -ForegroundColor Green
    
    # 验证替换结果
    $replacedIcons = Get-ChildItem -Path $validTargetPath -Filter *.ico
    Write-Host "✅ 替换后目标路径的图标：" -ForegroundColor Green
    $replacedIcons | ForEach-Object { Write-Host "   - $($_.Name) | 大小：$($_.Length)字节" }
}
catch {
    Write-Host "❌ 图标替换失败：$($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

Write-Host "`n===== [自定义图标替换] 执行完成 =====`n" -ForegroundColor Cyan

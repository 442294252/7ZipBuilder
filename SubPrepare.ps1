param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$BuildDirectory,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$BuildVersion
)

# 核心：基于脚本所在目录，拼接你的Resources完整路径（完美匹配当前目录结构）
$resDir = "$PSScriptRoot\Resources"

Write-Host "`n===== [资源替换] 开始执行（适配当前目录结构） =====`n" -ForegroundColor Cyan
Write-Host "✅ 源码目录：$BuildDirectory"
Write-Host "✅ 资源根目录：$resDir"

# 1. 替换格式图标（对应 Resources\FileIcons）
$iconSource = "$resDir\FileIcons\*.ico"
$iconTarget = "$BuildDirectory\CPP\7zip\Archive\Icons"
Copy-Item -Force -Recurse -Path $iconSource -Destination $iconTarget
Write-Host "✅ 格式图标替换完成" -ForegroundColor Green

# 2. 替换Format7zF.rc（对应 Resources\Format7zF.rc）
$rc7zSource = "$resDir\Format7zF.rc"
$rc7zTarget = "$BuildDirectory\CPP\7zip\Bundles\Format7zF\resource.rc"
Copy-Item -Force -Path $rc7zSource -Destination $rc7zTarget
Write-Host "✅ Format7zF.rc替换完成" -ForegroundColor Green

# 3. 替换Fm.rc（对应 Resources\Fm.rc）
$rcFmSource = "$resDir\Fm.rc"
$rcFmTarget = "$BuildDirectory\CPP\7zip\Bundles\Fm\resource.rc"
Copy-Item -Force -Path $rcFmSource -Destination $rcFmTarget
Write-Host "✅ Fm.rc替换完成" -ForegroundColor Green

# 4. 替换工具栏图标（对应 Resources\ToolBarIcons）
$toolbarSource = "$resDir\ToolBarIcons\*"
$toolbarTarget = "$BuildDirectory\CPP\7zip\UI\FileManager"
Copy-Item -Force -Path $toolbarSource -Destination $toolbarTarget
Write-Host "✅ 工具栏图标替换完成" -ForegroundColor Green

Write-Host "`n===== [资源替换] 执行完毕 =====`n" -ForegroundColor Cyan

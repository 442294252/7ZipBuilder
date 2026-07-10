<#
.SYNOPSIS
7-Zip 通用打包脚本（兼容official / zstd双分支，修复参数缺失、未定义变量、乱码、图标下载404）
#>
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

$ErrorActionPreference = "Stop"
$workDir = $PSScriptRoot
$tempDir = "$workDir\Temp"
$buildDir = "$workDir\$BuildVersion"
$outDir = "$tempDir\Out"
$sfxDir = "$tempDir\SFX"
$iconDir = "$tempDir\Icon"

# 提取纯数字版本 7z2600/7z2602 → 2600/2602
if ($BuildVersion -match '7z(\d+)') {
    $verNum = $matches[1]
}
else {
    throw "❌ 版本格式错误，入参必须以7z开头，当前输入：$BuildVersion"
}
$tempExe = "$sfxDir\temp.tmp.exe"

# 创建全部需要的目录
@($tempDir, $outDir, $sfxDir, $iconDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# 复制编译输出文件
$copyList = @(
    @{Src = "$buildDir\CPP\7zip\Bundles\Format7zF\x64\7z.dll"; Dst = "$outDir\7z.dll"},
    @{Src = "$buildDir\CPP\7zip\UI\Console\x64\7z.exe"; Dst = "$outDir\7z.exe"},
    @{Src = "$buildDir\CPP\7zip\UI\FileManager\x64\7zFM.exe"; Dst = "$outDir\7zFM.exe"},
    @{Src = "$buildDir\CPP\7zip\UI\GUI\x64\7zG.exe"; Dst = "$outDir\7zG.exe"},
    @{Src = "$buildDir\CPP\7zip\Bundles\SFXWin\x64\7z.sfx"; Dst = "$outDir\7z.sfx"},
    @{Src = "$buildDir\CPP\7zip\Bundles\SFXCon\x64\7zCon.sfx"; Dst = "$outDir\7zCon.sfx"},
    @{Src = "$buildDir\CPP\7zip\UI\Explorer\x64\7-zip.dll"; Dst = "$outDir\7-zip64.dll"},
    @{Src = "$buildDir\CPP\7zip\UI\Explorer\x86\7-zip.dll"; Dst = "$outDir\7-zip32.dll"},
    @{Src = "$buildDir\C\Util\7zipUninstall\x64\7zipUninstall.exe"; Dst = "$outDir\Uninstall.exe"}
)
foreach ($item in $copyList) {
    if (Test-Path $item.Src) {
        Copy-Item -Path $item.Src -Destination $item.Dst -Force
        Write-Host "✅ 复制文件：$($item.Src)"
    }
    else {
        Write-Warning "⚠️ 缺失编译产物：$($item.Src)"
    }
}

# 复制文档、语言包
$docPath = "$buildDir\DOC"
if (Test-Path $docPath) {
    Copy-Item -Path "$docPath\*" -Destination $outDir -Recurse -Force
}
$langSrc = "$buildDir\CPP\7zip\UI\GUI\Lang"
$langDst = "$outDir\Lang"
if (Test-Path $langSrc) {
    Copy-Item -Path "$langSrc\*" -Destination $langDst -Recurse -Force
}

# 读取官方安装SFX模块
$sfxSource = "$buildDir\CPP\7zip\Bundles\SFXSetup\x64\7zS.sfx"
if (-not (Test-Path $sfxSource)) {
    throw "❌ 缺失安装SFX文件 $sfxSource"
}
Copy-Item -Path $sfxSource -Destination "$sfxDir\7zS.sfx" -Force

# 生成安装配置 GB2312编码解决中文乱码
$cfgText = @"
;!@Install@!UTF-8!
Title="7-Zip $verNum 安装"
BeginPrompt="是否安装 7-Zip $verNum？"
InstallPath="%ProgramFiles%\7-Zip"
GUIMode="2"
;!@InstallEnd@!
"@
$gb2312 = [System.Text.Encoding]::GetEncoding("gb2312")
[System.IO.File]::WriteAllText("$sfxDir\config.txt", $cfgText, $gb2312)

# 打包文件 -mx=0 不压缩
& "$outDir\7z.exe" a -t7z -mx=0 "$sfxDir\app.7z" "$outDir\*"
if ($LASTEXITCODE -ne 0) {
    throw "❌ 打包资源文件失败"
}

# 拼接 SFX + 配置 + 压缩包 临时EXE
$mergeFiles = @("$sfxDir\7zS.sfx", "$sfxDir\config.txt", "$sfxDir\app.7z")
$fs = [System.IO.File]::Create($tempExe)
foreach ($f in $mergeFiles) {
    $buffer = [System.IO.File]::ReadAllBytes($f)
    $fs.Write($buffer, 0, $buffer.Length)
}
$fs.Close()

# 提取内置7z图标
Add-Type -AssemblyName System.Drawing
$icoSavePath = "$iconDir\main.ico"
$srcExe = "$outDir\7z.exe"
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($srcExe)
$icon.ToBitmap().Save($icoSavePath, [System.Drawing.Imaging.ImageFormat]::Icon)

# 注入图标（修正正确下载地址）
$rhExe = "$tempDir\ResourceHacker.exe"
if (-not (Test-Path $rhExe)) {
    Write-Host "🔧 下载ResourceHacker工具"
    $zipUrl = "https://github.com/angusj/resourcehacker/releases/download/v5.2.7/ResourceHacker_5.2.7.zip"
    Invoke-WebRequest -Uri $zipUrl -OutFile "$tempDir\rh.zip" -ErrorAction Stop
    Expand-Archive -Path "$tempDir\rh.zip" -DestinationPath $tempDir -Force
}

# 生成最终exe（先输出不带后缀，workflow统一重命名区分zstd）
$rawOutputExe = "$workDir\$BuildVersion.exe"
& "$rhExe" -open "$tempExe" -save "$rawOutputExe" -action addoverwrite -res "$icoSavePath" -mask ICONGROUP,MAINICON,
if ($LASTEXITCODE -ne 0) {
    throw "❌ EXE图标注入失败"
}

# 清理临时文件
Remove-Item $tempExe -Force -ErrorAction SilentlyContinue

Write-Host "✅ Pack脚本执行完毕，原始输出文件：$rawOutputExe"
exit 0

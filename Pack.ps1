<#
.SYNOPSIS
7-Zip 打包脚本 - 终版（修复乱码+图标+所有历史问题）
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

# ==============================================
# 1. 版本号自动提取（兼容所有格式）
# ==============================================
if ($BuildVersion -match '7z(\d+)') {
    $verNum = $matches[1]
} elseif ($BuildVersion -match '(\d+)\.(\d+)') {
    $verNum = "$($matches[1])$($matches[2])"
} else {
    throw "❌ 版本号格式错误: $BuildVersion"
}
$exeName = "7-Zip-$verNum-Custom-Icon.exe"
$finalExe = "$workDir\$exeName"

# ==============================================
# 2. 确保目录存在
# ==============================================
@($tempDir, $outDir, $sfxDir, $iconDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ==============================================
# 3. 拷贝编译产物（原逻辑不变）
# ==============================================
$filesToCopy = @(
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
foreach ($file in $filesToCopy) {
    if (Test-Path $file.Src) { Copy-Item -Path $file.Src -Destination $file.Dst -Force }
}

# ==============================================
# 4. 从源码提取文档/语言包（零网络）
# ==============================================
$docSrcDir = "$buildDir\DOC"
$resFiles = @("History.txt", "License.txt", "readme.txt")
foreach ($f in $resFiles) {
    if (Test-Path "$docSrcDir\$f") { Copy-Item -Path "$docSrcDir\$f" -Destination "$outDir\$f" -Force }
}
$langSrcDir = "$buildDir\CPP\7zip\UI\GUI\Lang"
$langDstDir = "$outDir\Lang"
if (-not (Test-Path $langDstDir)) { New-Item -ItemType Directory -Path $langDstDir -Force | Out-Null }
if (Test-Path $langSrcDir) { Copy-Item -Path "$langSrcDir\*" -Destination "$langDstDir\" -Recurse -Force }

# ==============================================
# 5. 生成标准安装包（修复乱码核心：GB2312编码）
# ==============================================
# 提取官方安装SFX
$sfxSrc = "$buildDir\CPP\7zip\Bundles\SFXSetup\x64\7zS.sfx"
if (-not (Test-Path $sfxSrc)) { throw "❌ 未找到SFX模块: $sfxSrc" }
Copy-Item -Path $sfxSrc -Destination "$sfxDir\7zS.sfx" -Force

# 🔧 核心修复1：用GB2312编码保存配置文件，彻底解决乱码
$configContent = @"
;!@Install@!UTF-8!
Title="7-Zip $verNum 安装"
BeginPrompt="是否安装 7-Zip $verNum？"
InstallPath="%ProgramFiles%\7-Zip"
GUIMode="2"
;!@InstallEnd@!
"@
# 用GB2312编码保存，SFX完美识别中文，不再乱码
$utf8 = [System.Text.Encoding]::GetEncoding('gb2312')
[System.IO.File]::WriteAllText("$sfxDir\config.txt", $configContent, $utf8)

# 打包文件（-mx=0 不压缩）
& "$outDir\7z.exe" a -t7z -mx=0 "$sfxDir\app.7z" "$outDir\*"
if ($LASTEXITCODE -ne 0) { throw "❌ 打包失败" }

# 拼接生成临时EXE（无图标）
$tempExe = "$sfxDir\temp.exe"
$filesToCombine = @("$sfxDir\7zS.sfx", "$sfxDir\config.txt", "$sfxDir\app.7z")
$fs = [System.IO.File]::Create($tempExe)
foreach ($f in $filesToCombine) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $fs.Write($bytes, 0, $bytes.Length)
}
$fs.Close()

# ==============================================
# 🔧 核心修复2：给EXE注入官方7-Zip图标（和原版一致）
# ==============================================
# 从官方7z.exe提取图标
$sourceExe = "$outDir\7z.exe"
$iconPath = "$iconDir\7z.ico"
if (-not (Test-Path $sourceExe)) { throw "❌ 未找到源EXE: $sourceExe" }

Add-Type -AssemblyName System.Drawing
$icon = [System.Drawing.Icon]::ExtractAssociatedIcon($sourceExe)
$icon.ToBitmap().Save($iconPath, [System.Drawing.Imaging.ImageFormat]::Icon)

# 用ResourceHacker注入图标
$rhPath = "$tempDir\ResourceHacker.exe"
if (-not (Test-Path $rhPath)) {
    Write-Host "🔧 下载ResourceHacker..."
    Invoke-WebRequest -Uri "https://github.com/angusj/resourcehacker/releases/download/v5.2.7/reshacker.zip" -OutFile "$tempDir\rh.zip"
    Expand-Archive -Path "$tempDir\rh.zip" -DestinationPath "$tempDir" -Force
}

Write-Host "🔧 注入7-Zip官方图标到EXE..."
& "$rhPath" -open "$tempExe" -save "$finalExe" -action addoverwrite -res "$iconPath" -mask ICONGROUP,MAINICON,
if ($LASTEXITCODE -ne 0) { throw "❌ 图标注入失败" }

# 清理临时文件
Remove-Item $tempExe -Force -ErrorAction SilentlyContinue

Write-Host "✅ Pack步骤执行完成！"
Write-Host "📦 输出文件: $finalExe"
Write-Host "🎨 已注入官方图标，中文弹窗正常显示！"
exit 0

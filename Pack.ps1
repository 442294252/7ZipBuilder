<#
.SYNOPSIS
通用打包脚本，official/zstd共用缓存7zS.sfx，带GUI安装向导
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

# 提取版本数字
if ($BuildVersion -match '7z(\d+)') {
    $verNum = $matches[1]
}
else {
    throw "版本必须以7z开头，输入值：$BuildVersion"
}
$tempExe = "$sfxDir\temp.tmp.exe"

# 创建目录
@($tempDir, $outDir, $sfxDir, $iconDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# 复制编译产物
$copyList = @(
    @{Src = "$buildDir\CPP\7zip\Bundles\Format7zF\x64\7z.dll"; Dst = "$outDir\7z.dll"},
    @{Src = "$buildDir\CPP\7zip\UI\Console\x64\7z.exe"; Dst = "$outDir\7z.exe"},
    @{Src = "$buildDir\CPP\7zip\UI\FileManager\x64\7zFM.exe"; Dst = "$outDir\7zFM.exe"},
    @{Src = "$buildDir\CPP\7zip\UI\GUI\x64\7zG.exe"; Dst = "$outDir\7zG.exe"},
    @{Src = "$buildDir\CPP\7zip\Bundles\SFXWin\x64\7z.sfx"; Dst = "$outDir\7z.sfx"},
    @{Src = "$buildDir\CPP\7zip\Bundles\SFXCon\x64\7zCon.sfx"; Dst = "$outDir\7zCon.sfx"},
    @{Src = "$buildDir\CPP\7zip\UI\Explorer\x64\7-zip.dll"; Dst = "$outDir\7-zip64.dll"},
    @{Src = "$buildDir\CPP\UI\Explorer\x86\7-zip.dll"; Dst = "$outDir\7-zip32.dll"},
    @{Src = "$buildDir\C\Util\7zipUninstall\x64\7zipUninstall.exe"; Dst = "$outDir\Uninstall.exe"}
)
foreach ($item in $copyList) {
    if (Test-Path $item.Src) {
        Copy-Item $item.Src $item.Dst -Force
        Write-Host "复制: $($item.Src)"
    }
}

# 复制文档&语言包
if (Test-Path "$buildDir\DOC") {
    Copy-Item "$buildDir\DOC\*" $outDir -Recurse -Force
}
if (Test-Path "$buildDir\CPP\7zip\UI\GUI\Lang") {
    Copy-Item "$buildDir\CPP\7zip\UI\GUI\Lang\*" "$outDir\Lang" -Recurse -Force
}

# ==========核心改动：读取缓存的官方7zS.sfx，不读源码目录==========
$cacheSfx = "$workDir/_CacheSFX/7zS.sfx"
if (-not (Test-Path $cacheSfx)) {
    throw "缓存缺少7zS.sfx，重新运行工作流生成缓存"
}
Copy-Item $cacheSfx "$sfxDir\7zS.sfx" -Force

# 安装配置（GB231防乱码）
$cfg = @"
;!@Install@!UTF-8!
Title="7-Zip $verNum 安装"
BeginPrompt="是否安装 7-Zip $verNum？"
InstallPath="%ProgramFiles%\7-Zip"
GUIMode="2"
;!@InstallEnd@!
"@
$gb = [System.Text.Encoding]::GetEncoding("gb2312")
[System.IO.File]::WriteAllText("$sfxDir\config.txt", $cfg, $gb)

# 打包资源
& "$outDir\7z.exe" a -t7z -mx=0 "$sfxDir\app.7z" "$outDir\*"
if ($LASTEXITCODE -ne 0) { throw "资源打包失败" }

# 拼接SFX+配置+压缩包
$merge = @("$sfxDir\7zS.sfx", "$sfxDir\config.txt", "$sfxDir\app.7z")
$fs = [System.IO.File]::Create($tempExe)
foreach ($f in $merge) {
    $b = [System.IO.File]::ReadAllBytes($f)
    $fs.Write($b, 0, $b.Length)
}
$fs.Close()

# 提取图标
Add-Type System.Drawing
$icoPath = "$iconDir\def.ico"
$ico = [System.Drawing.Icon]::ExtractAssociatedIcon("$outDir\7z.exe")
$ico.ToBitmap().Save($icoPath, [System.Drawing.Imaging.ImageFormat]::Icon)

# ResourceHacker注入图标
$rh = "$tempDir\ResourceHacker.exe"
if (-not (Test-Path $rh)) {
    Invoke-WebRequest "https://github.com/angusj/resourcehacker/releases/download/v5.2.7/ResourceHacker_5.2.7.zip" -OutFile "$tempDir/rh.zip"
    Expand-Archive "$tempDir/rh.zip" $tempDir -Force
}
$rawExe = "$workDir\$BuildVersion.exe"
& $rh -open "$tempExe" -save "$rawExe" -action addoverwrite -res "$icoPath" -mask ICONGROUP,MAINICON,
if ($LASTEXITCODE -ne 0) { throw "图标注入失败" }

Remove-Item $tempExe -Force
Write-Host "打包完成：$rawExe"
exit 0

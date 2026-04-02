<#
.SYNOPSIS
7-Zip 打包脚本 - 终版（解决安装包静默、网络超时、自动版本号问题）
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

# ==============================================
# 1. 版本号自动提取（兼容所有格式，解决空值问题）
# ==============================================
if ($BuildVersion -match '7z(\d+)') {
    $verNum = $matches[1] # 提取2600/2700
} elseif ($BuildVersion -match '(\d+)\.(\d+)') {
    $verNum = "$($matches[1])$($matches[2])" # 26.00 -> 2600
} else {
    throw "❌ 版本号格式错误: $BuildVersion"
}

# 自动生成文件名/Release名（2600/2700自动变）
$exeName = "7-Zip-$verNum-Custom-Icon.exe"
$finalExe = "$workDir\$exeName"

# ==============================================
# 2. 确保目录存在
# ==============================================
@($tempDir, $outDir, $sfxDir) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
    }
}

# ==============================================
# 3. 拷贝编译产物（完全保留原逻辑）
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
    if (Test-Path $file.Src) {
        Copy-Item -Path $file.Src -Destination $file.Dst -Force
        Write-Host "✅ 已拷贝: $($file.Src)"
    } else {
        Write-Warning "⚠️ 源文件不存在: $($file.Src)"
    }
}

# ==============================================
# 4. 从源码提取文档/语言包（彻底删除外部下载，解决网络问题）
# ==============================================
$docSrcDir = "$buildDir\DOC"
$resFiles = @(
    @{Src = "$docSrcDir\History.txt"; Dst = "$outDir\History.txt"},
    @{Src = "$docSrcDir\License.txt"; Dst = "$outDir\License.txt"},
    @{Src = "$docSrcDir\readme.txt"; Dst = "$outDir\readme.txt"}
)
foreach ($f in $resFiles) {
    if (Test-Path $f.Src) {
        Copy-Item -Path $f.Src -Destination $f.Dst -Force
        Write-Host "✅ 已拷贝文档: $($f.Src)"
    }
}

# 拷贝语言包（从源码提取，无下载）
$langSrcDir = "$buildDir\CPP\7zip\UI\GUI\Lang"
$langDstDir = "$outDir\Lang"
if (-not (Test-Path $langDstDir)) {
    New-Item -ItemType Directory -Path $langDstDir -Force | Out-Null
}
if (Test-Path $langSrcDir) {
    Copy-Item -Path "$langSrcDir\*" -Destination "$langDstDir\" -Recurse -Force
    Write-Host "✅ 已拷贝语言包"
}

# ==============================================
# 5. 生成标准安装包（带安装向导，解决直接解压到桌面问题）
# ==============================================
# 提取官方安装专用SFX模块（7zS.sfx）
$sfxSrc = "$buildDir\CPP\7zip\Bundles\SFXSetup\x64\7zS.sfx"
if (-not (Test-Path $sfxSrc)) {
    throw "❌ 未找到官方安装SFX模块: $sfxSrc"
}
Copy-Item -Path $sfxSrc -Destination "$sfxDir\7zS.sfx" -Force

# 生成标准安装配置（弹出安装向导、可选择路径）
$configContent = @"
;!@Install@!UTF-8!
Title="7-Zip $verNum 安装 (Custom Icon)"
BeginPrompt="是否安装 7-Zip $verNum？"
InstallPath="%ProgramFiles%\7-Zip"
GUIMode="2"
;!@InstallEnd@!
"@
Set-Content -Path "$sfxDir\config.txt" -Value $configContent -Encoding ASCII -Force

# 打包文件（-mx=0 完全不压缩，保留要求）
& "$outDir\7z.exe" a -t7z -mx=0 "$sfxDir\app.7z" "$outDir\*"
if ($LASTEXITCODE -ne 0) {
    throw "❌ 文件打包失败，退出码: $LASTEXITCODE"
}

# 拼接SFX+配置+包，生成最终安装EXE
$filesToCombine = @("$sfxDir\7zS.sfx", "$sfxDir\config.txt", "$sfxDir\app.7z")
$fs = [System.IO.File]::Create($finalExe)
foreach ($f in $filesToCombine) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $fs.Write($bytes, 0, $bytes.Length)
}
$fs.Close()

Write-Host "✅ Pack步骤执行完成！"
Write-Host "📦 输出文件: $finalExe"
Write-Host "📦 文件名: $exeName"
exit 0

<#
.SYNOPSIS
打包阶段：生成带 Custom Icon 的标准安装包
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
$packDir = "$tempDir\Pack"
$sfxDir = "$tempDir\SFX"

# 确保目录存在
@($tempDir, $outDir, $packDir, $sfxDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ==============================================
# 核心修复：安全提取版本号（万能逻辑）
# ==============================================
# $BuildVersion 可能是 "7z2600" 或 "26.00"，统一处理
if ($BuildVersion -match '7z(\d+)') {
    $verNum = $matches[1]  # 提取 2600
} elseif ($BuildVersion -match '(\d+)\.(\d+)') {
    $verNum = $matches[1] + $matches[2] # 提取 2600
} else {
    Write-Error "❌ 版本号格式错误: $BuildVersion"
    exit 1
}

# 自动生成的文件名
$exeFileName = "7-Zip-$verNum-Custom-Icon.exe"
$finalExe = "$workDir\$exeFileName"

# ==============================================
# 1. 拷贝编译产物
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
    }
}

# ==============================================
# 2. 拷贝文档/语言包
# ==============================================
$docSrcDir = "$buildDir\DOC"
$resFiles = @(
    @{Src = "$docSrcDir\History.txt"; Dst = "$outDir\History.txt"},
    @{Src = "$docSrcDir\License.txt"; Dst = "$outDir\License.txt"},
    @{Src = "$docSrcDir\readme.txt"; Dst = "$outDir\readme.txt"}
)
foreach ($f in $resFiles) {
    if (Test-Path $f.Src) { Copy-Item -Path $f.Src -Destination $f.Dst -Force }
}

$langSrcDir = "$buildDir\CPP\7zip\UI\GUI\Lang"
$langDstDir = "$outDir\Lang"
if (-not (Test-Path $langDstDir)) { New-Item -ItemType Directory -Path $langDstDir -Force | Out-Null }
if (Test-Path $langSrcDir) { Copy-Item -Path "$langSrcDir\*" -Destination "$langDstDir\" -Recurse -Force }

# ==============================================
# 3. 生成标准安装包（有向导、可选择路径）
# ==============================================
# 1. 获取安装 SFX 模块
$sfxSrc = "$buildDir\CPP\7zip\Bundles\SFXSetup\x64\7zS.sfx"
if (-not (Test-Path $sfxSrc)) { throw "❌ 未找到安装模块: $sfxSrc" }
Copy-Item -Path $sfxSrc -Destination "$sfxDir\7zS.sfx" -Force

# 2. 生成安装配置
$configContent = @"
;!@Install@!UTF-8!
Title="7-Zip $verNum 安装 (Custom)"
BeginPrompt="是否安装 7-Zip $verNum ?"
InstallPath="%ProgramFiles%\7-Zip-$verNum"
GUIMode="2"
;!@InstallEnd@!
"@
Set-Content -Path "$sfxDir\config.txt" -Value $configContent -Encoding UTF8 -Force

# 3. 打包文件（不压缩）
& "$outDir\7z.exe" a -t7z -mx=0 "$sfxDir\app.7z" "$outDir\*"
if ($LASTEXITCODE -ne 0) { throw "❌ 打包文件失败" }

# 4. 拼接生成最终 EXE
$files = @("$sfxDir\7zS.sfx", "$sfxDir\config.txt", "$sfxDir\app.7z")
$fs = [System.IO.File]::Create($finalExe)
foreach ($f in $files) {
    $bytes = [System.IO.File]::ReadAllBytes($f)
    $fs.Write($bytes, 0, $bytes.Length)
}
$fs.Close()

Write-Host "✅ 打包成功！"
Write-Host "📁 输出文件: $finalExe"
Write-Host "📁 文件名: $exeFileName"

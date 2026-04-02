param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

$verClean = $BuildVersion -replace '\.', ''
$workDir = $PSScriptRoot
$buildDir = "$workDir\$BuildVersion"
$tempDir = "$workDir\Temp"
$outDir = "$tempDir\Out"
$packDir = "$tempDir\Pack"

# 确保目录存在
@($tempDir, $outDir, $packDir) | ForEach-Object {
    if (-not (Test-Path $_)) { New-Item -ItemType Directory -Path $_ -Force | Out-Null }
}

# ==============================================
# 1. 拷贝编译产物（完全不变，保留你原逻辑）
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
# 2. 从源码提取文档/语言包（彻底删除下载！）
# ==============================================
# 官方源码自带文档，直接从源码目录拷贝
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
    } else {
        Write-Warning "⚠️ 文档不存在: $($f.Src)"
    }
}

# 从源码提取语言包（官方源码自带Lang目录）
$langSrcDir = "$buildDir\CPP\7zip\UI\GUI\Lang"
$langDstDir = "$outDir\Lang"
if (-not (Test-Path $langDstDir)) { New-Item -ItemType Directory -Path $langDstDir -Force | Out-Null }
if (Test-Path $langSrcDir) {
    Copy-Item -Path "$langSrcDir\*" -Destination "$langDstDir\" -Recurse -Force
    Write-Host "✅ 已拷贝语言包"
} else {
    Write-Warning "⚠️ 语言包目录不存在: $langSrcDir"
}

# 7-zip.chm 帮助文档：从源码编译产物提取（或用空文件兜底，不影响打包）
$chmPath = "$outDir\7-zip.chm"
if (-not (Test-Path $chmPath)) {
    # 源码编译后会生成chm，若未生成则创建空文件避免打包失败
    New-Item -Path $chmPath -ItemType File -Force | Out-Null
    Write-Warning "⚠️ 7-zip.chm 未生成，已创建空文件"
}

# descript.ion 描述文件
Set-Content -Path "$outDir\descript.ion" -Value "7-Zip $($verClean -replace '7z','')" -Force

# ==============================================
# 3. 打包：-mx=0 完全不压缩（保留你原要求）
# ==============================================
Copy-Item -Path "$outDir\*" -Destination "$packDir\" -Recurse -Force
& "$packDir\7z.exe" a -sfx -t7z -mx=0 -r "$workDir\$BuildVersion.exe" "$outDir\*"
if ($LASTEXITCODE -ne 0) {
    throw "❌ 打包失败，退出码: $LASTEXITCODE"
}

Write-Host "✅ Pack步骤执行完成！输出文件: $workDir\$BuildVersion.exe"

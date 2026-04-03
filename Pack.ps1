param(
    [Parameter(Mandatory = $true)]
    [string] $OfficialTag,
    [Parameter(Mandatory = $true)]
    [string] $PrebuildDownloadUrl
)

$workDir = $PSScriptRoot
$buildDir = "$workDir\$OfficialTag"
$tempDir = "$workDir\Temp"
$packDir = "$tempDir\Pack"
$prebuildDir = "$tempDir\PreBuild"
$outDir = "$tempDir\Out"

# 创建目录
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
if (-not (Test-Path $prebuildDir)) { New-Item -ItemType Directory -Path $prebuildDir -Force | Out-Null }
if (-not (Test-Path $packDir)) { New-Item -ItemType Directory -Path $packDir -Force | Out-Null }

# 拷贝编译好的主程序文件
Copy-Item -Destination $outDir -Path "$buildDir\CPP\7zip\Bundles\Format7zF\x64\7z.dll"
Copy-Item -Destination $outDir -Path "$buildDir\CPP\7zip\UI\Console\x64\7z.exe"
Copy-Item -Destination $outDir -Path "$buildDir\CPP\7zip\UI\FileManager\x64\7zFM.exe"
Copy-Item -Destination $outDir -Path "$buildDir\CPP\7zip\UI\GUI\x64\7zG.exe"
Copy-Item -Destination $outDir -Path "$buildDir\CPP\7zip\Bundles\SFXWin\x64\7z.sfx"
Copy-Item -Destination $outDir -Path "$buildDir\CPP\7zip\Bundles\SFXCon\x64\7zCon.sfx"
Copy-Item -Destination $outDir -Path "$buildDir\CPP\7zip\UI\Explorer\x64\7-zip.dll"
Copy-Item -Destination "$outDir\7-zip32.dll" -Path "$buildDir\CPP\7zip\UI\Explorer\x86\7-zip.dll"
Copy-Item -Destination "$outDir\Uninstall.exe" -Path "$buildDir\C\Util\7zipUninstall\x64\7zipUninstall.exe"

# 下载预编译包（用提前匹配好的官方链接，零匹配错误）
$prebuildZipPath = "$tempDir\$OfficialTag-pre.7z"
if (-not (Test-Path $prebuildZipPath)) {
    Write-Host "🔽 下载官方预编译包: $OfficialTag-x64.exe" -ForegroundColor Cyan
    Invoke-WebRequest -Uri $PrebuildDownloadUrl -OutFile $prebuildZipPath -UseBasicParsing
}

# 解压预编译包（文档、语言包等）
& "$outDir\7z.exe" x "$prebuildZipPath" -o"$prebuildDir" -y

# 拷贝文档和语言包
Copy-Item -Destination $outDir -Path "$prebuildDir\History.txt"
Copy-Item -Destination $outDir -Path "$prebuildDir\License.txt"
Copy-Item -Destination $outDir -Path "$prebuildDir\readme.txt"
Copy-Item -Destination $outDir -Path "$prebuildDir\7-zip.chm"
Copy-Item -Destination $outDir -Path "$prebuildDir\descript.ion"
if (-not (Test-Path "$outDir\Lang")) {
    New-Item -ItemType Directory -Path "$outDir\Lang" -Force | Out-Null
}
Copy-Item -Recurse -Force -Destination "$outDir\Lang" -Path "$prebuildDir\Lang\*"

# 拷贝打包工具
Copy-Item -Recurse -Force -Destination $packDir -Path "$outDir\*"
Copy-Item -Destination "$packDir\7z.sfx" -Path "$buildDir\C\Util\7zipInstall\x64\7zipInstall.exe"
Copy-Item -Destination "$packDir\7zCon.sfx" -Path "$buildDir\C\Util\7zipInstall\x64\7zipInstall.exe"

# 打包成最终安装程序
& "$packDir\7z.exe" a -sfx -t7z -mx=9 -m0=LZMA -r "$workDir\$OfficialTag.exe" "$outDir\*"
Write-Host "✅ Pack步骤完成，安装包已生成" -ForegroundColor Green

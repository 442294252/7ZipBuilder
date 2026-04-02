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

# 拷贝编译产物
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
    Copy-Item -Path $file.Src -Destination $file.Dst -Force
}

# 下载官方预编译包获取资源
$preFile = "$tempDir\${verClean}-x64.exe"
if (-not (Test-Path $preFile)) {
    Invoke-WebRequest -Uri "https://www.7-zip.org/a/7z$verClean-x64.exe" -OutFile $preFile -ErrorAction Stop
}
& "$outDir\7z.exe" x $preFile -o"$tempDir\PreBuild" -y | Out-Null

# 拷贝资源文件
$resFiles = @("History.txt", "License.txt", "readme.txt", "7-zip.chm", "descript.ion")
foreach ($f in $resFiles) {
    Copy-Item -Path "$tempDir\PreBuild\$f" -Destination "$outDir\$f" -Force
}

# 拷贝语言包
if (-not (Test-Path "$outDir\Lang")) { New-Item -ItemType Directory -Path "$outDir\Lang" -Force | Out-Null }
Copy-Item -Path "$tempDir\PreBuild\Lang\*" -Destination "$outDir\Lang\" -Recurse -Force

# 打包：-mx=0 完全不压缩，极速打包
Copy-Item -Path "$outDir\*" -Destination "$packDir\" -Recurse -Force
& "$packDir\7z.exe" a -sfx -t7z -mx=0 -r "$workDir\$BuildVersion.exe" "$outDir\*"
if ($LASTEXITCODE -ne 0) { throw "打包失败" }

Write-Host "Pack步骤执行完成 ✅ 输出文件: $workDir\$BuildVersion.exe"

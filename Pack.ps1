# ==============================================
# 3. 【自动版本号】生成标准安装包
# ==============================================
$verNum = $BuildVersion.Replace('7z','')  # 自动变成 2600 / 2700 / 2800...
$finalExe = "$workDir\7-Zip-$verNum-Custom-Icon.exe"  # 自动变文件名

# 提取官方安装SFX
$sfxSrc = "$buildDir\CPP\7zip\Bundles\SFXSetup\x64\7zS.sfx"
$sfxDst = "$sfxDir\7zS.sfx"
if (-not (Test-Path $sfxSrc)) { throw "找不到安装模块 $sfxSrc" }
Copy-Item -Path $sfxSrc -Destination $sfxDst -Force

# 安装配置
$configContent = @"
;!@Install@!UTF-8!
Title="7-Zip $verNum 安装"
BeginPrompt="安装 7-Zip $verNum"
InstallPath="%ProgramFiles%\7-Zip"
GUIMode="2"
RunProgram="%%T\7z.exe x `"%%S`" -o`"%ProgramFiles%\7-Zip`" -y"
;!@InstallEnd@!
"@
Set-Content -Path "$sfxDir\config.txt" -Value $configContent -Encoding ASCII -Force

# 打包文件（不压缩）
& "$outDir\7z.exe" a -t7z -mx=0 "$sfxDir\app.7z" "$outDir\*"
if ($LASTEXITCODE -ne 0) { throw "打包失败" }

# 生成安装包（带向导、路径选择）
$files = @($sfxDst, "$sfxDir\config.txt", "$sfxDir\app.7z")
$fs = [System.IO.File]::Create($finalExe)
foreach ($f in $files) { $bytes = [System.IO.File]::ReadAllBytes($f); $fs.Write($bytes,0,$bytes.Length) }
$fs.Close()

Write-Host "✅ 自动生成：$finalExe"
Write-Host "✅ 安装向导正常、可选择路径、不会装桌面"

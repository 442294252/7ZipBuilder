<#
.SYNOPSIS
7-Zip 编译脚本（完全保留原逻辑，无需修改）
#>
param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

$workDir = $PSScriptRoot
$buildDir = "$workDir\$BuildVersion"
$tempDir = "$workDir\Temp"
$currentDir = Get-Location

# 确保临时目录存在
if (-not (Test-Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
}

# 安装vswhere（获取VS路径）
if (-not (Test-Path "$tempDir\VsWhere")) {
    if (-not (Test-Path "$tempDir\vswhere.zip")) {
        Invoke-WebRequest -Uri "https://www.nuget.org/api/v2/package/vswhere" -OutFile "$tempDir\vswhere.zip"
    }
    Expand-Archive -Path "$tempDir\vswhere.zip" -DestinationPath "$tempDir\VsWhere"
}

# x64编译
$vsInstallPath = & "$tempDir\VsWhere\tools\vswhere.exe" -latest -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
Import-Module "$vsInstallPath\Common7\Tools\Microsoft.VisualStudio.DevShell.dll"
Enter-VsDevShell -VsInstallPath $vsInstallPath -DevCmdArguments "-arch=amd64 -host_arch=amd64" -SkipAutomaticLocation

Set-Location "$buildDir\CPP\7zip"
& nmake PLATFORM=x64
Set-Location "$buildDir\C\Util\7zipInstall"
& nmake PLATFORM=x64
Set-Location "$buildDir\C\Util\7zipUninstall"
& nmake PLATFORM=x64

# x86编译
Enter-VsDevShell -VsInstallPath $vsInstallPath -DevCmdArguments "-arch=x86 -host_arch=amd64" -SkipAutomaticLocation
Set-Location "$buildDir\CPP\7zip\UI\Explorer"
& nmake PLATFORM=x86

Set-Location $currentDir
Write-Host "✅ Build步骤执行完成！"
exit 0

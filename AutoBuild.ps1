param(
    [ValidateSet("official","zstd")]
    [string] $BuildMode = "official
)
$workDir = $PSScriptRoot
if ($BuildMode -eq "official") {
    $api = "https://api.github.com/repos/ip7z/7zip/releases/latest"
} else {
    $api = "https://api.github.com/repos/mcmilk/7-Zip-zstd/releases/latest"
}
$release = Invoke-RestMethod -Uri $api
$fullTag = $release.tag_name
if ($BuildMode -eq "official") {
    $verNum = $fullTag -replace '\.', ''
    $prefix = "7z$verNum"
    & "$workDir\Prepare.ps1" -BuildVersion $prefix
    $exeOut = "$prefix-Custom-Icon.exe"
} else {
    $verBase = $fullTag -split "-v" | Select-Object -First 1
    $verNum = $verBase.TrimStart('v') -replace '\.', ''
    $prefix = "7z$verNum"
    & "$workDir\PrepareZstd.ps1" -RawTag $fullTag
    $exeOut = "$prefix-ZS-Custom-Icon.exe"
}
# 编译打包共用
& "$workDir\Build.ps1" -BuildVersion $prefix
& "$workDir\Pack.ps1" -BuildVersion $prefix
Rename-Item "$prefix.exe" $exeOut -Force
Write-Host "✅ 构建完成，输出：$exeOut"

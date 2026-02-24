param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$BuildDirectory,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string]$BuildVersion
)

# 替换格式图标（压缩文件显示的图标）
Copy-Item -Force -Recurse -Path "FileIcons\*.ico" -Destination "$BuildDirectory\CPP\7zip\Archive\Icons"

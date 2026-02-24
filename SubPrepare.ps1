param(
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildDirectory,
    [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
    [string] $BuildVersion
)

Copy-Item -Force -Recurse -Path "FileIcons\*.ico" -Destination "$BuildDirectory\CPP\7zip\Archive\Icons"

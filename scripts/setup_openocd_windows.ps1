$SdkRelease = "v2.2.0-2"
$OpenOcdVersion = "0.12.0+dev"
$Pkg = "openocd-$OpenOcdVersion-x64-win.zip"
$ZipPath = Join-Path $env:TEMP $Pkg
$OutRoot = Join-Path $HOME ".pico-sdk\openocd\$OpenOcdVersion"

# fresh dir
Remove-Item -LiteralPath $OutRoot -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force -Path $OutRoot | Out-Null

# (re)download
Invoke-WebRequest -Uri "https://github.com/raspberrypi/pico-sdk-tools/releases/download/$SdkRelease/$Pkg" `
    -OutFile $ZipPath -UseBasicParsing

# extract with 7z
7z x $ZipPath "-o$OutRoot" -y

# normalize folder name if needed
if (Test-Path "$OutRoot\openocd-$OpenOcdVersion") {
    Rename-Item "$OutRoot\openocd-$OpenOcdVersion" "openocd"
}

# verify
(Get-ChildItem "$OutRoot" -Recurse -Filter openocd.exe -File | Select-Object -First 1).FullName
Test-Path "$OutRoot\scripts\target\rp2040.cfg"

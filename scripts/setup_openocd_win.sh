# Get windows version of pico supporting openocd
wget https://github.com/raspberrypi/pico-sdk-tools/releases/download/v2.1.0-0/openocd-0.12.0+dev-x64-win.zip

# Extract to parent directory
mkdir ../openocd
unzip openocd-0.12.0+dev-x64-win.zip -d ../openocd

# Clean up archive
rm openocd-0.12.0+dev-x64-win.zip
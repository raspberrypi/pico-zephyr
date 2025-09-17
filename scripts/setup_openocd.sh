# Get linux version of pico supporting openocd
wget https://github.com/raspberrypi/pico-sdk-tools/releases/download/v2.1.0-0/openocd-0.12.0+dev-aarch64-lin.tar.gz

# Extract to parent directory
mkdir ../openocd
tar xvzf openocd-0.12.0+dev-aarch64-lin.tar.gz -C ../openocd

# Create symbolic link for openocd so that build scripts can be shared across platforms
ln -s ../openocd/openocd ../openocd/openocd.exe

# Clean up archive
rm openocd-0.12.0+dev-aarch64-lin.tar.gz
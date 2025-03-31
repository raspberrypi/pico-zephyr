# This script should install all the dependencies to a Raspberry Pi 5 required to build, flash and debug Zephyr applications for RPi Picos
# The minimal script attempts to install the bare minimum to build, flash and debug the pico-zephyr applications
sudo apt update -y
sudo apt upgrade -y

# Zephyr dependencies
sudo apt install -y --no-install-recommends git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc libsdl2-dev libmagic1

# OpenOCD dependencies
sudo apt install -y pkg-config libtool libusb-1.0-0-dev

# Required on other linux platforms
# sudo apt install --no-install-recommends gcc-multilib g++-multilib

# Create venv
python -m venv .venv

. .venv/bin/activate

pip install west pyelftools

cd ..

west init -l pico-zephyr
west update

west packages pip --install

west zephyr-export

west sdk install -t arm-zephyr-eabi

# Build openocd
cd openocd
./bootstrap
./configure --enable-ftdi --enable-sysfsgpio --enable-bcm2835gpio --disable-werror
make -j4

# Generate build scripts
cd ../pico-zephyr
./scripts/build_scripts.sh
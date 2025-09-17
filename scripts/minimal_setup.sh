# This script should install all the dependencies to a Raspberry Pi 5 required to build, flash and debug Zephyr applications for RPi Picos
# The minimal script attempts to install the bare minimum to build, flash and debug the pico-zephyr applications
sudo apt update -y
sudo apt upgrade -y

# Zephyr dependencies
sudo apt install -y --no-install-recommends cmake gperf \
  ccache dfu-util \
  libsdl2-dev

# Create venv
python -m venv .venv

. .venv/bin/activate

pip install west pyelftools

cd ..

west init -l pico-zephyr
west update

west packages pip --install

west blobs fetch hal_infineon
west zephyr-export

west sdk install -t arm-zephyr-eabi

# Generate build scripts
cd pico-zephyr
./scripts/build_scripts.sh

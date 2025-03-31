# This script should install all the dependencies to a Raspberry Pi 5 required to build, flash and debug Zephyr applications for RPi Picos
sudo apt update -y
sudo apt upgrade -y

sudo apt install -y --no-install-recommends git cmake ninja-build gperf \
  ccache dfu-util device-tree-compiler wget \
  python3-dev python3-pip python3-setuptools python3-tk python3-wheel xz-utils file \
  make gcc libsdl2-dev libmagic1

# Required on other linux platforms
# sudo apt install --no-install-recommends gcc-multilib g++-multilib

# Create venv
python -m venv .venv

. .venv/bin/activate

pip install west pyelftools
west packages pip --install

cd ..

west init -l pico-zephyr
west update

west zephyr-export

west sdk install

# Setup pico sdk
sudo apt install -y wget
wget https://raw.githubusercontent.com/raspberrypi/pico-setup/master/pico_setup.sh

chmod +x pico_setup.sh

./pico_setup.sh


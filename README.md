# Pico Zephyr Project

This repo contains setup instructions and example for working with [Zephyr](https://zephyrproject.org/) on the Raspberry Pi Pico and Pico 2 boards.

The aim is to make it easy to get set up and going, with examples that point towards more complex applications.

# Instructions

## Installation

From a blank Raspberry Pi image, open a terminal, create a folder and go into it:

```bash
mkdir dev
cd dev
```

Clone this repository:

```bash
git clone https://github.com/raspberrypi/pico-zephyr.git
```

Run the setup script:

```bash
cd pico-zephyr
./scripts/setup.sh
```

This command will take a few minutes to run, as it is downloading and installing Zephyr dependencies.

While the command is running, plug your Pico board in via the Debug Probe:

![Debug Probe setup for Pico and Pico 2](https://www.raspberrypi.com/documentation/microcontrollers/images/labelled-wiring.jpg)

## Building and Flashing

### Command Line

When the installation has finished, build the example image for your Pico:

```bash
# For Pico (H)
./scripts/build.sh -b rpi_pico
# For Pico W(H)
./scripts/build.sh -b rpi_pico/rp2040/w
# For Pico 2 (H)
./scripts/build.sh -b rpi_pico2/rp2350a/m33
# For Pico 2 W(H)
./scripts/build.sh -b rpi_pico2/rp2350a/m33/w
```

By default, this will use the UART serial port.
To use the USB serial port which also powers the Pico, add `usb_serial_port` when building:

```bash
./scripts/build.sh -s
```

Note that when switching between UART and USB serial, it may be necessary to delete the build directory for this change to take effect.

Flash the Pico:

```bash
. .venv/bin/activate
west flash
```

### VSCode

Install VSCode with:

```bash
./scripts/vscode_setup.sh
# Or add this to your setup command
./scripts/setup.sh --vscode
```

This will install Microsoft Visual Studio Code and the [pico-vscode](https://marketplace.visualstudio.com/items?itemName=raspberry-pi.raspberry-pi-pico) extension.

Open this folder in VSCode. (You can run `code .` from the command line.)

To build, press the 'Compile' button in the bottom bar.

### View Output (Linux)

View the output via serial port with:

```bash
minicom -D /dev/ttyACM0
```

You may need to change `/dev/ttyACM0` to another value depending on the serial port the Debug Probe is recognised on.
When the USB serial port is in use, it will may be found on a `/dev/ttyACM1`.
Find the port using `ls /dev/tty*` while plugging and unplugging the debug probe or Pico board to see which values change.

## Debugging

### Command Line

Debug with gdb:

```bash
west debug
...
(gdb) break main
(gdb) run
...
(gdb) n
...
```

### VSCode

Install VSCode with:

```bash
./scripts/vscode_setup.sh
```

This will install VSCode and the [Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug) extension.

Open this folder in VSCode. You can run `code .` from the command line.

To debug, press `Ctrl+Shift+D` to open the `Run and Debug` pane.

At the top, next to the `Start Debugging` button, you can select `RP2040 Debug (Zephyr)` or `RP2350 Debug (Zephyr)` for the chip you are targetting.
Press `Enter` to confirm the OpenOCD path or change it to the directory where OpenOCD is installed.

VSCode will then enter the debugging view starting in `main`, where you can step over each instruction and inspect the source code.
Further debugging instructions can be found [here](https://code.visualstudio.com/docs/debugtest/debugging#_debug-actions).

# More Examples

## Wifi Example

The `wifi` example connects to a Wi-Fi network, pings `8.8.8.8`, and performs HTTP GET and POST requests with JSON.

To begin, create a file in `wifi_example/src/` called `wifi_info.h` and add the SSID and PSK for the Wi-Fi network:

> [!CAUTION]
> NEVER COMMIT OR SHARE THIS FILE PUBLICLY - This could be a big security issue and is for demonstration purposes only

```c
// wifi/src/wifi_info.h
#define WIFI_SSID "MySSID"
#define WIFI_PSK  "my_password"
```

Then build (currently only supports Pico W):

```bash
./scripts/build.sh -p wifi -b rpi_pico/rp2040/w
```

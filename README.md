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
./scripts/minimal_setup.sh
```

This command will take a few minutes to run, as it is downloading and installing Zephyr dependencies.

While the command is running, plug your Pico board in via the Debug Probe:

![Debug Probe setup for Pico and Pico 2](https://www.raspberrypi.com/documentation/microcontrollers/images/labelled-wiring.jpg)

## Building and Flashing

### Command Line

When the installation has finished, build the example image for your Pico:

```bash
# For Pico H and Pico WH using RP2040:
build_rp2040.sh
# For Pico 2 and Pico 2W using RP2350:
build_rp2350.sh
```

Flash the Pico:
```bash
. .venv/bin/activate
west flash
```

### VSCode

Install VSCode with:

```bash
./scripts/vscode_setup.sh
```

This will install VSCode and the [Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug) extension.

Open this folder in VSCode. You can run `code` from the command line.

To build, press `Ctrl+Shift+B` and select either `Zephyr Build RP2040` or `Zephyr Build RP2350` for the chip you are targetting.

To flash, press `Ctrl+Shift+B` and select `Zephyr Flash`.

## Debugging

### Command Line

Debug with gdb:
```bash
west debug
...
(gdb) break main
(gdb) run
Thread 1 "rp2350.dap.core0" hit Breakpoint 1, main () at /home/user/dev/pico-zephyr/app/src/main.c:8
8               printk("Zephyr Example Application for Pico\n");
(gdb) n
11                      printk("Running on %s...\n", CONFIG_BOARD);
(gdb) n
13                      k_sleep(K_MSEC(1000));
(gdb) n
10              while (1) {
(gdb) n
11                      printk("Running on %s...\n", CONFIG_BOARD);
(gdb) n
13                      k_sleep(K_MSEC(1000));
(gdb) n
```

View the output via serial port with:

```bash
minicom -D /dev/ttyACM0
```

You may need to change `/dev/ttyACM0` to another value depending on the serial port the Debug Probe is recognised on.
Find the port using `ls /dev/tty*`

### VSCode

Install VSCode with:

```bash
./scripts/vscode_setup.sh
```

This will install VSCode and the [Cortex-Debug](https://marketplace.visualstudio.com/items?itemName=marus25.cortex-debug) extension.

Open this folder in VSCode. You can run `code` from the command line.

To debug, press `Ctrl+Shift+D` to open the `Run and Debug` pane.

At the top, next to the `Start Debugging` button, you can select `RP2040 Debug (Zephyr)` or `RP2350 Debug (Zephyr)`  for the chip you are targetting.

VSCode will then enter the debugging view starting in `main`, where you can step over each instruction and inspect the source code.
Further debugging instructions can be found [here](https://code.visualstudio.com/docs/debugtest/debugging#_debug-actions).
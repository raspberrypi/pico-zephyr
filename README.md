# Pico Zephyr Project

This repo contains setup instructions and example for working with [Zephyr](https://zephyrproject.org/) on the Raspberry Pi Pico and Pico 2 boards.

The aim is to make it easy to get set up and going, with examples that point towards more complex applications.

# Instructions

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

# VSCode

Use VSCode to build and debug the app for RP2040 or RP2350
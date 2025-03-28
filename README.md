# Pico Zephyr Project

This repo contains setup instructions and example for working with [Zephyr](https://zephyrproject.org/) on the Raspberry Pi Pico and Pico 2 boards.

The aim is to make it easy to get set up and going, with examples that point towards more complex applications.

# Build and Flash

Pico:

```bash
west build -b rpi_pico app -p=auto
west flash -r openocd --openocd=/usr/local/bin/openocd
```

Pico2:

```bash
west build -b rpi_pico2/rp2350a/m33 app -p=auto
west flash -r openocd --openocd=/usr/local/bin/openocd
```

# VSCode

Use VSCode to build and debug the app for RP2040 or RP2350
# Setup (RPi 5, minimal)

```
./scripts/setup_zephyr_minimal.sh
```

# Or full toolchain + extras

```
./scripts/setup_zephyr_full.sh
```

# Optional: OpenOCD (RPi 5 Linux)

```
./scripts/setup_openocd_linux.sh
```

# Windows OpenOCD (PowerShell)

```
pwsh -File scripts/setup_openocd_windows.ps1
```

# VS Code + Pico extension

```
./scripts/vscode_setup.sh
```

# Build examples

```
./scripts/build.sh -b rpi_pico
./scripts/build.sh -b rpi_pico/rp2040/w -a app -- clean
./scripts/build.sh -b rpi_pico2/rp2350a/m33 -a samples/basic/blinky -s
```

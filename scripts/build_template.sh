echo "Building RPI_PICO_BOARD with command:"
set -x
SNIPPET_ROOT="$(pwd)" west build -b RPI_PICO_BOARD app -p auto -S usb_serial_port -- -DOPENOCD=OPENOCD_INSTALL_DIR/src/openocd -DOPENOCD_DEFAULT_PATH=OPENOCD_INSTALL_DIR/tcl
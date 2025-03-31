echo "Building RPI_PICO_BOARD with command:"
set -x
west build -b RPI_PICO_BOARD app -p auto -- -DOPENOCD=OPENOCD_INSTALL_DIR/openocd/src/openocd -DOPENOCD_DEFAULT_PATH=OPENOCD_INSTALL_DIR/tcl
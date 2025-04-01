echo "Building RPI_PICO_BOARD with command:"
set -x
west build -b RPI_PICO_BOARD app -p auto -- -DOPENOCD=OPENOCD_INSTALL_DIR/src/openocd -DOPENOCD_DEFAULT_PATH=OPENOCD_INSTALL_DIR/tcl -DEXTRA_CONF_FILE="usb_serial_port/usb_serial_port.conf" -DEXTRA_DTC_OVERLAY_FILE="usb_serial_port.overlay"
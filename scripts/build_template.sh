# Check for an argument of usb_serial_port to add snippet
if [ $# -eq 1 ]
    then if [ "$1" == "usb_serial_port" ]
        then
            SNIPPET_USB="-S usb_serial_port"
        else
            SNIPPET_USB=""
    fi
fi

echo "Building RPI_PICO_BOARD with command:"
set -x
SNIPPET_ROOT="$(pwd)" west build -b RPI_PICO_BOARD app -p auto $SNIPPET_USB -- -DOPENOCD=OPENOCD_INSTALL_DIR/src/openocd -DOPENOCD_DEFAULT_PATH=OPENOCD_INSTALL_DIR/tcl
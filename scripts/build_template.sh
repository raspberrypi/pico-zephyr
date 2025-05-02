# Check for an argument of usb_serial_port to add snippet

# Defaults
APP="app"
SNIPPET_USB=""

if [ $# -eq 1 ]
    then if [ "$1" == "usb_serial_port" ]
        then
            SNIPPET_USB="-S usb_serial_port"
        else
            APP=$1
    fi
fi

if [ $# -eq 2 ]
    then if [ "$2" == "usb_serial_port" ]
        then
            SNIPPET_USB="-S usb_serial_port"
    fi
    APP=$1
fi

. .venv/bin/activate
echo "Building RPI_PICO_BOARD with command:"
set -x
SNIPPET_ROOT="$(pwd)" west build -b RPI_PICO_BOARD $APP -p auto $SNIPPET_USB -- -DOPENOCD=OPENOCD_INSTALL_DIR/openocd.exe -DOPENOCD_DEFAULT_PATH=OPENOCD_INSTALL_DIR/scripts

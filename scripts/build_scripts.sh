cp scripts/build.sh build_rp2040.sh
cp scripts/build.sh build_rp2350.sh

sed -i "s/RPI_PICO_BOARD/rpi_pico/g" build_rp2040.sh
sed -i "s,RPI_PICO_BOARD,rpi_pico/rp2350a/m33,g" build_rp2350.sh

sed -i "s,OPENOCD_INSTALL_DIR,$(readlink -f ../openocd),g" build_rp*

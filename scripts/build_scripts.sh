cp scripts/build_template.sh build_rp2040.sh
cp scripts/build_template.sh build_rp2040_w.sh
cp scripts/build_template.sh build_rp2350.sh

sed -i "s/RPI_PICO_BOARD/rpi_pico/g" build_rp2040.sh
sed -i "s,RPI_PICO_BOARD,rpi_pico/rp2040/w,g" build_rp2040_w.sh
sed -i "s,RPI_PICO_BOARD,rpi_pico2/rp2350a/m33,g" build_rp2350.sh

sed -i "s,OPENOCD_INSTALL_DIR,~/.pico-sdk/openocd/0.12.0+dev,g" build_rp*

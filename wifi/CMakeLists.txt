#pico-zephyr-project
#-------------------------------------------------------------------------------
# Zephyr Wi-Fi Example Application
#
# SPDX-License-Identifier: Apache-2.0
#-------------------------------------------------------------------------------
# NOTE: Please do not remove the #pico-zephyr-project header, it is used by
# the Raspberry Pi Pico VS Code extension to identify the project type.
#-------------------------------------------------------------------------------

cmake_minimum_required(VERSION 3.20.0)

find_package(Zephyr REQUIRED HINTS $ENV{ZEPHYR_BASE})
project(wifi LANGUAGES C)

target_sources(app PRIVATE src/main.c src/http.c src/ping.c src/wifi.c)
